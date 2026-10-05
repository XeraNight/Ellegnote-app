import Foundation
import Combine
import Supabase
import SwiftUI
import LocalAuthentication
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import OSLog

// MARK: - Google Sign-In Outcome (Sendable bridge out of the SDK callback)
private struct GoogleCredentialPayload: Sendable {
    let idToken: String
    let email: String
    let name: String
    let sub: String
    let avatar: String
}

private enum GoogleSignInOutcome: Sendable {
    case success(GoogleCredentialPayload)
    case cancelled
    case failure(String)
}

// MARK: - Supabase Auth Manager
// Single source of truth: the user is "authenticated" if and only if a Supabase session exists.
// The session lives in the Keychain (supabase-swift default) and is refreshed automatically,
// so a temporarily expired access token or a lost network connection never logs the user out.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool
    @Published var isCheckingInitialAuth: Bool = true
    @Published var isLoading = false
    @Published var authErrorMessage: String? = nil
    @Published var authSuccessMessage: String? = nil
    @Published var showSettingsLink: Bool = false
    /// Presented globally (RootAppView) after the user opens a password-recovery link.
    @Published var showPasswordRecoverySheet: Bool = false

    @AppStorage("profileName") var userName: String = "Tanečník"
    @AppStorage("userEmail")   var userEmail: String = ""
    @AppStorage("userAvatarURL") var userAvatarURL: String = ""
    @AppStorage("googleSubId") var googleSubId: String = ""
    @AppStorage("isBiometricsEnabled") var isBiometricsEnabled: Bool = true

    private static let authCallbackURL = URL(string: "encore://auth-callback")!
    private static let pendingResetKey = "encore_pending_password_reset_at"
    private static let minPasswordLength = 6

    // Uses the shared SupabaseConfig.client singleton
    nonisolated private var client: SupabaseClient? { SupabaseConfig.client }

    private init() {
        self.isAuthenticated = false
        self.isCheckingInitialAuth = true

        // Older builds stored the password / a refresh-token copy; remove them.
        KeychainHelper.shared.purgeLegacySecrets()

        Task { await checkInitialAuth() }
    }

    // MARK: - Initial Auth Restoration
    private func checkInitialAuth() async {
        Task { await startAuthListener() }

        if let client {
            // 1. Apply the locally cached session immediately (no flash of the login screen).
            // Even if the access token is expired, Supabase refreshes it with the refresh token.
            if let local = client.auth.currentSession {
                applySession(local)
            }

            do {
                let session = try await client.auth.session
                applySession(session)
            } catch {
                // Offline / temporary failure → NEVER clear the local session here.
                // A truly revoked refresh token is reported by the listener as .signedOut.
                Logger.auth.debug("[AuthManager] Initial session check note: \(error.localizedDescription, privacy: .public)")
            }
        }

        // 2. Silent Google restore – only when Supabase has no session at all.
        if !isAuthenticated {
            _ = await restoreGoogleSignInAsync(silent: true)
        }

        isCheckingInitialAuth = false
    }

    // MARK: - Reactive Auth State Listener
    private func startAuthListener() async {
        guard let client else {
            isCheckingInitialAuth = false
            return
        }
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession:
                if let s = session {
                    applySession(s)
                } else if !isAuthenticated {
                    clearSession()
                }
                isCheckingInitialAuth = false
            case .signedIn, .tokenRefreshed, .userUpdated:
                if let s = session { applySession(s) }
                isCheckingInitialAuth = false
            case .passwordRecovery:
                if let s = session { applySession(s) }
                showPasswordRecoverySheet = true
                isCheckingInitialAuth = false
            case .signedOut, .userDeleted:
                clearSession()
                isCheckingInitialAuth = false
            default:
                break
            }
        }
    }

    private func applySession(_ session: Session) {
        currentUser = session.user
        isAuthenticated = true
        if let email = session.user.email, !email.isEmpty {
            userEmail = email
        }
        if let metaName = session.user.userMetadata["name"] {
            if case let .string(str) = metaName, !str.isEmpty {
                userName = str
            }
        }
        UserProfileStore.shared.refreshForActiveUser()
    }

    private func clearSession() {
        currentUser = nil
        isAuthenticated = false
        userEmail = ""
        userName = "Tanečník"
        UserProfileStore.shared.refreshForActiveUser()
    }

    /// Remembers only the e-mail (to pre-fill the form) and the provider (to offer the right
    /// quick-login). Passwords and tokens are never stored by us: the Supabase SDK keeps the
    /// session in the Keychain, and iOS AutoFill / iCloud Keychain handles saved passwords.
    private func persistLogin(email: String, provider: String) {
        KeychainHelper.shared.saveSession(email: email, provider: provider)
    }

    // MARK: - Saved Credentials Info
    var savedEmail: String? {
        let fromKeychain = KeychainHelper.shared.readSession()?.email
        if let fromKeychain, !fromKeychain.isEmpty { return fromKeychain }
        return userEmail.isEmpty ? nil : userEmail
    }

    /// True when the login screen can honestly offer biometric login: a Supabase session that
    /// can still be restored, or a previous Google sign-in.
    var canUseBiometricLogin: Bool {
        guard isBiometricsEnabled else { return false }
        if client?.auth.currentSession != nil { return true }
        if KeychainHelper.shared.readSession()?.provider == "google" {
            return GIDSignIn.sharedInstance.hasPreviousSignIn()
        }
        return false
    }

    /// Only users who registered with e-mail + password have a password to change.
    var canChangePassword: Bool {
        guard isAuthenticated, let user = currentUser else { return false }
        if let identities = user.identities, !identities.isEmpty {
            return identities.contains { $0.provider == "email" }
        }
        if case let .string(provider)? = user.appMetadata["provider"] {
            return provider == "email"
        }
        return false
    }

    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    var biometryName: String {
        switch biometryType {
        case .touchID: return "Touch ID"
        case .faceID:  return "Face ID"
        case .opticID: return "Optic ID"
        default:       return "Face ID"
        }
    }

    var biometrySystemImage: String {
        switch biometryType {
        case .touchID: return "touchid"
        case .faceID:  return "faceid"
        case .opticID: return "opticid"
        default:       return "faceid"
        }
    }

    // Called on scenePhase → active. NEVER destroys the local session on a network error.
    func checkCurrentSession() async {
        guard let client, isAuthenticated else { return }
        do {
            let session = try await client.auth.session
            applySession(session)
        } catch {
            Logger.auth.debug("[AuthManager] Background session check note: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Sign In (Email & Password)
    func signIn(email: String, pass: String) async -> Bool {
        guard let client else {
            authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera."
            return false
        }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        // Passwords may legitimately contain leading/trailing spaces – never trim them.
        guard !cleanEmail.isEmpty, !pass.isEmpty else {
            authErrorMessage = "Zadaj prosím e-mail aj heslo."
            return false
        }

        isLoading = true
        authErrorMessage = nil
        authSuccessMessage = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: cleanEmail, password: pass)
            applySession(session)
            persistLogin(email: cleanEmail, provider: "email")
            return true
        } catch {
            authErrorMessage = friendlyAuthError(from: error, isSignUp: false)
            return false
        }
    }

    // MARK: - Sign Up (Email & Password)
    func signUp(email: String, pass: String, name: String) async -> Bool {
        guard let client else {
            authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera."
            return false
        }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, pass.count >= Self.minPasswordLength, !cleanName.isEmpty else {
            authErrorMessage = "Vyplň prosím meno, platný e-mail a heslo s aspoň \(Self.minPasswordLength) znakmi."
            return false
        }

        isLoading = true
        authErrorMessage = nil
        authSuccessMessage = nil
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(
                email: cleanEmail,
                password: pass,
                data: [
                    "name": .string(cleanName),
                    "platform": .string("ios"),
                    "last_platform": .string("ios"),
                    "client_type": .string("ios_native")
                ],
                redirectTo: Self.authCallbackURL
            )

            // Supabase hides "already registered" by returning a user without identities.
            if response.user.identities?.isEmpty == true {
                authErrorMessage = "Účet s týmto e-mailom už existuje. Prejdi na záložku Prihlásenie."
                return false
            }

            if let session = response.session {
                applySession(session)
                userName = cleanName
                // Must run AFTER applySession so the profile is stored under the new user id.
                UserProfileStore.shared.saveProfile(name: cleanName, club: "")
                persistLogin(email: cleanEmail, provider: "email")
                return true
            } else {
                // E-mail confirmation required by the server.
                persistLogin(email: cleanEmail, provider: "email")
                authSuccessMessage = "Účet bol vytvorený! Na tvoj e-mail sme poslali potvrdzovací odkaz. Po potvrdení sa môžeš prihlásiť."
                return false
            }
        } catch {
            authErrorMessage = friendlyAuthError(from: error, isSignUp: true)
            return false
        }
    }

    // MARK: - Password Reset (forgot password)
    /// Sends a recovery e-mail. Returns an error message, or nil on success.
    /// Supabase answers identically for unknown addresses (no account enumeration).
    func sendPasswordReset(email: String) async -> String? {
        guard let client else { return "Chyba spojenia: Chýba platná konfigurácia Supabase servera." }
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.contains("@"), clean.contains("."), clean.count >= 5 else {
            return "Zadaj platný formát e-mailovej adresy (napr. meno@domena.sk)."
        }
        do {
            try await client.auth.resetPasswordForEmail(clean, redirectTo: Self.authCallbackURL)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.pendingResetKey)
            return nil
        } catch {
            return friendlyAuthError(from: error, fallbackPrefix: "Odoslanie odkazu zlyhalo")
        }
    }

    /// Sets a new password for the current session (used after opening a recovery link).
    /// Returns an error message, or nil on success.
    func setNewPassword(_ newPassword: String) async -> String? {
        guard let client else { return "Chyba spojenia: Chýba platná konfigurácia Supabase servera." }
        guard newPassword.count >= Self.minPasswordLength else {
            return "Heslo musí mať aspoň \(Self.minPasswordLength) znakov."
        }
        do {
            _ = try await client.auth.update(user: UserAttributes(password: newPassword))
            let email = currentUser?.email ?? userEmail
            persistLogin(email: email, provider: "email")
            return nil
        } catch {
            return friendlyAuthError(from: error, fallbackPrefix: "Zmena hesla zlyhala")
        }
    }

    /// Changes the password of a signed-in e-mail user after verifying the current one.
    /// Returns an error message, or nil on success.
    func changePassword(current: String, new newPassword: String) async -> String? {
        guard let client else { return "Chyba spojenia: Chýba platná konfigurácia Supabase servera." }
        let email = (currentUser?.email ?? userEmail).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return "Nepodarilo sa zistiť e-mail účtu. Prihlás sa znova." }
        guard !current.isEmpty else { return "Zadaj súčasné heslo." }
        guard newPassword.count >= Self.minPasswordLength else {
            return "Nové heslo musí mať aspoň \(Self.minPasswordLength) znakov."
        }
        guard newPassword != current else { return "Nové heslo musí byť iné ako súčasné." }

        // Re-verify the current password (also guarantees a fresh session for the update).
        do {
            let session = try await client.auth.signIn(email: email, password: current)
            applySession(session)
        } catch {
            let desc = error.localizedDescription.lowercased()
            if desc.contains("invalid login credentials") || desc.contains("invalid_credentials") || desc.contains("invalid_grant") {
                return "Súčasné heslo nie je správne."
            }
            return friendlyAuthError(from: error, fallbackPrefix: "Overenie hesla zlyhalo")
        }
        return await setNewPassword(newPassword)
    }

    // MARK: - Biometric Auth (Face ID / Touch ID)
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Zrušiť"
        var error: NSError?
        showSettingsLink = false

        let canEvaluateBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let canEvaluatePasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        guard canEvaluateBiometrics || canEvaluatePasscode else {
            showSettingsLink = true
            if let laError = error as? LAError, laError.code == .biometryLockout {
                authErrorMessage = "Face ID je zablokované. Odomkni iPhone kódom alebo prejdi do Nastavení."
            } else {
                authErrorMessage = "Face ID nie je na tomto zariadení povolené. Povoľ ho v Nastaveniach iPhonu."
            }
            return false
        }

        let policy: LAPolicy = canEvaluateBiometrics ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication

        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }

        do {
            let reason = "Prihlásiť sa do Encore pomocou \(biometryName)"
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            guard success else {
                authErrorMessage = "\(biometryName) overenie nebolo úspešné."
                return false
            }

            // 1. A refreshable Supabase session is still around.
            if let client = self.client {
                if let local = client.auth.currentSession {
                    applySession(local)
                    return true
                }
                if let session = try? await client.auth.session {
                    applySession(session)
                    return true
                }
            }

            // 2. No restorable session: fall back to the previous Google sign-in, if any.
            let saved = KeychainHelper.shared.readSession()
            let email = saved?.email ?? userEmail
            let provider = saved?.provider ?? "email"

            if provider == "google" {
                if await restoreGoogleSignInAsync(silent: false) { return true }
                if authErrorMessage == nil {
                    authErrorMessage = "Platnosť Google prihlásenia vypršala. Klikni na „Continue with Google“."
                }
                return false
            }

            if !email.isEmpty {
                authErrorMessage = "Platnosť prihlásenia pre \(email) vypršala. Prihlás sa heslom (môžeš použiť automatické dopĺňanie) alebo cez Google."
            } else {
                authErrorMessage = "Na tomto zariadení zatiaľ nie sú uložené prihlasovacie údaje. Prihlás sa najprv e-mailom, cez Google alebo Apple."
            }
            return false

        } catch let laError as LAError {
            if laError.code == .biometryNotAvailable || laError.code == .biometryLockout {
                showSettingsLink = true
                authErrorMessage = "Face ID je pre Encore zablokované. Povoľ ho v Nastaveniach iPhonu."
            } else if laError.code == .userCancel || laError.code == .appCancel || laError.code == .systemCancel {
                authErrorMessage = nil
            } else {
                authErrorMessage = "Biometrické overenie zlyhalo."
            }
            return false
        } catch {
            authErrorMessage = "Biometrické overenie zlyhalo alebo bolo zrušené."
            return false
        }
    }

    // MARK: - Friendly Error Translation
    private func friendlyAuthError(from error: Error, isSignUp: Bool) -> String {
        friendlyAuthError(from: error, fallbackPrefix: isSignUp ? "Registrácia zlyhala" : "Prihlásenie zlyhalo")
    }

    private func friendlyAuthError(from error: Error, fallbackPrefix: String) -> String {
        let desc = error.localizedDescription.lowercased()

        if desc.contains("email not confirmed") || desc.contains("email_not_confirmed") || desc.contains("not confirmed") {
            return "Tvoj e-mail zatiaľ nebol potvrdený. Skontroluj si doručenú poštu alebo spam a klikni na potvrdzovací odkaz."
        }
        if desc.contains("invalid login credentials") || desc.contains("invalid_grant") || desc.contains("bad credentials") {
            return "Účet s týmto e-mailom a heslom neexistuje alebo je heslo nesprávne. Skontroluj údaje alebo sa najprv zaregistruj."
        }
        if desc.contains("user already registered") || desc.contains("already exists") || desc.contains("user_already_exists") {
            return "Účet s týmto e-mailom už existuje. Prejdi na záložku Prihlásenie."
        }
        if desc.contains("different from the old password") || desc.contains("same_password") {
            return "Nové heslo musí byť iné ako súčasné."
        }
        if desc.contains("password should be at least") || desc.contains("weak_password") || desc.contains("weak password") {
            return "Heslo je príliš slabé. Použi aspoň \(Self.minPasswordLength) znakov."
        }
        if desc.contains("unable to validate email") || desc.contains("invalid email") || desc.contains("email address is invalid") {
            return "Zadaj platný formát e-mailovej adresy (napr. meno@domena.sk)."
        }
        if desc.contains("offline") || desc.contains("network") || desc.contains("timed out") || desc.contains("connection lost") || desc.contains("could not connect") {
            return "Nepodarilo sa spojiť so serverom. Skontroluj internetové pripojenie."
        }
        if desc.contains("rate limit") || desc.contains("too many requests") || desc.contains("over_email_send_rate_limit") {
            return "Príliš veľa pokusov za krátky čas. Počkaj prosím chvíľu a skús to znova."
        }
        if desc.contains("provider is not enabled") || desc.contains("unsupported provider") {
            return "Tento spôsob prihlásenia momentálne nie je dostupný. Skús Google alebo e-mail."
        }
        if desc.contains("session") && (desc.contains("missing") || desc.contains("not found")) {
            return "Prihlásenie vypršalo. Prihlás sa prosím znova."
        }
        if desc.contains("expired") || desc.contains("otp_expired") {
            return "Odkaz už vypršal. Vyžiadaj si nový."
        }

        return "\(fallbackPrefix): \(error.localizedDescription)"
    }

    // MARK: - Google Sign In (native SDK → Supabase ID-token exchange)
    func signInWithGoogleNative(presenting rootViewController: UIViewController) async -> Bool {
        isLoading = true
        authErrorMessage = nil
        authSuccessMessage = nil
        defer { isLoading = false }

        let outcome: GoogleSignInOutcome = await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.code == GIDSignInError.canceled.rawValue {
                        continuation.resume(returning: .cancelled)
                    } else {
                        continuation.resume(returning: .failure(error.localizedDescription))
                    }
                    return
                }
                guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                    continuation.resume(returning: .failure("Nepodarilo sa získať Google token."))
                    return
                }
                continuation.resume(returning: .success(GoogleCredentialPayload(
                    idToken: idToken,
                    email: user.profile?.email ?? "",
                    name: user.profile?.name ?? "Tanečník",
                    sub: user.userID ?? "",
                    avatar: user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
                )))
            }
        }

        switch outcome {
        case .cancelled:
            return false
        case .failure(let message):
            Logger.auth.error("[GoogleSignIn] Error: \(message, privacy: .public)")
            authErrorMessage = "Google prihlásenie zlyhalo: \(message)"
            return false
        case .success(let payload):
            return await completeGoogleLogin(payload, silent: false)
        }
    }

    /// Exchanges a Google ID token for a Supabase session. The user only becomes authenticated
    /// when the exchange really succeeded – no half-logged-in state without a server session.
    private func completeGoogleLogin(_ payload: GoogleCredentialPayload, silent: Bool) async -> Bool {
        guard let client else {
            if !silent { authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera." }
            return false
        }
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: payload.idToken)
            )
            applySession(session)
            if userName == "Tanečník" { userName = payload.name }
            googleSubId = payload.sub
            if !payload.avatar.isEmpty { userAvatarURL = payload.avatar }
            persistLogin(email: session.user.email ?? payload.email, provider: "google")
            AnalyticsManager.shared.signInGoogle()
            Logger.auth.info("[GoogleSignIn] Supabase session established.")
            return true
        } catch {
            Logger.auth.error("[GoogleSignIn] Supabase token exchange error: \(error.localizedDescription, privacy: .public)")
            if !silent {
                authErrorMessage = friendlyAuthError(from: error, fallbackPrefix: "Google prihlásenie zlyhalo")
            }
            return false
        }
    }

    // MARK: - Restore Google Sign In
    private func restoreGoogleSignInAsync(silent: Bool) async -> Bool {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return false }

        let payload: GoogleCredentialPayload? = await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                guard let user, error == nil, let idToken = user.idToken?.tokenString else {
                    if let error {
                        Logger.auth.debug("[GoogleSignIn] Silent restore note: \(error.localizedDescription, privacy: .public)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: GoogleCredentialPayload(
                    idToken: idToken,
                    email: user.profile?.email ?? "",
                    name: user.profile?.name ?? "Tanečník",
                    sub: user.userID ?? "",
                    avatar: user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
                ))
            }
        }

        guard let payload else { return false }
        return await completeGoogleLogin(payload, silent: silent)
    }

    // MARK: - Sign in with Apple
    private var currentAppleNonce: String?

    /// Call from the SignInWithAppleButton's onRequest to get the hashed nonce to attach to the request.
    func startAppleSignInNonce() -> String {
        let nonce = AuthManager.randomNonceString()
        currentAppleNonce = nonce
        return AuthManager.sha256(nonce)
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if status != errSecSuccess {
            return UUID().uuidString + UUID().uuidString
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Call after ASAuthorizationAppleIDCredential returns an identityToken.
    func signInWithApple(idToken: String, fullName: String? = nil, email: String? = nil) async -> Bool {
        guard let client else {
            authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera."
            return false
        }
        guard let nonce = currentAppleNonce else {
            authErrorMessage = "Chyba prihlásenia cez Apple: chýba bezpečnostný nonce. Skús to znova."
            return false
        }
        isLoading = true
        authErrorMessage = nil
        authSuccessMessage = nil
        defer { isLoading = false; currentAppleNonce = nil }

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            applySession(session)
            // Apple only sends the name / e-mail on the very first authorization.
            if let fullName, !fullName.isEmpty {
                userName = fullName
                UserProfileStore.shared.saveProfile(name: fullName, club: "")
            }
            persistLogin(email: session.user.email ?? email ?? userEmail, provider: "apple")
            AnalyticsManager.shared.signInApple()
            return true
        } catch {
            Logger.auth.error("[AppleSignIn] Supabase token exchange error: \(error.localizedDescription, privacy: .public)")
            authErrorMessage = friendlyAuthError(from: error, fallbackPrefix: "Prihlásenie cez Apple zlyhalo")
            return false
        }
    }

    // MARK: - Google OAuth Sign In (Browser Fallback)
    func signInWithGoogle() async -> Bool {
        guard let client else { return false }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let oauthURL = try client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: Self.authCallbackURL
            )
            await MainActor.run {
                UIApplication.shared.open(oauthURL)
            }
            AnalyticsManager.shared.signInGoogle()
            return true
        } catch {
            authErrorMessage = "Prihlásenie cez Google zlyhalo: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Deep Link (e-mail confirmation / OAuth callback / password recovery)
    /// Only `encore://auth-callback…` URLs belong to Supabase Auth. Friend-invite links
    /// (which can carry a `code` query item too) are routed elsewhere by the app.
    func handleDeepLink(_ url: URL) async {
        guard url.scheme == "encore", url.host == "auth-callback" else { return }
        guard let client else { return }
        do {
            let session = try await client.auth.session(from: url)
            applySession(session)

            if isRecoveryLink(url) {
                showPasswordRecoverySheet = true
                authSuccessMessage = nil
            } else {
                authSuccessMessage = "E-mail bol úspešne potvrdený!"
            }
            authErrorMessage = nil
        } catch {
            Logger.auth.error("[AuthManager] Deep link error: \(error.localizedDescription, privacy: .public)")
            authErrorMessage = friendlyAuthError(from: error, fallbackPrefix: "Odkaz sa nepodarilo spracovať")
        }
    }

    /// Implicit flow marks recovery links with `type=recovery`. PKCE links only carry a `code`,
    /// so we also remember that a reset was requested from this device in the last hour.
    private func isRecoveryLink(_ url: URL) -> Bool {
        if url.absoluteString.contains("type=recovery") { return true }
        let defaults = UserDefaults.standard
        let requestedAt = defaults.double(forKey: Self.pendingResetKey)
        defaults.removeObject(forKey: Self.pendingResetKey)
        guard requestedAt > 0 else { return false }
        return Date().timeIntervalSince1970 - requestedAt < 3600
    }

    // MARK: - Sign Out
    func signOut(forgetDevice: Bool = false) async {
        GIDSignIn.sharedInstance.signOut()
        userAvatarURL = ""
        googleSubId = ""

        if let client {
            // .local: sign out this device only – don't kick the user off their other devices.
            try? await client.auth.signOut(scope: .local)
        }

        if forgetDevice {
            KeychainHelper.shared.deleteCredentials()
            isBiometricsEnabled = false
        }
        clearSession()
    }

    // MARK: - Delete Account (Apple Guideline 5.1.1(v) Compliant)
    func deleteAccount() async {
        GIDSignIn.sharedInstance.signOut()
        userAvatarURL = ""
        googleSubId = ""

        if let client {
            do {
                try await client.rpc("delete_user_account").execute()
            } catch {
                Logger.auth.warning("[AuthManager] RPC delete_user_account: \(error.localizedDescription, privacy: .public)")
            }
            try? await client.auth.signOut(scope: .local)
        }

        KeychainHelper.shared.deleteCredentials()
        isBiometricsEnabled = false
        clearSession()
    }
}
