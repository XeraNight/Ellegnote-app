import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - Dance Mirror View (Čisté Tanečné Zrkadlo)
// A 100% distraction-free front-camera mirror designed for dancers and competitors.
// Displays ONLY the pristine front camera video feed and a single Liquid Glass "Späť" button.
// Does NOT touch AVAudioSession / microphone, so background studio music keeps playing uninterrupted.

public struct DanceMirrorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = DanceMirrorCameraManager()
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color.black.ignoresSafeArea()
            
            // 1. Fullscreen Pristine Front Camera Feed
            if cameraManager.isCameraAvailable {
                GeometryReader { geo in
                    DanceMirrorPreviewRepresentable(session: cameraManager.session)
                        .ignoresSafeArea()
                        .onTapGesture(count: 2) {
                            HapticFeedback.light()
                            cameraManager.toggleZoom()
                        }
                        .onTapGesture(count: 1) { location in
                            guard geo.size.width > 0 && geo.size.height > 0 else { return }
                            let normalizedX = max(0, min(1, location.x / geo.size.width))
                            let normalizedY = max(0, min(1, location.y / geo.size.height))
                            cameraManager.focusAndExpose(at: CGPoint(x: normalizedX, y: normalizedY))
                        }
                }
            } else {
                // Simulator / No Camera Fallback
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 52))
                        .foregroundColor(LuxuryTheme.gold400.opacity(0.8))
                    
                    Text("Tanečné Zrkadlo")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Predná kamera je k dispozícii na reálnom zariadení iPhone.\nV simulátore nie je k dispozícii hardvér kamery.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 2. Single Liquid Glass "Späť" Button
            VStack {
                HStack {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Späť")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.35))
                                .background(.ultraThinMaterial, in: Capsule())
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.40), radius: 12, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.top, 54) // Safely below notch and Dynamic Island
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .statusBarHidden(true)
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}

// MARK: - Front Camera Preview UIKit Wrapper
private struct DanceMirrorPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> DanceMirrorPreviewUIView {
        let view = DanceMirrorPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = view.videoPreviewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        return view
    }
    
    func updateUIView(_ uiView: DanceMirrorPreviewUIView, context: Context) {
        if let connection = uiView.videoPreviewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}

private final class DanceMirrorPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Camera Manager (Dedicated to Front Camera, No Mic / Audio Session)
final class DanceMirrorCameraManager: NSObject, ObservableObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.ellegnote.mirror.sessionQueue")
    
    @Published var isRunning = false
    @Published var isCameraAvailable = true
    @Published var currentZoom: CGFloat = 1.0
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Acquire front camera device
            if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: frontCamera),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
                DispatchQueue.main.async {
                    self.isCameraAvailable = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isRunning = self.session.isRunning
            }
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
    
    func toggleZoom() {
        guard let device = videoInput?.device else { return }
        let targetZoom: CGFloat = currentZoom > 1.2 ? 1.0 : 2.0
        do {
            try device.lockForConfiguration()
            let clamped = max(1.0, min(targetZoom, device.activeFormat.videoMaxZoomFactor))
            device.ramp(toVideoZoomFactor: clamped, withRate: 4.0)
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.currentZoom = clamped
            }
        } catch {
            // Silently ignore zoom errors
        }
    }
    
    func focusAndExpose(at point: CGPoint) {
        guard let device = videoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            // Silently ignore configuration errors
        }
    }
}
