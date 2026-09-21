import SwiftUI
import AVKit
import Combine

enum DualLayoutMode: String, CaseIterable, Identifiable {
    case stacked = "Nad sebou"
    case sideBySide = "Vedľa seba"
    case singleSwitch = "Prepínač A/B"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .stacked: return "rectangle.split.1x2.fill"
        case .sideBySide: return "rectangle.split.2x1.fill"
        case .singleSwitch: return "arrow.left.and.right.square.fill"
        }
    }
}

enum DualAudioSource: String, CaseIterable, Identifiable {
    case slotA = "Zvuk: Moje (A)"
    case slotB = "Zvuk: Vzor (B)"
    case mute = "Bez zvuku"
    
    var id: String { rawValue }
}

enum DualSlotTarget: String, Identifiable {
    case slotA = "Moje video / fotka (Slot A)"
    case slotB = "Vzor / Idol (Slot B)"
    
    var id: String { rawValue }
}

struct DualVideoComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Video/Photo Paths (Local file names in Documents)
    @Binding var pathA: String?
    @Binding var pathB: String?
    
    var titleA: String = "Moje video (A)"
    var titleB: String = "Vzor / Idol (B)"
    
    // Player instances
    @State private var playerA: AVPlayer?
    @State private var playerB: AVPlayer?
    @State private var observerTokenA: Any?
    @State private var observerTokenB: Any?
    @State private var timeObserverTokenA: Any?
    
    // Photo Image instances
    @State private var imageA: UIImage? = nil
    @State private var imageB: UIImage? = nil
    
    // Slot Picker Sheet Target
    @State private var activePickerSlot: DualSlotTarget? = nil
    
    // Playback state
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 1.0
    @State private var isScrubbing: Bool = false
    @State private var playbackRate: Float = 1.0
    @State private var isLooping: Bool = true
    
    // Synchronization & Offset
    /// Offset in seconds applied to Video B relative to Video A (e.g. +0.50s means Video B starts 0.5s later)
    @State private var offsetB: Double = 0.0
    @State private var layoutMode: DualLayoutMode = .stacked
    @State private var activeSingleSlot: Int = 1 // 1 for A, 2 for B
    @State private var audioSource: DualAudioSource = .slotA
    
    // UI Feedback
    @State private var showOffsetFineControl: Bool = false
    @State private var showPostureAnalysis: Bool = false
    
    var isPhotoA: Bool {
        guard let p = pathA else { return false }
        return MediaResolver.isImagePath(path: p) || imageA != nil
    }
    
    var isPhotoB: Bool {
        guard let p = pathB else { return false }
        return MediaResolver.isImagePath(path: p) || imageB != nil
    }
    
    var isBothPhotos: Bool {
        (pathA != nil || pathB != nil) && (pathA == nil || isPhotoA) && (pathB == nil || isPhotoB) && (playerA == nil && playerB == nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                VStack(spacing: 0) {
                    // Header Bar with Layout Switcher & Audio source
                    topControlsBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    
                    // Video Viewport Area
                    videoViewportArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 12)
                    
                    // Bottom Synchronization & Control Deck
                    bottomControlDeck
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 16)
                        .background(
                            Color.obsidian900
                                .shadow(color: Color.black.opacity(0.4), radius: 10, y: -4)
                        )
                }
            }
            .navigationTitle("⚔️ Dual Porovnávač")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zavrieť") {
                        tearDownPlayers()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.gold400)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            if isPlaying { togglePlayPause() }
                            showPostureAnalysis = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "angle")
                                Text("Postúra")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.latinRed)
                        }
                        
                        Button(action: swapSlots) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Prehodiť")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.gold400)
                        }
                    }
                }
            }
            .sheet(item: $activePickerSlot) { slot in
                UniversalMediaPickerSheet(
                    slotTitle: slot.rawValue,
                    currentPath: slot == .slotA ? pathA : pathB,
                    onSelectMedia: { selectedPath in
                        if slot == .slotA {
                            pathA = selectedPath
                        } else {
                            pathB = selectedPath
                        }
                        setupPlayers()
                    },
                    onClearMedia: {
                        if slot == .slotA {
                            pathA = nil
                        } else {
                            pathB = nil
                        }
                        setupPlayers()
                    }
                )
            }
            .fullScreenCover(isPresented: $showPostureAnalysis) {
                let urlA = pathA.flatMap { MediaResolver.resolveVideoURL(path: $0) }
                let urlB = pathB.flatMap { MediaResolver.resolveVideoURL(path: $0) }
                if let resolvedURL = urlA ?? urlB {
                    PostureAnalysisOverlayView(videoURL: resolvedURL, freezeTime: currentTime)
                }
            }
            .onChange(of: pathA) { _, _ in
                setupPlayers()
            }
            .onChange(of: pathB) { _, _ in
                setupPlayers()
            }
            .onAppear {
                setupPlayers()
            }
            .onDisappear {
                tearDownPlayers()
            }
        }
    }
    
    // MARK: - Top Controls Bar
    private var topControlsBar: some View {
        HStack {
            // Layout picker
            Picker("Rozloženie", selection: $layoutMode) {
                ForEach(DualLayoutMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Audio selection menu
            Menu {
                ForEach(DualAudioSource.allCases) { source in
                    Button {
                        audioSource = source
                        applyAudioVolumes()
                    } label: {
                        HStack {
                            Text(source.rawValue)
                            if audioSource == source {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: audioSource == .mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(Color.gold400)
                    Text(audioSource == .slotA ? "Zvuk: A" : (audioSource == .slotB ? "Zvuk: B" : "Ticho"))
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.obsidian800)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Video Viewport Area
    private var videoViewportArea: some View {
        Group {
            switch layoutMode {
            case .stacked:
                VStack(spacing: 8) {
                    videoSlotView(title: titleA, path: pathA, player: playerA, image: imageA, isPhoto: isPhotoA, slotBadge: "🔴 MOJE (A)", isSlotA: true)
                    videoSlotView(title: titleB, path: pathB, player: playerB, image: imageB, isPhoto: isPhotoB, slotBadge: "🟢 VZOR / IDOL (B)", isSlotA: false)
                }
            case .sideBySide:
                HStack(spacing: 8) {
                    videoSlotView(title: titleA, path: pathA, player: playerA, image: imageA, isPhoto: isPhotoA, slotBadge: "🔴 MOJE (A)", isSlotA: true)
                    videoSlotView(title: titleB, path: pathB, player: playerB, image: imageB, isPhoto: isPhotoB, slotBadge: "🟢 VZOR (B)", isSlotA: false)
                }
            case .singleSwitch:
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            activeSingleSlot = 1
                        } label: {
                            Text("🔴 \(titleA)")
                                .font(.system(size: 13, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(activeSingleSlot == 1 ? Color.red.opacity(0.2) : Color.themeCard)
                                .foregroundColor(activeSingleSlot == 1 ? .red : .white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeSingleSlot == 1 ? Color.red : Color.white.opacity(0.12), lineWidth: 1.5))
                        }
                        
                        Button {
                            activeSingleSlot = 2
                        } label: {
                            Text("🟢 \(titleB)")
                                .font(.system(size: 13, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(activeSingleSlot == 2 ? Color.green.opacity(0.2) : Color.themeCard)
                                .foregroundColor(activeSingleSlot == 2 ? .green : .white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeSingleSlot == 2 ? Color.green : Color.white.opacity(0.12), lineWidth: 1.5))
                        }
                    }
                    
                    if activeSingleSlot == 1 {
                        videoSlotView(title: titleA, path: pathA, player: playerA, image: imageA, isPhoto: isPhotoA, slotBadge: "🔴 MOJE (A)", isSlotA: true)
                    } else {
                        videoSlotView(title: titleB, path: pathB, player: playerB, image: imageB, isPhoto: isPhotoB, slotBadge: "🟢 VZOR (B)", isSlotA: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Individual Media Slot Card
    private func videoSlotView(title: String, path: String?, player: AVPlayer?, image: UIImage?, isPhoto: Bool, slotBadge: String, isSlotA: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            Color.obsidian900
                .cornerRadius(12)
            
            if isPhoto, let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let player = player {
                CustomAVPlayerRepresentable(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    activePickerSlot = isSlotA ? .slotA : .slotB
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isSlotA ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(isSlotA ? .red : .green)
                        }
                        
                        Text("Zvoliť video alebo fotku")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Klepni pre výber z knižnice, galérie alebo natočenie")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Top Badge Overlay & Controls
            HStack {
                HStack(spacing: 6) {
                    Text(slotBadge)
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSlotA ? Color.red.opacity(0.85) : Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    if path != nil {
                        Text(isPhoto ? "📷 FOTKA" : "🎬 VIDEO")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(Color.gold400)
                            .cornerRadius(5)
                    }
                }
                
                Spacer()
                
                if path != nil {
                    // Change media button
                    Button {
                        activePickerSlot = isSlotA ? .slotA : .slotB
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Zmeniť")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(Color.gold400)
                        .cornerRadius(6)
                    }
                    
                    // Clear media button
                    Button {
                        if isSlotA {
                            pathA = nil
                        } else {
                            pathB = nil
                        }
                        setupPlayers()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.75))
                            .background(Color.black.clipShape(Circle()))
                    }
                }
                
                if !isSlotA && !isPhoto && abs(offsetB) > 0.01 {
                    Text(String(format: "Offset: %+.2fs", offsetB))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .foregroundColor(.yellow)
                        .cornerRadius(6)
                }
            }
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSlotA ? Color.red.opacity(0.4) : Color.green.opacity(0.4), lineWidth: 2)
        )
    }
    
    // MARK: - Bottom Control Deck
    private var bottomControlDeck: some View {
        VStack(spacing: 12) {
            if isBothPhotos {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.metering.center.weighted")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.gold400)
                        Text("Porovnanie línie & postúry (Statické fotky)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Obe médiá v slotoch sú fotografie. Porovnaj geometriu držania tela, polohu rúk a ťažisko.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.obsidian800)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            } else {
                // Combined Scrubber
                VStack(spacing: 4) {
                    Slider(value: Binding(
                        get: { currentTime },
                        set: { newTime in
                            currentTime = newTime
                            seekPlayers(to: newTime)
                        }
                    ), in: 0...max(duration, 0.1))
                    .tint(Color.gold400)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatTime(duration))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                
                // Primary Playback Buttons & Speed Selector
                HStack(spacing: 16) {
                    // Rate Selector
                    Menu {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { rate in
                            Button("\(String(format: "%.2f", rate))x") {
                                playbackRate = Float(rate)
                                if isPlaying {
                                    playerA?.rate = playbackRate
                                    playerB?.rate = playbackRate
                                }
                            }
                        }
                    } label: {
                        Text(String(format: "%.2fx", playbackRate))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.obsidian800)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // Step Back 1 Frame (Funkcia 6)
                    Button {
                        stepFrame(by: -1)
                    } label: {
                        Image(systemName: "backward.frame")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Step Back 1s
                    Button {
                        let target = max(0, currentTime - 1.0)
                        currentTime = target
                        seekPlayers(to: target)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Main Play / Pause Button
                    Button(action: togglePlayPause) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 54, height: 54)
                                .shadow(color: Color.gold500.opacity(0.35), radius: 8, y: 3)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.obsidian900)
                                .offset(x: isPlaying ? 0 : 1.5)
                        }
                    }
                    
                    // Step Forward 1s
                    Button {
                        let target = min(duration, currentTime + 1.0)
                        currentTime = target
                        seekPlayers(to: target)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Step Forward 1 Frame (Funkcia 6)
                    Button {
                        stepFrame(by: 1)
                    } label: {
                        Image(systemName: "forward.frame")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Loop / Repeat Toggle
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            isLooping.toggle()
                        }
                    } label: {
                        Image(systemName: "repeat")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isLooping ? Color.gold400 : Color.white.opacity(0.45))
                            .padding(6)
                            .background(isLooping ? Color.gold400.opacity(0.15) : Color.clear)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Toggle Fine Offset Control Button
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            showOffsetFineControl.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.below.rectangle")
                            Text("Offset")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(showOffsetFineControl ? Color.yellow.opacity(0.25) : Color.obsidian800)
                        .foregroundColor(showOffsetFineControl ? Color.yellow : .white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showOffsetFineControl ? Color.yellow : Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
            }
            
            // Fine Offset Controller Sheet/Slider (Align Dancers Beats)
            if showOffsetFineControl && !isBothPhotos {
                VStack(spacing: 8) {
                    HStack {
                        Text("⏱️ Synchronizácia dôb (Offset Vzoru B):")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%+.2f s", offsetB))
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.gold400)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            offsetB = max(-3.0, offsetB - 0.1)
                            seekPlayers(to: currentTime)
                        } label: {
                            Text("-0.1s")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.obsidian800)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        Slider(value: $offsetB, in: -3.0...3.0, step: 0.05) { editing in
                            if !editing {
                                seekPlayers(to: currentTime)
                            }
                        }
                        .tint(.yellow)
                        
                        Button {
                            offsetB = min(3.0, offsetB + 0.1)
                            seekPlayers(to: currentTime)
                        } label: {
                            Text("+0.1s")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.obsidian800)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        Button("Reset") {
                            offsetB = 0.0
                            seekPlayers(to: currentTime)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                .padding(10)
                .background(Color.obsidian800)
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    // MARK: - Player Setup & Lifecycle
    private func setupPlayers() {
        tearDownPlayers()
        
        // Setup Slot A (Video or Photo)
        if let pathA = pathA {
            if MediaResolver.isImagePath(path: pathA) {
                self.imageA = MediaResolver.resolveImage(path: pathA)
                self.playerA = nil
            } else if let urlA = MediaResolver.resolveVideoURL(path: pathA) {
                self.imageA = nil
                let itemA = AVPlayerItem(url: urlA)
                let pA = AVPlayer(playerItem: itemA)
                self.playerA = pA
                
                // Loop A
                observerTokenA = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: itemA,
                    queue: OperationQueue.main
                ) { [weak pA] _ in
                    if isLooping {
                        pA?.seek(to: .zero)
                        pA?.play()
                    }
                }
            } else if let imgA = MediaResolver.resolveImage(path: pathA) {
                self.imageA = imgA
                self.playerA = nil
            }
        } else {
            self.imageA = nil
            self.playerA = nil
        }
        
        // Setup Slot B (Video or Photo)
        if let pathB = pathB {
            if MediaResolver.isImagePath(path: pathB) {
                self.imageB = MediaResolver.resolveImage(path: pathB)
                self.playerB = nil
            } else if let urlB = MediaResolver.resolveVideoURL(path: pathB) {
                self.imageB = nil
                let itemB = AVPlayerItem(url: urlB)
                let pB = AVPlayer(playerItem: itemB)
                self.playerB = pB
                
                // Loop B
                observerTokenB = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: itemB,
                    queue: OperationQueue.main
                ) { [weak pB] _ in
                    if isLooping {
                        pB?.seek(to: .zero)
                        pB?.play()
                    }
                }
            } else if let imgB = MediaResolver.resolveImage(path: pathB) {
                self.imageB = imgB
                self.playerB = nil
            }
        } else {
            self.imageB = nil
            self.playerB = nil
        }
        
        applyAudioVolumes()
        
        // Time observation from Player A (or B if A is nil)
        let observedPlayer = playerA ?? playerB
        if let p = observedPlayer {
            let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverTokenA = p.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { time in
                guard !isScrubbing else { return }
                self.currentTime = time.seconds
                
                if let dur = p.currentItem?.duration.seconds, !dur.isNaN && dur > 0 {
                    self.duration = dur
                }
            }
        }
        
        Task {
            try? await AudioSessionCoordinator.shared.activate(.player)
        }
    }
    
    private func tearDownPlayers() {
        if let token = observerTokenA {
            NotificationCenter.default.removeObserver(token)
            observerTokenA = nil
        }
        if let token = observerTokenB {
            NotificationCenter.default.removeObserver(token)
            observerTokenB = nil
        }
        if let token = timeObserverTokenA, let p = (playerA ?? playerB) {
            p.removeTimeObserver(token)
            timeObserverTokenA = nil
        }
        
        playerA?.pause()
        playerB?.pause()
        playerA = nil
        playerB = nil
        isPlaying = false
        
        Task {
            await AudioSessionCoordinator.shared.deactivate(.player)
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            playerA?.pause()
            playerB?.pause()
            isPlaying = false
        } else {
            // Activate audio session first
            Task {
                try? await AudioSessionCoordinator.shared.activate(.player)
                await MainActor.run {
                    seekPlayers(to: currentTime)
                    playerA?.play()
                    playerA?.rate = playbackRate
                    playerB?.play()
                    playerB?.rate = playbackRate
                    isPlaying = true
                }
            }
        }
    }
    
    private func seekPlayers(to time: Double) {
        let timeA = CMTime(seconds: max(0, time), preferredTimescale: 600)
        let timeB = CMTime(seconds: max(0, time + offsetB), preferredTimescale: 600)
        
        playerA?.seek(to: timeA, toleranceBefore: .zero, toleranceAfter: .zero)
        playerB?.seek(to: timeB, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func stepFrame(by count: Int) {
        if isPlaying {
            togglePlayPause()
        }
        let frameDuration = 1.0 / 30.0
        let target = max(0, min(duration, currentTime + Double(count) * frameDuration))
        currentTime = target
        seekPlayers(to: target)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
    
    private func applyAudioVolumes() {
        switch audioSource {
        case .slotA:
            playerA?.volume = 1.0
            playerB?.volume = 0.0
        case .slotB:
            playerA?.volume = 0.0
            playerB?.volume = 1.0
        case .mute:
            playerA?.volume = 0.0
            playerB?.volume = 0.0
        }
    }
    
    private func swapSlots() {
        let temp = pathA
        pathA = pathB
        pathB = temp
        setupPlayers()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Native AVPlayer Layer Representable
struct CustomAVPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}
