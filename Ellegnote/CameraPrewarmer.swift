import Foundation
import AVFoundation
import UIKit

// MARK: - Zero-Lag Camera Pre-Warming Engine
final class CameraPrewarmer: NSObject, @unchecked Sendable {
    static let shared = CameraPrewarmer()
    
    private(set) var captureSession: AVCaptureSession?
    private(set) var movieOutput: AVCaptureMovieFileOutput?
    private(set) var activeInput: AVCaptureDeviceInput?
    private(set) var isPrewarmed = false
    
    private let prewarmQueue = DispatchQueue(label: "com.ellegnote.cameraprewarm", qos: .userInitiated)
    
    private override init() {
        super.init()
    }
    
    /// Pre-warms camera HW session on background queue during 2-second launch splash
    func prewarm() {
        guard !isPrewarmed else { return }
        
        prewarmQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            // 1. Rear Camera Video Input
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
               session.canAddInput(videoInput) {
                session.addInput(videoInput)
                self.activeInput = videoInput
            }
            
            // 2. Microphone Audio Input
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
            
            // 3. Movie File Output
            let output = AVCaptureMovieFileOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.movieOutput = output
            }
            
            // 4. Start session running in background
            session.startRunning()
            
            self.captureSession = session
            self.isPrewarmed = true
        }
    }
    
    /// Ensures camera session is active and running when camera view is presented
    func ensureSessionRunning() {
        guard let session = captureSession else {
            prewarm()
            return
        }
        if !session.isRunning {
            prewarmQueue.async {
                session.startRunning()
            }
        }
    }
}
