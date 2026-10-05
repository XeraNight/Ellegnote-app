import SwiftUI
import SwiftData

/// The 20-second reflection after a training: dictate or type, pick the dance and how it felt.
/// The text is saved as an `InstantNote` (tag #Reflexia) so it lands in the same inbox as every note.
struct DebriefSheet: View {
    let entry: TrainingLogEntry

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dance.name) private var dances: [Dance]

    @StateObject private var speech = SpeechRecognizerHelper()
    @State private var text = ""
    @State private var danceName: String?
    @State private var feeling: TrainingFeeling?
    @State private var saveTick = 0

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || feeling != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Čo kľúčové ste dnes vylepšili?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Napíš alebo nadiktuj pár viet…")
                                    .foregroundColor(Color.white.opacity(0.35))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $text)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.white)
                                .frame(minHeight: 130)
                        }
                        .font(.system(size: 16))

                        Button(action: toggleDictation) {
                            Label(speech.isRecording ? "Zastaviť diktovanie" : "Diktovať",
                                  systemImage: speech.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(speech.isRecording ? .white : Color.obsidian900)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(speech.isRecording ? Color.latinCrimson : Color.gold400, in: Capsule())
                        }
                        .buttonStyle(.pressable)
                    }
                    .plannerCard()

                    VStack(alignment: .leading, spacing: 10) {
                        plannerSectionTitle("TANEC")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(dances) { dance in
                                    chip(dance.name, isOn: danceName == dance.name) {
                                        danceName = (danceName == dance.name) ? nil : dance.name
                                    }
                                }
                            }
                        }
                        .scrollClipDisabled()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        plannerSectionTitle("AKO TO BOLO")
                        HStack(spacing: 10) {
                            ForEach(TrainingFeeling.allCases) { item in
                                Button {
                                    feeling = (feeling == item) ? nil : item
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(item.emoji).font(.system(size: 26))
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        feeling == item ? Color.gold400.opacity(0.22) : Color.white.opacity(0.06),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(feeling == item ? Color.gold400 : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }

                    Button(action: save) {
                        Text("Uložiť reflexiu")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSave ? Color.gold400 : Color.white.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.pressable)
                    .disabled(!canSave)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(EllegancePageBackground())
            .navigationTitle(entry.title.isEmpty ? "Tréning" : entry.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                }
            }
            .onChange(of: speech.transcript) { _, newValue in
                if !newValue.isEmpty { text = newValue }
            }
            .onAppear {
                text = entry.reflectionNote
                danceName = entry.danceName
                feeling = entry.feeling
            }
            .onDisappear { _ = speech.stopTranscribing() }
            .sensoryFeedback(.success, trigger: saveTick)
        }
        .preferredColorScheme(.dark)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .foregroundColor(isOn ? Color.obsidian900 : Color.white.opacity(0.85))
                .background(isOn ? Color.gold400 : Color.white.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.pressable)
    }

    private func toggleDictation() {
        if speech.isRecording {
            let captured = speech.stopTranscribing()
            if !captured.isEmpty { text = captured }
        } else {
            speech.requestPermissions()
            speech.transcript = ""
            speech.startTranscribing()
        }
    }

    private func save() {
        if speech.isRecording {
            let captured = speech.stopTranscribing()
            if !captured.isEmpty { text = captured }
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        entry.reflectionNote = trimmed
        entry.danceName = danceName
        entry.feeling = feeling
        entry.status = .attended

        if !trimmed.isEmpty {
            if let noteId = entry.noteId, let existing = fetchNote(noteId) {
                existing.text = trimmed
                existing.danceName = danceName
            } else {
                let note = InstantNote(text: trimmed, tags: ["#Reflexia"], danceName: danceName)
                modelContext.insert(note)
                entry.noteId = note.id
            }
        }

        try? modelContext.save()
        saveTick += 1
        dismiss()
    }

    private func fetchNote(_ id: UUID) -> InstantNote? {
        var descriptor = FetchDescriptor<InstantNote>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
