#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

struct EllegnoteAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamické dáta, ktoré sa menia počas tréningu
        var currentFigureName: String
        var nextFigureName: String
        var currentFigureIndex: Int
        var totalFigures: Int
        var lastUpdated: Date
    }

    // Statické vlastnosti, ktoré sa počas tréningu nemenia
    var routineName: String
    var danceName: String
}

struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var sessionTitle: String
        var metronomeName: String
        var bpm: Int
        var beatsPerMeasure: Int
        var audioLevel: Float
    }

    var recordingName: String
}
#endif
