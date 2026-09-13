import SwiftUI

// MARK: - Radial Hub Action Definition
public enum RadialHubAction: String, CaseIterable, Identifiable {
    case newRoutine
    case mirror
    case organizer
    case speedTrainer
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .newRoutine:    return "Nová zostava"
        case .mirror:        return "Zrkadlo"
        case .organizer:     return "Organizér kôl"
        case .speedTrainer:  return "Speed Trainer"
        }
    }
    
    public var shortTitle: String {
        switch self {
        case .newRoutine:    return "Nová zostava"
        case .mirror:        return "Zrkadlo"
        case .organizer:     return "Organizér"
        case .speedTrainer:  return "Tempo"
        }
    }
    
    public var iconName: String {
        switch self {
        case .newRoutine:    return "plus.circle.fill"
        case .mirror:        return "sparkles.rectangle.stack.fill"
        case .organizer:     return "trophy.fill"
        case .speedTrainer:  return "metronome.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .newRoutine:    return Color.gold400
        case .mirror:        return Color.silkIvory
        case .organizer:     return Color.amberGold
        case .speedTrainer:  return Color.standardBlue
        }
    }
    
    // Relative offset from logo center (radius ~114pt)
    // Angles: Top-Left (-135°), Top-Right (-45°), Bottom-Left (135°), Bottom-Right (45°)
    public var offset: CGSize {
        switch self {
        case .newRoutine:    return CGSize(width: -86, height: -82)
        case .mirror:        return CGSize(width: 86,  height: -82)
        case .organizer:     return CGSize(width: -86, height: 82)
        case .speedTrainer:  return CGSize(width: 86,  height: 82)
        }
    }
}

// MARK: - Encore Pure Gold 3D Emblem View (Seamless, Specular Sheen, Shockwave & 3D Gyro Tilt)
/// High-end native 60/120 FPS pure gold emblem:
/// - 100% unified, intact silhouette (NO awkward scissors cut or slicing!)
/// - Resonant golden shockwaves & radiant aura that erupt when opened
/// - Specular metallic gold light glint (sheen beam) that slides across the emblem
/// - Smooth 3D pirouette twist around Y-axis
/// - Gyroscopic 3D pitch & yaw that dynamically leans towards the user's finger during drag
public struct EncoreGoldenEmblemView: View {
    let size: CGFloat
    let spinDegrees: Double       // 3D pirouette rotation (Y axis)
    let pitchDegrees: Double      // 3D gyroscopic tilt (X axis - following finger)
    let yawDegrees: Double        // 3D gyroscopic tilt (Y axis - following finger)
    let sheenProgress: CGFloat    // Position of metallic light glint across logo (-0.5 to 1.5)
    let shockwaveProgress: CGFloat // Expanding golden energy ring (0.0 to 1.0)
    let glowIntensity: Double     // Burst flash intensity
    let scale: CGFloat
    let offset: CGSize
    
    public init(
        size: CGFloat,
        spinDegrees: Double = 0.0,
        pitchDegrees: Double = 0.0,
        yawDegrees: Double = 0.0,
        sheenProgress: CGFloat = -0.5,
        shockwaveProgress: CGFloat = 0.0,
        glowIntensity: Double = 0.0,
        scale: CGFloat = 1.0,
        offset: CGSize = .zero
    ) {
        self.size = size
        self.spinDegrees = spinDegrees
        self.pitchDegrees = pitchDegrees
        self.yawDegrees = yawDegrees
        self.sheenProgress = sheenProgress
        self.shockwaveProgress = shockwaveProgress
        self.glowIntensity = glowIntensity
        self.scale = scale
        self.offset = offset
    }
    
    public var body: some View {
        ZStack {
            // ── 1. Resonant Golden Shockwave Rings (Burst Outwards Behind Logo) ──
            if shockwaveProgress > 0.02 && shockwaveProgress < 0.99 {
                // Outer expanding ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gold300.opacity(0.85), Color.gold500.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1.0, 3.5 * (1.0 - shockwaveProgress))
                    )
                    .frame(
                        width: size * (0.8 + shockwaveProgress * 1.35),
                        height: size * (0.8 + shockwaveProgress * 1.35)
                    )
                    .opacity(Double(1.0 - shockwaveProgress) * 0.75)
                    .blur(radius: 1.5)
                
                // Inner golden energy ripple
                Circle()
                    .stroke(Color.gold400.opacity(Double(1.0 - shockwaveProgress) * 0.5), lineWidth: 1.5)
                    .frame(
                        width: size * (0.5 + shockwaveProgress * 0.9),
                        height: size * (0.5 + shockwaveProgress * 0.9)
                    )
                    .opacity(Double(1.0 - shockwaveProgress) * 0.6)
            }
            
            // ── 2. Ambient Gold Core Halo ──
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.gold400.opacity(0.25 + glowIntensity * 0.40),
                            Color.gold500.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: size * 0.75
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(1.0 + CGFloat(glowIntensity * 0.3))
            
            // ── 3. Pristine Pure Gold Emblem (100% Intact Silhouette - No Broken Scissors Cut!) ──
            Image("EncoreLogo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(
                    color: Color.gold400.opacity(0.35 + glowIntensity * 0.45),
                    radius: 10 + CGFloat(glowIntensity * 12),
                    x: 0,
                    y: 2
                )
            
            // ── 4. Specular Liquid Gold Sheen Beam (Light glint traversing the logo) ──
            if sheenProgress > -0.4 && sheenProgress < 1.4 {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.gold300.opacity(0.40), location: 0.35),
                        .init(color: Color.white.opacity(0.95), location: 0.50),
                        .init(color: Color.gold300.opacity(0.40), location: 0.65),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: size * 0.60, height: size * 1.6)
                .rotationEffect(.degrees(25))
                .offset(x: (sheenProgress - 0.5) * (size * 2.0))
                .mask(
                    Image("EncoreLogo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: size, height: size)
                )
                .blendMode(.screen)
            }
            
            // ── 5. Golden Flash Burst on Rejoin / Button Snap ──
            if glowIntensity > 0.01 {
                Image("EncoreLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color.gold300)
                    .frame(width: size, height: size)
                    .blur(radius: 5)
                    .opacity(glowIntensity)
                    .blendMode(.screen)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .offset(offset)
        // 3D Pirouette & Gyroscopic Lean (Tilts towards dragging finger!)
        .rotation3DEffect(
            .degrees(spinDegrees + yawDegrees),
            axis: (x: 0.0, y: 1.0, z: 0.04),
            perspective: 0.35
        )
        .rotation3DEffect(
            .degrees(pitchDegrees),
            axis: (x: 1.0, y: 0.0, z: 0.0),
            perspective: 0.35
        )
        // High-end metallic obsidian drop shadow
        .shadow(color: Color.black.opacity(0.65), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Compatibility Bridge
public struct DancePairSplitLogoView: View {
    let size: CGFloat
    let splitProgress: CGFloat
    let spinDegrees: Double
    let glowIntensity: Double
    let scale: CGFloat
    let offset: CGSize
    
    public init(
        size: CGFloat,
        splitProgress: CGFloat = 0.0,
        spinDegrees: Double = 0.0,
        glowIntensity: Double = 0.0,
        scale: CGFloat = 1.0,
        offset: CGSize = .zero
    ) {
        self.size = size
        self.splitProgress = splitProgress
        self.spinDegrees = spinDegrees
        self.glowIntensity = glowIntensity
        self.scale = scale
        self.offset = offset
    }
    
    public var body: some View {
        EncoreGoldenEmblemView(
            size: size,
            spinDegrees: spinDegrees,
            glowIntensity: glowIntensity,
            scale: scale,
            offset: offset
        )
    }
}

// MARK: - Frame Sequence Player (For Flipbook / Spritesheet Animations)
/// If you have a sequence of exported PNG frames (e.g. from Rive, Blender or After Effects),
/// this player cycles through them smoothly at 60 FPS.
public struct EncoreFrameSequencePlayer: View {
    let frameNames: [String]
    let fps: Double
    let isPlaying: Bool
    
    @State private var currentFrameIndex: Int = 0
    
    public init(frameNames: [String], fps: Double = 30.0, isPlaying: Bool = true) {
        self.frameNames = frameNames
        self.fps = fps
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        Group {
            if currentFrameIndex < frameNames.count {
                Image(frameNames[currentFrameIndex])
                    .resizable()
                    .scaledToFit()
            } else if let first = frameNames.first {
                Image(first)
                    .resizable()
                    .scaledToFit()
            }
        }
        .task(id: isPlaying) {
            guard isPlaying, !frameNames.isEmpty else { return }
            let interval = UInt64((1.0 / max(fps, 1.0)) * 1_000_000_000)
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(nanoseconds: interval)
                currentFrameIndex = (currentFrameIndex + 1) % frameNames.count
            }
        }
    }
}

// MARK: - Interactive Encore Radial Hub View (Pure Gold + Dance Pirouette & Split Animation)
public struct EncoreRadialHubView: View {
    @Binding var isOpen: Bool
    var logoSize: CGFloat
    var onSelectAction: (RadialHubAction) -> Void
    var onTogglePaletteFallback: () -> Void
    
    // ── 3D Emblem Animation & Gyroscopic States ──
    @State private var spinDegrees: Double = 0.0       // 3D pirouette rotation (Y axis)
    @State private var pitchDegrees: Double = 0.0      // 3D gyroscopic tilt (X axis)
    @State private var yawDegrees: Double = 0.0        // 3D gyroscopic tilt (Y axis)
    @State private var sheenProgress: CGFloat = -0.5   // Specular gold light glint sweep
    @State private var shockwaveProgress: CGFloat = 0.0 // Concentric golden halo shockwaves
    @State private var glowBurst: Double = 0.0         // Flash on snap
    @State private var goldScale: CGFloat = 1.0
    @State private var goldOffset: CGSize = .zero
    @State private var isSpinning: Bool = false
    
    // ── Gesture & Drag-to-Select States ──
    @State private var hoveredAction: RadialHubAction? = nil
    @State private var triggeringAction: RadialHubAction? = nil
    @State private var isDragging: Bool = false
    
    public init(
        isOpen: Binding<Bool>,
        logoSize: CGFloat = 110,
        onSelectAction: @escaping (RadialHubAction) -> Void,
        onTogglePaletteFallback: @escaping () -> Void = {}
    ) {
        self._isOpen = isOpen
        self.logoSize = logoSize
        self.onSelectAction = onSelectAction
        self.onTogglePaletteFallback = onTogglePaletteFallback
    }
    
    public var body: some View {
        ZStack {
            // ── 4 Radial Satellite Action Buttons (Erupt out on Open) ──
            if isOpen {
                ForEach(RadialHubAction.allCases) { action in
                    satelliteButton(for: action)
                        .offset(actionOffset(for: action))
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.15)
                                    .combined(with: .opacity)
                                    .combined(with: .offset(x: -action.offset.width * 0.75, y: -action.offset.height * 0.75)),
                                removal: .scale(scale: 0.20)
                                    .combined(with: .opacity)
                            )
                        )
                }
            }
            
            // ── Central Pure Gold Logo (Seamless 3D Emblem, Sheen Glint, Halo Shockwaves & Gyro Tilt) ──
            centerPureGoldButton
        }
        .frame(width: max(logoSize + 195, 310), height: max(logoSize + 185, 300))
        .contentShape(Rectangle())
        .animation(.spring(response: 0.32, dampingFraction: 0.70), value: isOpen)
        .animation(.spring(response: 0.20, dampingFraction: 0.68), value: hoveredAction)
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: goldScale)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: goldOffset)
        .onChange(of: isOpen) { _, newValue in
            if !newValue {
                hoveredAction = nil
                triggeringAction = nil
                withAnimation(.spring(response: 0.26, dampingFraction: 0.75)) {
                    goldScale = 1.0
                    goldOffset = .zero
                    pitchDegrees = 0.0
                    yawDegrees = 0.0
                    spinDegrees = 0.0
                    glowBurst = 0.0
                    sheenProgress = -0.5
                    shockwaveProgress = 0.0
                }
            }
        }
    }
    
    // MARK: - Center Pure Gold Logo Button (NO CIRCLES - ONLY THE GOLD PART)
    private var centerPureGoldButton: some View {
        VStack(spacing: 8) {
            // 🌟 PURE GOLD EMBLEM WITH 3D PIROUETTE, SPECULAR SHEEN & GYRO TILT
            EncoreGoldenEmblemView(
                size: logoSize * 0.88,
                spinDegrees: spinDegrees,
                pitchDegrees: pitchDegrees,
                yawDegrees: yawDegrees,
                sheenProgress: sheenProgress,
                shockwaveProgress: shockwaveProgress,
                glowIntensity: glowBurst,
                scale: goldScale,
                offset: goldOffset
            )
            
            // Steady Brand Title
            HStack(spacing: 4) {
                Text("ENCORE")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2.6)
                
                Image(systemName: isOpen ? "xmark" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.gold400.opacity(0.85))
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
            }
            .opacity(isOpen ? 0.95 : 0.75)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
    }
    
    // MARK: - Dynamic Magnetic Offset for Buttons
    private func actionOffset(for action: RadialHubAction) -> CGSize {
        var base = action.offset
        // Magnetic pull when hovered
        if hoveredAction == action {
            base.width += (base.width > 0 ? -4 : 4)
            base.height += (base.height > 0 ? -4 : 4)
        }
        return base
    }
    
    // MARK: - Satellite Button Component
    private func satelliteButton(for action: RadialHubAction) -> some View {
        let isHovered = hoveredAction == action
        let isAnyHovered = hoveredAction != nil
        let isTriggering = triggeringAction == action
        
        let scale: CGFloat = isTriggering ? 0.88 : (isHovered ? 1.28 : (isAnyHovered ? 0.92 : 1.0))
        let opacity: Double = isHovered ? 1.0 : (isAnyHovered ? 0.50 : 1.0)
        
        return Button {
            executeAction(action)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Outer aura glow on hover
                    if isHovered {
                        Circle()
                            .fill(action.accentColor.opacity(0.55))
                            .frame(width: 72, height: 72)
                            .blur(radius: 10)
                    }
                    
                    // Liquid Glass Circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isHovered
                                    ? [action.accentColor.opacity(0.40), Color.obsidian700.opacity(0.95)]
                                    : [Color.obsidian700.opacity(0.88), Color.obsidian900.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: isHovered
                                            ? [Color.white, action.accentColor, Color.gold400]
                                            : [Color.gold400.opacity(0.50), Color.gold500.opacity(0.20)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isHovered ? 2.2 : 1.3
                                )
                        )
                        .shadow(
                            color: isHovered ? action.accentColor.opacity(0.80) : Color.black.opacity(0.50),
                            radius: isHovered ? 16 : 6,
                            x: 0,
                            y: 3
                        )
                    
                    // Icon
                    Image(systemName: action.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            isHovered
                                ? LinearGradient(colors: [.white, action.accentColor], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [action.accentColor, action.accentColor.opacity(0.90)], startPoint: .top, endPoint: .bottom)
                        )
                }
                
                // Mini Badge Label
                Text(action.shortTitle)
                    .font(.system(size: 11, weight: isHovered ? .black : .semibold, design: .rounded))
                    .foregroundColor(isHovered ? .white : Color.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        Capsule()
                            .fill(isHovered ? Color.obsidian800.opacity(0.95) : Color.obsidian900.opacity(0.80))
                            .overlay(
                                Capsule()
                                    .stroke(isHovered ? action.accentColor.opacity(0.60) : Color.white.opacity(0.12), lineWidth: 0.9)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 3)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.spring(response: 0.20, dampingFraction: 0.68), value: scale)
            .animation(.easeInOut(duration: 0.18), value: opacity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 60/120 FPS Dance Pirouette, Sheen Glint & Shockwave Trigger
    private func triggerDancePirouetteAndSplit(openOnFinish: Bool, onComplete: (() -> Void)? = nil) {
        guard !isSpinning else { return }
        isSpinning = true
        
        // Haptic feedback start
        HapticFeedback.light()
        
        // Reset sheen & shockwaves for launch
        sheenProgress = -0.4
        shockwaveProgress = 0.0
        
        // Phase 1 (0ms -> 130ms): Anticipation squash + start 3D spin + light glint begins
        withAnimation(.spring(response: 0.15, dampingFraction: 0.58)) {
            goldScale = 0.86
            spinDegrees = 180.0  // Polovica otočky
            sheenProgress = 0.50 // Odlesk prechádza stredom loga
            shockwaveProgress = 0.40
        }
        
        // Phase 2 (130ms -> 320ms): Elastic spring overshoot + complete 360° spin + shockwaves burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.60)) {
                spinDegrees = 360.0  // Dokončenie celej 360° piruety
                goldScale = 1.15     // Pružinový odraz pri otvorení satelitov
                sheenProgress = 1.35 // Odlesk opúšťa logo
                shockwaveProgress = 1.0 // Zlatá vlna vystrelí do satelitov
            }
            
            // Phase 3 (300ms): Snap fusion burst + haptic punch + satellite eruption
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
                
                withAnimation(.easeOut(duration: 0.22)) {
                    glowBurst = 0.90
                }
                
                withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                    goldScale = 1.0
                    if openOnFinish {
                        isOpen = true
                    } else {
                        isOpen = false
                    }
                }
                
                // Fade glow burst smoothly & reset rotation cleanly for next trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        glowBurst = 0.0
                    }
                    spinDegrees = 0.0
                    sheenProgress = -0.5
                    shockwaveProgress = 0.0
                    isSpinning = false
                    onComplete?()
                }
            }
        }
    }
    
    // MARK: - Drag Gesture Tracking & 3D Gyro Hit Testing
    private func handleDragChanged(_ value: DragGesture.Value) {
        let translation = value.translation
        let distance = hypot(translation.width, translation.height)
        
        // 1. Initial touch down: trigger dance pirouette & sheen glint!
        if !isDragging {
            isDragging = true
            if !isOpen {
                triggerDancePirouetteAndSplit(openOnFinish: true)
            } else {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.60)) {
                    goldScale = 0.90
                }
            }
        }
        
        // 2. 3D Gyroscopic Lean & Magnetic Tether: The logo physically tilts towards finger
        if isDragging {
            let maxPull: CGFloat = 12.0
            let pullX = max(-maxPull, min(maxPull, translation.width * 0.10))
            let pullY = max(-maxPull, min(maxPull, translation.height * 0.10))
            goldOffset = CGSize(width: pullX, height: pullY)
            
            // 3D pitch (tilt up/down) & yaw (tilt left/right)
            let targetPitch = max(-16.0, min(16.0, Double(-translation.height * 0.13)))
            let targetYaw = max(-18.0, min(18.0, Double(translation.width * 0.13)))
            withAnimation(.spring(response: 0.16, dampingFraction: 0.70)) {
                pitchDegrees = targetPitch
                yawDegrees = targetYaw
            }
        }
        
        // 3. Swipe-to-select: Detect direction and quadrant as user swipes towards buttons
        if isOpen && distance > 32 {
            let target = resolveTargetAction(translation: translation, distance: distance)
            if hoveredAction != target {
                hoveredAction = target
                if target != nil {
                    HapticFeedback.light()
                }
            }
        } else if distance <= 32 {
            hoveredAction = nil
        }
    }
    
    // MARK: - Directional Quadrant & Proximity Resolver
    private func resolveTargetAction(translation: CGSize, distance: CGFloat) -> RadialHubAction? {
        let dx = translation.width
        let dy = translation.height
        
        // Quadrant mapping:
        // Top-Left: -180° to -90° -> newRoutine
        // Top-Right: -90° to 0°   -> mirror
        // Bottom-Left: 90° to 180° -> organizer
        // Bottom-Right: 0° to 90°  -> speedTrainer
        if distance >= 34 && distance <= 220 {
            if dx < 0 && dy < 0 {
                return .newRoutine
            } else if dx >= 0 && dy < 0 {
                return .mirror
            } else if dx < 0 && dy >= 0 {
                return .organizer
            } else {
                return .speedTrainer
            }
        }
        return nil
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation
        let distance = hypot(translation.width, translation.height)
        isDragging = false
        
        withAnimation(.spring(response: 0.22, dampingFraction: 0.70)) {
            pitchDegrees = 0.0
            yawDegrees = 0.0
        }
        
        // A. User swiped and released directly onto a button ("ked pustim tak sa akokeby stlacia")
        if let selected = hoveredAction {
            executeAction(selected)
            return
        }
        
        // B. Quick tap on the center logo without swiping (< 18pt)
        if distance < 18 {
            if isOpen {
                // Trigger quick closure twist
                withAnimation(.spring(response: 0.24, dampingFraction: 0.75)) {
                    isOpen = false
                    goldScale = 1.0
                    goldOffset = .zero
                }
                HapticFeedback.light()
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.70)) {
                    goldScale = 1.0
                    goldOffset = .zero
                }
            }
            return
        }
        
        // C. Swiped into empty void or cancelled -> smoothly retract
        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
            isOpen = false
            goldScale = 1.0
            goldOffset = .zero
            hoveredAction = nil
        }
        HapticFeedback.light()
    }
    
    // MARK: - Execute Click Action ("a tým na nich kliknúť")
    private func executeAction(_ action: RadialHubAction) {
        triggeringAction = action
        HapticFeedback.notify(.success)
        
        // 60FPS Click pop animation on button & gold snap
        withAnimation(.spring(response: 0.12, dampingFraction: 0.55)) {
            goldScale = 0.94
            goldOffset = .zero
            glowBurst = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                isOpen = false
                goldScale = 1.0
                goldOffset = .zero
                pitchDegrees = 0.0
                yawDegrees = 0.0
                glowBurst = 0.0
                hoveredAction = nil
                triggeringAction = nil
            }
            onSelectAction(action)
        }
    }
}
