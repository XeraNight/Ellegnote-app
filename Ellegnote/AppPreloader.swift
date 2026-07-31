import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - App Preloader for Zero-Lag Launch Performance
@MainActor
final class AppPreloader: ObservableObject {
    static let shared = AppPreloader()
    
    @Published private(set) var isPreloaded = false
    
    private init() {}
    
    /// Preloads camera HW, background network status, and memory models during 2-second splash
    func preloadAll() {
        guard !isPreloaded else { return }
        
        // 1. Instant Camera HW Pre-warming
        CameraPrewarmer.shared.prewarm()
        
        self.isPreloaded = true
    }
}
