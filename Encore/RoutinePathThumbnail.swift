import SwiftUI

/// Tiny map of a routine: the order in which figures travel across the floor, with a start dot and
/// an arrow at the end. Meant to help dancers remember the direction of their routine at a glance.
struct RoutinePathThumbnail: View {
    /// Figure positions in canvas coordinates, already sorted by `orderIndex`.
    let points: [CGPoint]

    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var normalized: [CGPoint] { Self.normalize(points) }

    var body: some View {
        ZStack {
            RoutinePathShape(points: normalized)
                .trim(from: 0, to: progress)
                .stroke(
                    Color.gold400.opacity(0.75),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                )

            if let first = normalized.first {
                GeometryReader { geo in
                    Circle()
                        .fill(Color.syncEmerald)
                        .frame(width: 7, height: 7)
                        .position(x: first.x * geo.size.width, y: first.y * geo.size.height)
                }
            }

            RoutinePathArrow(points: normalized)
                .fill(Color.gold300)
                .opacity(progress >= 1 ? 1 : 0)
        }
        .padding(6)
        .onAppear {
            guard progress == 0 else { return }
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeInOut(duration: 0.9)) { progress = 1 }
            }
        }
    }

    /// Maps points into the unit square, keeping the aspect ratio and centering the result.
    static func normalize(_ pts: [CGPoint]) -> [CGPoint] {
        guard pts.count > 1 else { return pts.map { _ in CGPoint(x: 0.5, y: 0.5) } }
        let xs = pts.map(\.x), ys = pts.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        let w = max(maxX - minX, 1), h = max(maxY - minY, 1)
        let scale = max(w, h)
        let offsetX = (1 - w / scale) / 2
        let offsetY = (1 - h / scale) / 2
        return pts.map {
            CGPoint(x: ($0.x - minX) / scale + offsetX, y: ($0.y - minY) / scale + offsetY)
        }
    }
}

private struct RoutinePathShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
        for p in points.dropFirst() {
            path.addLine(to: CGPoint(x: p.x * rect.width, y: p.y * rect.height))
        }
        return path
    }
}

private struct RoutinePathArrow: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let a = points[points.count - 2], b = points[points.count - 1]
        let tip = CGPoint(x: b.x * rect.width, y: b.y * rect.height)
        let from = CGPoint(x: a.x * rect.width, y: a.y * rect.height)
        let angle = atan2(tip.y - from.y, tip.x - from.x)
        let size: CGFloat = 8
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x - size * cos(angle - .pi / 7), y: tip.y - size * sin(angle - .pi / 7)))
        path.addLine(to: CGPoint(x: tip.x - size * cos(angle + .pi / 7), y: tip.y - size * sin(angle + .pi / 7)))
        path.closeSubpath()
        return path
    }
}
