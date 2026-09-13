import SwiftUI
import SwiftData
import AVFoundation
import AVKit
import Combine
import CoreMotion
import AudioToolbox
import OSLog
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif



// MARK: - Samospúšť (Countdown Timer) Enum
enum CountdownDuration: Int, CaseIterable, Identifiable {
    case off = 0
    case threeSeconds = 3
    case fiveSeconds = 5
    case tenSeconds = 10
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .off: return "Vypnuté"
        case .threeSeconds: return "3s"
        case .fiveSeconds: return "5s"
        case .tenSeconds: return "10s"
        }
    }
}

// MARK: - Zoom Factor Options
enum CameraZoomFactor: Double, CaseIterable, Identifiable {
    case wide = 0.5
    case standard = 1.0
    case telephoto = 2.0
    
    var id: Double { rawValue }
    
    var label: String {
        switch self {
        case .wide: return "0.5x"
        case .standard: return "1x"
        case .telephoto: return "2x"
        }
    }
}

// MARK: - Tanečný Metronóm Preset (Funkcia 9)
enum DanceMetronomePreset: String, CaseIterable, Identifiable {
    case off = "Vypnuté"
    case waltz = "Waltz (29 MPM)"
    case tango = "Tango (32 MPM)"
    case vienneseWaltz = "Viedenský valčík (59 MPM)"
    case slowfox = "Slowfox (29 MPM)"
    case quickstep = "Quickstep (51 MPM)"
    case samba = "Samba (51 MPM)"
    case chacha = "Cha-Cha (31 MPM)"
    case rumba = "Rumba (26 MPM)"
    case pasoDoble = "Paso Doble (61 MPM)"
    case jive = "Jive (43 MPM)"
    
    var id: String { rawValue }
    
    var shortCode: String {
        switch self {
        case .off: return "Off"
        case .waltz: return "Waltz"
        case .tango: return "Tango"
        case .vienneseWaltz: return "V.Valčík"
        case .slowfox: return "Slowfox"
        case .quickstep: return "Quickstep"
        case .samba: return "Samba"
        case .chacha: return "Cha-Cha"
        case .rumba: return "Rumba"
        case .pasoDoble: return "Paso"
        case .jive: return "Jive"
        }
    }
    
    var mpm: Double {
        switch self {
        case .off: return 0
        case .waltz: return 29.0
        case .tango: return 32.0
        case .vienneseWaltz: return 59.0
        case .slowfox: return 29.0
        case .quickstep: return 51.0
        case .samba: return 51.0
        case .chacha: return 31.0
        case .rumba: return 26.0
        case .pasoDoble: return 61.0
        case .jive: return 43.0
        }
    }
    
    var bpm: Double {
        switch self {
        case .off: return 0
        case .waltz: return 87.0 // 29 * 3
        case .tango: return 128.0 // 32 * 4
        case .vienneseWaltz: return 177.0 // 59 * 3
        case .slowfox: return 116.0 // 29 * 4
        case .quickstep: return 204.0 // 51 * 4
        case .samba: return 102.0 // 51 * 2
        case .chacha: return 124.0 // 31 * 4
        case .rumba: return 104.0 // 26 * 4
        case .pasoDoble: return 122.0 // 61 * 2
        case .jive: return 172.0 // 43 * 4
        }
    }
    
    var beatsPerMeasure: Int {
        switch self {
        case .waltz, .vienneseWaltz: return 3
        case .samba, .pasoDoble: return 2
        default: return 4
        }
    }
}

// MARK: - DanceCameraView
struct DanceCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Callbacks
    var ghostVideoPath: String? = nil
    var onRecordComplete: (String) -> Void
    
    // Camera Controller State
    @StateObject private var camera = DanceCameraManager()
    
    // Instant Memory Toast
    @State private var bookmarkToastText: String? = nil
    @State private var lastLiveActivityUpdate: Date = .distantPast
    
    // UI Feature States (Funkcie 1 - 5)
    @State private var countdownDuration: CountdownDuration = .off
    @State private var countdownRemaining: Int = 0
    @State private var isCountingDown: Bool = false
    @State private var countdownTimer: Timer? = nil
    
    @State private var showGridAndLevel: Bool = true
    @State private var selectedZoom: CameraZoomFactor = .standard
    @State private var isFrontMirrorMode: Bool = false
    
    // Ghost / Onion Skinning State (Funkcia 4)
    @State private var showGhostOverlay: Bool = false
    @State private var ghostOpacity: Double = 0.45
    @State private var ghostPlayer: AVPlayer? = nil
    
    // Torch state
    @State private var isTorchOn: Bool = false
    
    // Metronome State (Funkcia 9)
    @State private var selectedMetronome: DanceMetronomePreset = .off
    @State private var tempoMultiplier: Double = 1.0
    @State private var currentBeat: Int = 1
    @State private var isMetronomePulse: Bool = false
    @State private var metronomeTimer: Timer? = nil
    @State private var isMetronomeHapticEnabled: Bool = true
    
    // Post-Recording Quick Tag & Trim Modal (Funkcia 8 & 10)
    @State private var rawRecordedURL: URL? = nil
    @State private var showSaveDetailsSheet: Bool = false
    @State private var showTrimmerSheet: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. Live Camera Preview Viewport
            CameraPreviewRepresentable(session: camera.session)
                .ignoresSafeArea()
                .onTapGesture { location in
                    camera.focus(at: location)
                }
            
            // 2. Ghosting Video Overlay (Funkcia 4: Cibuľová koža / Onion Skinning)
            if showGhostOverlay, let player = ghostPlayer {
                GhostPlayerRepresentable(player: player)
                    .opacity(ghostOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // 3. Gyroscope Level & 3x3 Composition Grid (Funkcia 1 & 2)
            if showGridAndLevel {
                CameraGridAndLevelOverlay(
                    tiltAngle: camera.deviceRollAngle,
                    isLevel: camera.isDeviceLevel,
                    isFlat: camera.isDeviceFlat,
                    flatOffset: camera.flatOffset
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            // 4. Large Samospúšť Countdown Overlay
            if isCountingDown {
                Text("\(countdownRemaining)")
                    .font(.system(size: 110, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.amberGold)
                    .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
                    .transition(.scale.combined(with: .opacity))
                    .id(countdownRemaining)
            }
            
            // 5. Instant Memory Toast Banner
            if let toast = bookmarkToastText {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.98, green: 0.88, blue: 0.20))
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.88))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.98, green: 0.88, blue: 0.20).opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, 56)
                .zIndex(100)
            }
            
            // 6. Camera Controls Deck UI (Header + Ambient VU Meter + Footer)
            VStack {
                // Top Header Bar
                topHeaderBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                Spacer()
                
                // Live VU Meter & Recording Duration Pill
                HStack(spacing: 10) {
                    if camera.isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(formatDuration(camera.recordingDuration))
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                        .overlay(Capsule().stroke(Color.red.opacity(0.6), lineWidth: 1))
                    }
                    
                    // Live Audio VU Meter (Funkcia 7: Reálny ambientný mikrofón)
                    CameraVUMeterView(audioLevel: camera.audioLevel)
                }
                .padding(.bottom, 10)
                
                // Zoom Quick Switcher (Funkcia 3: 0.5x, 1x, 2x)
                zoomSwitcherBar
                    .padding(.bottom, 16)
                
                // Bottom Camera Shutter Deck
                bottomControlsDeck
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .statusBarHidden()
        .onReceive(NotificationCenter.default.publisher(for: .stopRecordingFromLiveActivity)) { _ in
            stopRecordingFromLiveActivity()
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookmarkRecordingFromLiveActivity)) { _ in
            saveInstantMemoryBookmark()
        }
        .onAppear {
            camera.start()
            
            // Setup Darwin notification listener for Lock Screen & Dynamic Island Bookmark / Stop intents
            let observer = Unmanaged.passUnretained(self as AnyObject).toOpaque()
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer,
                { _, _, name, _, _ in
                    guard let name = name?.rawValue as String? else { return }
                    if name == "com.ellegnote.bookmark" {
                        NotificationCenter.default.post(name: .bookmarkRecordingFromLiveActivity, object: nil)
                    } else if name == "com.ellegnote.stopRecording" {
                        NotificationCenter.default.post(name: .stopRecordingFromLiveActivity, object: nil)
                    }
                },
                nil,
                nil,
                .deliverImmediately
            )
            
            if let ghostPath = ghostVideoPath, let url = MediaResolver.resolveVideoURL(path: ghostPath) {
                let item = AVPlayerItem(url: url)
                let player = AVPlayer(playerItem: item)
                player.actionAtItemEnd = .none
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
                self.ghostPlayer = player
            }
        }
        .onDisappear {
            stopCountdown()
            stopMetronome()
            endRecordingLiveActivity()
            ghostPlayer?.pause()
            ghostPlayer = nil
            camera.stop()
        }
        .onChange(of: camera.recordedVideoURL) { _, newURL in
            if let url = newURL {
                rawRecordedURL = url
                showSaveDetailsSheet = true
            }
        }
        .onChange(of: selectedMetronome) { _, _ in
            updateRecordingLiveActivity(force: true)
        }
        .onChange(of: tempoMultiplier) { _, _ in
            updateRecordingLiveActivity(force: true)
        }
        .onChange(of: camera.audioLevel) { _, _ in
            if camera.isRecording {
                updateRecordingLiveActivity()
            }
        }
        // Modal for Quick Tag & Trim (Funkcia 8 & 10)
        .sheet(isPresented: $showSaveDetailsSheet) {
            if let url = rawRecordedURL {
                QuickSaveVideoSheet(
                    videoURL: url,
                    onTrimRequest: {
                        showTrimmerSheet = true
                    },
                    onSaveCompleted: { finalURL in
                        do {
                            let filename = try MediaStorageManager.moveIntoDocuments(from: finalURL, fileExtension: "mp4")
                            onRecordComplete(filename)
                            dismiss()
                        } catch {
                            print("Failed to save final video: \(error)")
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showTrimmerSheet) {
            if let url = rawRecordedURL {
                VideoTrimView(originalVideoURL: url) { trimmedURL in
                    rawRecordedURL = trimmedURL
                }
            }
        }
    }
    
    // MARK: - Top Header Bar (Safe from Dynamic Island)
    private var topHeaderBar: some View {
        HStack {
            // Dismiss Button (44pt HIG Target)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            
            Spacer()
            
            // Flash / Torch Toggle Button
            Button {
                isTorchOn.toggle()
                camera.toggleTorch(on: isTorchOn)
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            } label: {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isTorchOn ? Color.amberGold : .white)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isTorchOn ? Color.amberGold : Color.white.opacity(0.18), lineWidth: 1))
            }
        }
    }
    
    private var recordingStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            Text(formatDuration(camera.recordingDuration))
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
            
            if selectedMetronome != .off {
                Divider()
                    .frame(height: 14)
                    .overlay(Color.white.opacity(0.25))
                
                beatIndicator
                
                Text("\(Int(selectedMetronome.bpm * tempoMultiplier)) BPM")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(currentBeat == 1 ? Color.amberGold : .white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.68))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.red.opacity(0.55), lineWidth: 1))
    }
    
    private var metronomeStatusPill: some View {
        HStack(spacing: 7) {
            beatIndicator
            
            Text("\(selectedMetronome.shortCode) • \(Int(selectedMetronome.bpm * tempoMultiplier)) BPM • Doba \(currentBeat)/\(selectedMetronome.beatsPerMeasure)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(currentBeat == 1 ? Color.amberGold : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.65))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(currentBeat == 1 ? Color.amberGold.opacity(0.6) : Color.white.opacity(0.18), lineWidth: 1))
    }
    
    private var beatIndicator: some View {
        Circle()
            .fill(currentBeat == 1 ? Color.amberGold : Color.white)
            .frame(width: isMetronomePulse ? 10 : 7, height: isMetronomePulse ? 10 : 7)
            .shadow(color: currentBeat == 1 ? Color.amberGold : Color.clear, radius: isMetronomePulse ? 6 : 0)
    }
    
    // MARK: - Action Control Strip (Always Accessible Below Dynamic Island)
    private var actionControlStrip: some View {
        HStack(spacing: 8) {
            // Metronome Menu with Tempo Adjuster
            Menu {
                Section("Tanečný metronóm") {
                    ForEach(DanceMetronomePreset.allCases) { preset in
                        Button {
                            selectedMetronome = preset
                            restartMetronome()
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                if selectedMetronome == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                if selectedMetronome != .off {
                    Section("Tempo: \(Int(selectedMetronome.bpm * tempoMultiplier)) BPM (\(Int(selectedMetronome.mpm * tempoMultiplier)) MPM)") {
                        Button("Svižnejšie (+5%)") {
                            tempoMultiplier = min(1.3, tempoMultiplier + 0.05)
                            restartMetronome()
                        }
                        Button("Pomalšie (-5%)") {
                            tempoMultiplier = max(0.7, tempoMultiplier - 0.05)
                            restartMetronome()
                        }
                        Button("Pôvodné tempo (100%)") {
                            tempoMultiplier = 1.0
                            restartMetronome()
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if selectedMetronome != .off {
                        beatIndicator
                        Text("\(selectedMetronome.shortCode) \(Int(selectedMetronome.bpm * tempoMultiplier)) BPM")
                            .font(.system(size: 12, weight: .bold))
                    } else {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Metronóm")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(selectedMetronome != .off ? Color.amberGold : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedMetronome != .off ? Color.amberGold.opacity(0.22) : Color.black.opacity(0.55))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedMetronome != .off ? (currentBeat == 1 ? Color.amberGold : Color.amberGold.opacity(0.4)) : Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            
            // Grid & Horizon Level Button (Funkcia 2)
            Button {
                showGridAndLevel.toggle()
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: showGridAndLevel ? "grid" : "grid.slash")
                        .font(.system(size: 13, weight: .bold))
                    Text("Mriežka")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(showGridAndLevel ? Color.amberGold : .white.opacity(0.75))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(showGridAndLevel ? Color.amberGold.opacity(0.22) : Color.black.opacity(0.55))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(showGridAndLevel ? Color.amberGold : Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            
            // Samospúšť / Countdown Duration Selector (Funkcia 1)
            Menu {
                ForEach(CountdownDuration.allCases) { dur in
                    Button {
                        countdownDuration = dur
                    } label: {
                        HStack {
                            Text(dur.title)
                            if countdownDuration == dur {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .bold))
                    Text(countdownDuration == .off ? "Spúšť" : countdownDuration.title)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(countdownDuration != .off ? Color.amberGold : .white.opacity(0.75))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(countdownDuration != .off ? Color.amberGold.opacity(0.22) : Color.black.opacity(0.55))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(countdownDuration != .off ? Color.amberGold : Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            
            // Ghost / Onion Skinning Button (Funkcia 4)
            if ghostVideoPath != nil {
                Button {
                    showGhostOverlay.toggle()
                    if showGhostOverlay {
                        ghostPlayer?.play()
                    } else {
                        ghostPlayer?.pause()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.wave.2.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Ghost")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(showGhostOverlay ? Color.amberGold : .white.opacity(0.75))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(showGhostOverlay ? Color.amberGold.opacity(0.22) : Color.black.opacity(0.55))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(showGhostOverlay ? Color.amberGold : Color.white.opacity(0.18), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Ghost Controls Bar
    private var ghostControlsBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .foregroundColor(.amberGold)
                .font(.system(size: 12))
            
            Slider(value: $ghostOpacity, in: 0.15...0.85)
                .tint(.amberGold)
            
            Text("\(Int(ghostOpacity * 100))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.65))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
    
    // MARK: - Zoom Switcher Bar (Funkcia 3: 0.5x, 1x, 2x)
    private var zoomSwitcherBar: some View {
        HStack(spacing: 6) {
            ForEach(CameraZoomFactor.allCases) { zoom in
                Button {
                    selectedZoom = zoom
                    camera.setZoom(zoom.rawValue)
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                } label: {
                    Text(zoom.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedZoom == zoom ? Color.black : Color.white)
                        .frame(width: 44, height: 32)
                        .background(selectedZoom == zoom ? Color.amberGold : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
    
    // MARK: - Bottom Controls Deck
    private var bottomControlsDeck: some View {
        HStack {
            // Left Balance Spacer
            Color.clear
                .frame(width: 52, height: 52)
            
            Spacer()
            
            // Main Shutter Button with Countdown & Morphing Record Icon
            Button(action: handleShutterTap) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 76, height: 76)
                    
                    if camera.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    } else if isCountingDown {
                        Circle()
                            .fill(Color.amberGold)
                            .frame(width: 62, height: 62)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 62, height: 62)
                    }
                }
            }
            
            Spacer()
            
            // Flip Front / Back Camera with Mirror Mode (Funkcia 5)
            Button {
                isFrontMirrorMode.toggle()
                camera.switchCamera(isFront: isFrontMirrorMode)
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .disabled(camera.isRecording || isCountingDown)
        }
    }
    
    // MARK: - Shutter Action & Countdown Handler
    private func handleShutterTap() {
        if camera.isRecording {
            stopActiveRecording()
        } else if isCountingDown {
            stopCountdown()
        } else {
            if countdownDuration != .off {
                startCountdown(seconds: countdownDuration.rawValue)
            } else {
                startRecordingNow()
            }
        }
    }
    
    private func stopActiveRecording() {
        camera.stopRecording()
        endRecordingLiveActivity()
        ghostPlayer?.pause()
    }
    
    private func stopRecordingFromLiveActivity() {
        guard camera.isRecording else { return }
        stopActiveRecording()
    }
    
    private func startCountdown(seconds: Int) {
        isCountingDown = true
        countdownRemaining = seconds
        playBeep()
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownRemaining > 1 {
                countdownRemaining -= 1
                playBeep()
            } else {
                timer.invalidate()
                countdownTimer = nil
                isCountingDown = false
                playStartBeep()
                startRecordingNow()
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountingDown = false
    }
    
    private func startRecordingNow() {
        camera.startRecording()
        startRecordingLiveActivity()
        if showGhostOverlay {
            ghostPlayer?.seek(to: .zero)
            ghostPlayer?.play()
        }
    }
    
    // MARK: - Metronome Logic (Funkcia 9 - Precise Rhythm & Downbeat)
    private func restartMetronome() {
        stopMetronome()
        guard selectedMetronome != .off else { return }
        
        let effectiveBpm = selectedMetronome.bpm * tempoMultiplier
        guard effectiveBpm > 0 else { return }
        let interval = 60.0 / effectiveBpm
        currentBeat = 1
        
        // Immediate downbeat on start
        withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
            isMetronomePulse = true
        }
        if isMetronomeHapticEnabled {
            HapticFeedback.heavy()
        }
        AudioServicesPlaySystemSound(1103)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isMetronomePulse = false
        }
        
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            currentBeat = (currentBeat % selectedMetronome.beatsPerMeasure) + 1
            
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                isMetronomePulse = true
            }
            
            if isMetronomeHapticEnabled {
                if currentBeat == 1 {
                    HapticFeedback.heavy()
                } else {
                    HapticFeedback.light()
                }
            }
            
            if currentBeat == 1 {
                AudioServicesPlaySystemSound(1103) // High downbeat
            } else {
                AudioServicesPlaySystemSound(1057) // Beat tick
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                isMetronomePulse = false
            }
        }
    }
    
    private func stopMetronome() {
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        currentBeat = 1
        isMetronomePulse = false
    }
    
    private func saveInstantMemoryBookmark() {
        let durationString = formatDuration(camera.recordingDuration)
        let danceName = selectedMetronome != .off ? "\(selectedMetronome.shortCode) Tréning" : "Dance Training Hall 4"
        let noteText = "📌 Značka [\(durationString)] — \(danceName)"
        
        let newNote = InstantNote(text: noteText)
        modelContext.insert(newNote)
        try? modelContext.save()
        
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            bookmarkToastText = "Značka [\(durationString)] uložená do Instant Memory"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.25)) {
                bookmarkToastText = nil
            }
        }
    }
    
    #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
    private func startRecordingLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let state = RecordingActivityAttributes.ContentState(
            startDate: Date(),
            sessionTitle: selectedMetronome != .off ? "\(selectedMetronome.shortCode) Tréning" : "Dance Training Hall 4",
            metronomeName: selectedMetronome == .off ? "" : selectedMetronome.shortCode,
            bpm: selectedMetronome == .off ? 0 : Int(selectedMetronome.bpm * tempoMultiplier),
            beatsPerMeasure: selectedMetronome == .off ? 0 : selectedMetronome.beatsPerMeasure,
            audioLevel: camera.audioLevel
        )
        
        Task {
            for activity in Activity<RecordingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            
            do {
                _ = try Activity.request(
                    attributes: RecordingActivityAttributes(recordingName: "Tanečné nahrávanie"),
                    content: .init(state: state, staleDate: nil, relevanceScore: 100),
                    pushType: nil
                )
            } catch {
                Logger.camera.error("Failed to start recording Live Activity: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    private func updateRecordingLiveActivity(force: Bool = false) {
        guard camera.isRecording else { return }
        let now = Date()
        guard force || now.timeIntervalSince(lastLiveActivityUpdate) >= 0.7 else { return }
        lastLiveActivityUpdate = now
        
        let state = RecordingActivityAttributes.ContentState(
            startDate: Date().addingTimeInterval(-Double(camera.recordingDuration)),
            sessionTitle: selectedMetronome != .off ? "\(selectedMetronome.shortCode) Tréning" : "Dance Training Hall 4",
            metronomeName: selectedMetronome == .off ? "" : selectedMetronome.shortCode,
            bpm: selectedMetronome == .off ? 0 : Int(selectedMetronome.bpm * tempoMultiplier),
            beatsPerMeasure: selectedMetronome == .off ? 0 : selectedMetronome.beatsPerMeasure,
            audioLevel: camera.audioLevel
        )
        
        Task {
            for activity in Activity<RecordingActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil, relevanceScore: 100))
            }
        }
    }
    
    private func endRecordingLiveActivity() {
        Task {
            for activity in Activity<RecordingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    #else
    private func startRecordingLiveActivity() {}
    private func updateRecordingLiveActivity(force: Bool = false) {}
    private func endRecordingLiveActivity() {}
    #endif
    
    private func playBeep() {
        AudioServicesPlaySystemSound(1057) // Native camera countdown tick
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
    
    private func playStartBeep() {
        AudioServicesPlaySystemSound(1117) // Begin recording beep
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
