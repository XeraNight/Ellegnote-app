import SwiftUI
import SwiftData

/// "Režim" part of the planner: the permanent weekly training rhythm.
struct PlannerRoutineView: View {
    let cadences: [TrainingCadence]

    @Environment(\.modelContext) private var modelContext
    @State private var editing: TrainingCadence?
    @State private var showNew = false

    private var sorted: [TrainingCadence] {
        cadences.sorted { ($0.weekday, $0.startMinutes) < ($1.weekday, $1.startMinutes) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            plannerSectionTitle("MÔJ TÝŽDENNÝ REŽIM")

            if sorted.isEmpty {
                Text("Zatiaľ tu nič nie je. Pridaj tréningy, ktoré máš každý týždeň, a appka ti v daný deň ponúkne Idem / Vynechávam a po tréningu reflexiu.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .plannerCard()
            }

            ForEach(sorted) { cadence in
                row(cadence)
            }

            Button { showNew = true } label: {
                Label("Pridať tréning", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.obsidian900)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(Color.gold400, in: Capsule())
            }
            .buttonStyle(.pressable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sorted.map(\.id))
        .sheet(isPresented: $showNew) { CadenceEditorSheet(cadence: nil) }
        .sheet(item: $editing) { CadenceEditorSheet(cadence: $0) }
    }

    private func row(_ cadence: TrainingCadence) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { editing = cadence } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(PlannerCalendar.weekdayName(iso: cadence.weekday)) · \(PlannerCalendar.timeRange(of: cadence))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.gold400)
                    Text(cadence.title.isEmpty ? "Tréning" : cadence.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if !cadence.location.isEmpty {
                        Label(cadence.location, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)

            Toggle("", isOn: Binding(
                get: { cadence.isEnabled },
                set: { cadence.isEnabled = $0; try? modelContext.save() }
            ))
            .labelsHidden()
            .tint(Color.gold500)
        }
        .plannerCard()
        .opacity(cadence.isEnabled ? 1 : 0.55)
        .contextMenu {
            Button { editing = cadence } label: { Label("Upraviť", systemImage: "pencil") }
            Button(role: .destructive) {
                modelContext.delete(cadence)
                try? modelContext.save()
            } label: { Label("Zmazať", systemImage: "trash") }
        }
    }
}

// MARK: - Editor
struct CadenceEditorSheet: View {
    let cadence: TrainingCadence?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var weekday = 2
    @State private var startDate = PlannerCalendar.date(on: Date(), minutes: 18 * 60)
    @State private var duration = 90
    @State private var location = ""
    @State private var category = "Mixed"
    @State private var addToCalendar = false

    private let durations = [30, 45, 60, 75, 90, 105, 120, 150, 180]
    private let categories = [("Standard", "Štandard"), ("Latin", "Latina"), ("Mixed", "Mix"), ("Free", "Voľný")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tréning") {
                    TextField("Názov (napr. Vedený tréning Štandard)", text: $title)
                    TextField("Miesto (napr. Sála 1)", text: $location)
                    Picker("Typ", selection: $category) {
                        ForEach(categories, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Kedy") {
                    Picker("Deň", selection: $weekday) {
                        ForEach(1...7, id: \.self) { Text(PlannerCalendar.weekdayName(iso: $0)).tag($0) }
                    }
                    DatePicker("Začiatok", selection: $startDate, displayedComponents: .hourAndMinute)
                    Picker("Dĺžka", selection: $duration) {
                        ForEach(durations, id: \.self) { Text("\($0) min").tag($0) }
                    }
                }

                if cadence?.calendarEventId == nil {
                    Section {
                        Toggle("Pridať aj do Apple Kalendára (každý týždeň)", isOn: $addToCalendar)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(EllegancePageBackground())
            .navigationTitle(cadence == nil ? "Nový tréning" : "Upraviť tréning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušiť") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Uložiť", action: save) }
            }
            .onAppear(perform: load)
        }
        .preferredColorScheme(.dark)
    }

    private func load() {
        guard let cadence else { return }
        title = cadence.title
        weekday = cadence.weekday
        startDate = PlannerCalendar.date(on: Date(), minutes: cadence.startMinutes)
        duration = cadence.durationMinutes
        location = cadence.location
        category = cadence.danceCategory
    }

    private func save() {
        let comps = PlannerCalendar.calendar.dateComponents([.hour, .minute], from: startDate)
        let minutes = (comps.hour ?? 18) * 60 + (comps.minute ?? 0)

        let target: TrainingCadence
        if let cadence {
            target = cadence
        } else {
            target = TrainingCadence(weekday: weekday, title: title, startMinutes: minutes)
            modelContext.insert(target)
        }
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.weekday = weekday
        target.startMinutes = minutes
        target.durationMinutes = duration
        target.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        target.danceCategory = category
        try? modelContext.save()

        let wantsCalendar = addToCalendar
        Task {
            // Ask for notification permission in context, the first time a session exists.
            if !NotificationManager.shared.isAuthorized {
                _ = await NotificationManager.shared.requestAuthorization()
            }
            if wantsCalendar, let id = await CalendarExporter.shared.export(cadence: target) {
                target.calendarEventId = id
                try? modelContext.save()
            }
        }
        dismiss()
    }
}
