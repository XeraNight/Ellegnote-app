import Foundation
import SwiftUI

// MARK: - Subscription Tiers
public enum SubscriptionTier: String, CaseIterable, Codable, Sendable {
    case free = "Free"
    case plus = "Plus"
    case studio = "Studio"
    
    public var title: String { rawValue }
    
    public var shortDescription: String {
        switch self {
        case .free:
            return "Základné tréningové plátno, 1 zostava na každý tanec, metronóm"
        case .plus:
            return "Neobmedzené zostavy na tanec, Apple Kalendár sync, Top 3 priority, hosťovský kľúč trénera, KSIS kalkulačka, Optima parket (Košice)"
        case .studio:
            return "KSIS Radar súperov & priateľov s notifikáciami, biomechanická video analýza držania tela, Video Duel, trénerský denník"
        }
    }
    
    public var monthlyPriceFormatted: String {
        switch self {
        case .free: return "0,00 €"
        case .plus: return "5,99 €"
        case .studio: return "14,99 €"
        }
    }
    
    public var annualPriceFormatted: String {
        switch self {
        case .free: return "0,00 €"
        case .plus: return "49,99 €"
        case .studio: return "129,99 €"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .free: return Color.gray
        case .plus: return Color.amberGold
        case .studio: return Color.gold400
        }
    }
    
    public var iconName: String {
        switch self {
        case .free: return "sparkles"
        case .plus: return "crown.fill"
        case .studio: return "building.columns.fill"
        }
    }
}

// MARK: - Comparable Conformance for Priority Comparison
extension SubscriptionTier: Comparable {
    public var rank: Int {
        switch self {
        case .free: return 0
        case .plus: return 1
        case .studio: return 2
        }
    }
    
    public static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rank < rhs.rank
    }
}

// MARK: - Entitlement Source
public enum EntitlementSource: String, Codable, Sendable {
    case storeKit = "storekit"         // Paid via Apple App Store
    case ownerGrant = "owner_grant"     // Gifted by app owner (Comped / VIP)
    case appOwner = "app_owner"         // Developer / Owner himself
    case none = "none"
}

// MARK: - User Entitlement Record (from Supabase or local cache)
public struct UserEntitlementRecord: Codable, Sendable {
    public let userId: UUID
    public let tier: SubscriptionTier
    public let source: EntitlementSource
    public let expiresAt: Date?
    public let grantedBy: UUID?
    public let notes: String?
    
    public var isValid: Bool {
        guard let exp = expiresAt else { return true } // nil means lifetime
        return exp > Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case source
        case expiresAt = "expires_at"
        case grantedBy = "granted_by"
        case notes
    }
}

// MARK: - Account Moderation Status
public enum AccountModerationStatus: String, Codable, Sendable {
    case active = "active"
    case suspended = "suspended"
    case banned = "banned"
}
