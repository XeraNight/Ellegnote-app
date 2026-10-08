import SwiftUI
import SwiftData

// MARK: - My library (opened from Profile)

/// All routines, newest first, as the same cards as on Home and in the Canvas tab.
struct ProfileRoutinesListView: View {
    let routines: [Routine]
    @State private var routineToOpen: Routine?

    var body: some View {
        ZStack {
            EllegancePageBackground()
            ScrollView {
                LazyVStack(spacing: 14) {
                    if routines.isEmpty {
                        ProfileEmptyState(icon: "rectangle.dashed", text: "Zatiaľ nemáš žiadne zostavy.")
                    }
                    ForEach(routines) { routine in
                        RoutineCard(routine: routine) { routineToOpen = routine }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Zostavy")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $routineToOpen) { RoutineCanvasView(routine: $0) }
    }
}

/// The figure library with own and default figures.
struct ProfileFiguresListView: View {
    let figures: [FigureLibraryItem]
    @State private var selectedFigure: FigureLibraryItem?

    var body: some View {
        ZStack {
            EllegancePageBackground()
            ScrollView {
                LazyVStack(spacing: 10) {
                    if figures.isEmpty {
                        ProfileEmptyState(icon: "book.closed", text: "Knižnica je zatiaľ prázdna.")
                    }
                    ForEach(figures) { figure in
                        Button { selectedFigure = figure } label: { figureRow(figure) }
                            .buttonStyle(.pressable(scale: 0.97))
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Knižnica figúr")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFigure) { LibraryFigureDetailSheet(figure: $0) }
    }

    private func figureRow(_ figure: FigureLibraryItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(figure.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text([figure.danceName, figure.rhythm].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.65))
            }
            Spacer(minLength: 8)
            if figure.videoPath != nil {
                Image(systemName: "video.fill").foregroundColor(Color.gold400).accessibilityLabel("Má video")
            }
            Text(figure.isCustom ? "Vlastná" : "Predvolená")
                .font(.caption2.weight(.bold))
                .foregroundColor(figure.isCustom ? Color.obsidian900 : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(figure.isCustom ? Color.gold400 : Color.white.opacity(0.12), in: Capsule())
        }
        .font(.footnote)
        .padding(14)
        .homeCard(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

/// Every video and note across routines, figures and dances.
struct ProfileMediaListView: View {
    let dances: [Dance]
    let figures: [FigureLibraryItem]
    let nodes: [CanvasNode]

    @State private var selectedNode: CanvasNode?
    @State private var selectedFigure: FigureLibraryItem?
    @State private var selectedDance: Dance?

    private func hasText(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var nodesWithMedia: [CanvasNode] { nodes.filter { $0.videoPath != nil || hasText($0.notes) } }
    private var figuresWithMedia: [FigureLibraryItem] { figures.filter { $0.videoPath != nil || hasText($0.techniqueNotes) } }
    private var dancesWithMedia: [Dance] { dances.filter { $0.videoPath != nil || hasText($0.info) } }

    var body: some View {
        ZStack {
            EllegancePageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if nodesWithMedia.isEmpty && figuresWithMedia.isEmpty && dancesWithMedia.isEmpty {
                        ProfileEmptyState(icon: "tray", text: "Zatiaľ tu nie sú videá ani poznámky.")
                    }
                    if !nodesWithMedia.isEmpty {
                        HomeRowGroup(title: "Z MOJICH ZOSTÁV") {
                            ForEach(Array(nodesWithMedia.enumerated()), id: \.element.id) { index, node in
                                if index > 0 { HomeRowDivider() }
                                Button { selectedNode = node } label: {
                                    mediaRow(node.figureName, node.routine?.name ?? "Zostava", video: node.videoPath != nil, note: hasText(node.notes))
                                }
                                .buttonStyle(.pressable(scale: 0.98))
                            }
                        }
                    }
                    if !figuresWithMedia.isEmpty {
                        HomeRowGroup(title: "FIGÚRY") {
                            ForEach(Array(figuresWithMedia.enumerated()), id: \.element.id) { index, figure in
                                if index > 0 { HomeRowDivider() }
                                Button { selectedFigure = figure } label: {
                                    mediaRow(figure.name, figure.danceName, video: figure.videoPath != nil, note: hasText(figure.techniqueNotes))
                                }
                                .buttonStyle(.pressable(scale: 0.98))
                            }
                        }
                    }
                    if !dancesWithMedia.isEmpty {
                        HomeRowGroup(title: "TANCE") {
                            ForEach(Array(dancesWithMedia.enumerated()), id: \.element.id) { index, dance in
                                if index > 0 { HomeRowDivider() }
                                Button { selectedDance = dance } label: {
                                    mediaRow(dance.name, dance.category == "Standard" ? "Štandard" : "Latina", video: dance.videoPath != nil, note: hasText(dance.info))
                                }
                                .buttonStyle(.pressable(scale: 0.98))
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Videá a poznámky")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedNode) { FigureDetailCard(node: $0) }
        .sheet(item: $selectedFigure) { LibraryFigureDetailSheet(figure: $0) }
        .sheet(item: $selectedDance) { EditDanceSheet(dance: $0) }
    }

    private func mediaRow(_ title: String, _ subtitle: String, video: Bool, note: Bool) -> some View {
        HomeRow(
            icon: video ? "video.fill" : "text.alignleft",
            title: title,
            subtitle: subtitle,
            detail: [video ? "video" : nil, note ? "poznámka" : nil].compactMap { $0 }.joined(separator: " + ")
        )
    }
}

/// Empty list message in the library screens.
struct ProfileEmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.gold400.opacity(0.8))
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .homeCard()
    }
}
