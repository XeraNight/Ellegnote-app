import SwiftUI
import LocalAuthentication
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

// MARK: - Native Official Google "G" Vector Mark
struct GoogleLogoView: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24.0
            
            // 1. Blue: M 22.56 12.25
            var pBlue = Path()
            pBlue.move(to: CGPoint(x: 22.56 * s, y: 12.25 * s))
            pBlue.addCurve(to: CGPoint(x: 22.36 * s, y: 10.0 * s), control1: CGPoint(x: 22.56 * s, y: 11.47 * s), control2: CGPoint(x: 22.49 * s, y: 10.72 * s))
            pBlue.addLine(to: CGPoint(x: 12.0 * s, y: 10.0 * s))
            pBlue.addLine(to: CGPoint(x: 12.0 * s, y: 14.26 * s))
            pBlue.addLine(to: CGPoint(x: 17.92 * s, y: 14.26 * s))
            pBlue.addCurve(to: CGPoint(x: 15.71 * s, y: 17.57 * s), control1: CGPoint(x: 17.66 * s, y: 15.63 * s), control2: CGPoint(x: 16.88 * s, y: 16.79 * s))
            pBlue.addLine(to: CGPoint(x: 19.28 * s, y: 20.34 * s))
            pBlue.addCurve(to: CGPoint(x: 22.56 * s, y: 12.25 * s), control1: CGPoint(x: 21.36 * s, y: 18.42 * s), control2: CGPoint(x: 22.56 * s, y: 15.6 * s))
            pBlue.closeSubpath()
            context.fill(pBlue, with: .color(Color(red: 66/255, green: 133/255, blue: 244/255)))

            // 2. Green
            var pGreen = Path()
            pGreen.move(to: CGPoint(x: 12.0 * s, y: 23.0 * s))
            pGreen.addCurve(to: CGPoint(x: 19.28 * s, y: 20.34 * s), control1: CGPoint(x: 14.97 * s, y: 23.0 * s), control2: CGPoint(x: 17.46 * s, y: 22.02 * s))
            pGreen.addLine(to: CGPoint(x: 15.71 * s, y: 17.57 * s))
            pGreen.addCurve(to: CGPoint(x: 12.0 * s, y: 18.63 * s), control1: CGPoint(x: 14.73 * s, y: 18.23 * s), control2: CGPoint(x: 13.48 * s, y: 18.63 * s))
            pGreen.addCurve(to: CGPoint(x: 5.84 * s, y: 14.1 * s), control1: CGPoint(x: 9.14 * s, y: 18.63 * s), control2: CGPoint(x: 6.71 * s, y: 16.7 * s))
            pGreen.addLine(to: CGPoint(x: 2.18 * s, y: 16.94 * s))
            pGreen.addCurve(to: CGPoint(x: 12.0 * s, y: 23.0 * s), control1: CGPoint(x: 3.99 * s, y: 20.53 * s), control2: CGPoint(x: 7.7 * s, y: 23.0 * s))
            pGreen.closeSubpath()
            context.fill(pGreen, with: .color(Color(red: 52/255, green: 168/255, blue: 83/255)))

            // 3. Yellow
            var pYellow = Path()
            pYellow.move(to: CGPoint(x: 5.84 * s, y: 14.09 * s))
            pYellow.addCurve(to: CGPoint(x: 5.49 * s, y: 12.0 * s), control1: CGPoint(x: 5.62 * s, y: 13.43 * s), control2: CGPoint(x: 5.49 * s, y: 12.73 * s))
            pYellow.addCurve(to: CGPoint(x: 5.84 * s, y: 9.91 * s), control1: CGPoint(x: 5.49 * s, y: 11.27 * s), control2: CGPoint(x: 5.62 * s, y: 10.57 * s))
            pYellow.addLine(to: CGPoint(x: 2.18 * s, y: 7.07 * s))
            pYellow.addCurve(to: CGPoint(x: 1.0 * s, y: 12.0 * s), control1: CGPoint(x: 1.43 * s, y: 8.55 * s), control2: CGPoint(x: 1.0 * s, y: 10.22 * s))
            pYellow.addCurve(to: CGPoint(x: 2.18 * s, y: 16.93 * s), control1: CGPoint(x: 1.0 * s, y: 13.78 * s), control2: CGPoint(x: 1.43 * s, y: 15.45 * s))
            pYellow.addLine(to: CGPoint(x: 5.84 * s, y: 14.09 * s))
            pYellow.closeSubpath()
            context.fill(pYellow, with: .color(Color(red: 251/255, green: 188/255, blue: 5/255)))

            // 4. Red
            var pRed = Path()
            pRed.move(to: CGPoint(x: 12.0 * s, y: 5.38 * s))
            pRed.addCurve(to: CGPoint(x: 16.21 * s, y: 7.02 * s), control1: CGPoint(x: 13.62 * s, y: 5.38 * s), control2: CGPoint(x: 15.06 * s, y: 5.94 * s))
            pRed.addLine(to: CGPoint(x: 19.36 * s, y: 3.87 * s))
            pRed.addCurve(to: CGPoint(x: 12.0 * s, y: 1.0 * s), control1: CGPoint(x: 17.45 * s, y: 2.09 * s), control2: CGPoint(x: 14.97 * s, y: 1.0 * s))
            pRed.addCurve(to: CGPoint(x: 2.18 * s, y: 7.07 * s), control1: CGPoint(x: 7.7 * s, y: 1.0 * s), control2: CGPoint(x: 3.99 * s, y: 3.47 * s))
            pRed.addLine(to: CGPoint(x: 5.84 * s, y: 9.91 * s))
            pRed.addCurve(to: CGPoint(x: 12.0 * s, y: 5.38 * s), control1: CGPoint(x: 6.71 * s, y: 7.3 * s), control2: CGPoint(x: 9.14 * s, y: 5.38 * s))
            pRed.closeSubpath()
            context.fill(pRed, with: .color(Color(red: 234/255, green: 67/255, blue: 53/255)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Spotify-Inspired Glowing Luxury Card for iOS
struct AuthSheetView: View {
    var isSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    enum AuthTab: String, CaseIterable {
        case signIn = "Prihlásenie"
        case signUp = "Registrácia"
    }
    
    @State private var selectedTab: AuthTab = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Canvas Base
                Color.obsidian900.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                // Ambient Background Glows
                RadialGradient(
                    gradient: Gradient(colors: [Color.gold500.opacity(0.18), Color.clear]),
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 350
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 24)
                            
                            // ── Glowing Card Container (Spotify-style) ──
                            ZStack {
                                // Outer Ambient Glow Bleed (behind the card)
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.gold500.opacity(0.35), Color.gold400.opacity(0.15), Color.clear],
                                            startPoint: .topTrailing,
                                            endPoint: .bottomLeading
                                        )
                                    )
                                    .blur(radius: 20)
                                    .offset(x: 8, y: 0)
                                
                                // The Card
                                VStack(spacing: 0) {
                                    
                                    // ── Official Logo ──
                                    ZStack {
                                        Circle()
                                            .fill(Color.gold500.opacity(0.25))
                                            .frame(width: 80, height: 80)
                                            .blur(radius: 16)
                                        
                                        Image("EncoreLogo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 68, height: 68)
                                            .shadow(color: Color.gold500.opacity(0.5), radius: 14)
                                    }
                                    .padding(.top, 32)
                                    .padding(.bottom, 12)
                                    
                                    // ── Title (Encore) ──
                                    Text("Encore")
                                        .font(.system(size: 32, weight: .black, design: .serif))
                                        .foregroundColor(.gold400)
                                        .shadow(color: Color.gold500.opacity(0.55), radius: 18)
                                        .padding(.bottom, 22)
                                    
                                    // ── Form Inputs ──
                                    VStack(spacing: 14) {
                                        if selectedTab == .signUp {
                                            TextField("", text: $nickname, prompt: Text("Dancer Name / Nickname").foregroundColor(Color.gold300.opacity(0.45)))
                                                .textContentType(.name)
                                                .autocorrectionDisabled()
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .medium))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 14)
                                                .background(Color.obsidian800)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                                                )
                                        }
                                        
                                        TextField("", text: $email, prompt: Text("Email Address").foregroundColor(Color.gold300.opacity(0.45)))
                                            .textContentType(.username)
                                            .keyboardType(.emailAddress)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(Color.obsidian800)
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                                            )
                                        
                                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color.gold300.opacity(0.45)))
                                            .textContentType(selectedTab == .signUp ? .newPassword : .password)
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(Color.obsidian800)
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                                            )
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    // ── Error Alert ──
                                    if let errorMsg = authManager.authErrorMessage {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.latinRed)
                                                    .font(.system(size: 13))
                                                Text(errorMsg)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.latinRed)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            if authManager.showSettingsLink {
                                                Button(action: {
                                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                                        UIApplication.shared.open(url)
                                                    }
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "gearshape.fill")
                                                            .font(.system(size: 11))
                                                        Text("Otvoriť Nastavenia iPhonu")
                                                            .font(.system(size: 11, weight: .bold))
                                                    }
                                                    .foregroundColor(.gold400)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.gold500.opacity(0.12))
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                                                    )
                                                }
                                                .padding(.top, 2)
                                            }
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.latinRed.opacity(0.12))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.latinRed.opacity(0.5), lineWidth: 1)
                                        )
                                        .padding(.horizontal, 24)
                                        .padding(.top, 10)
                                    }
                                    
                                    // ── Success Alert ──
                                    if let successMsg = authManager.authSuccessMessage {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.gold400)
                                                .font(.system(size: 13))
                                            Text(successMsg)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.gold400)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gold500.opacity(0.12))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gold500.opacity(0.4), lineWidth: 1)
                                        )
                                        .padding(.horizontal, 24)
                                        .padding(.top, 10)
                                    }
                                    
                                    // ── Primary Action Button (Login) ──
                                    Button(action: handleAuthSubmit) {
                                        HStack {
                                            if authManager.isLoading {
                                                ProgressView().tint(Color.gold400)
                                            } else {
                                                Text(selectedTab == .signIn ? "Login" : "Sign Up")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(canSubmit ? Color.gold400 : Color.white.opacity(0.35))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color.obsidian900)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(canSubmit ? Color.gold500 : Color.white.opacity(0.15), lineWidth: 2)
                                        )
                                        .shadow(color: canSubmit ? Color.gold500.opacity(0.35) : Color.clear, radius: 12)
                                    }
                                    .disabled(!canSubmit || authManager.isLoading)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 18)
                                    
                                    // ── Forgot Password ──
                                    Button(action: {
                                        authManager.authErrorMessage = "Pre obnovenie hesla kontaktuj správcu alebo skontroluj email."
                                    }) {
                                        Text("Forgot password?")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.top, 14)
                                    
                                    // ── Mode Switcher ──
                                    Button(action: {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            selectedTab = selectedTab == .signIn ? .signUp : .signIn
                                            authManager.authErrorMessage = nil
                                        }
                                    }) {
                                        Text(selectedTab == .signIn ? "Nemáš účet? Zaregistruj sa" : "Už máš účet? Prihlás sa")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gold400)
                                    }
                                    .padding(.top, 8)
                                    
                                    // ── Quick Google & Face ID ──
                                    VStack(spacing: 8) {
                                        Button(action: handleGoogleAuth) {
                                            HStack(spacing: 10) {
                                                GoogleLogoView(size: 18)
                                                Text("Continue with Google")
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(.white.opacity(0.9))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 42)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                                            )
                                            .shadow(color: Color.gold500.opacity(0.12), radius: 8)
                                        }

                                        SignInWithAppleButton(.continue, onRequest: { request in
                                            let hashedNonce = authManager.startAppleSignInNonce()
                                            request.requestedScopes = [.fullName, .email]
                                            request.nonce = hashedNonce
                                        }, onCompletion: handleAppleAuthCompletion)
                                        .signInWithAppleButtonStyle(.white)
                                        .frame(height: 42)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                                        )
                                        .shadow(color: Color.gold500.opacity(0.12), radius: 8)
                                        
                                        if selectedTab == .signIn {
                                            Button(action: handleFaceIDAuth) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "faceid")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gold400)
                                                    Text("Prihlásenie cez Face ID")
                                                        .font(.system(size: 12, weight: .semibold))
                                                }
                                                .foregroundColor(.white.opacity(0.85))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 38)
                                                .background(Color.white.opacity(0.04))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                                    .padding(.bottom, 28)
                                }
                                .background(Color.themeCard)
                                .cornerRadius(28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.gold500.opacity(0.55), lineWidth: 1.5)
                                )
                                .shadow(color: Color.gold500.opacity(0.25), radius: 25, x: 0, y: 10)
                                .shadow(color: Color.black.opacity(0.8), radius: 30, x: 0, y: 15)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 24)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .onAppear {
                if email.isEmpty, let saved = authManager.savedEmail {
                    email = saved
                }
            }
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zatvoriť") { dismiss() }
                            .foregroundColor(.gold400)
                    }
                }
            }
        }
    }
    
    private var canSubmit: Bool {
        if selectedTab == .signUp {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   password.count >= 6 &&
                   !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !password.isEmpty
        }
    }
    
    private func handleAuthSubmit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            if selectedTab == .signUp {
                let success = await authManager.signUp(email: email, pass: password, name: nickname)
                if success && isSheet { dismiss() }
            } else {
                let success = await authManager.signIn(email: email, pass: password)
                if success && isSheet { dismiss() }
            }
        }
    }

    private func handleGoogleAuth() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            Task {
                let success = await authManager.signInWithGoogle()
                if success && isSheet { dismiss() }
            }
            return
        }

        Task {
            let success = await authManager.signInWithGoogleNative(presenting: rootViewController)
            if success && isSheet { dismiss() }
        }
    }
    
    private func handleAppleAuthCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idTokenString = String(data: tokenData, encoding: .utf8) else {
                authManager.authErrorMessage = "Nepodarilo sa získať Apple prihlasovací token."
                return
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task {
                let success = await authManager.signInWithApple(idToken: idTokenString)
                if success && isSheet { dismiss() }
            }
        case .failure(let error):
            // User cancelling the sheet isn't a real error — don't show a scary message for it.
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                authManager.authErrorMessage = "Prihlásenie cez Apple zlyhalo: \(error.localizedDescription)"
            }
        }
    }

    private func handleFaceIDAuth() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            let success = await authManager.authenticateWithBiometrics()
            if success && isSheet { dismiss() }
        }
    }
}

// MARK: - Xcode Canvas Preview
#Preview("AuthSheetView - Spotify Glowing Luxury") {
    AuthSheetView(isSheet: true)
        .preferredColorScheme(.dark)
}
