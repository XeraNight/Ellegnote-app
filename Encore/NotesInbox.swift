import SwiftUI
import SwiftData

// MARK: - Shared note vocabulary
enum NoteTags {
    static let quick = ["#Držanie", "#Rytmus", "#Sway", "#Rotácia", "#Nášľap", "#Partner", "#Hudba"]
}

private extension InstantNote {
    var kindIcon: String {
        if videoPath != nil { return "video.fill" }
        if imagePath != nil { return "photo.fill" }
        return "text.alignleft"
    }

    var previewText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return videoPath != nil ? "Tréningové video" : "Prázdna poznámka"
    }
}

// MARK: - Home strip
/// Horizontal strip of not-yet-imported notes shown under the capture field on Home.
struct NotesInboxStrip: View {
    let notes: [InstantNote]
    let onOpenAll: () -> Void
    let onOpenNote: (InstantNote) -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.gold400)
                    .symbolEffect(.bounce, value: notes.count)

                Text("SCHRÁNKA")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(Color.gold400)
                    .tracking(1.4)

                if !notes.isEmpty {
                    Text("\(notes.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.obsidian900)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.gold400, in: Capsule())
                        .contentTransition(.numericText())
                }

                Spacer()

                Button(action: onOpenAll) {
                    HStack(spacing: 4) {
                        Text("Všetky")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.55))
                }
                .buttonStyle(.pressable)
            }

            if notes.isEmpty {
                Text("Tvoje rýchle poznámky sa objavia tu. Neskôr ich jedným ťuknutím pridáš k figúre.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.40))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(notes.prefix(12)) { note in
                            Button { onOpenNote(note) } label: { NoteCard(note: note) }
                                .buttonStyle(.pressable)
                                .contextMenu {
                                    Button {
                                        note.isPinned.toggle()
                                        try? modelContext.save()
                                    } label: {
                                        Label(note.isPinned ? "Odopnúť" : "Pripnúť", systemImage: note.isPinned ? "pin.slash" : "pin")
                                    }
                                    Button(role: .destructive) {
                                        modelContext.delete(note)
                                        try? modelContext.save()
                                    } label: {
                                        Label("Zmazať", systemImage: "trash")
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.7, anchor: .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: notes.map(\.id))
        .sensoryFeedback(.selection, trigger: notes.first?.isPinned)
    }
}

private struct NoteCard: View {
    let note: InstantNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: note.kindIcon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.gold400)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.gold300)
                }
                Spacer(minLength: 0)
                Text(note.createdAt, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.40))
            }

            Text(note.previewText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            HStack(spacing: 5) {
                if let dance = note.danceName {
                    chip(dance, filled: true)
                }
                ForEach(note.tags.prefix(2), id: \.self) { chip($0, filled: false) }
            }
            .frame(height: 18, alignment: .leading)
        }
        .padding(12)
        .frame(width: 186, height: 118, alignment: .topLeading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func chip(_ text: String, filled: Bool) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(filled ? Color.obsidian900 : Color.gold300)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(filled ? Color.gold400 : Color.gold500.opacity(0.14), in: Capsule())
            .lineLimit(1)
    }
}

// MARK: - Full list
struct NotesInboxSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var allNotes: [InstantNote]
    @Query(sort: \Dance.name) private var dances: [Dance]

    @State private var search = ""
    @State private var filter: Filter = .inbox
    @State private var danceFilter: String? = nil
    @State private var noteToEdit: InstantNote?

    private enum Filter: String, CaseIterable, Identifiable {
        case inbox = "Schránka", pinned = "Pripnuté", imported = "Importované", all = "Všetky"
        var id: String { rawValue }
    }

    private var filtered: [InstantNote] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allNotes
            .filter { note in
                switch filter {
                case .inbox: return !note.isImported
                case .pinned: return note.isPinned
                case .imported: return note.isImported
                case .all: return true
                }
            }
            .filter { danceFilter == nil || $0.danceName == danceFilter }
            .filter { q.isEmpty || $0.text.lowercased().contains(q) || $0.tags.contains { $0.lowercased().contains(q) } }
            .sorted { ($0.isPinned ? 1 : 0, $0.createdAt) > ($1.isPinned ? 1 : 0, $1.createdAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Nič tu nie je",
                        systemImage: "tray",
                        description: Text(filter == .inbox ? "Všetky poznámky sú pridané k figúram." : "Skús iný filter.")
                    )
                    .listRowBackground(Color.clear)
                }

                ForEach(filtered) { note in
                    Button { noteToEdit = note } label: { row(note) }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.white.opacity(0.05))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(note)
                                try? modelContext.save()
                            } label: { Label("Zmazať", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                note.isPinned.toggle()
                                try? modelContext.save()
                            } label: { Label(note.isPinned ? "Odopnúť" : "Pripnúť", systemImage: "pin") }
                            .tint(Color.gold500)

                            if note.isImported {
                                Button {
                                    note.importedAt = nil
                                    try? modelContext.save()
                                } label: { Label("Vrátiť", systemImage: "arrow.uturn.backward") }
                                .tint(.blue)
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.obsidian900.ignoresSafeArea())
            .navigationTitle("Poznámky")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Hľadať v poznámkach")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Všetky tance") { danceFilter = nil }
                        ForEach(dances) { dance in
                            Button(dance.name) { danceFilter = dance.name }
                        }
                    } label: {
                        Label(danceFilter ?? "Tanec", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $noteToEdit) { NoteDetailSheet(note: $0) }
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ note: InstantNote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: note.kindIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                if note.isPinned {
                    Image(systemName: "pin.fill").font(.system(size: 10)).foregroundColor(Color.gold300)
                }
                if let dance = note.danceName {
                    Text(dance).font(.system(size: 11, weight: .bold)).foregroundColor(Color.gold300)
                }
                Spacer()
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Text(note.previewText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(3)
            if !note.tags.isEmpty {
                Text(note.tags.joined(separator: "  "))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.gold300.opacity(0.8))
            }
            if note.isImported {
                Label("Pridané k figúre", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.syncEmerald)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit one note
struct NoteDetailSheet: View {
    @Bindable var note: InstantNote
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dance.name) private var dances: [Dance]
    @State private var showFigurePicker = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    TextEditor(text: $note.text)
                        .frame(minHeight: 140)
                }

                Section("Tanec") {
                    Picker("Tanec", selection: $note.danceName) {
                        Text("Bez tanca").tag(String?.none)
                        ForEach(dances) { Text($0.name).tag(String?.some($0.name)) }
                    }
                }

                Section("Značky") {
                    FlowTags(selected: $note.tags)
                }

                if note.videoPath != nil {
                    Section {
                        Label("Poznámka obsahuje video. Pripojíš ho v detaile figúry.", systemImage: "video.fill")
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        showFigurePicker = true
                    } label: {
                        Label(note.isImported ? "Pridať k ďalšej figúre" : "Pridať k figúre", systemImage: "arrow.down.doc.fill")
                    }
                    .disabled(note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Zmazať poznámku", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.obsidian900.ignoresSafeArea())
            .navigationTitle("Poznámka")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFigurePicker) {
                FigurePickerSheet(note: note) { dismiss() }
            }
            .confirmationDialog("Zmazať poznámku?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Zmazať", role: .destructive) {
                    modelContext.delete(note)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct FlowTags: View {
    @Binding var selected: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NoteTags.quick, id: \.self) { tag in
                    let isOn = selected.contains(tag)
                    Button {
                        if isOn { selected.removeAll { $0 == tag } } else { selected.append(tag) }
                    } label: {
                        Text(tag)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundColor(isOn ? Color.obsidian900 : Color.gold300)
                            .background(isOn ? Color.gold400 : Color.gold500.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - Add a note to a figure
/// Appends the note text (with its date) to a figure on a routine canvas or in the library.
/// The note stays in the app and is only marked as imported, so it can be restored.
struct FigurePickerSheet: View {
    let note: InstantNote
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CanvasNode.figureName) private var nodes: [CanvasNode]
    @Query(sort: \FigureLibraryItem.name) private var library: [FigureLibraryItem]
    @State private var search = ""

    private var query: String { search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    private var matchingNodes: [CanvasNode] {
        nodes.filter { node in
            guard let routine = node.routine else { return false }
            if let dance = note.danceName, routine.danceName != dance { return false }
            return query.isEmpty || node.figureName.lowercased().contains(query) || routine.name.lowercased().contains(query)
        }
    }

    private var matchingLibrary: [FigureLibraryItem] {
        library.filter { item in
            if let dance = note.danceName, item.danceName != dance { return false }
            return query.isEmpty || item.name.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !matchingNodes.isEmpty {
                    Section("Zo mojich zostáv") {
                        ForEach(matchingNodes) { node in
                            Button { add(to: node) } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.figureName).font(.system(size: 15, weight: .semibold))
                                    Text(node.routine?.name ?? "")
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                if !matchingLibrary.isEmpty {
                    Section("Knižnica figúr") {
                        ForEach(matchingLibrary) { item in
                            Button { add(to: item) } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.system(size: 15, weight: .semibold))
                                    Text(item.danceName).font(.system(size: 12)).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                if matchingNodes.isEmpty && matchingLibrary.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Hľadať figúru alebo zostavu")
            .navigationTitle("Vybrať figúru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušiť") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var stamped: String {
        "• \(note.createdAt.formatted(date: .numeric, time: .omitted)) — \(note.text.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func finish() {
        note.importedAt = Date()
        try? modelContext.save()
        HapticFeedback.medium()
        dismiss()
        onDone()
    }

    private func add(to node: CanvasNode) {
        node.notes = node.notes.isEmpty ? stamped : node.notes + "\n" + stamped
        note.linkedFigureId = node.id
        note.linkedRoutineId = node.routine?.id
        if let routine = node.routine {
            routine.updatedAt = Date()
            SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        }
        finish()
    }

    private func add(to item: FigureLibraryItem) {
        item.techniqueNotes = item.techniqueNotes.isEmpty ? stamped : item.techniqueNotes + "\n" + stamped
        note.linkedFigureId = item.id
        finish()
    }
}
