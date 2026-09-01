import SwiftUI
import AVFoundation
import AVKit

// MARK: - Live Audio VU Meter (Funkcia 7)
struct CameraVUMeterView: View {
    let audioLevel: Float // 0.0 to 1.0
    
    var body: some View {
        HStack(spacing: 2.5) {
            Image(systemName: "mic.fill")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.75))
                .padding(.trailing, 2)
            
            ForEach(0..<8, id: \.self) { idx in
                let threshold = Float(idx) / 8.0
                Rectangle()
                    .fill(barColor(for: idx, isActive: audioLevel > threshold))
                    .frame(width: 3, height: 9 + CGFloat(idx))
                    .cornerRadius(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.65))
        .cornerRadius(14)
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
    
    private func barColor(for index: Int, isActive: Bool) -> Color {
        guard isActive else { return Color.white.opacity(0.18) }
        if index < 5 {
            return Color.green
        } else if index < 7 {
            return Color.amberGold
        } else {
            return Color.red
        }
    }
}

// MARK: - Grid & Gyroscope Level Overlay (Apple Camera & Measure Style)
struct CameraGridAndLevelOverlay: View {
    let tiltAngle: Double // in degrees
    let isLevel: Bool
    let isFlat: Bool
    let flatOffset: CGPoint
    
    var body: some View {
        ZStack {
            // 3x3 Composition Grid
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                Path { path in
                    // Vertical lines
                    path.move(to: CGPoint(x: w / 3, y: 0))
                    path.addLine(to: CGPoint(x: w / 3, y: h))
                    path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                    path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                    
                    // Horizontal lines
                    path.move(to: CGPoint(x: 0, y: h / 3))
                    path.addLine(to: CGPoint(x: w, y: h / 3))
                    path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                    path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
                }
                .stroke(Color.white.opacity(0.20), lineWidth: 0.75)
            }
            
            // Apple-Style Center Horizon Level
            if !isFlat {
                ZStack {
                    // Fixed Reference Reticle (Notches on Left and Right)
                    HStack(spacing: 50) {
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 24, height: 1.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 24, height: 1.5)
                    }
                    
                    // Dynamic Rotating Horizon Line
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(isLevel ? Color.amberGold : Color.white.opacity(0.9))
                            .frame(width: 36, height: isLevel ? 2.5 : 1.5)
                        
                        Circle()
                            .fill(isLevel ? Color.amberGold : Color.white.opacity(0.9))
                            .frame(width: isLevel ? 6 : 4, height: isLevel ? 6 : 4)
                        
                        Rectangle()
                            .fill(isLevel ? Color.amberGold : Color.white.opacity(0.9))
                            .frame(width: 36, height: isLevel ? 2.5 : 1.5)
                    }
                    .rotationEffect(.degrees(-tiltAngle))
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.85), value: tiltAngle)
                    
                    // Angle Badge Readout (e.g. 0° / 1.5°)
                    VStack {
                        Spacer()
                            .frame(height: 52)
                        
                        Text(isLevel ? "0°" : String(format: "%+.1f°", -tiltAngle))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isLevel ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isLevel ? Color.amberGold : Color.black.opacity(0.6))
                            .cornerRadius(6)
                            .animation(.easeInOut(duration: 0.2), value: isLevel)
                    }
                }
            } else {
                // Flat Table / Bullseye Measure Mode
                ZStack {
                    // Outer fixed ring
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 46, height: 46)
                    
                    // Center crosshair
                    Path { p in
                        p.move(to: CGPoint(x: 23, y: 17))
                        p.addLine(to: CGPoint(x: 23, y: 29))
                        p.move(to: CGPoint(x: 17, y: 23))
                        p.addLine(to: CGPoint(x: 29, y: 23))
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    .frame(width: 46, height: 46)
                    
                    // Inner floating bubble
                    Circle()
                        .fill(isLevel ? Color.amberGold : Color.white.opacity(0.85))
                        .frame(width: 14, height: 14)
                        .offset(x: flatOffset.x, y: flatOffset.y)
                        .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.85), value: flatOffset)
                }
            }
        }
    }
}

// MARK: - Quick Save Details & Tagging Sheet (Funkcia 10 & 8)
struct QuickSaveVideoSheet: View {
    let videoURL: URL
    let onTrimRequest: () -> Void
    let onSaveCompleted: (URL) -> Void
    
    @State private var selectedRole: VideoMediaRole = .myTake
    @State private var selectedTags: Set<String> = []
    @State private var videoTitle: String = "Záznam z tréningu"
    
    let availableTags = ["🦶 Chodidlá", "💃 Postúra & Rám", "🔄 Rotácia", "⏱️ Rytmus & Timing", "👔 Trénerov komentár", "⭐ Najlepší pokus"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Quick Trim Action Bar (Funkcia 8)
                        Button {
                            onTrimRequest()
                        } label: {
                            HStack {
                                Image(systemName: "scissors")
                                    .font(.system(size: 16, weight: .bold))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Orezať začiatok a koniec")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Odstrániť príchod k partnerke a odchod")
                                        .font(.system(size: 11))
                                        .foregroundColor(.themeTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.themeTextSecondary)
                            }
                            .padding(14)
                            .background(Color.white)
                            .neubrutalistCard(cornerRadius: 14, shadowOffset: 2)
                        }
                        .buttonStyle(.plain)
                        
                        // Role Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ROLA ZÁZNAMU")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            
                            HStack(spacing: 8) {
                                roleButton(role: .myTake, title: "Moje video", icon: "person.fill", color: .latinRed)
                                roleButton(role: .targetIdol, title: "Vzor / Idol", icon: "star.fill", color: .themeAccent)
                                roleButton(role: .coach, title: "Tréner", icon: "figure.walk", color: .standardBlue)
                            }
                        }
                        
                        // Quick Tag Chips (Funkcia 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RÝCHLE ŠTÍTKY")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(availableTags, id: \.self) { tag in
                                    Button {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    } label: {
                                        Text(tag)
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(selectedTags.contains(tag) ? Color.themeAccent : Color.white)
                                            .foregroundColor(selectedTags.contains(tag) ? .white : .themeDark)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.themeBorder, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Title Input
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NÁZOV")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            
                            TextField("Zadaj názov videa...", text: $videoTitle)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeBorder, lineWidth: 1.5)
                                )
                        }
                        
                        // Save Button
                        Button {
                            onSaveCompleted(videoURL)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Uložiť do inventára")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                        }
                        .buttonStyle(.neubrutalist(accentColor: Color.themeAccent, cornerRadius: 16))
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Detaily nového videa")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func roleButton(role: VideoMediaRole, title: String, icon: String, color: Color) -> some View {
        Button {
            selectedRole = role
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(selectedRole == role ? .white : .themeDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedRole == role ? color : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.themeBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout Helper for Tag Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowMaxH: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowMaxH + spacing
                rowMaxH = 0
            }
            currentX += size.width + spacing
            rowMaxH = max(rowMaxH, size.height)
        }
        height = currentY + rowMaxH
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowMaxH: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowMaxH + spacing
                rowMaxH = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowMaxH = max(rowMaxH, size.height)
        }
    }
}

// MARK: - AVCapture Video Preview Layer Representable
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Ghost Video Layer Representable
struct GhostPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

typealias GhostVideoPlayerView = GhostPlayerRepresentable

