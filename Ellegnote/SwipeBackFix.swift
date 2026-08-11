import UIKit
import SwiftUI

// MARK: - Swipe-back gesture controller
// When NavDepth.depth > 0 (e.g. RoutineCanvasView is shown),
// the edge swipe-back gesture is FULLY disabled — the only exit is the
// custom "Speť" button. On root tabs it works normally.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Block swipe-back entirely when inside a pushed detail view (canvas)
        guard viewControllers.count > 1 else { return false }
        // NavDepth.depth > 0 means we're on a locked screen (e.g. RoutineCanvasView)
        // Dispatch to main actor synchronously — safe because this is always called on main thread
        return !NavDepth.shared.isLocked
    }
}
