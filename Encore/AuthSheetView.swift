import SwiftUI
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

// MARK: - Login & registration
/// Brand screen: gold-on-obsidian card. All logic lives in `AuthManager`; this view only collects input.
struct AuthSheetView: View {
    var isSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    enum AuthTab {
        case signIn, signUp
    }

    @State private var selectedTab: AuthTab = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var legalTab: LegalComplianceView.LegalTab?
    @State private var showForgotPassword = false
    @State private var showCodeSheet = false
    @State private var ageConfirmed = false
    @State private var danceRole = "dancer"
    @State private var showBiometricButton = false
    @State private var tapFeedback = 0
    @FocusState private var focus: AuthField?

    private var isSignUp: Bool { selectedTab == .signUp }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 24)
                            card
                                .padding(.horizontal, 20)
                            Spacer(minLength: 24)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .sheet(item: $legalTab) { LegalComplianceView(initialTab: $0) }
            .sheet(isPresented: $showForgotPassword) { ForgotPasswordSheet(prefillEmail: email) }
            .sheet(isPresented: $showCodeSheet) { EmailCodeSheet() }
            .onAppear {
                if email.isEmpty, let saved = authManager.savedEmail {
                    email = saved
                }
                // Read once, not on every redraw (it touches the Keychain).
                showBiometricButton = authManager.canUseBiometricLogin
            }
            .onChange(of: authManager.authErrorMessage) { _, message in
                // VoiceOver users hear the error without hunting for it.
                if let message { AccessibilityNotification.Announcement(message).post() }
            }
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zatvoriť") { dismiss() }
                            .foregroundColor(.gold400)
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: tapFeedback)
        }
    }

    // MARK: Background
    private var background: some View {
        ZStack {
            Color.obsidian900
            RadialGradient(
                colors: [Color.gold500.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { focus = nil }
    }

    // MARK: Card
    private var card: some View {
        VStack(spacing: 0) {
            header
            form
            messages
            PrimarySheetButton(
                title: isSignUp ? "Vytvoriť účet" : "Prihlásiť sa",
                isLoading: authManager.isLoading,
                isEnabled: canSubmit,
                action: handleAuthSubmit
            )
            .padding(.top, 18)
            accountLinks
            alternativeSignIn
            legalLinks
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.gold500.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: Color.gold500.opacity(0.25), radius: 25, y: 10)
        .shadow(color: Color.black.opacity(0.8), radius: 30, y: 15)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedTab)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("EncoreLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            EncoreWordmark(size: 15, color: .gold400)
            Text(isSignUp ? "Vytvor si účet" : "Vitaj späť")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .contentTransition(.opacity)
        }
        .padding(.bottom, 22)
    }

    // MARK: Form
    private var form: some View {
        VStack(spacing: 14) {
            if isSignUp {
                Picker("Som", selection: $danceRole) {
                    Text("Tanečník").tag("dancer")
                    Text("Tréner").tag("coach")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Kto som")

                TextField("", text: $nickname, prompt: fieldPrompt("Meno alebo prezývka"))
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focus = .email }
                    .onChange(of: nickname) { _, value in
                        if value.count > NameRules.maxLength {
                            nickname = String(value.prefix(NameRules.maxLength))
                        }
                    }
                    .authFieldChrome()
            }

            TextField("", text: $email, prompt: fieldPrompt("E-mail"))
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }
                .authFieldChrome()

            PasswordField(
                prompt: isSignUp ? "Heslo (aspoň \(PasswordPolicy.minLength) znakov)" : "Heslo",
                text: $password,
                contentType: isSignUp ? .newPassword : .password,
                submitLabel: isSignUp ? .done : .go,
                focus: $focus,
                field: .password,
                onSubmit: { handleAuthSubmit() }
            )

            if isSignUp {
                signUpExtras
            }
        }
    }

    @ViewBuilder
    private var signUpExtras: some View {
        PasswordStrengthBar(password: password)

        if !password.isEmpty, let issue = PasswordPolicy.issue(for: password, email: email) {
            Text(issue)
                .font(.caption.weight(.medium))
                .foregroundColor(.latinRed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        Button {
            ageConfirmed.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: ageConfirmed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(.gold400)
                Text("Mám aspoň 16 rokov, alebo mám súhlas rodiča či zákonného zástupcu.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(ageConfirmed ? "zapnuté" : "vypnuté")
    }

    private func fieldPrompt(_ text: String) -> Text {
        Text(text).foregroundColor(Color.gold300.opacity(0.5))
    }

    // MARK: Messages
    @ViewBuilder
    private var messages: some View {
        if let errorMessage = authManager.authErrorMessage {
            VStack(alignment: .leading, spacing: 8) {
                SheetBanner(text: errorMessage, isError: true)
                if authManager.showSettingsLink {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Otvoriť Nastavenia iPhonu", systemImage: "gearshape.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.gold400)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.gold500.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.top, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }

        if let successMessage = authManager.authSuccessMessage {
            SheetBanner(text: successMessage, isError: false)
                .padding(.top, 12)
                .transition(.opacity)
        }
    }

    // MARK: Links under the main button
    private var accountLinks: some View {
        VStack(spacing: 4) {
            if !isSignUp {
                Button("Zabudnuté heslo?") {
                    clearMessages()
                    showForgotPassword = true
                }
                .font(.footnote.weight(.medium))
                .foregroundColor(.white.opacity(0.65))
                .frame(minHeight: 44)
            }

            Button(isSignUp ? "Už máš účet? Prihlás sa" : "Nemáš účet? Zaregistruj sa") {
                selectedTab = isSignUp ? .signIn : .signUp
                clearMessages()
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(.gold400)
            .frame(minHeight: 44)
        }
        .padding(.top, 6)
    }

    // MARK: Google, Apple, Face ID
    private var alternativeSignIn: some View {
        VStack(spacing: 10) {
            Button(action: handleGoogleAuth) {
                HStack(spacing: 10) {
                    GoogleLogoView(size: 18)
                    Text("Pokračovať cez Google")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.92))
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
                )
            }
            .buttonStyle(.pressable)

            if AuthFeatureFlags.appleSignInEnabled {
                SignInWithAppleButton(.continue, onRequest: { request in
                    let hashedNonce = authManager.startAppleSignInNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = hashedNonce
                }, onCompletion: handleAppleAuthCompletion)
                .signInWithAppleButtonStyle(.white)
                .frame(height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if !isSignUp && showBiometricButton {
                Button(action: handleFaceIDAuth) {
                    Label("Prihlásiť sa cez \(authManager.biometryName)", systemImage: authManager.biometrySystemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.top, 10)
    }

    /// Two real links in one sentence; each opens its own section of the legal screen.
    private var legalLinks: some View {
        Text("Pokračovaním súhlasíš s [Podmienkami používania](encore-legal://terms) a [Zásadami ochrany súkromia](encore-legal://privacy).")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.55))
            .tint(.gold400)
            .multilineTextAlignment(.center)
            .padding(.top, 14)
            .environment(\.openURL, OpenURLAction { url in
                legalTab = url.host == "terms" ? .terms : .privacy
                return .handled
            })
    }

    // MARK: Actions
    private var canSubmit: Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSignUp {
            return EmailValidator.isValid(cleanEmail)
                && PasswordPolicy.issue(for: password, email: cleanEmail) == nil
                && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && ageConfirmed
        }
        return !cleanEmail.isEmpty && !password.isEmpty
    }

    private func clearMessages() {
        authManager.authErrorMessage = nil
        authManager.authSuccessMessage = nil
    }

    private func handleAuthSubmit() {
        guard canSubmit, !authManager.isLoading else { return }
        focus = nil
        tapFeedback += 1
        Task {
            let success: Bool
            if isSignUp {
                success = await authManager.signUp(email: email, pass: password, name: nickname, danceRole: danceRole, ageConfirmed: ageConfirmed)
            } else {
                success = await authManager.signIn(email: email, pass: password)
            }
            if success {
                if isSheet { dismiss() }
            } else if authManager.pendingConfirmationEmail != nil {
                showCodeSheet = true
            }
        }
    }

    private func handleGoogleAuth() {
        tapFeedback += 1
        focus = nil
        guard let presenter = UIViewController.topMost() else {
            Task {
                let success = await authManager.signInWithGoogle()
                if success && isSheet { dismiss() }
            }
            return
        }

        Task {
            let success = await authManager.signInWithGoogleNative(presenting: presenter)
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

            let fullName: String? = {
                if let name = credential.fullName {
                    let parts = [name.givenName, name.familyName].compactMap { $0 }.filter { !$0.isEmpty }
                    return parts.isEmpty ? nil : parts.joined(separator: " ")
                }
                return nil
            }()
            let appleEmail = credential.email

            tapFeedback += 1
            Task {
                let success = await authManager.signInWithApple(
                    idToken: idTokenString,
                    fullName: fullName,
                    email: appleEmail
                )
                if success && isSheet { dismiss() }
            }
        case .failure(let error):
            // User cancelling the sheet isn't a real error — don't show a scary message for it.
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                authManager.authErrorMessage = AuthErrorMapper.message(for: error, fallback: "Prihlásenie cez Apple zlyhalo")
            }
        }
    }

    private func handleFaceIDAuth() {
        tapFeedback += 1
        Task {
            let success = await authManager.authenticateWithBiometrics()
            if success && isSheet { dismiss() }
        }
    }
}

#Preview("Prihlásenie") {
    AuthSheetView(isSheet: true)
        .preferredColorScheme(.dark)
}
