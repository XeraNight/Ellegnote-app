import SwiftUI

// MARK: - Main Tab View
// Uses SwiftUI-native horizontal paging ScrollView instead of TabView(.page).
// Reason: TabView(.page) uses UIPageViewController under the hood and
// .scrollDisabled() does not reliably propagate to its UIKit gesture
// recognizers. SwiftUI ScrollView FULLY respects .scrollDisabled().
struct MainTabView: View {

    // Page index: 0 = Home, 1 = Library, 2 = Profile (sequential for ScrollView)
    @State private var pageIndex: Int? = 0
    @State private var showCaptureSheet = false
    @StateObject private var navDepth = NavDepth.shared

    // Splash — skryje prvý render kým SwiftData načíta dáta
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // ── Native SwiftUI paging scroll ───────────────────────────────
            // .scrollTargetBehavior(.paging) gives Photos-style snap-to-page.
            // .scrollDisabled(navDepth.isLocked) fully blocks horizontal swipe
            // when inside RoutineCanvasView — the OS ignores the gesture entirely.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ContentView()
                        .id(0)
                        .containerRelativeFrame(.horizontal)
                        .ignoresSafeArea(edges: .all)

                    GlobalLibraryView()
                        .id(1)
                        .containerRelativeFrame(.horizontal)
                        .ignoresSafeArea(edges: .all)

                    ProfileView()
                        .id(2)
                        .containerRelativeFrame(.horizontal)
                        .ignoresSafeArea(edges: .all)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $pageIndex)
            .scrollDisabled(navDepth.isLocked)   // ← fully locks when on canvas
            .ignoresSafeArea(edges: .all)

            // ── Custom Liquid Glass dock overlay ───────────────────────────
            if navDepth.isDocked {
                VStack {
                    Spacer()
                    NativeLiquidGlassDock(
                        pageIndex: Binding(
                            get: { pageIndex ?? 0 },
                            set: { pageIndex = $0 }
                        ),
                        showCaptureSheet: $showCaptureSheet
                    )
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Splash overlay ─────────────────────────────────────────────
            // AppSplashView má vlastný exit timer (~1.1s), potom zavolá onComplete
            // a zmizne s opacity transition. Skryje prvý render SwiftData queries.
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

// MARK: - Native iOS Liquid Glass Dock
private struct NativeLiquidGlassDock: View {
    @Binding var pageIndex: Int
    @Binding var showCaptureSheet: Bool

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 6) {
                // 1. Home
                DockItem(
                    icon: "house.fill",
                    title: "Domov",
                    isActive: pageIndex == 0
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        pageIndex = 0
                    }
                    HapticFeedback.light()
                }

                // 2. Canvas / Library
                DockItem(
                    icon: "square.grid.2x2.fill",
                    title: "Canvas",
                    isActive: pageIndex == 1
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        pageIndex = 1
                    }
                    HapticFeedback.light()
                }

                // 3. Instant Camera
                DockItem(
                    icon: "video.fill",
                    title: "Kamera",
                    isActive: false
                ) {
                    showCaptureSheet = true
                    HapticFeedback.medium()
                }

                // 4. Settings / Profile
                DockItem(
                    icon: "person.crop.circle.fill",
                    title: "Profil",
                    isActive: pageIndex == 2
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        pageIndex = 2
                    }
                    HapticFeedback.light()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.gold400.opacity(0.30), Color.white.opacity(0.12), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Single dock item — with subtle interactive liquid glass pill
private struct DockItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: isActive ? 16 : 17, weight: isActive ? .bold : .regular))
                
                if isActive {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .foregroundStyle(isActive ? Color.gold400 : Color.white.opacity(0.55))
            .padding(.horizontal, isActive ? 14 : 12)
            .padding(.vertical, 10)
        }
        .if(isActive) { view in
            view.glassEffect(.regular.interactive(), in: .capsule)
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}



