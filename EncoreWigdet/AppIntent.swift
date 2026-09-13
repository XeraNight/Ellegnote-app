//
//  AppIntent.swift
//  EllegnoteWigdet
//
//  Created by Jakub on 19/07/2026.
//

import WidgetKit
import AppIntents
import ActivityKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops the active dance camera recording.")

    func perform() async throws -> some IntentResult {
        let notificationName = "com.ellegnote.stopRecording" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )

        for activity in Activity<RecordingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        return .result()
    }
}

struct BookmarkRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Bookmark Moment"
    static var description = IntentDescription("Bookmarks a key dance moment during recording into Instant Notes.")

    func perform() async throws -> some IntentResult {
        let notificationName = "com.ellegnote.bookmark" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )

        return .result()
    }
}

