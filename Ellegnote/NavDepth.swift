import SwiftUI
import Combine

// MARK: - Shared navigation depth tracker
// Views that push navigation (e.g. RoutineCanvasView) call NavDepth.shared.push()
// and pop() to hide/show the floating dock automatically.
@MainActor
final class NavDepth: ObservableObject {
    static let shared = NavDepth()
    @Published private(set) var depth: Int = 0
    
    private init() {}
    
    func push() { depth += 1 }
    func pop()  { depth = max(0, depth - 1) }

    /// True when any view is pushed on the nav stack (e.g. RoutineCanvasView)
    /// Used by SwipeBackFix to block the edge swipe-back gesture.
    var isDocked: Bool { depth == 0 }
    var isLocked: Bool { depth > 0 }
}
