import Foundation

// MARK: - Friend Status
enum FriendStatus: String, Codable {
    case active
    case pending
    case incoming
}

// MARK: - Dancer Friend Model
struct DancerFriend: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: String
    var name: String
    var club: String
    var avatarURL: String?
    var addedAt: Date
    var status: FriendStatus
    var sharedRoutinesCount: Int
    
    init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        club: String = "",
        avatarURL: String? = nil,
        addedAt: Date = Date(),
        status: FriendStatus = .active,
        sharedRoutinesCount: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.club = club
        self.avatarURL = avatarURL
        self.addedAt = addedAt
        self.status = status
        self.sharedRoutinesCount = sharedRoutinesCount
    }
}

// MARK: - Friend Invite Payload (Encoded in QR Code, Token and Deep Link)
struct FriendInvitePayload: Codable, Equatable {
    let userId: String
    let name: String
    let club: String
    let action: String
    var ksisId: String?
    var dancerCode: String?
    var dancerGroups: [String]
    var avatarURL: String?
    var token: String?
    
    init(
        userId: String,
        name: String,
        club: String = "",
        action: String = "add_friend",
        ksisId: String? = nil,
        dancerCode: String? = nil,
        dancerGroups: [String] = [],
        avatarURL: String? = nil,
        token: String? = nil
    ) {
        self.userId = userId
        self.name = name
        self.club = club
        self.action = action
        self.ksisId = ksisId
        self.dancerCode = dancerCode
        self.dancerGroups = dancerGroups
        self.avatarURL = avatarURL
        self.token = token
    }
    
    var displayId: String {
        if let ksis = ksisId, !ksis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "KSIS ID: \(ksis)"
        }
        if let dCode = dancerCode, !dCode.isEmpty {
            return "ID TANEČNÍKA: \(dCode)"
        }
        return "ENCORE DANCER"
    }
}
