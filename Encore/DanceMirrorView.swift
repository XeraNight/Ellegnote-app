import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - Zrkadlo (Nástroje)
/// Full-screen front camera for checking hold, posture, hair and make-up. Optional fill light: a warm
/// frame around the picture plus full screen brightness, for dark halls. No microphone, so music keeps playing.
public struct DanceMirrorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var cameraManager = DanceMirrorCameraManager()

    @State private var isLightOn = false
    @State private var brightnessBeforeLight: CGFloat?
    @State private var showsHint = true
    @State private var zoomTaps = 0

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.isCameraAvailable {
                GeometryReader { geo in
                    DanceMirrorPreviewRepresentable(session: cameraManager.session)
                        .ignoresSafeArea()
                        .onTapGesture(count: 2) {
                            zoomTaps += 1
                            cameraManager.toggleZoom()
                        }
                        .onTapGesture(count: 1) { location in
                            guard geo.size.width > 0 && geo.size.height > 0 else { return }
                            cameraManager.focusAndExpose(at: CGPoint(
                                x: max(0, min(1, location.x / geo.size.width)),
                                y: max(0, min(1, location.y / geo.size.height))
                            ))
                        }
                }
                .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color.gold400)
                    Text("Zrkadlo")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    Text("Predná kamera nie je dostupná. Povoľ Encore prístup ku kamere v Nastaveniach iPhonu.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
            }

            // Fill light: a soft warm frame that lights the face from the screen.
            if isLightOn {
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .strokeBorder(Color(red: 1.0, green: 0.95, blue: 0.86), lineWidth: 64)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            VStack {
                HStack {
                    LiquidGlassCircleButton(icon: "xmark", label: "Zavrieť") { dismiss() }
                    Spacer()
                    LiquidGlassCircleButton(
                        icon: isLightOn ? "sun.max.fill" : "sun.max",
                        label: isLightOn ? "Vypnúť svetlo" : "Zapnúť svetlo",
                        isActive: isLightOn
                    ) { setLight(!isLightOn) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                if showsHint && cameraManager.isCameraAvailable {
                    Text("Ťukni pre zaostrenie · dvakrát pre priblíženie")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.bottom, 28)
                        .transition(.opacity)
                }
            }
        }
        .statusBarHidden(true)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isLightOn)
        .animation(.easeOut(duration: 0.4), value: showsHint)
        .sensoryFeedback(.selection, trigger: isLightOn)
        .sensoryFeedback(.impact(weight: .light), trigger: zoomTaps)
        .task {
            try? await Task.sleep(for: .seconds(3))
            showsHint = false
        }
        .onAppear { cameraManager.start() }
        .onDisappear {
            setLight(false)
            cameraManager.stop()
        }
    }

    /// Full brightness while the light is on; the previous brightness comes back afterwards.
    private func setLight(_ on: Bool) {
        guard let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen else { return }
        if on, !isLightOn {
            brightnessBeforeLight = screen.brightness
            screen.brightness = 1.0
        } else if !on, isLightOn, let previous = brightnessBeforeLight {
            screen.brightness = previous
            brightnessBeforeLight = nil
        }
        isLightOn = on
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
    private let sessionQueue = DispatchQueue(label: "com.encore.mirror.sessionQueue")
    
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

            // Acquire front camera device
            if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: frontCamera),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
                self.configureForBestPicture(frontCamera)
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
    
    /// The sharpest live picture the front camera offers: 4K when supported (otherwise 1080p),
    /// 60 frames per second when possible, automatic HDR and low-light boost.
    private func configureForBestPicture(_ device: AVCaptureDevice) {
        if session.canSetSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }

        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        if device.activeFormat.isVideoHDRSupported {
            device.automaticallyAdjustsVideoHDREnabled = true
        }
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
        if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= 60 }) {
            let frame = CMTime(value: 1, timescale: 60)
            device.activeVideoMinFrameDuration = frame
            device.activeVideoMaxFrameDuration = frame
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
