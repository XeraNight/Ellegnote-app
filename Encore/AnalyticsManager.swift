import Foundation
import OSLog

// MARK: - AnalyticsManager
//
// Centralized analytics singleton wrapping PostHog.
// All event calls go through here so switching providers in the future
// requires editing only this file.
//
// Setup: Add PostHog Swift SDK via Swift Package Manager in Xcode:
//   File > Add Package Dependencies > https://github.com/PostHog/posthog-ios
// Then uncomment the import and the PostHog calls below.
//
// POSTHOG_API_KEY: Create a free project at https://posthog.com/
// Set the key in Info.plist as POSTHOG_API_KEY or hardcode it here (anon key is safe to ship).

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private let logger = Logger(subsystem: "com.jakub.encore", category: "Analytics")

    private init() {}

    // MARK: - Setup (called once from EncoreApp.init)
    func setup() {
        // Uncomment after adding PostHog SPM package:
        //
        // let config = PostHogConfig(
        //     apiKey: Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String ?? "",
        //     host: "https://eu.posthog.com"  // EU server for GDPR
        // )
        // config.captureApplicationLifecycleEvents = true
        // config.capturePushNotifications = false
        // PostHogSDK.shared.setup(config)
        //
        logger.debug("[Analytics] Setup called (PostHog stub)")
    }

    // MARK: - Generic Event
    func capture(_ event: String, properties: [String: Any] = [:]) {
        logger.debug("[Analytics] Event: \(event, privacy: .public) props: \(properties.description, privacy: .public)")
        // Uncomment after adding PostHog:
        // PostHogSDK.shared.capture(event, properties: properties)
    }

    // MARK: - Identity (call after login to associate events with a user)
    func identify(userId: String, email: String?) {
        logger.debug("[Analytics] Identify: \(userId, privacy: .private)")
        // PostHogSDK.shared.identify(userId, userProperties: ["email": email ?? ""])
    }

    // MARK: - Reset (call on sign out)
    func reset() {
        // PostHogSDK.shared.reset()
        logger.debug("[Analytics] Reset")
    }
}

// MARK: - Typed Event Helpers
//
// Add a typed function for every event so call-sites are clean and typo-safe.
// Usage: AnalyticsManager.shared.mirrorOpened()

extension AnalyticsManager {

    // ── Zrkadlo (Dance Mirror) ──────────────────────────────────────────────
    func mirrorOpened(source: String = "radial_hub") {
        capture("mirror_opened", properties: ["source": source])
    }

    // ── Routine ─────────────────────────────────────────────────────────────
    func routineCreated(danceName: String, danceCategory: String) {
        capture("routine_created", properties: [
            "dance_name": danceName,
            "dance_category": danceCategory
        ])
    }

    func canvasOpened(routineId: String, danceName: String) {
        capture("canvas_opened", properties: [
            "routine_id": routineId,
            "dance_name": danceName
        ])
    }

    func canvasNodeAdded(figureName: String, danceName: String) {
        capture("canvas_node_added", properties: [
            "figure_name": figureName,
            "dance_name": danceName
        ])
    }

    func routineExported() {
        capture("routine_exported_json")
    }

    // ── Metronóm ─────────────────────────────────────────────────────────────
    func metronomeStarted(bpm: Int, dance: String) {
        capture("metronome_started", properties: [
            "bpm": bpm,
            "dance": dance
        ])
    }

    // ── Tance (Dance Library) ────────────────────────────────────────────────
    func danceCardViewed(danceName: String, category: String) {
        capture("dance_card_viewed", properties: [
            "dance_name": danceName,
            "category": category
        ])
    }

    // ── Autentifikácia ───────────────────────────────────────────────────────
    func signInApple() {
        capture("auth_signin_apple")
    }

    func signInGoogle() {
        capture("auth_signin_google")
    }

    func signInEmail() {
        capture("auth_signin_email")
    }

    func accountDeleted() {
        capture("account_deleted")
        reset()
    }
    
    // ── Predplatné, Paywall & Limity ──────────────────────────────────────────
    func paywallViewed(source: String, initialTier: String) {
        capture("paywall_viewed", properties: [
            "source": source,
            "initial_tier": initialTier
        ])
    }

    func routineLimitHit(danceName: String) {
        capture("routine_limit_hit", properties: [
            "dance_name": danceName,
            "rule": "1_routine_per_dance_free_limit"
        ])
    }

    func subscriptionUpgradeInitiated(tier: String, isAnnual: Bool) {
        capture("subscription_upgrade_initiated", properties: [
            "tier": tier,
            "is_annual": isAnnual
        ])
    }

    func subscriptionPurchased(tier: String, isAnnual: Bool) {
        capture("subscription_purchased", properties: [
            "tier": tier,
            "is_annual": isAnnual
        ])
    }

    // ── Premium funkcie ─────────────────────────────────────────────
    func radarCoupleFollowed(coupleId: String) {
        capture("radar_couple_followed", properties: [
            "couple_id": coupleId
        ])
    }

    func videoDuelLaunched() {
        capture("video_duel_launched")
    }

    func guestCoachKeyGenerated(routineId: String) {
        capture("guest_coach_key_generated", properties: [
            "routine_id": routineId
        ])
    }

    func top3PrioritiesSaved(danceName: String) {
        capture("top3_priorities_saved", properties: [
            "dance_name": danceName
        ])
    }

    func walletPassDownloaded() {
        capture("wallet_pass_downloaded")
    }

    func walletPassSharedProximity() {
        capture("wallet_pass_shared_proximity")
    }
}
