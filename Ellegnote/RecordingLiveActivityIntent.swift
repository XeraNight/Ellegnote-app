import Foundation
import AppIntents

#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops the active dance camera recording.")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .stopRecordingFromLiveActivity, object: nil)
        }

        for activity in Activity<RecordingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        return .result()
    }
}
#endif
