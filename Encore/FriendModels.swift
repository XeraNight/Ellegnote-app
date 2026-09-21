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

// MARK: - Friend Invite Payload (Encoded in QR Code and Deep Link)
struct FriendInvitePayload: Codable, Equatable {
    let userId: String
    let name: String
    let club: String
    let action: String
    
    init(userId: String, name: String, club: String = "", action: String = "add_friend") {
        self.userId = userId
        self.name = name
        self.club = club
        self.action = action
    }
}
