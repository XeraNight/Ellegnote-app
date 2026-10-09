import Testing
import Foundation
@testable import Encore

/// Guest coach keys must round-trip through the QR link and nothing else may pass as a key;
/// plan limits on the app side match the server (Free 7 days, Plus and Premium 30).
struct CoachToolsTests {

    @Test func keyLinkRoundTrips() throws {
        let token = "0123456789abcdef0123456789abcdef"
        let link = try #require(GuestCoachLink.url(token: token))
        #expect(link.absoluteString == "encore://guest?k=\(token)")
        #expect(GuestCoachLink.token(from: link.absoluteString) == token)
        #expect(GuestCoachLink.token(from: "  \(link.absoluteString)\n") == token)
    }

    @Test func onlyAWellFormedKeyIsAccepted() {
        #expect(GuestCoachLink.token(from: "encore://guest?k=1234") == nil)                                  // too short
        #expect(GuestCoachLink.token(from: "encore://guest?k=0123456789abcdef0123456789abcdeg") == nil)     // not hex
        #expect(GuestCoachLink.token(from: "https://guest?k=0123456789abcdef0123456789abcdef") == nil)     // other scheme
        #expect(GuestCoachLink.token(from: "encore://add?k=0123456789abcdef0123456789abcdef") == nil)      // invite link
        #expect(GuestCoachLink.token(from: "ENC1:routine-share-code") == nil)                               // routine QR
        #expect(GuestCoachLink.token(from: "encore://guest?k=0123456789ABCDEF0123456789ABCDEF") == "0123456789abcdef0123456789abcdef")
    }

    @Test func keyLengthFollowsThePlan() {
        #expect(GuestCoachLink.maxDays(for: .free) == 7)
        #expect(GuestCoachLink.maxDays(for: .plus) == 30)
        #expect(GuestCoachLink.maxDays(for: .premium) == 30)
    }

    @Test func lessonDateIsTheLocalDay() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 9
        components.hour = 23
        components.minute = 30
        let lateEvening = try #require(Calendar.current.date(from: components))
        #expect(CoachLesson.dayString(lateEvening) == "2026-10-09")
    }

    @Test func paywallListsEveryPaidPlanFeatureOnce() {
        for tier in [SubscriptionTier.plus, .premium] {
            let titles = SubscriptionPaywallView.features(for: tier).map(\.title)
            #expect(!titles.isEmpty)
            #expect(Set(titles).count == titles.count)
        }
        #expect(SubscriptionPaywallView.features(for: .free).isEmpty)
    }
}
