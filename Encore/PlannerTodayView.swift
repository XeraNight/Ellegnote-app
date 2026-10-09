import SwiftUI
import SwiftData

/// "Dnes" part of the planner: today's sessions with one-tap check-in, next competition, recent reflections.
struct PlannerTodayView: View {
    let cadences: [TrainingCadence]
    let logs: [TrainingLogEntry]
    let competitions: [PlannedCompetition]
    let onOpenRoutine: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var debriefEntry: TrainingLogEntry?
    @State private var changeTick = 0

    private var today: Date { PlannerCalendar.startOfDay(Date()) }

    private var todaysCadences: [TrainingCadence] {
        let weekday = PlannerCalendar.isoWeekday(of: Date())
        return cadences
            .filter { $0.isEnabled && $0.weekday == weekday }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    private var nextSession: (cadence: TrainingCadence, day: Date)? {
        let cal = PlannerCalendar.calendar
        for offset in 1...7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = PlannerCalendar.isoWeekday(of: day)
            if let cadence = cadences
                .filter({ $0.isEnabled && $0.weekday == weekday })
                .min(by: { $0.startMinutes < $1.startMinutes }) {
                return (cadence, day)
            }
        }
        return nil
    }

    private var nextCompetition: PlannedCompetition? {
        competitions.first { $0.intent != .declined && PlannerCalendar.startOfDay($0.date) >= today }
    }

    private var recentReflections: [TrainingLogEntry] {
        Array(logs.filter { !$0.reflectionNote.isEmpty }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .textCase(.uppercase)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            sessions

            LessonPrioritiesSection()

            if let comp = nextCompetition {
                competitionCard(comp)
            }

            if !recentReflections.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    plannerSectionTitle("POSLEDNÉ REFLEXIE")
                    ForEach(recentReflections) { entry in
                        reflectionRow(entry)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: changeTick)
        .sheet(item: $debriefEntry) { entry in
            DebriefSheet(entry: entry)
                .presentationDetents([.large])
        }
    }

    // MARK: Sessions
    @ViewBuilder
    private var sessions: some View {
        if cadences.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nastav si týždenný režim")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Raz zadáš, kedy trénuješ. Potom ti stačí v daný deň ťuknúť Idem alebo Vynechávam a po tréningu zapísať, čo si sa naučil.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
                Button(action: onOpenRoutine) {
                    Text("Nastaviť režim")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.obsidian900)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.gold400, in: Capsule())
                }
                .buttonStyle(.pressable)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .plannerCard()
        } else if todaysCadences.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Dnes máš voľno")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                if let next = nextSession {
                    Text("Najbližší tréning: \(PlannerCalendar.weekdayName(iso: next.cadence.weekday)) \(PlannerCalendar.timeString(minutes: next.cadence.startMinutes)), \(next.cadence.title)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .plannerCard()
        } else {
            ForEach(todaysCadences) { cadence in
                TodaySessionCard(
                    cadence: cadence,
                    entry: entry(for: cadence),
                    onSetStatus: { setStatus($0, for: cadence) },
                    onDebrief: { debriefEntry = entryCreatingIfNeeded(for: cadence) }
                )
            }
        }
    }

    private func entry(for cadence: TrainingCadence) -> TrainingLogEntry? {
        logs.first { $0.cadenceId == cadence.id && PlannerCalendar.calendar.isDate($0.day, inSameDayAs: today) }
    }

    private func entryCreatingIfNeeded(for cadence: TrainingCadence) -> TrainingLogEntry {
        if let existing = entry(for: cadence) { return existing }
        let created = TrainingLogEntry(day: today, cadenceId: cadence.id, title: cadence.title)
        modelContext.insert(created)
        return created
    }

    private func setStatus(_ status: TrainingStatus, for cadence: TrainingCadence) {
        let target = entryCreatingIfNeeded(for: cadence)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            target.status = status
        }
        try? modelContext.save()
        changeTick += 1
    }

    // MARK: Competition
    private func competitionCard(_ comp: PlannedCompetition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            plannerSectionTitle("NAJBLIŽŠIA SÚŤAŽ")
            HStack(alignment: .firstTextBaseline) {
                Text("\(PlannerCalendar.daysText(until: comp.date)) — \(comp.name)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                Text(comp.intent.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(comp.intent == .going ? Color.obsidian900 : Color.gold300)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(comp.intent == .going ? Color.gold400 : Color.gold500.opacity(0.14), in: Capsule())
            }
            if !comp.city.isEmpty {
                Text(comp.city)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            if let deadline = comp.entryDeadline,
               PlannerCalendar.startOfDay(deadline) >= today,
               (PlannerCalendar.calendar.dateComponents([.day], from: today, to: PlannerCalendar.startOfDay(deadline)).day ?? 99) <= 7 {
                Label("Uzávierka prihlášok: \(deadline.formatted(.dateTime.weekday(.wide).day().month()))",
                      systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.latinCrimson)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerCard()
    }

    private func reflectionRow(_ entry: TrainingLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.feeling?.emoji ?? "📝")
                Text(entry.title.isEmpty ? "Tréning" : entry.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(entry.day, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            Text(entry.reflectionNote)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.75))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerCard(cornerRadius: 14)
    }
}

// MARK: - One session card
private struct TodaySessionCard: View {
    let cadence: TrainingCadence
    let entry: TrainingLogEntry?
    let onSetStatus: (TrainingStatus) -> Void
    let onDebrief: () -> Void

    private var status: TrainingStatus { entry?.status ?? .planned }

    private var hasEnded: Bool {
        Date() > PlannerCalendar.date(on: PlannerCalendar.startOfDay(Date()), minutes: cadence.endMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(PlannerCalendar.timeRange(of: cadence))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.gold400)
                Text(cadence.title.isEmpty ? "Tréning" : cadence.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                if !cadence.location.isEmpty {
                    Label(cadence.location, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }

            switch status {
            case .planned:
                if hasEnded {
                    HStack(spacing: 10) {
                        pill("Zapísať reflexiu", icon: "square.and.pencil", filled: true, action: onDebrief)
                        pill("Nebol som", icon: "xmark", filled: false) { onSetStatus(.skipped) }
                    }
                } else {
                    HStack(spacing: 10) {
                        pill("Idem", icon: "checkmark", filled: true) { onSetStatus(.going) }
                        pill("Vynechávam", icon: "xmark", filled: false) { onSetStatus(.skipped) }
                    }
                }
            case .going:
                if hasEnded {
                    pill("Zapísať reflexiu", icon: "square.and.pencil", filled: true, action: onDebrief)
                } else {
                    HStack {
                        Label("Ideš", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.syncEmerald)
                        Spacer()
                        Button("Zmeniť") { onSetStatus(.planned) }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.55))
                            .buttonStyle(.pressable)
                    }
                }
            case .skipped:
                HStack {
                    Label("Dnes vynechávaš", systemImage: "moon.zzz.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.55))
                    Spacer()
                    Button("Vrátiť") { onSetStatus(.planned) }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gold400)
                        .buttonStyle(.pressable)
                }
            case .attended:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Reflexia uložená", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.syncEmerald)
                        if let feeling = entry?.feeling {
                            Text(feeling.emoji)
                        }
                        Spacer()
                        Button("Upraviť", action: onDebrief)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gold400)
                            .buttonStyle(.pressable)
                    }
                    if let note = entry?.reflectionNote, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.75))
                            .lineLimit(3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerCard()
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: status)
    }

    private func pill(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(filled ? Color.obsidian900 : Color.white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(filled ? Color.gold400 : Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.pressable)
    }
}
