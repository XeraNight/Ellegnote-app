import SwiftUI

// MARK: - Animated Splash Screen
// Clean 0.8s entry — no fake progress bar, no "Načítavam..." text.
// The app is fully loaded by the time splash completes.
struct AppSplashView: View {
    var onComplete: () -> Void

    @AppStorage("profileName") private var userName = "Jakub"
    @State private var isAnimatingLogo = false
    @State private var rotationDegrees: Double = 0.0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var nameOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()

            // Lightweight ambient blobs — no blur, just RadialGradient
            Canvas { ctx, size in
                ctx.fill(
                    Path(ellipseIn: CGRect(x: -80, y: -60, width: 320, height: 320)),
                    with: .color(Color.themeAccent.opacity(0.10))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: size.width - 200, y: size.height - 220, width: 280, height: 280)),
                    with: .color(Color.amberGold.opacity(0.10))
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer()

                // Logo ring
                ZStack {
                    Circle()
                        .stroke(Color.themeDark.opacity(0.30), lineWidth: 1.5)
                        .frame(width: 140, height: 140)

                    Circle()
                        .stroke(Color.themeDark.opacity(0.75), lineWidth: 2)
                        .frame(width: 124, height: 124)

                    // Spinning gradient arc
                    Circle()
                        .trim(from: 0.15, to: 0.75)
                        .stroke(
                            LinearGradient(
                                colors: [.themeAccent, .amberGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 136, height: 136)
                        .rotationEffect(.degrees(rotationDegrees))

                    Circle()
                        .fill(Color.themeCard)
                        .frame(width: 104, height: 104)
                        .shadow(color: Color.themeDark.opacity(0.10), radius: 8, x: 0, y: 4)

                    Image(systemName: "figure.dance")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.themeAccent)
                        .scaleEffect(isAnimatingLogo ? 1.05 : 0.95)
                }

                // Name fade-in (no stroke animation — lighter on GPU)
                VStack(spacing: 4) {
                    Text("vítaj")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.themeDark.opacity(0.60))

                    Text(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Jakub" : userName)
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.themeAccent, .amberGold, .latinPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.themeAccent.opacity(0.28), radius: 6, x: 0, y: 3)
                }
                .opacity(nameOpacity)

                Spacer()
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Logo pulse
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isAnimatingLogo = true
            }
            // Arc spin
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationDegrees = 360
            }
            // Name fades in
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                nameOpacity = 1.0
            }
            // Exit at 0.85s — fast but not rushed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                    scale   = 1.04
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onComplete()
                }
            }
        }
    }
}
