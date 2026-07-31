import SwiftUI

// MARK: - Main Tab View with Launch Splash & Liquid Glass Dock
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCaptureSheet = false
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()
            
            if isShowingSplash {
                // MARK: 2-Second Apple Hello Launch Splash
                AppSplashView {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else {
                // MARK: Phase 1 — Home / Routines & Canvas Focus
                ZStack {
                    // Screen switching container
                    Group {
                        switch selectedTab {
                        case 0:
                            ContentView()
                        case 1:
                            GlobalLibraryView()
                        case 3:
                            ProfileView()
                        default:
                            ContentView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 85)
                    
                    // MARK: - Floating Pure Transparent Liquid Glass Dock
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            // 1. Domov (Zostavy)
                            LiquidDockIconButton(
                                iconName: "house.fill",
                                label: "Domov",
                                isActive: selectedTab == 0
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
                                    selectedTab = 0
                                }
                            }
                            
                            // 2. Knižnica
                            LiquidDockIconButton(
                                iconName: "books.vertical.fill",
                                label: "Knižnica",
                                isActive: selectedTab == 1
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
                                    selectedTab = 1
                                }
                            }
                            
                            // 3. Instantka
                            LiquidDockIconButton(
                                iconName: "video.badge.plus",
                                label: "Instantka",
                                isActive: false
                            ) {
                                showCaptureSheet = true
                            }
                            
                            // 4. Profil
                            LiquidDockIconButton(
                                iconName: "person.crop.circle.fill",
                                label: "Profil",
                                isActive: selectedTab == 3
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
                                    selectedTab = 3
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .modifier(PureTransparentGlassDockModifier(cornerRadius: 32))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .allowsHitTesting(true)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showCaptureSheet) {
            CaptureModeView(isPresented: $showCaptureSheet)
        }
        .onAppear {
            // ── Globálny vzhľad Navigation Baru ─────────────────────────────
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(Color.themeBg)
            navAppearance.shadowColor = UIColor(Color.themeBorder)
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor(Color.themeDark),
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Color.themeDark)
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
            UINavigationBar.appearance().tintColor = UIColor(Color.themeAccent)
            
            // ── Oprava pozadia pre TextEditor ─────────────────────────────
            UITextView.appearance().backgroundColor = .clear
        }
    }
}

// MARK: - Pure Transparent Liquid Glass Container Modifier (Crystal Clear Glass Refraction)
struct PureTransparentGlassDockModifier: ViewModifier {
    var cornerRadius: CGFloat = 32
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Glass Layer 1: Pure Thin Glass Blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Glass Layer 2: Crystal Clear Reflection Tint
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.12))
                    
                    // Glass Layer 3: Glossy Specular Light Rim
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.8
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: Color.themeDark.opacity(0.4), radius: 0, x: 3, y: 3)
    }
}

// MARK: - Liquid Dock Icon Button
struct LiquidDockIconButton: View {
    let iconName: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(Color.themeAccent.opacity(0.16))
                            .frame(width: 42, height: 42)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: isActive ? .bold : .medium))
                        .foregroundColor(isActive ? .themeAccent : .themeDark.opacity(0.65))
                        .scaleEffect(isActive ? 1.12 : 1.0)
                }
                .frame(width: 44, height: 40)
                
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .black : .bold))
                    .foregroundColor(isActive ? .themeAccent : .themeDark.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidDockButtonStyle())
    }
}

// MARK: - Spring Physics Button Style for Liquid Dock
struct LiquidDockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.62), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}
