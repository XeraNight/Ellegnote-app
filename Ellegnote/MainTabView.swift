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
                .foregroundColor: UIColor(Color.themeDark),
                .font: titleFont
            ]
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Color.themeDark)
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
            UINavigationBar.appearance().tintColor = UIColor(Color.themeAccent)
            UITextView.appearance().backgroundColor = .clear
        }
    }
}

// MARK: - Native iOS 26 Liquid Glass Dock
private struct NativeLiquidGlassDock: View {
    @Binding var pageIndex: Int
    @Binding var showCaptureSheet: Bool

    private let pages: [(page: Int, icon: String)] = [
        (0, "house.fill"),
        (1, "books.vertical.fill"),
        (2, "person.crop.circle.fill")
    ]

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                ForEach(pages, id: \.page) { item in
                    DockItem(
                        icon: item.icon,
                        isActive: pageIndex == item.page
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            pageIndex = item.page
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                // Camera — modal action (not a tab page)
                DockItem(icon: "video.badge.plus", isActive: false) {
                    showCaptureSheet = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
    }
}

// MARK: - Single dock icon — conditionally wrapped in native iOS 26 glass
private struct DockItem: View {
    let icon: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        if isActive {
            Button(action: onTap) { iconLabel }
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            Button(action: onTap) { iconLabel }
        }
    }

    private var iconLabel: some View {
        Image(systemName: icon)
            .font(.system(size: 22, weight: isActive ? .semibold : .regular))
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
    }
}

// MARK: - (Legacy shim — kept for any external references)
struct PureTransparentGlassDockModifier: ViewModifier {
    var cornerRadius: CGFloat = 36
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .shadow(color: .black.opacity(0.30), radius: 20, x: 0, y: 8)
    }
}
