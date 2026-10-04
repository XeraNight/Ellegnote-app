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
    @Published var isRefreshingToken: Bool = false
    @Published var inviteErrorMessage: String? = nil
    @Published var activeInviteToken: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadFriends()
        
        // Reload friends and check pending invite codes when active user changes
        UserProfileStore.shared.$currentName
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadFriends()
                self?.checkPendingInviteAfterLogin()
                Task {
                    await self?.fetchOrGenerateInviteToken()
                }
            }
            .store(in: &cancellables)
    }
    
    private var storageKey: String {
        let uid = UserProfileStore.shared.activeUserId
        return "encore_dancer_friends_\(uid)"
    }
    
    // MARK: - Token Management
    func fetchOrGenerateInviteToken() async {
        guard AuthManager.shared.isAuthenticated else { return }
        let client = SupabaseConfig.client
        let uid = UserProfileStore.shared.activeUserId
        
        if let cached = UserDefaults.standard.string(forKey: "encore_active_invite_token_\(uid)"), !cached.isEmpty {
            self.activeInviteToken = cached
        }
        
        do {
            struct TokenParams: Encodable {
                let p_expires_in_days: Int
            }
            let token: String = try await client.rpc(
                "create_friend_invite_token",
                params: TokenParams(p_expires_in_days: 7)
            ).execute().value
            
            self.activeInviteToken = token
            UserDefaults.standard.set(token, forKey: "encore_active_invite_token_\(uid)")
        } catch {
            print("Token generation fallback: \(error.localizedDescription)")
            if activeInviteToken.isEmpty {
                activeInviteToken = "tok_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16)
            }
        }
    }
    
    func refreshInviteToken() async {
        isRefreshingToken = true
        HapticFeedback.light()
        await fetchOrGenerateInviteToken()
        isRefreshingToken = false
        HapticFeedback.success()
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
    
    // MARK: - Add Friend & Local Cache
    @discardableResult
    func addFriend(from invite: FriendInvitePayload) -> Bool {
        let currentUserId = UserProfileStore.shared.activeUserId
        let myCode = UserProfileStore.shared.currentInviteCode
        
        if invite.userId.lowercased() == currentUserId.lowercased() ||
           (!myCode.isEmpty && invite.userId.uppercased() == myCode.uppercased()) {
            return false
        }
        
        if let index = friends.firstIndex(where: { $0.userId.lowercased() == invite.userId.lowercased() }) {
            friends[index].name = invite.name
            friends[index].club = invite.club
            friends[index].avatarURL = invite.avatarURL
            saveFriends()
            return true
        }
        
        let newFriend = DancerFriend(
            userId: invite.userId,
            name: invite.name,
            club: invite.club,
            avatarURL: invite.avatarURL,
            addedAt: Date(),
            status: .active,
            sharedRoutinesCount: 0
        )
        friends.insert(newFriend, at: 0)
        saveFriends()
        HapticFeedback.success()
        return true
    }
    
    func removeFriend(id: UUID) {
        friends.removeAll { $0.id == id }
        saveFriends()
    }
    
    // MARK: - Member Card Smart URL Generator
    func buildMemberCardURL() -> String {
        if !activeInviteToken.isEmpty {
            return "https://encore-app.vercel.app/add?t=\(activeInviteToken)"
        }
        let code = UserProfileStore.shared.dancerCode
        if !code.isEmpty {
            return "https://encore-app.vercel.app/add/\(code)"
        }
        return "https://encore-app.vercel.app/add"
    }
    
    // MARK: - Universal Link / Deep Link Handler
    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        // 1. Universal Link with Token query param: /add?t=tok_...
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let tokenParam = components.queryItems?.first(where: { $0.name == "t" || $0.name == "token" })?.value, !tokenParam.isEmpty {
                return processInviteToken(tokenParam)
            }
        }
        
        // 2. Universal Link path: /add/[code]
        if (url.host == "encore-app.vercel.app" || url.host?.contains("encore") == true) && url.path.hasPrefix("/add/") {
            let code = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !code.isEmpty {
                if code.starts(with: "tok_") {
                    return processInviteToken(code)
                }
                return processInviteCode(code.uppercased())
            }
        }
        
        // 3. Custom URL Scheme: encore://friend/add?t=... OR encore://add?t=...
        if url.scheme == "encore" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                if let tokenParam = components.queryItems?.first(where: { $0.name == "t" || $0.name == "token" })?.value, !tokenParam.isEmpty {
                    return processInviteToken(tokenParam)
                }
                if let codeParam = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    return processInviteCode(codeParam)
                }
            }
            return parseAndPresentLegacyInvite(from: url)
        }
        
        // 4. Legacy Profile Link: /u/{userId}
        if (url.host == "encore-app.vercel.app" || url.host?.contains("encore") == true) && url.path.hasPrefix("/u/") {
            return parseAndPresentLegacyInvite(from: url)
        }
        
        return false
    }
    
    // MARK: - Process Token Invite (Opaque Token)
    @discardableResult
    func processInviteToken(_ token: String) -> Bool {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return false }
        
        if !AuthManager.shared.isAuthenticated {
            UserDefaults.standard.set(cleanToken, forKey: "encore_pending_invite_token")
            return true
        }
        
        isProcessingInvite = true
        inviteErrorMessage = nil
        
        Task {
            await fetchAndPresentTokenInvite(token: cleanToken)
        }
        return true
    }
    
    // MARK: - Process Legacy Invite Code
    @discardableResult
    func processInviteCode(_ code: String) -> Bool {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCode.isEmpty else { return false }
        
        if !AuthManager.shared.isAuthenticated {
            UserDefaults.standard.set(cleanCode, forKey: "encore_pending_invite_code")
            return true
        }
        
        if cleanCode == UserProfileStore.shared.currentInviteCode || cleanCode == UserProfileStore.shared.dancerCode {
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
        if let pendingToken = defaults.string(forKey: "encore_pending_invite_token"), !pendingToken.isEmpty {
            defaults.removeObject(forKey: "encore_pending_invite_token")
            processInviteToken(pendingToken)
            return
        }
        if let pending = defaults.string(forKey: "encore_pending_invite_code"), !pending.isEmpty {
            defaults.removeObject(forKey: "encore_pending_invite_code")
            processInviteCode(pending)
        }
    }
    
    // MARK: - Deferred Deep Link Pasteboard Inspection
    func checkPasteboardForDeferredInvite() {
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
    
    // MARK: - Fetch Token Preview from Supabase RPC
    private func fetchAndPresentTokenInvite(token: String) async {
        defer { isProcessingInvite = false }
        let client = SupabaseConfig.client
        
        do {
            struct PreviewParams: Encodable {
                let p_token: String
            }
            struct InviterData: Decodable {
                let name: String
                let club: String
                let avatar_url: String?
                let ksis_id: String?
                let dancer_code: String?
                let dancer_groups: [String]?
            }
            struct PreviewResponse: Decodable {
                let success: Bool
                let error_code: String?
                let message: String?
                let is_self: Bool?
                let already_connected: Bool?
                let is_pending: Bool?
                let inviter: InviterData?
            }
            
            let res: PreviewResponse = try await client.rpc(
                "get_friend_invite_preview",
                params: PreviewParams(p_token: token)
            ).execute().value
            
            if !res.success {
                if res.error_code == "REVOKED" {
                    self.inviteErrorMessage = "Tento QR kód bol zrušený a obnovený novým."
                } else if res.error_code == "EXPIRED" {
                    self.inviteErrorMessage = "Platnosť tohto QR kódu vypršala."
                } else {
                    self.inviteErrorMessage = "Pozvánka neexistuje alebo bola odstránená."
                }
                HapticFeedback.warning()
                return
            }
            
            if res.is_self == true {
                self.inviteErrorMessage = "Nemôžeš poslať pozvánku sám sebe."
                HapticFeedback.warning()
                return
            }
            
            if res.already_connected == true {
                self.inviteErrorMessage = "Tento tanečník už je vo vašich spojeniach."
                HapticFeedback.warning()
                return
            }
            
            if res.is_pending == true {
                self.inviteErrorMessage = "Pozvánka tomuto tanečníkovi už bola odoslaná."
                HapticFeedback.warning()
                return
            }
            
            guard let inviter = res.inviter else {
                self.inviteErrorMessage = "Dáta pozvánky nie sú dostupné."
                return
            }
            
            let payload = FriendInvitePayload(
                userId: inviter.dancer_code ?? token,
                name: inviter.name,
                club: inviter.club,
                action: "add_friend",
                ksisId: inviter.ksis_id,
                dancerCode: inviter.dancer_code,
                dancerGroups: inviter.dancer_groups ?? [],
                avatarURL: inviter.avatar_url,
                token: token
            )
            presentPayload(payload)
        } catch {
            self.inviteErrorMessage = "Nepodarilo sa overiť pozvánku: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }
    
    // MARK: - Respond to Incoming Invite (Accept or Decline)
    func respondToIncomingInvite(accept: Bool) async -> Bool {
        guard let token = incomingInvite?.token else {
            // Fallback for legacy invites
            if accept, let payload = incomingInvite {
                addFriend(from: payload)
            }
            showInviteSheet = false
            incomingInvite = nil
            return true
        }
        
        let client = SupabaseConfig.client
        isProcessingInvite = true
        defer { isProcessingInvite = false }
        
        do {
            struct RPCParams: Encodable {
                let p_token: String
                let p_accept: Bool
            }
            struct RPCResponse: Decodable {
                let success: Bool
                let message: String?
                let error_code: String?
            }
            let res: RPCResponse = try await client.rpc(
                "respond_to_friend_invite",
                params: RPCParams(p_token: token, p_accept: accept)
            ).execute().value
            
            if res.success && accept {
                if let payload = incomingInvite {
                    addFriend(from: payload)
                }
                showInviteSheet = false
                incomingInvite = nil
                HapticFeedback.success()
                return true
            } else {
                showInviteSheet = false
                incomingInvite = nil
                if !accept {
                    HapticFeedback.light()
                } else {
                    inviteErrorMessage = res.message ?? "Nepodarilo sa prijať pozvánku."
                    HapticFeedback.error()
                }
                return res.success
            }
        } catch {
            inviteErrorMessage = "Chyba spojenia: \(error.localizedDescription)"
            HapticFeedback.error()
            return false
        }
    }
    
    // MARK: - Fetch Invite Details & Present Confirm Sheet (Legacy Code)
    private func fetchAndPresentInvite(code: String) async {
        defer { isProcessingInvite = false }
        
        // 1. Direct Dancer ID check via ConnectionManager RPC/profiles
        if code.starts(with: "DNC-") {
            let dancers = await ConnectionManager.shared.searchDancers(query: code)
            if let dancer = dancers.first(where: { $0.dancerCode.uppercased() == code }) ?? dancers.first {
                presentPayload(FriendInvitePayload(
                    userId: dancer.id.uuidString,
                    name: dancer.fullName,
                    club: dancer.club.isEmpty ? "Encore" : dancer.club,
                    action: "add_friend",
                    dancerCode: dancer.dancerCode,
                    avatarURL: dancer.avatarUrl
                ))
                return
            }
        }
        
        // 2. Fetch public profile metadata from /api/invite/[code]
        guard let url = URL(string: "https://encore-app.vercel.app/api/invite/\(code)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
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
                action: "add_friend",
                avatarURL: decoded.invite.avatarUrl
            )
            presentPayload(payload)
        } catch {
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
