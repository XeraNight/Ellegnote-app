import Foundation
import WatchConnectivity
import UIKit
import Combine

// MARK: - Watch Cue Type
enum WatchHapticCueType: String, Codable {
    case warning = "warning"         // 1 bar before hard transition
    case beatAccent = "beatAccent"   // Beat 1 downbeat
    case figureChange = "figureChange" // Immediate transition
    case finalGong = "finalGong"     // End of dance
}

// MARK: - Watch Cueing Manager (WatchConnectivity)
final class WatchCueingManager: NSObject, ObservableObject, @unchecked Sendable, WCSessionDelegate {
    static let shared = WatchCueingManager()
    
    @Published var isWatchPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var lastCueSent: String = "Žiadny pokyn"
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Silent Haptic Cue
    func sendHapticCue(_ type: WatchHapticCueType, label: String) {
        lastCueSent = "\(label) (\(type.rawValue))"
        
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        if session.activationState == .activated && session.isReachable {
            let payload: [String: Any] = [
                "action": "hapticCue",
                "type": type.rawValue,
                "label": label,
                "timestamp": Date().timeIntervalSince1970
            ]
            session.sendMessage(payload, replyHandler: nil) { error in
                print("Watch haptic send error: \(error.localizedDescription)")
            }
        }
        
        // Also trigger local device haptic feedback as tactile reinforcement
        DispatchQueue.main.async {
            switch type {
            case .warning:
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.warning)
            case .beatAccent:
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
            case .figureChange:
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            case .finalGong:
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
