import SwiftUI
import UIKit

// MARK: - Vector Mirror Shapes (Derived from SVG viewBox 0 0 24 24)
// <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
//   <path d="M11 6L8 9m8-2l-8 8"/>
//   <rect width="16" height="20" x="4" y="2" rx="2"/>
// </g>

struct MirrorFrameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        let frameRect = CGRect(x: 4 * sx, y: 2 * sy, width: 16 * sx, height: 20 * sy)
        let cornerRadius = 2.0 * min(sx, sy)
        return Path(roundedRect: frameRect, cornerRadius: cornerRadius)
    }
}

struct MirrorGlintShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        
        // Line 1: M11 6 L8 9
        path.move(to: CGPoint(x: 11 * sx, y: 6 * sy))
        path.addLine(to: CGPoint(x: 8 * sx, y: 9 * sy))
        
        // Line 2: m8 -2 l-8 8 -> from (16, 7) to (8, 15)
        path.move(to: CGPoint(x: 16 * sx, y: 7 * sy))
        path.addLine(to: CGPoint(x: 8 * sx, y: 15 * sy))
        
        return path
    }
}

// MARK: - Animated Mirror Icon View (Vektorová SVG Ikona s Odleskom)
// 100% Vektorová ikona, bez pozadia, nekonečne ostrá na každom Retina displeji.
// Animuje sa IBA na hover alebo dotyk a to PRESNE JEDENKRÁT na danú akciu (svetelný lúč a odlesk).
struct AnimatedMirrorIconView: View {
    var size: CGFloat = 28
    var tintColor: Color = Color.gold400
    var triggerExternal: Bool = false
    var onTap: (() -> Void)? = nil
    
    @State private var isAnimating: Bool = false
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var iconScale: CGFloat = 1.0
    
    init(
        size: CGFloat = 28,
        tintColor: Color = Color.gold400,
        triggerExternal: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.size = size
        self.tintColor = tintColor
        self.triggerExternal = triggerExternal
        self.onTap = onTap
    }
    
    private var strokeWidth: CGFloat {
        max(1.5, (2.0 / 24.0) * size)
    }
    
    public var body: some View {
        ZStack {
            // 1. Jemné sklenené podfarbenie zrkadlovej plochy
            MirrorFrameShape()
                .fill(tintColor.opacity(0.12))
            
            // 2. Svetelný odlesk prechádzajúci cez zrkadlo (iba počas animácie)
            if isAnimating {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.85),
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: shimmerOffset * w, y: shimmerOffset * h * 0.5)
                }
                .clipShape(MirrorFrameShape())
            }
            
            // 3. Rám zrkadla (rect width="16" height="20" x="4" y="2" rx="2")
            MirrorFrameShape()
                .stroke(
                    tintColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
            
            // 4. Diagonálne odlesky zrkadla (path d="M11 6L8 9m8-2l-8 8")
            MirrorGlintShape()
                .stroke(
                    isAnimating ? Color.white : tintColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: isAnimating ? Color.white.opacity(0.9) : Color.clear, radius: 4)
        }
        .frame(width: size, height: size)
        .scaleEffect(iconScale)
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered {
                playOnce()
            }
        }
        .onTapGesture {
            playOnce()
            HapticFeedback.light()
            onTap?()
        }
        .onChange(of: triggerExternal) { _, shouldTrigger in
            if shouldTrigger {
                playOnce()
            }
        }
    }
    
    /// Spustí animáciu svetelného odlesku presne jedenkrát
    func playOnce() {
        guard !isAnimating else { return }
        isAnimating = true
        shimmerOffset = -1.5
        
        // 1. Jemný fyzikálny spring pulz
        withAnimation(.spring(response: 0.30, dampingFraction: 0.50)) {
            iconScale = 1.15
        }
        
        // 2. Prechod svetelného lúča cez sklo
        withAnimation(.easeInOut(duration: 0.65)) {
            shimmerOffset = 1.5
        }
        
        // 3. Návrat veľkosti do pokojového stavu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                iconScale = 1.0
            }
        }
        
        // 4. Dokončenie cyklu a reset do pokojového stavu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            isAnimating = false
            shimmerOffset = -1.5
        }
    }
}
