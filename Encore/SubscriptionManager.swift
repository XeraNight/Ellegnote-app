import Foundation
import SwiftUI
import StoreKit
import Combine
import OSLog
import Supabase

// MARK: - Subscription & Entitlements Manager
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Published State
    @Published var currentTier: SubscriptionTier = .free
    @Published var entitlementSource: EntitlementSource = .none
    @Published var isAccountBanned: Bool = false
    @Published var banReason: String = ""
    @Published var isCheckingEntitlements: Bool = false
    @Published var availableProducts: [Product] = []
    @Published var isPurchasing: Bool = false
    
    // Known Developer / Owner emails with automatic God-mode access
    public static let ownerEmails: Set<String> = [
        "jakubkalina61@gmail.com",
        "kalinajakub19@gmail.com",
        "admin@encore-dance.com"
    ]
    
    // Product IDs for Apple App Store (StoreKit 2)
    public enum ProductID {
        static let plusMonthly = "com.jakub.encore.plus.monthly"
        static let plusAnnual = "com.jakub.encore.plus.annual"
        static let studioMonthly = "com.jakub.encore.studio.monthly"
        static let studioAnnual = "com.jakub.encore.studio.annual"
        
        static let all: [String] = [plusMonthly, plusAnnual, studioMonthly, studioAnnual]
    }
    
    private var transactionListener: Task<Void, Error>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Start listening to StoreKit 2 transactions
        transactionListener = listenForTransactions()
        
        // React to auth changes to immediately refresh entitlements
        AuthManager.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.refreshEntitlements()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Owner Check
    public var isAppOwner: Bool {
        let email = AuthManager.shared.userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if Self.ownerEmails.contains(email) { return true }
        if let metaRole = AuthManager.shared.currentUser?.userMetadata["role"] {
            if case let .string(r) = metaRole, r.lowercased() == "owner" { return true }
        }
        return false
    }
    
    // MARK: - Capability Matrix
    /// Tanečník si môže sledovať svoje vlastné body a históriu zo súťaží (Plus & Studio)
    public var canTrackOwnPoints: Bool {
        isAppOwner || currentTier == .plus || currentTier == .studio
    }
    
    /// Tréner / pokročilý môže sledovať body a súťaže cudzích párov a zverencov (Iba Studio)
    public var canTrackRosterPoints: Bool {
        isAppOwner || currentTier == .studio
    }
    
    /// Prístup k trénerskej sekcii Štúdio (Roster párov, hromadné figúry, video anotácie)
    public var canAccessStudioRoster: Bool {
        isAppOwner || currentTier == .studio
    }
    
    /// Možnosť zdieľať zostavy s partnerom v cloude
    public var canShareWithPartner: Bool {
        isAppOwner || currentTier == .plus || currentTier == .studio
    }
    
    /// Maximálny počet vytvorených zostáv (Free = 2, Plus/Studio = neobmedzene)
    public var maxRoutinesAllowed: Int {
        (isAppOwner || currentTier == .plus || currentTier == .studio) ? 9999 : 2
    }
    
    // MARK: - Entitlements Refresh & Verification
    public func refreshEntitlements() async {
        isCheckingEntitlements = true
        defer { isCheckingEntitlements = false }
        
        // 1. Priorita: Majiteľ aplikácie (God Mode / SuperAdmin)
        if isAppOwner {
            currentTier = .studio
            entitlementSource = .appOwner
            isAccountBanned = false
            return
        }
        
        // 2. Skontrolovať moderátorský stav účtu (Ban status)
        await checkAccountBanStatus()
        if isAccountBanned {
            currentTier = .free
            entitlementSource = .none
            return
        }
        
        // 3. Skontrolovať manuálny VIP / Comped grant zo Supabase
        if let supabaseGrant = await fetchSupabaseEntitlement() {
            if supabaseGrant.isValid {
                currentTier = supabaseGrant.tier
                entitlementSource = supabaseGrant.source
                return
            }
        }
        
        // 4. Skontrolovať Apple StoreKit 2 nákupy
        let storeKitTier = await checkStoreKitEntitlements()
        if storeKitTier != .free {
            currentTier = storeKitTier
            entitlementSource = .storeKit
            return
        }
        
        // 5. Fallback na Free plán
        currentTier = .free
        entitlementSource = .none
    }
    
    // MARK: - StoreKit 2 Transactions Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await self.refreshEntitlements()
                    await transaction.finish()
                } catch {
                    Logger.auth.error("StoreKit transaction update failed verification: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
    
    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Check StoreKit 2 Entitlements
    private func checkStoreKitEntitlements() async -> SubscriptionTier {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            
            // Check if transaction is still active / not revoked
            if transaction.revocationDate == nil {
                let pid = transaction.productID
                if pid == ProductID.studioMonthly || pid == ProductID.studioAnnual {
                    return .studio
                } else if pid == ProductID.plusMonthly || pid == ProductID.plusAnnual {
                    return .plus
                }
            }
        }
        return .free
    }
    
    // MARK: - Load Products
    public func loadProducts() async {
        do {
            let products = try await Product.products(for: ProductID.all)
            self.availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            Logger.auth.warning("Failed to load StoreKit products: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Purchase
    public func purchase(product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            Logger.auth.warning("StoreKit restorePurchases failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Supabase Entitlement Verification (VIP / Comped)
    private func fetchSupabaseEntitlement() async -> UserEntitlementRecord? {
        guard let userUUID = AuthManager.shared.currentUser?.id else { return nil }
        let client = SupabaseConfig.client
        
        do {
            struct EntitlementDTO: Decodable {
                let user_id: UUID
                let tier: String
                let source: String
                let expires_at: String?
                let granted_by: UUID?
                let notes: String?
            }
            
            let res: EntitlementDTO = try await client
                .from("user_entitlements")
                .select()
                .eq("user_id", value: userUUID)
                .single()
                .execute()
                .value
            
            let tier = SubscriptionTier(rawValue: res.tier.capitalized) ?? .free
            let source = EntitlementSource(rawValue: res.source) ?? .none
            var expiresDate: Date? = nil
            if let exp = res.expires_at {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                expiresDate = iso.date(from: exp) ?? ISO8601DateFormatter().date(from: exp)
            }
            
            return UserEntitlementRecord(
                userId: res.user_id,
                tier: tier,
                source: source,
                expiresAt: expiresDate,
                grantedBy: res.granted_by,
                notes: res.notes
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Check Account Moderation / Ban Status
    private func checkAccountBanStatus() async {
        guard let userUUID = AuthManager.shared.currentUser?.id else { return }
        let client = SupabaseConfig.client
        
        do {
            struct ProfileStatusDTO: Decodable {
                let account_status: String?
                let ban_reason: String?
            }
            
            let res: ProfileStatusDTO = try await client
                .from("profiles")
                .select("account_status, ban_reason")
                .eq("id", value: userUUID)
                .single()
                .execute()
                .value
            
            if let status = res.account_status, (status == "banned" || status == "suspended") {
                self.isAccountBanned = true
                self.banReason = res.ban_reason ?? "Porušenie pravidiel komunity a Podmienok používania aplikácie."
            } else {
                self.isAccountBanned = false
                self.banReason = ""
            }
        } catch {
            // Offline or table column not yet created -> default to active
        }
    }
    
    // MARK: - Admin Actions (Exclusively for App Owner)
    
    /// Udeliť používateľovi bezplatný tier (VIP / Partner / Tréner)
    public func grantEntitlementAsOwner(
        targetUserId: UUID,
        tier: SubscriptionTier,
        durationMonths: Int?, // nil = lifetime
        notes: String
    ) async throws {
        guard isAppOwner else { throw NSError(domain: "EncoreAdmin", code: 403, userInfo: [NSLocalizedDescriptionKey: "Nemáš oprávnenie majiteľa aplikácie."]) }
        let client = SupabaseConfig.client
        
        var expiresAtString: String? = nil
        if let months = durationMonths, months > 0 {
            let future = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
            let iso = ISO8601DateFormatter()
            expiresAtString = iso.string(from: future)
        }
        
        struct UpsertPayload: Encodable {
            let user_id: UUID
            let tier: String
            let source: String
            let expires_at: String?
            let granted_by: UUID?
            let notes: String
        }
        
        let payload = UpsertPayload(
            user_id: targetUserId,
            tier: tier.rawValue.lowercased(),
            source: EntitlementSource.ownerGrant.rawValue,
            expires_at: expiresAtString,
            granted_by: AuthManager.shared.currentUser?.id,
            notes: notes
        )
        
        try await client
            .from("user_entitlements")
            .upsert(payload)
            .execute()
    }
    
    /// Zablokovať alebo odblokovať používateľský účet
    public func setAccountBanStatusAsOwner(
        targetUserId: UUID,
        isBanned: Bool,
        reason: String
    ) async throws {
        guard isAppOwner else { throw NSError(domain: "EncoreAdmin", code: 403, userInfo: [NSLocalizedDescriptionKey: "Nemáš oprávnenie majiteľa aplikácie."]) }
        let client = SupabaseConfig.client
        
        struct UpdatePayload: Encodable {
            let account_status: String
            let ban_reason: String?
        }
        
        let payload = UpdatePayload(
            account_status: isBanned ? "banned" : "active",
            ban_reason: isBanned ? reason : nil
        )
        
        try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: targetUserId)
            .execute()
    }
}
