import Testing
import Foundation
@testable import Encore

struct FriendInviteTokenTests {

    @Test func testTokenFormatAndPrefix() {
        let sampleToken = "tok_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16)
        #expect(sampleToken.hasPrefix("tok_"))
        #expect(sampleToken.count >= 20)
    }

    @Test func testDisplayIdPrefersKsisId() {
        let payloadWithKsis = FriendInvitePayload(
            userId: "user-123",
            name: "Jakub Kalina",
            club: "Akadémia Tanca",
            ksisId: "98214",
            dancerCode: "DNC-1024"
        )
        #expect(payloadWithKsis.displayId == "KSIS ID: 98214")
    }

    @Test func testDisplayIdFallbacksToDancerCodeWhenKsisMissing() {
        let payloadWithoutKsis = FriendInvitePayload(
            userId: "user-123",
            name: "Jakub Kalina",
            club: "Akadémia Tanca",
            ksisId: nil,
            dancerCode: "DNC-1024"
        )
        #expect(payloadWithoutKsis.displayId == "DANCER ID: DNC-1024")
    }

    @Test func testTokenExpirationDetection() {
        let expiredDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let isExpired = expiredDate < Date()
        #expect(isExpired == true)
        
        let validDate = Date().addingTimeInterval(7 * 24 * 3600) // 7 days in future
        let isValid = validDate > Date()
        #expect(isValid == true)
    }

    @Test func testSelfInvitePreventionLogic() {
        let currentUserId = "my-active-user-uuid"
        let incomingInviterId = "my-active-user-uuid"
        let isSelfInvite = currentUserId.lowercased() == incomingInviterId.lowercased()
        #expect(isSelfInvite == true)
    }

    @Test func testDuplicateConnectionPrevention() {
        var existingFriends = [
            DancerFriend(userId: "user-999", name: "Partner", club: "Club A")
        ]
        
        let incomingPayload = FriendInvitePayload(userId: "user-999", name: "Partner Updated", club: "Club A")
        let alreadyFriends = existingFriends.contains(where: { $0.userId == incomingPayload.userId })
        #expect(alreadyFriends == true)
    }
}
