import Foundation
import AVFoundation
import UIKit

// MARK: - Lightweight Camera Permission Preparation
final class CameraPrewarmer: NSObject, @unchecked Sendable {
    static let shared = CameraPrewarmer()
    
    private(set) var isPrewarmed = false
    private let prewarmQueue = DispatchQueue(label: "com.ellegnote.cameraprewarm", qos: .utility)
    
    private override init() {
        super.init()
    }
    
    /// Requests camera/microphone permissions without starting a shared capture session.
    func prewarm() {
        guard !isPrewarmed else { return }
        
        prewarmQueue.async { [weak self] in
            guard let self = self else { return }
            
            let group = DispatchGroup()
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                group.enter()
                AVCaptureDevice.requestAccess(for: .video) { _ in group.leave() }
            }
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                group.enter()
                AVCaptureDevice.requestAccess(for: .audio) { _ in group.leave() }
            }
            group.wait()
            self.isPrewarmed = true
        }
    }
    
    /// Kept for older call sites. Actual sessions are owned by each camera screen.
    func ensureSessionRunning() {
        prewarm()
    }
}
