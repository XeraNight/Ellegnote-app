import Testing
@testable import Encore

/// The top plan was renamed from Studio to Premium. Grants saved under the old name must keep working.
struct SubscriptionTierTests {

    @Test func serverValuesMapToTiers() {
        #expect(SubscriptionTier(serverValue: "free") == .free)
        #expect(SubscriptionTier(serverValue: "plus") == .plus)
        #expect(SubscriptionTier(serverValue: "premium") == .premium)
        #expect(SubscriptionTier(serverValue: "nonsense") == nil)
    }

    @Test func oldStudioNameStillMeansPremium() {
        #expect(SubscriptionTier(serverValue: "studio") == .premium)
        #expect(SubscriptionTier(serverValue: "Studio") == .premium)   // cached on the iPhone before the rename
    }

    @Test func serverValueRoundTrips() {
        for tier in SubscriptionTier.allCases {
            #expect(SubscriptionTier(serverValue: tier.serverValue) == tier)
        }
    }
}
