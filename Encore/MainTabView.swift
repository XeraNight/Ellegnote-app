import SwiftUI
import SwiftData

// MARK: - Main Tab View (Adopting Official Apple iOS 18 Liquid Glass TabView)
struct MainTabView: View {

    // Tab Index: 0 = Domov, 1 = Canvas, 2 = Kamera, 3 = Profil
    @State private var selectedTab: Int = 0
    @State private var showCaptureSheet: Bool = false
    @StateObject private var navDepth = NavDepth.shared

    // Splash overlay
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            // Root Velvet Stage Background covering 100% of screen without black bars
            EllegancePageBackground()

            // ── Native SwiftUI paging scroll ───────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ContentView()
                        .id(0)
                        .containerRelativeFrame(.horizontal)

                    CanvasRoutinesHubView()
                        .id(1)
                        .containerRelativeFrame(.horizontal)

                    ProfileView()
                        .id(2)
                        .containerRelativeFrame(.horizontal)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding(
                get: { selectedTab == 3 ? 2 : selectedTab },
                set: { selectedTab = ($0 ?? 0) == 2 ? 3 : ($0 ?? 0) }
            ))
            .scrollDisabled(navDepth.isLocked)
            .ignoresSafeArea(edges: .vertical)
            
            // ── Custom Liquid Glass dock overlay ───────────────────────────
            if navDepth.isDocked {
                VStack {
                    Spacer()
                    NativeLiquidGlassDock(
                        pageIndex: Binding(
                            get: { selectedTab == 3 ? 2 : selectedTab },
                            set: { selectedTab = $0 == 2 ? 3 : $0 }
                        ),
                        showCaptureSheet: $showCaptureSheet
                    )
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Splash overlay ─────────────────────────────────────────────
            if showSplash {
                AppSplashView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showSplash = false
                    }
                }
                .zIndex(10)
                .transition(.opacity)
                .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: navDepth.isDocked)
        .sheet(isPresented: $showCaptureSheet) {
            CaptureModeView(isPresented: $showCaptureSheet)
        }
        .onAppear {
            // Transparent Navigation Bar
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithTransparentBackground()
            navAppearance.backgroundColor = .clear
            navAppearance.shadowColor = .clear
            let baseFont = UIFont.systemFont(ofSize: 17, weight: .bold)
            let titleFont: UIFont
            if let serifDesc = baseFont.fontDescriptor.withDesign(.serif) {
                titleFont = UIFont(descriptor: serifDesc, size: 17)
            } else {
                titleFont = baseFont
            }
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor(Color.gold500),
                .font: titleFont
            ]
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Color.gold500)
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
            UINavigationBar.appearance().tintColor = UIColor(Color.gold500)
            UITextView.appearance().backgroundColor = .clear
        }
    }
}

// MARK: - Native iOS Liquid Glass Dock (Layered Apple System Liquid Glass)
private struct NativeLiquidGlassDock: View {
    @Binding var pageIndex: Int
    @Binding var showCaptureSheet: Bool
    
    @State private var dragX: CGFloat? = nil
    @State private var isTouching: Bool = false
    @State private var hoveredTabId: Int? = nil
    
    // Tab definitions
    private let tabs: [(id: Int, icon: String, title: String)] = [
        (0, "house.fill", "Domov"),
        (1, "square.grid.2x2.fill", "Canvas"),
        (2, "video.fill", "Kamera"),
        (3, "person.crop.circle.fill", "Profil")
    ]
    
    var body: some View {
        GeometryReader { dockGeo in
            let dockWidth = dockGeo.size.width
            let horizontalPadding: CGFloat = 8
            let usableWidth = max(dockWidth - (horizontalPadding * 2), 1)
            let itemWidth = usableWidth / CGFloat(tabs.count)
            
            // Active index mapping (0: Domov, 1: Canvas, 2: Kamera, 3: Profil mapped to page 2)
            let currentTabId: Int = {
                if let hovered = hoveredTabId, isTouching {
                    return hovered
                }
                if pageIndex == 0 { return 0 }
                if pageIndex == 1 { return 1 }
                if pageIndex == 2 { return 3 }
                return 0
            }()
            
            // Calculate current bubble center X
            let bubbleCenterX: CGFloat = {
                if let dragX = dragX {
                    return min(max(dragX, itemWidth / 2), usableWidth - (itemWidth / 2))
                }
                return CGFloat(currentTabId) * itemWidth + (itemWidth / 2)
            }()
            
            ZStack(alignment: .leading) {
                // ── 1. Active Sliding Liquid Glass Pill (Exact iOS Native Material Lens) ──
                ZStack {
                    // System Ultra-Thin Material Blur
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    // Liquid Glass Specular Top Highlight
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isTouching ? 0.35 : 0.22),
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay(
                    // Crisp Specular Glass Rim
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isTouching ? 0.85 : 0.65),
                                    Color.white.opacity(0.25),
                                    Color.clear,
                                    Color.white.opacity(isTouching ? 0.45 : 0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.3
                        )
                )
                .shadow(color: Color.black.opacity(0.30), radius: isTouching ? 10 : 6, x: 0, y: 3)
                .shadow(color: Color.white.opacity(isTouching ? 0.20 : 0.10), radius: 6, x: 0, y: 0)
                .frame(width: itemWidth - 4, height: 48)
                .scaleEffect(
                    x: isTouching ? (dragX != nil ? 1.12 : 1.05) : 1.0,
                    y: isTouching ? (dragX != nil ? 0.94 : 1.03) : 1.0
                )
                .position(x: horizontalPadding + bubbleCenterX, y: 32)
                .animation(
                    isTouching
                    ? .interactiveSpring(response: 0.16, dampingFraction: 0.84)
                    : .spring(response: 0.32, dampingFraction: 0.74),
                    value: bubbleCenterX
                )
                
                // ── 2. Dock Tabs Content (Icons and Text) ──
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.id) { tab in
                        let isSelected = (tab.id == currentTabId)
                        
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: isSelected ? 18 : 17, weight: isSelected ? .bold : .regular))
                            
                            if isSelected {
                                Text(tab.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))
                        .frame(width: itemWidth, height: 48)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
            .background(
                // 100% Pure Crystal UltraThinMaterial Pass-Through (Pure Apple Liquid Glass)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.35),
                                Color.clear,
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 8)
            .shadow(color: Color.white.opacity(0.15), radius: 4, x: 0, y: -1)
            .contentShape(Rectangle())
            // ── 3. Active Real-Time Gesture Tracking ──
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isTouching = true
                        let localX = gesture.location.x - horizontalPadding
                        dragX = localX
                        
                        let targetIdx = min(max(Int(localX / itemWidth), 0), tabs.count - 1)
                        let targetTab = tabs[targetIdx].id
                        
                        if hoveredTabId != targetTab {
                            hoveredTabId = targetTab
                            
                            // Instant continuous page transition as finger slides over tabs
                            if targetTab != 2 {
                                let mappedPage = (targetTab == 3 ? 2 : targetTab)
                                if pageIndex != mappedPage {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        pageIndex = mappedPage
                                    }
                                    HapticFeedback.light()
                                }
                            }
                        }
                    }
                    .onEnded { gesture in
                        let localX = gesture.location.x - horizontalPadding
                        let targetIdx = min(max(Int(localX / itemWidth), 0), tabs.count - 1)
                        let targetTab = tabs[targetIdx].id
                        
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            isTouching = false
                            dragX = nil
                            hoveredTabId = nil
                            handleFinalSelection(tabId: targetTab)
                        }
                    }
            )
        }
        .frame(height: 64)
    }
    
    private func handleFinalSelection(tabId: Int) {
        HapticFeedback.medium()
        if tabId == 2 {
            showCaptureSheet = true
        } else {
            let mappedPage = (tabId == 3 ? 2 : tabId)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                pageIndex = mappedPage
            }
        }
    }
}



// MARK: - Xcode Canvas Preview (Safe Static Container for Instant Live Preview)
#Preview("MainTabView - App Workspace & Dock") {
    let schema = Schema([
        Dance.self,
        FigureLibraryItem.self,
        Routine.self,
        CanvasNode.self,
        InstantNote.self,
        VideoMediaEntry.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return MainTabView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}



