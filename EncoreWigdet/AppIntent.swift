//
//  AppIntent.swift
//  EncoreWigdet
//
//  Created by Jakub on 19/07/2026.
//

import WidgetKit
import AppIntents
import ActivityKit

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Zastaviť nahrávanie"
    static var description = IntentDescription("Zastaví nahrávanie tanečnej kamery.")

    func perform() async throws -> some IntentResult {
        let notificationName = "com.encore.stopRecording" as CFString
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
    static var title: LocalizedStringResource = "Označiť moment"
    static var description = IntentDescription("Označí dôležitý moment nahrávky do poznámok.")

    func perform() async throws -> some IntentResult {
        let notificationName = "com.encore.bookmark" as CFString
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

