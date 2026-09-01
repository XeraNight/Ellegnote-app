import Foundation
import Combine
import Supabase
import SwiftUI
import LocalAuthentication
import GoogleSignIn
import OSLog

// MARK: - Supabase Auth Manager
// Uses authStateChanges reactive stream — never does a blocking network call on startup.
// This is the standard pattern used in production Supabase apps.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool
    @Published var isLoading = false
    @Published var authErrorMessage: String? = nil

    @AppStorage("profileName") var userName: String = "Jakub"
    @AppStorage("userEmail")   var userEmail: String = ""
    @AppStorage("userAvatarURL") var userAvatarURL: String = ""
    @AppStorage("googleSubId") var googleSubId: String = ""
    @AppStorage("isBiometricsEnabled") var isBiometricsEnabled: Bool = false

    // Uses the shared SupabaseConfig.client singleton — no separate instantiation.
    nonisolated private var client: SupabaseClient? { SupabaseConfig.client }

    private init() {
        let savedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let savedGoogleId = UserDefaults.standard.string(forKey: "googleSubId") ?? ""
        let hasCreds = KeychainHelper.shared.readCredentials() != nil
        self.isAuthenticated = !savedEmail.isEmpty || !savedGoogleId.isEmpty || hasCreds

        // Start listening to auth state changes reactively.
        // Does NOT block — the first event (.initialSession) fires from local keychain
        // without any network call.
        Task { await startAuthListener() }
        restoreGoogleSignInIfNeeded()
    }

    // MARK: - Restore Google Sign In on App Launch
    private func restoreGoogleSignInIfNeeded() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            guard let self, let user, error == nil else {
                if let error = error {
                    Logger.auth.warning("[GoogleSignIn] Silent restore not available: \(error.localizedDescription, privacy: .public)")
                }
                return
            }

            let email = user.profile?.email ?? ""
            let name = user.profile?.name ?? "Tanečník"
            let sub = user.userID ?? ""
            let avatar = user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
            let idToken = user.idToken?.tokenString ?? ""

            Logger.auth.info("[GoogleSignIn] Successfully restored sign-in for user: \(name, privacy: .private(mask: .hash))")

            Task { @MainActor in
                if self.userEmail.isEmpty, !email.isEmpty {
                    self.userEmail = email
                }
                self.userName = name
                self.googleSubId = sub
                if !avatar.isEmpty {
                    self.userAvatarURL = avatar
                }
                self.isAuthenticated = true

                // Exchange restored ID token with Supabase if available
                if let client = self.client, !idToken.isEmpty {
                    do {
                        let session = try await client.auth.signInWithIdToken(
                            credentials: .init(provider: .google, idToken: idToken)
                        )
                        self.applySession(session)
                        Logger.auth.info("[GoogleSignIn] Supabase session restored via Google ID token.")
                    } catch {
                        Logger.auth.warning("[GoogleSignIn] Supabase token restoration note: \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        }
    }

    // MARK: - Reactive auth state listener
    private func startAuthListener() async {
        guard let client else { return }
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession:
                // Local session from keychain — check expiry without network
                if let s = session, !s.isExpired {
                    applySession(s)
                } else {
                    clearSession()
                }
            case .signedIn, .tokenRefreshed, .userUpdated:
                if let s = session { applySession(s) }
            case .signedOut, .userDeleted:
                clearSession()
            default:
                break
            }
        }
    }

    private func applySession(_ session: Session) {
        currentUser = session.user
        isAuthenticated = true
        if let email = session.user.email { userEmail = email }
    }

    private func clearSession() {
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Saved Credentials Info
    var hasSavedCredentials: Bool {
        KeychainHelper.shared.readCredentials() != nil
    }

    var savedEmail: String? {
        KeychainHelper.shared.readCredentials()?.email
    }

    // Kept for biometric flow — reads cached session, does NOT do a network call
    // when emitLocalSessionAsInitialSession is enabled.
    func checkCurrentSession() async {
        guard let client else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { clearSession(); return }
            applySession(session)
        } catch {
            clearSession()
        }
    }

    // MARK: - Sign In
    func signIn(email: String, pass: String) async -> Bool {
        guard let client else {
            authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera."
            return false
        }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: email, password: pass)
            applySession(session)
            KeychainHelper.shared.saveCredentials(email: email, pass: pass)
            isBiometricsEnabled = true
            return true
        } catch {
            authErrorMessage = friendlyAuthError(from: error, isSignUp: false)
            return false
        }
    }

    // MARK: - Biometric Auth
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authErrorMessage = "Face ID / Biometria nie je dostupná alebo povolená na tomto zariadení."
            return false
        }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Prihlásiť sa do Ellegnote pomocou Face ID"
            )
            if success {
                await checkCurrentSession()
                if isAuthenticated { return true }
                
                // If local session expired or missing, retrieve saved credentials from Keychain
                if let creds = KeychainHelper.shared.readCredentials() {
                    guard let client else {
                        authErrorMessage = "Chyba spojenia: Chýba konfigurácia servera."
                        return false
                    }
                    do {
                        let session = try await client.auth.signIn(email: creds.email, password: creds.pass)
                        applySession(session)
                        return true
                    } catch {
                        authErrorMessage = "Uložené heslo expirovalo alebo bolo zmenené: \(friendlyAuthError(from: error, isSignUp: false))"
                        return false
                    }
                }
                
                authErrorMessage = "Na tomto zariadení zatiaľ nie sú uložené prihlasovacie údaje. Prihlás sa najprv e-mailom a heslom."
            }
        } catch {
            authErrorMessage = "Biometrické overenie zlyhalo alebo bolo zrušené."
        }
        return false
    }

    // MARK: - Sign Up
    func signUp(email: String, pass: String, name: String) async -> Bool {
        guard let client else {
            authErrorMessage = "Chyba spojenia: Chýba platná konfigurácia Supabase servera."
            return false
        }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: pass,
                data: ["name": .string(name)],
                redirectTo: URL(string: "ellegnote://auth-callback")
            )
            currentUser = response.user
            userEmail = email
            userName = name
            isAuthenticated = true
            KeychainHelper.shared.saveCredentials(email: email, pass: pass)
            isBiometricsEnabled = true
            return true
        } catch {
            authErrorMessage = friendlyAuthError(from: error, isSignUp: true)
            return false
        }
    }

    // MARK: - Friendly Error Translation
    private func friendlyAuthError(from error: Error, isSignUp: Bool) -> String {
        let desc = error.localizedDescription.lowercased()
        
        if desc.contains("invalid login credentials") || desc.contains("invalid_grant") || desc.contains("bad credentials") {
            return "Účet s týmto e-mailom a heslom neexistuje alebo je heslo nesprávne. Skontroluj údaje alebo sa najprv zaregistruj."
        }
        if desc.contains("user already registered") || desc.contains("already exists") || desc.contains("user_already_exists") {
            return "Účet s týmto e-mailom už existuje. Prejdi na záložku Prihlásenie."
        }
        if desc.contains("password should be at least") || desc.contains("weak_password") {
            return "Heslo musí mať aspoň 6 znakov."
        }
        if desc.contains("unable to validate email") || desc.contains("invalid email") || desc.contains("email address is invalid") {
            return "Zadaj platný formát e-mailovej adresy (napr. meno@domena.sk)."
        }
        if desc.contains("email not confirmed") || desc.contains("not confirmed") {
            return "Tvoj e-mail zatiaľ nebol potvrdený. Skontroluj si doručenú poštu alebo spam."
        }
        if desc.contains("offline") || desc.contains("network") || desc.contains("timed out") || desc.contains("connection lost") || desc.contains("could not connect") {
            return "Nepodarilo sa spojiť so serverom. Skontroluj internetové pripojenie."
        }
        if desc.contains("rate limit") || desc.contains("too many requests") {
            return "Príliš veľa pokusov za krátky čas. Počkaj prosím chvíľu a skús to znova."
        }
        
        if isSignUp {
            return "Registrácia zlyhala: \(error.localizedDescription)"
        } else {
            return "Prihlásenie zlyhalo: \(error.localizedDescription)"
        }
    }

    // MARK: - Native Google Sign In via GoogleSignIn SDK
    func signInWithGoogleNative(presenting rootViewController: UIViewController) async -> Bool {
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }
                
                if let error = error {
                    Logger.auth.error("[GoogleSignIn] Error: \(error.localizedDescription, privacy: .public)")
                    Task { @MainActor in
                        self.authErrorMessage = "Google prihlásenie: \(error.localizedDescription)"
                    }
                    continuation.resume(returning: false)
                    return
                }
                
                guard let user = signInResult?.user,
                      let idToken = user.idToken?.tokenString else {
                    Task { @MainActor in
                        self.authErrorMessage = "Nepodarilo sa získať Google token."
                    }
                    continuation.resume(returning: false)
                    return
                }
                
                let email = user.profile?.email ?? ""
                let name = user.profile?.name ?? "Tanečník"
                let sub = user.userID ?? ""
                let avatar = user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""

                Logger.auth.info("[GoogleSignIn] Successful sign-in for user: \(name, privacy: .private(mask: .hash))")
                
                Task {
                    if let client = self.client {
                        do {
                            let session = try await client.auth.signInWithIdToken(
                                credentials: .init(provider: .google, idToken: idToken)
                            )
                            await MainActor.run {
                                self.applySession(session)
                                self.userEmail = email
                                self.userName = name
                                self.googleSubId = sub
                                if !avatar.isEmpty {
                                    self.userAvatarURL = avatar
                                }
                                continuation.resume(returning: true)
                            }
                        } catch {
                            Logger.auth.error("[GoogleSignIn] Supabase token exchange error: \(error.localizedDescription, privacy: .public)")
                            await MainActor.run {
                                self.userEmail = email
                                self.userName = name
                                self.googleSubId = sub
                                if !avatar.isEmpty {
                                    self.userAvatarURL = avatar
                                }
                                self.isAuthenticated = true
                                continuation.resume(returning: true)
                            }
                        }
                    } else {
                        await MainActor.run {
                            self.userEmail = email
                            self.userName = name
                            self.googleSubId = sub
                            if !avatar.isEmpty {
                                self.userAvatarURL = avatar
                            }
                            self.isAuthenticated = true
                            continuation.resume(returning: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Google OAuth Sign In (Fallback)
    func signInWithGoogle() async -> Bool {
        guard let client else { return false }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let oauthURL = try client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "ellegnote://auth-callback")
            )
            await MainActor.run {
                UIApplication.shared.open(oauthURL)
            }
            return true
        } catch {
            authErrorMessage = "Prihlásenie cez Google zlyhalo: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Deep Link (email confirmation / OAuth callback)
    func handleDeepLink(_ url: URL) async {
        guard let client else { return }
        do {
            let session = try await client.auth.session(from: url)
            applySession(session)
        } catch {
            Logger.auth.error("[AuthManager] Deep link error: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Sign Out
    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        userAvatarURL = ""
        googleSubId = ""
        guard let client else {
            clearSession()
            return
        }
        try? await client.auth.signOut()
        KeychainHelper.shared.deleteCredentials()
        isBiometricsEnabled = false
        clearSession()
    }
}
