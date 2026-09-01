import SwiftUI
import SwiftData

// MARK: - Canvas Grid Background
struct CanvasGridBackground: View {
    let roomSize: CGFloat
    var body: some View {
        Path { path in
            let step: CGFloat = 80
            for x in stride(from: 0, to: roomSize, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: roomSize))
            }
            for y in stride(from: 0, to: roomSize, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: roomSize, y: y))
            }
        }
        .stroke(Color.themeBorder.opacity(0.6), lineWidth: 1)
        .drawingGroup()
    }
}

// MARK: - Ballroom Markings
struct BallroomMarkingsView: View {
    let roomSize: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.themeDark.opacity(0.06), lineWidth: 5)
                .frame(width: roomSize - 160, height: roomSize - 160)
            Circle()
                .stroke(Color.themeDark.opacity(0.08), lineWidth: 2)
                .frame(width: 200, height: 200)
            Text("STRED SÁLY\n(Center of Room)")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.themeDark.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Connections Layer
struct ConnectionsLayer: View {
    let nodes: [CanvasNode]
    var livePositions: [UUID: CGPoint] = [:]
    var onConnectionTap: (CanvasNode, CanvasNode) -> Void
    
    private func pos(for node: CanvasNode) -> CGPoint {
        livePositions[node.id] ?? CGPoint(x: node.x, y: node.y)
    }
    
    var body: some View {
        let sorted = nodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        ZStack {
            // GPU-accelerated Metal stroke layer
            ZStack {
                ForEach(0..<sorted.count, id: \.self) { idx in
                    if idx > 0 {
                        let prev = sorted[idx - 1]
                        let curr = sorted[idx]
                        let p1 = pos(for: prev)
                        let p2 = pos(for: curr)
                        
                        ConnectionLineShape(from: p1, to: p2)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.gold500.opacity(0.6), Color.gold400.opacity(0.2)],
                                    startPoint: .init(x: 0, y: 0),
                                    endPoint: .init(x: 1, y: 1)
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
                            )
                    }
                }
            }
            .drawingGroup()
            
            // Interactive connection buttons overlay
            ForEach(0..<sorted.count, id: \.self) { idx in
                if idx > 0 {
                    let prev = sorted[idx - 1]
                    let curr = sorted[idx]
                    let p1 = pos(for: prev)
                    let p2 = pos(for: curr)
                    let centerPoint = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                    Button(action: { onConnectionTap(prev, curr) }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.themeAccent)
                                .background(Color.themeCard.clipShape(Circle()))
                            if !curr.transitionNotes.isEmpty {
                                Text(curr.transitionNotes)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.themeAccent)
                                    .cornerRadius(6)
                                    .shadow(color: Color.themeDark.opacity(0.05), radius: 2)
                            }
                        }
                    }
                    .position(centerPoint)
                }
            }
        }
    }
}

struct ConnectionLineShape: Shape {
    var from: CGPoint
    var to: CGPoint
    
    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(from.animatableData, to.animatableData) }
        set { from.animatableData = newValue.first; to.animatableData = newValue.second }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let dx = to.x - from.x
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x + dx * 0.5, y: from.y),
            control2: CGPoint(x: from.x + dx * 0.5, y: to.y)
        )
        return path
    }
}

// MARK: - Canvas Node Card View
struct CanvasNodeCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var node: CanvasNode
    let scale: CGFloat
    var onTap: () -> Void
    var onDelete: () -> Void
    var onDrag: ((Double, Double) -> Void)? = nil
    var onDragStart: (() -> Void)? = nil
    var onDragEnd: ((Double, Double) -> Void)? = nil
    
    @State private var dragOffset: CGSize = .zero
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("#\(node.orderIndex + 1)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.themeAccent)
                    .cornerRadius(6)
                Spacer()
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "multiply")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeDark.opacity(0.4))
                }
            }
            Text(node.figureName)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(.themeDark)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if !node.rhythm.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.rhythm)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeAccent)
                    
                    BeatsTimelineView(rhythm: node.rhythm)
                }
            }
            HStack(spacing: 6) {
                if node.videoPath != nil {
                    Image(systemName: "video.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.themeAccent)
                }
                if !node.notes.isEmpty {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.themeDark.opacity(0.5))
                }
            }
        }
        .padding(12)
        .frame(width: 140, height: 132)
        .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
        .position(x: node.x + dragOffset.width, y: node.y + dragOffset.height)
        .confirmationDialog("Vymazať túto figúru zo zostavy?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Vymazať", role: .destructive) { onDelete() }
            Button("Zrušiť", role: .cancel) {}
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if dragOffset == .zero { onDragStart?() }
                    dragOffset = CGSize(
                        width:  value.translation.width  / scale,
                        height: value.translation.height / scale
                    )
                    onDrag?(node.x + dragOffset.width, node.y + dragOffset.height)
                }
                .onEnded { value in
                    let finalX = node.x + value.translation.width  / scale
                    let finalY = node.y + value.translation.height / scale
                    node.x = finalX
                    node.y = finalY
                    dragOffset = .zero
                    try? modelContext.save()
                    if let routine = node.routine {
                        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                    }
                    onDragEnd?(finalX, finalY)
                }
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Beats Timeline View
struct BeatsTimelineView: View {
    let rhythm: String
    
    var beats: [String] {
        rhythm.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<beats.count, id: \.self) { index in
                let token = beats[index]
                let isAnd = token.lowercased() == "a"
                
                if isAnd {
                    Text("&")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.themeAccent)
                } else {
                    let label = token.first?.uppercased() ?? ""
                    Text(label)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.themeDark)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Partner Cursor View (Presence)
struct PartnerCursorView: View {
    let name: String
    let isDragging: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isDragging ? "hand.draw.fill" : "arrow.up.left.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isDragging ? Color.orange : Color.themeAccent)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Canvas Connection Model
struct CanvasConnection: Identifiable {
    let from: CanvasNode
    let to: CanvasNode
    var id: String { "\(from.id.uuidString)-\(to.id.uuidString)" }
}
