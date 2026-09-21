import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - Friend & Community Manager (Supabase RPC, Universal Links & Deferred Deep Linking)
@MainActor
final class FriendManager: ObservableObject {
    static let shared = FriendManager()
    
    @Published var friends: [DancerFriend] = []
    @Published var incomingInvite: FriendInvitePayload? = nil
    @Published var showInviteSheet: Bool = false
    @Published var showDeferredInvitePrompt: Bool = false
    @Published var isProcessingInvite: Bool = false
    @Published var inviteErrorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadFriends()
        
        // Reload friends and check pending invite codes when active user changes
        UserProfileStore.shared.$currentName
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadFriends()
                self?.checkPendingInviteAfterLogin()
            }
            .store(in: &cancellables)
    }
    
    private var storageKey: String {
        let uid = UserProfileStore.shared.activeUserId
        return "encore_dancer_friends_\(uid)"
    }
    
    // MARK: - Persistence
    func loadFriends() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DancerFriend].self, from: data) {
            self.friends = decoded
        } else {
            // Default welcome partner if friend list is empty
            if defaults.object(forKey: storageKey) == nil {
                self.friends = [
                    DancerFriend(
                        userId: "encore_master",
                        name: "Encore Dance Studio",
                        club: "Akadémia Tanca",
                        avatarURL: nil,
                        addedAt: Date(),
                        status: .active,
                        sharedRoutinesCount: 2
                    )
                ]
                saveFriends()
            } else {
                self.friends = []
            }
        }
    }
    
    func saveFriends() {
        let defaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(friends) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    // MARK: - Add Friend & Supabase RPC Sync
    @discardableResult
    func addFriend(from invite: FriendInvitePayload) -> Bool {
        let currentUserId = UserProfileStore.shared.activeUserId
        let myCode = UserProfileStore.shared.currentInviteCode
        
        if invite.userId.lowercased() == currentUserId.lowercased() ||
           (!myCode.isEmpty && invite.userId.uppercased() == myCode.uppercased()) {
            // Cannot add yourself
            return false
        }
        
        // Check if already friends locally
        if let index = friends.firstIndex(where: { $0.userId.lowercased() == invite.userId.lowercased() }) {
            friends[index].name = invite.name
            friends[index].club = invite.club
            saveFriends()
            return true
        }
        
        let newFriend = DancerFriend(
            userId: invite.userId,
            name: invite.name,
            club: invite.club,
            avatarURL: nil,
            addedAt: Date(),
            status: .active,
            sharedRoutinesCount: 0
        )
        friends.insert(newFriend, at: 0)
        saveFriends()
        HapticFeedback.success()
        
        // Also sync friendship to Supabase via RPC if invite code is present
        Task {
            await syncFriendshipToSupabase(inviteCode: invite.userId)
        }
        
        return true
    }
    
    private func syncFriendshipToSupabase(inviteCode: String) async {
        guard AuthManager.shared.isAuthenticated else { return }
        let client = SupabaseConfig.client
        do {
            struct RPCParams: Encodable {
                let p_invite_code: String
            }
            let _: [String: AnyJSON] = try await client.rpc(
                "send_friend_request_by_code",
                params: RPCParams(p_invite_code: inviteCode)
            ).execute().value
        } catch {
            print("Supabase RPC send_friend_request_by_code note: \(error.localizedDescription)")
        }
    }
    
    func removeFriend(id: UUID) {
        friends.removeAll { $0.id == id }
        saveFriends()
    }
    
    // MARK: - Member Card Smart URL Generator
    func buildMemberCardURL() -> String {
        let code = UserProfileStore.shared.currentInviteCode
        let uid = UserProfileStore.shared.activeUserId
        
        if !code.isEmpty {
            return "https://encore-app.vercel.app/add/\(code)"
        }
        
        let name = UserProfileStore.shared.currentName
        let club = UserProfileStore.shared.currentClub
        var components = URLComponents(string: "https://encore-app.vercel.app/u/\(uid)")!
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "club", value: club),
            URLQueryItem(name: "action", value: "add_friend")
        ]
        return components.url?.absoluteString ?? "https://encore-app.vercel.app/u/\(uid)"
    }
    
    // MARK: - Universal Link / Deep Link Handler
    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        // 1. Universal Link: https://encore-app.vercel.app/add/[code]
        if (url.host == "encore-app.vercel.app" || url.host?.contains("encore") == true) && url.path.hasPrefix("/add/") {
            let code = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if !code.isEmpty {
                return processInviteCode(code)
            }
        }
        
        // 2. Custom URL Scheme: encore://friend/add?code=... OR ?id=...
        if url.scheme == "encore" {
            let host = url.host ?? ""
            let path = url.path
            if host == "friend" || path.contains("friend") || host == "add" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                        return processInviteCode(code)
                    }
                }
                return parseAndPresentLegacyInvite(from: url)
            }
        }
        
        // 3. Legacy Profile Link: /u/{userId}
        if (url.host == "encore-app.vercel.app" || url.host?.contains("encore") == true) && url.path.hasPrefix("/u/") {
            return parseAndPresentLegacyInvite(from: url)
        }
        
        return false
    }
    
    // MARK: - Process Invite Code with Deferred / Auth Check
    @discardableResult
    func processInviteCode(_ code: String) -> Bool {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCode.isEmpty else { return false }
        
        // If user is not authenticated, persist code for post-login auto-presentation
        if !AuthManager.shared.isAuthenticated {
            UserDefaults.standard.set(cleanCode, forKey: "encore_pending_invite_code")
            return true
        }
        
        // Don't add own code
        if cleanCode == UserProfileStore.shared.currentInviteCode {
            return false
        }
        
        isProcessingInvite = true
        
        Task {
            await fetchAndPresentInvite(code: cleanCode)
        }
        return true
    }
    
    // MARK: - Check Pending Invite After Login
    func checkPendingInviteAfterLogin() {
        guard AuthManager.shared.isAuthenticated else { return }
        let defaults = UserDefaults.standard
        if let pending = defaults.string(forKey: "encore_pending_invite_code"), !pending.isEmpty {
            defaults.removeObject(forKey: "encore_pending_invite_code")
            processInviteCode(pending)
        }
    }
    
    // MARK: - Deferred Deep Link Pasteboard Inspection
    func checkPasteboardForDeferredInvite() {
        // Safe check without triggering iOS system permission dialog
        if UIPasteboard.general.hasURLs {
            self.showDeferredInvitePrompt = true
        }
    }
    
    func applyPastedURL(_ url: URL) {
        self.showDeferredInvitePrompt = false
        if (url.host == "encore-app.vercel.app" || url.host?.contains("encore") == true) {
            _ = handleIncomingURL(url)
        }
    }
    
    // MARK: - Fetch Invite Details & Present Confirm Sheet
    private func fetchAndPresentInvite(code: String) async {
        defer { isProcessingInvite = false }
        
        // Fetch public profile metadata from /api/invite/[code]
        guard let url = URL(string: "https://encore-app.vercel.app/api/invite/\(code)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Fallback payload with raw code
                presentPayload(FriendInvitePayload(
                    userId: code,
                    name: "Tanečník (\(code))",
                    club: "Encore",
                    action: "add_friend"
                ))
                return
            }
            
            struct InviteResponse: Decodable {
                struct InviteData: Decodable {
                    let code: String
                    let name: String
                    let club: String?
                    let avatarUrl: String?
                }
                let success: Bool
                let invite: InviteData
            }
            
            let decoded = try JSONDecoder().decode(InviteResponse.self, from: data)
            let payload = FriendInvitePayload(
                userId: decoded.invite.code,
                name: decoded.invite.name,
                club: decoded.invite.club ?? "",
                action: "add_friend"
            )
            presentPayload(payload)
        } catch {
            // Local fallback
            presentPayload(FriendInvitePayload(
                userId: code,
                name: "Tanečník",
                club: "",
                action: "add_friend"
            ))
        }
    }
    
    private func presentPayload(_ payload: FriendInvitePayload) {
        self.incomingInvite = payload
        self.showInviteSheet = true
        HapticFeedback.light()
    }
    
    private func parseAndPresentLegacyInvite(from url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return false }
        
        let queryItems = components.queryItems ?? []
        let nameParam = queryItems.first(where: { $0.name == "name" })?.value
        let clubParam = queryItems.first(where: { $0.name == "club" })?.value ?? ""
        let idParam = queryItems.first(where: { $0.name == "id" })?.value
        
        var targetUserId: String = ""
        if let idParam, !idParam.isEmpty {
            targetUserId = idParam
        } else if components.path.hasPrefix("/u/") {
            targetUserId = components.path.replacingOccurrences(of: "/u/", with: "")
        }
        
        guard !targetUserId.isEmpty else { return false }
        
        let currentUserId = UserProfileStore.shared.activeUserId
        if targetUserId.lowercased() == currentUserId.lowercased() {
            return false
        }
        
        let friendName = (nameParam?.isEmpty == false) ? nameParam! : "Tanečník"
        let payload = FriendInvitePayload(
            userId: targetUserId,
            name: friendName,
            club: clubParam,
            action: "add_friend"
        )
        
        presentPayload(payload)
        return true
    }
}
