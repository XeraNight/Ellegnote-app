import Foundation
import SwiftData
import SwiftUI

// MARK: - Weekly rhythm
/// One permanent weekly training slot ("Utorok 18:00, vedený tréning Štandard").
@Model
final class TrainingCadence {
    @Attribute(.unique) var id: UUID
    /// ISO weekday: 1 = pondelok … 7 = nedeľa.
    var weekday: Int = 1
    var title: String = ""
    /// Start time as minutes after midnight (18:00 = 1080).
    var startMinutes: Int = 18 * 60
    var durationMinutes: Int = 90
    var location: String = ""
    /// "Standard", "Latin", "Mixed" or "Free".
    var danceCategory: String = "Mixed"
    var isEnabled: Bool = true
    /// Identifier of the recurring Apple Calendar event, if exported.
    var calendarEventId: String? = nil

    init(
        id: UUID = UUID(),
        weekday: Int,
        title: String,
        startMinutes: Int,
        durationMinutes: Int = 90,
        location: String = "",
        danceCategory: String = "Mixed"
    ) {
        self.id = id
        self.weekday = weekday
        self.title = title
        self.startMinutes = startMinutes
        self.durationMinutes = durationMinutes
        self.location = location
        self.danceCategory = danceCategory
    }

    var endMinutes: Int { startMinutes + durationMinutes }
}

// MARK: - One day of training
enum TrainingStatus: String, CaseIterable {
    case planned, going, skipped, attended
}

enum TrainingFeeling: String, CaseIterable, Identifiable {
    case great, tired, breakthrough
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "🔥"
        case .tired: return "⚡"
        case .breakthrough: return "🎯"
        }
    }

    var title: String {
        switch self {
        case .great: return "Skvelý pocit"
        case .tired: return "Únava"
        case .breakthrough: return "Prelom v technike"
        }
    }
}

/// What happened on one concrete day for one cadence (going / skipped / reflection).
@Model
final class TrainingLogEntry {
    @Attribute(.unique) var id: UUID
    /// Start of the day this entry belongs to.
    var day: Date = Date()
    var cadenceId: UUID? = nil
    var title: String = ""
    var statusRaw: String = TrainingStatus.planned.rawValue
    var reflectionNote: String = ""
    var feelingRaw: String? = nil
    var danceName: String? = nil
    /// The `InstantNote` created from the reflection, so it can be edited later.
    var noteId: UUID? = nil
    var associatedRoutineId: UUID? = nil

    init(id: UUID = UUID(), day: Date, cadenceId: UUID?, title: String) {
        self.id = id
        self.day = day
        self.cadenceId = cadenceId
        self.title = title
    }

    var status: TrainingStatus {
        get { TrainingStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    var feeling: TrainingFeeling? {
        get { feelingRaw.flatMap(TrainingFeeling.init(rawValue:)) }
        set { feelingRaw = newValue?.rawValue }
    }
}

// MARK: - Competitions
enum CompetitionIntent: String, CaseIterable, Identifiable {
    case interested, going, declined
    var id: String { rawValue }

    var title: String {
        switch self {
        case .interested: return "Zvažujem"
        case .going: return "Idem"
        case .declined: return "Neidem"
        }
    }
}

/// A competition the dancer tracks. Entered by hand until a KSIS source is available.
@Model
final class PlannedCompetition {
    @Attribute(.unique) var id: UUID
    /// Reserved for the future KSIS link; nil for manually entered competitions.
    var ksisCompetitionId: String? = nil
    var name: String = ""
    var city: String = ""
    var date: Date = Date()
    var entryDeadline: Date? = nil
    var targetCategories: [String] = []
    var intentRaw: String = CompetitionIntent.interested.rawValue
    /// Main peak of the season.
    var isTargetCompetition: Bool = false
    var calendarEventId: String? = nil

    init(id: UUID = UUID(), name: String, city: String, date: Date) {
        self.id = id
        self.name = name
        self.city = city
        self.date = date
    }

    var intent: CompetitionIntent {
        get { CompetitionIntent(rawValue: intentRaw) ?? .interested }
        set { intentRaw = newValue.rawValue }
    }
}

// MARK: - Date helpers (ISO weekdays, Slovak labels)
enum PlannerCalendar {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "sk")
        c.firstWeekday = 2
        return c
    }()

    /// 1 = pondelok … 7 = nedeľa (Calendar itself uses 1 = nedeľa).
    static func isoWeekday(of date: Date) -> Int {
        let w = calendar.component(.weekday, from: date)
        return w == 1 ? 7 : w - 1
    }

    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    static func date(on day: Date, minutes: Int) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: startOfDay(day)) ?? day
    }

    static func weekdayName(iso: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        let name = symbols[iso % 7]
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    static func timeString(minutes: Int) -> String {
        String(format: "%d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    static func timeRange(of cadence: TrainingCadence) -> String {
        "\(timeString(minutes: cadence.startMinutes)) – \(timeString(minutes: cadence.endMinutes))"
    }

    /// "Dnes", "Zajtra", "O 2 dni", "O 11 dní", "Pred 3 dňami".
    static func daysText(until date: Date, from now: Date = Date()) -> String {
        let days = calendar.dateComponents([.day], from: startOfDay(now), to: startOfDay(date)).day ?? 0
        switch days {
        case 0: return "Dnes"
        case 1: return "Zajtra"
        case 2...4: return "O \(days) dni"
        case 5...: return "O \(days) dní"
        case -1: return "Včera"
        default: return "Pred \(-days) dňami"
        }
    }
}
