import SwiftUI

// MARK: - 2-Second Animated App Splash Screen with Apple Calligraphic Hello Effect
struct AppSplashView: View {
    var onComplete: () -> Void
    
    @AppStorage("profileName") private var userName = "Jakub"
    @State private var progress: CGFloat = 0.0
    @State private var isAnimatingLogo = false
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Warm Cream Background
            Color.themeBg.ignoresSafeArea()
            
            // Soft background ambient blobs
            VStack {
                HStack {
                    Circle()
                        .fill(Color.themeAccent.opacity(0.08))
                        .frame(width: 320, height: 320)
                        .blur(radius: 50)
                        .offset(x: -80, y: -60)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.amberGold.opacity(0.08))
                        .frame(width: 280, height: 280)
                        .blur(radius: 50)
                        .offset(x: 60, y: 60)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Animated Ellegnote Logo Container
                ZStack {
                    Circle()
                        .fill(Color.themeCard)
                        .frame(width: 104, height: 104)
                        .neubrutalistCard(cornerRadius: 52, shadowOffset: 4)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.themeAccent, .amberGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 112, height: 112)
                        .scaleEffect(isAnimatingLogo ? 1.05 : 0.98)
                        .opacity(isAnimatingLogo ? 0.9 : 0.5)
                    
                    Image(systemName: "figure.dance")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.themeAccent)
                        .scaleEffect(isAnimatingLogo ? 1.06 : 0.96)
                }
                
                // MARK: Apple Hello Calligraphic Stroke Animation for User's Nickname
                AppleHelloNameStrokeView(name: userName)
                    .padding(.top, 8)
                
                Spacer()
                
                // 2-Second Progress Bar
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.themeBorder)
                            .frame(width: 180, height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.themeAccent, .amberGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 180 * progress, height: 6)
                    }
                    
                    Text("Načítavam tvoje zostavy...")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeDark.opacity(0.5))
                        .tracking(0.5)
                }
                .padding(.bottom, 60)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Trigger zero-lag camera pre-warming and data preloading in background
            AppPreloader.shared.preloadAll()
            
            // Logo pulsing animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimatingLogo = true
            }
            
            // 2.0s exact progress bar animation
            withAnimation(.linear(duration: 2.0)) {
                progress = 1.0
            }
            
            // At 2.0 seconds exact, smoothly fade out and trigger onComplete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    scale = 1.05
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Apple Calligraphic Stroke & Shimmer Hello Effect for User Name
struct AppleHelloNameStrokeView: View {
    let name: String
    
    @State private var strokeProgress: CGFloat = 0.0
    @State private var fillOpacity: Double = 0.0
    
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Jakub" : trimmed
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("vítaj")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.themeDark.opacity(0.65))
            
            ZStack {
                // Background Calligraphic Glow
                Text(displayName)
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.themeAccent, .amberGold, .latinPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(fillOpacity)
                    .shadow(color: Color.themeAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                
                // Animated Vector Path Stroke Drawing (0 to 1 pathLength animation)
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.themeAccent, .amberGold, .latinPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            Text(displayName)
                                .font(.system(size: 42, weight: .bold, design: .serif))
                                .italic()
                        )
                        .mask(
                            Rectangle()
                                .frame(width: geo.size.width * strokeProgress)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }
                .frame(height: 54)
            }
            .frame(height: 54)
        }
        .onAppear {
            // Path stroke animation (0 to 1 over 1.2s easeInOut)
            withAnimation(.easeInOut(duration: 1.2)) {
                strokeProgress = 1.0
            }
            
            // Fills in full gradient glow right as stroke finishes
            withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
                fillOpacity = 1.0
            }
        }
    }
}
