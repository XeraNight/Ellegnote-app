import Foundation
import Combine
import AVFoundation
import CoreMotion
import SwiftUI
import OSLog

// MARK: - Dance Camera Manager (AVFoundation + CoreMotion)
final class DanceCameraManager: NSObject, ObservableObject, @unchecked Sendable, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.encore.camera.sessionQueue")
    
    // State
    @Published var isRecording: Bool = false
    @Published var recordingDuration: Int = 0
    @Published var recordedVideoURL: URL? = nil
    @Published var audioLevel: Float = 0.0
    
    // CoreMotion Gyroscope Level State (Funkcia 2)
    @Published var deviceRollAngle: Double = 0.0
    @Published var isDeviceLevel: Bool = false
    @Published var isDeviceFlat: Bool = false
    @Published var flatOffset: CGPoint = .zero
    private var wasLevelBefore: Bool = false
    private let motionManager = CMMotionManager()
    
    private var isConfigured: Bool = false
    private var durationTimer: Timer? = nil
    
    override init() {
        super.init()
    }
    
    func start() {
        // Pre-configure unified audio session BEFORE camera session starts
        // This eliminates category conflict (err=-19224 / err=-17281) with simultaneous metronome audio
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .videoRecording,
                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true)
        } catch {
            Logger.camera.warning("AudioSession pre-configuration warning: \(error.localizedDescription)")
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured {
                self.setupSessionDirect()
                self.isConfigured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                self.startMotionUpdates()
            }
        }
    }
    
    func stop() {
        stopMotionUpdates()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func setupSessionDirect() {
        self.session.beginConfiguration()
        self.session.sessionPreset = .high
        
        // Video Input (Default back camera)
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: backCamera),
           self.session.canAddInput(input) {
            self.session.addInput(input)
            self.videoDeviceInput = input
        }
        
        // Audio Input (Microphone)
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           self.session.canAddInput(audioInput) {
            self.session.addInput(audioInput)
        }
        
        // Movie File Output (Čistý audio a video záznam bez konfliktných audio bufferov)
        if self.session.canAddOutput(self.movieOutput) {
            self.session.addOutput(self.movieOutput)
        }
        
        self.session.commitConfiguration()
    }
    
    func switchCamera(isFront: Bool) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            let position: AVCaptureDevice.Position = isFront ? .front : .back
            if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let newInput = try? AVCaptureDeviceInput(device: newCamera),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
                
                // Set mirroring for front camera (Funkcia 5)
                if let connection = self.movieOutput.connection(with: .video) {
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = isFront
                    }
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func setZoom(_ factor: Double) {
        guard let device = videoDeviceInput?.device else { return }
        do {
            try device.lockForConfiguration()
            let clamped = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.ramp(toVideoZoomFactor: CGFloat(clamped), withRate: 4.0)
            device.unlockForConfiguration()
        } catch {
            Logger.camera.error("Failed to set zoom: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func focus(at point: CGPoint) {
        guard let device = videoDeviceInput?.device, device.isFocusPointOfInterestSupported else { return }
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {
            Logger.camera.error("Failed to focus: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func toggleTorch(on: Bool) {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            Logger.camera.error("Failed to toggle torch: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mp4")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
                self.durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.recordingDuration += 1
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        DispatchQueue.main.async { [weak self] in
            self?.durationTimer?.invalidate()
            self?.durationTimer = nil
            self?.isRecording = false
        }
        
        sessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            DispatchQueue.main.async {
                self.recordedVideoURL = outputFileURL
            }
        }
    }
    
    // MARK: - CoreMotion Gyroscope Level (Apple Measure & Camera Style)
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let gx = motion.gravity.x
            let gy = motion.gravity.y
            let gz = motion.gravity.z
            
            // Check if phone is placed flat (like on a table or tripod pointing down)
            let isFlat = abs(gz) > 0.85
            
            // Calculate 2D screen tilt angle relative to upright gravity
            let angle = atan2(gx, -gy) * (180.0 / .pi)
            let isLevel = abs(angle) < 0.8
            
            DispatchQueue.main.async {
                self.deviceRollAngle = angle
                self.isDeviceLevel = isLevel
                self.isDeviceFlat = isFlat
                self.flatOffset = CGPoint(x: gx * 35.0, y: -gy * 35.0)
                
                // Trigger subtle haptic snap on entering level
                if isLevel && !self.wasLevelBefore {
                    let gen = UIImpactFeedbackGenerator(style: .rigid)
                    gen.impactOccurred()
                }
                self.wasLevelBefore = isLevel
            }
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
