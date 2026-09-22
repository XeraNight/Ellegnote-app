import Foundation

// MARK: - KSIS User Couple Model
public struct UserCouple: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID?
    public let coupleId: Int
    public let discipline: String
    public let partnerName: String?
    public let partnerConsent: Bool
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case coupleId = "couple_id"
        case discipline
        case partnerName = "partner_name"
        case partnerConsent = "partner_consent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        coupleId: Int,
        discipline: String,
        partnerName: String? = nil,
        partnerConsent: Bool,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.coupleId = coupleId
        self.discipline = discipline
        self.partnerName = partnerName
        self.partnerConsent = partnerConsent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayTitle: String {
        if let partner = partnerName, !partner.isEmpty {
            return "\(partner) (#\(coupleId))"
        }
        return "Pár #\(coupleId) (\(discipline))"
    }

    public func fullCoupleTitle(myUserName: String? = nil) -> String {
        let me = myUserName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let partner = partnerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !me.isEmpty && !partner.isEmpty && me != "Tanečník" {
            return "\(me) & \(partner)"
        } else if !partner.isEmpty {
            return "Pár: \(partner)"
        }
        return "Pár #\(coupleId)"
    }

    public var disciplineTitle: String {
        switch discipline.uppercased() {
        case "ALL", "10T":
            return "Štandard aj Latina"
        case "STT":
            return "Štandard (STT)"
        case "LAT":
            return "Latina (LAT)"
        default:
            return discipline
        }
    }

    public var isAllDisciplines: Bool {
        discipline.uppercased() == "ALL" || discipline.uppercased() == "10T"
    }
}

// MARK: - KSIS Competition Result Model
public struct CompetitionResult: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID?
    public let sutazId: Int
    public let coupleId: Int
    public let eventName: String
    public let categoryName: String
    public let discipline: String
    public let date: String
    public let place: String?
    public let coupleCount: Int?
    public let placementText: String?
    public let placement: Int?
    public let pointsEarned: Int?
    public let cumulativeStats: String?
    public let cumulativePoints: Int?
    public let cumulativeFinals: Int?
    public let isOfficial: Bool
    public let season: String?
    public let isDeleted: Bool?
    public let deletedAt: String?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sutazId = "sutaz_id"
        case coupleId = "couple_id"
        case eventName = "event_name"
        case categoryName = "category_name"
        case discipline
        case date
        case place
        case coupleCount = "couple_count"
        case placementText = "placement_text"
        case placement
        case pointsEarned = "points_earned"
        case cumulativeStats = "cumulative_stats"
        case cumulativePoints = "cumulative_points"
        case cumulativeFinals = "cumulative_finals"
        case isOfficial = "is_official"
        case season
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        sutazId: Int,
        coupleId: Int,
        eventName: String,
        categoryName: String,
        discipline: String,
        date: String,
        place: String? = nil,
        coupleCount: Int? = nil,
        placementText: String? = nil,
        placement: Int? = nil,
        pointsEarned: Int? = nil,
        cumulativeStats: String? = nil,
        cumulativePoints: Int? = nil,
        cumulativeFinals: Int? = nil,
        isOfficial: Bool = true,
        season: String? = nil,
        isDeleted: Bool? = false,
        deletedAt: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.sutazId = sutazId
        self.coupleId = coupleId
        self.eventName = eventName
        self.categoryName = categoryName
        self.discipline = discipline
        self.date = date
        self.place = place
        self.coupleCount = coupleCount
        self.placementText = placementText
        self.placement = placement
        self.pointsEarned = pointsEarned
        self.cumulativeStats = cumulativeStats
        self.cumulativePoints = cumulativePoints
        self.cumulativeFinals = cumulativeFinals
        self.isOfficial = isOfficial
        self.season = season
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayPlacement: String {
        if let text = placementText, !text.isEmpty {
            return "\(text) m."
        }
        if let place = placement {
            return "\(place). m."
        }
        return "–"
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let d = formatter.date(from: date) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "sk_SK")
            out.dateFormat = "d. MMMM yyyy"
            return out.string(from: d)
        }
        return date
    }

    public var isFinalPlacement: Bool {
        guard let p = placement else { return false }
        return p <= 6
    }
}

// MARK: - KSIS Advancement Rule Model
public struct AdvancementRule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let category: String
    public let fromClass: String
    public let toClass: String
    public let requiredPoints: Int
    public let requiredFinals: Int
    public let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case fromClass = "from_class"
        case toClass = "to_class"
        case requiredPoints = "required_points"
        case requiredFinals = "required_finals"
        case notes
    }

    public init(
        id: UUID = UUID(),
        category: String,
        fromClass: String,
        toClass: String,
        requiredPoints: Int,
        requiredFinals: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.category = category
        self.fromClass = fromClass
        self.toClass = toClass
        self.requiredPoints = requiredPoints
        self.requiredFinals = requiredFinals
        self.notes = notes
    }

    public var ruleDescription: String {
        "\(category) \(fromClass) ➔ \(toClass) (\(requiredPoints) b. & \(requiredFinals) finále)"
    }
}

// MARK: - Edge Function Request & Response DTOs

public struct KSISImportRequest: Encodable {
    public let sutaz_id: Int
    public let couple_id: Int
    public let preview_only: Bool

    public init(sutaz_id: Int, couple_id: Int, preview_only: Bool = false) {
        self.sutaz_id = sutaz_id
        self.couple_id = couple_id
        self.preview_only = preview_only
    }
}

public struct KSISPreviewMeta: Decodable, Sendable {
    public let sutazId: Int
    public let eventName: String
    public let categoryName: String
    public let discipline: String
    public let date: String
    public let place: String?
    public let coupleCount: Int?
    public let season: String?
    public let isOfficial: Bool?
}

public struct KSISPreviewCouple: Decodable, Sendable {
    public let coupleId: Int
    public let coupleName: String?
    public let club: String?
    public let bib: String?
    public let roundName: String?
    public let placementText: String?
    public let placement: Int?
    public let pointsEarned: Int?
    public let cumulativeStats: String?
    public let cumulativePoints: Int?
    public let cumulativeFinals: Int?
    public let isOfficial: Bool?
    public let state: String?
}

public struct KSISPreviewPayload: Decodable, Sendable {
    public let meta: KSISPreviewMeta?
    public let couple: KSISPreviewCouple?
    public let stateHash: String?

    public func toCompetitionResult(userId: UUID? = nil) -> CompetitionResult? {
        guard let meta = meta, let couple = couple else { return nil }
        return CompetitionResult(
            id: UUID(),
            userId: userId,
            sutazId: meta.sutazId,
            coupleId: couple.coupleId,
            eventName: meta.eventName,
            categoryName: meta.categoryName,
            discipline: meta.discipline,
            date: meta.date,
            place: meta.place,
            coupleCount: meta.coupleCount,
            placementText: couple.placementText,
            placement: couple.placement,
            pointsEarned: couple.pointsEarned,
            cumulativeStats: couple.cumulativeStats,
            cumulativePoints: couple.cumulativePoints,
            cumulativeFinals: couple.cumulativeFinals,
            isOfficial: (couple.isOfficial ?? false) || (meta.isOfficial ?? false),
            season: meta.season,
            isDeleted: false,
            deletedAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

public struct KSISImportResponse: Decodable {
    public let success: Bool
    public let preview: KSISPreviewPayload?
    public let result: CompetitionResult?
    public let message: String?
    public let error: String?
    public let can_restore: Bool?
    public let conflict_id: String?
    public let existing_result_id: String?
    public let retry_after: Int?
    public let name_warning: String?

    public var resolvedResult: CompetitionResult? {
        result ?? preview?.toCompetitionResult()
    }
}

public struct KSISCoupleActionRequest: Encodable {
    public let action: String
    public let couple_id: Int?
    public let discipline: String?
    public let partner_name: String?
    public let partner_consent: Bool?

    public init(
        action: String,
        couple_id: Int? = nil,
        discipline: String? = nil,
        partner_name: String? = nil,
        partner_consent: Bool? = nil
    ) {
        self.action = action
        self.couple_id = couple_id
        self.discipline = discipline
        self.partner_name = partner_name
        self.partner_consent = partner_consent
    }
}

public struct KSISCoupleActionResponse: Decodable {
    public let success: Bool
    public let couples: [UserCouple]?
    public let couple: UserCouple?
    public let error: String?
}

public struct KSISManageResultsRequest: Encodable {
    public let action: String
    public let result_id: String

    public init(action: String, result_id: String) {
        self.action = action
        self.result_id = result_id
    }
}

public struct KSISManageResultsResponse: Decodable {
    public let success: Bool
    public let result: CompetitionResult?
    public let error: String?
}
