import SwiftUI
import AVFoundation

// MARK: - Posture Analysis Tool Mode
enum PostureToolMode: String, CaseIterable, Identifiable {
    case spineSway = "Sway & Chrbtica"
    case shoulderFrame = "Rám & Lakte"
    case threePointAngle = "Uhol 3 Bodov"
    case freeLine = "Voľná línia"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .spineSway: return "figure.walk"
        case .shoulderFrame: return "arrow.left.and.right"
        case .threePointAngle: return "angle"
        case .freeLine: return "pencil.line"
        }
    }
}

// MARK: - Posture Mark Model
struct PostureMark: Identifiable {
    let id = UUID()
    var start: CGPoint
    var end: CGPoint
    var mid: CGPoint? = nil // For 3-point angle
    var tool: PostureToolMode
    var color: Color
    
    var angleDegrees: Double {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let radians = atan2(dy, dx)
        let degrees = radians * (180.0 / .pi)
        
        switch tool {
        case .spineSway:
            // Angle relative to vertical (90 deg is straight up/down)
            let sway = abs(abs(degrees) - 90.0)
            return sway
        case .shoulderFrame:
            // Angle relative to horizontal (0 deg is level)
            return abs(degrees)
        case .threePointAngle:
            guard let m = mid else { return abs(degrees) }
            let v1 = CGPoint(x: start.x - m.x, y: start.y - m.y)
            let v2 = CGPoint(x: end.x - m.x, y: end.y - m.y)
            let dot = v1.x * v2.x + v1.y * v2.y
            let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
            let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
            guard mag1 > 0 && mag2 > 0 else { return 0 }
            let cosAngle = max(-1.0, min(1.0, dot / (mag1 * mag2)))
            return acos(cosAngle) * (180.0 / .pi)
        case .freeLine:
            return abs(degrees)
        }
    }
    
    var label: String {
        switch tool {
        case .spineSway:
            return String(format: "%.1f° Sway", angleDegrees)
        case .shoulderFrame:
            return String(format: "%.1f° Sklon", angleDegrees)
        case .threePointAngle:
            return String(format: "%.1f° Uhol", angleDegrees)
        case .freeLine:
            return String(format: "%.1f°", angleDegrees)
        }
    }
}

// MARK: - PostureAnalysisOverlayView
struct PostureAnalysisOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    let videoURL: URL?
    let freezeTime: Double
    var onSaveAnalysisSnapshot: ((UIImage) -> Void)? = nil
    
    @State private var selectedTool: PostureToolMode = .spineSway
    @State private var selectedColor: Color = .yellow
    @State private var marks: [PostureMark] = []
    
    // Drag drawing state
    @State private var currentStart: CGPoint? = nil
    @State private var currentEnd: CGPoint? = nil
    @State private var currentMid: CGPoint? = nil
    
    @State private var frameImage: UIImage? = nil
    @State private var isLoadingFrame: Bool = true
    @State private var showSavedNotification: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. Frozen Video Frame Image
                if let img = frameImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            drawingCanvasOverlay
                        )
                } else if isLoadingFrame {
                    ProgressView("Načítavam snímku...")
                        .tint(.yellow)
                        .foregroundColor(.white)
                } else {
                    Text("Snímku sa nepodarilo načítať.")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // 2. Saved Toast Notification
                if showSavedNotification {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Analýza postúry uložená!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .padding(.top, 16)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 3. Bottom Tool Selector Deck
                VStack {
                    Spacer()
                    bottomToolsDeck
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Analýza držania tela")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zavrieť") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        captureAndSaveSnapshot()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Uložiť")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                    }
                    .disabled(marks.isEmpty && frameImage == nil)
                }
            }
        }
        .onAppear {
            extractFrameImage()
        }
    }
    
    // MARK: - Drawing Canvas Overlay
    private var drawingCanvasOverlay: some View {
        GeometryReader { geo in
            ZStack {
                // Plumb Reference Line (Center Vertical Dashed Guide)
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                    p.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                // Render Existing Marks
                ForEach(marks) { mark in
                    renderMark(mark: mark)
                }
                
                // Render Currently Active Dragging Mark
                if let s = currentStart, let e = currentEnd {
                    renderMark(mark: PostureMark(start: s, end: e, mid: currentMid, tool: selectedTool, color: selectedColor))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { val in
                        if currentStart == nil {
                            currentStart = val.startLocation
                        }
                        currentEnd = val.location
                    }
                    .onEnded { val in
                        if let s = currentStart {
                            let newMark = PostureMark(start: s, end: val.location, mid: currentMid, tool: selectedTool, color: selectedColor)
                            marks.append(newMark)
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }
                        currentStart = nil
                        currentEnd = nil
                        currentMid = nil
                    }
            )
        }
    }
    
    // MARK: - Render Individual Mark with Angle Badge
    private func renderMark(mark: PostureMark) -> some View {
        ZStack {
            // Main Line
            Path { p in
                p.move(to: mark.start)
                p.addLine(to: mark.end)
            }
            .stroke(mark.color, lineWidth: 3)
            
            // End Endpoint Circles
            Circle()
                .fill(mark.color)
                .frame(width: 8, height: 8)
                .position(mark.start)
            
            Circle()
                .fill(mark.color)
                .frame(width: 8, height: 8)
                .position(mark.end)
            
            // Floating Angle Badge Label
            let midX = (mark.start.x + mark.end.x) / 2
            let midY = (mark.start.y + mark.end.y) / 2
            
            HStack(spacing: 4) {
                Image(systemName: mark.tool.icon)
                    .font(.system(size: 9, weight: .black))
                Text(mark.label)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.85))
            .foregroundColor(mark.color)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(mark.color, lineWidth: 1)
            )
            .position(x: midX, y: midY - 18)
        }
    }
    
    // MARK: - Bottom Tools Deck
    private var bottomToolsDeck: some View {
        VStack(spacing: 12) {
            // Color Selector
            HStack(spacing: 12) {
                ForEach([Color.yellow, Color.red, Color.green, Color.cyan, Color.white], id: \.self) { c in
                    Circle()
                        .fill(c)
                        .frame(width: selectedColor == c ? 26 : 20, height: selectedColor == c ? 26 : 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColor == c ? 2 : 0)
                        )
                        .onTapGesture {
                            selectedColor = c
                        }
                }
                
                Spacer()
                
                // Clear All Lines Button
                if !marks.isEmpty {
                    Button(action: { marks.removeAll() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Vymazať línie")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Tool Mode Selector
            HStack(spacing: 8) {
                ForEach(PostureToolMode.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 15, weight: .bold))
                            Text(tool.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedTool == tool ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTool == tool ? Color.yellow : Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTool == tool ? Color.yellow : Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.75))
        .cornerRadius(18)
    }
    
    // MARK: - Extract Video Frame
    private func extractFrameImage() {
        guard let url = videoURL else {
            isLoadingFrame = false
            return
        }
        
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 720)
        
        let cmTime = CMTime(seconds: freezeTime, preferredTimescale: 600)
        
        Task {
            if let result = try? await generator.image(at: cmTime) {
                let img = UIImage(cgImage: result.image)
                await MainActor.run {
                    self.frameImage = img
                    self.isLoadingFrame = false
                }
            } else {
                await MainActor.run {
                    self.isLoadingFrame = false
                }
            }
        }
    }
    
    // MARK: - Capture & Save Snapshot
    private func captureAndSaveSnapshot() {
        guard let base = frameImage else { return }
        
        let renderer = UIGraphicsImageRenderer(size: base.size)
        let finalImg = renderer.image { ctx in
            base.draw(at: .zero)
            
            let cgContext = ctx.cgContext
            cgContext.setLineWidth(4.0)
            cgContext.setStrokeColor(UIColor.yellow.cgColor)
            
            for mark in marks {
                let s = CGPoint(x: mark.start.x, y: mark.start.y)
                let e = CGPoint(x: mark.end.x, y: mark.end.y)
                
                cgContext.move(to: s)
                cgContext.addLine(to: e)
                cgContext.strokePath()
            }
        }
        
        UIImageWriteToSavedPhotosAlbum(finalImg, nil, nil, nil)
        onSaveAnalysisSnapshot?(finalImg)
        
        withAnimation {
            showSavedNotification = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSavedNotification = false
        }
    }
}
