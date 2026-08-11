import Foundation
import Supabase
import SwiftUI
import LocalAuthentication

// MARK: - Supabase Auth Manager
// Uses authStateChanges reactive stream — never does a blocking network call on startup.
// This is the standard pattern used in production Supabase apps.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authErrorMessage: String? = nil

    @AppStorage("profileName") var userName: String = "Jakub"
    @AppStorage("userEmail")   var userEmail: String = ""
    @AppStorage("isBiometricsEnabled") var isBiometricsEnabled: Bool = false

    private let client: SupabaseClient?

    private init() {
        if let url = SupabaseConfig.url, let key = SupabaseConfig.anonKey {
            // emitLocalSessionAsInitialSession: true → emits cached local session
            // immediately without a network round-trip, stopping the 9999ms timeout loop.
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key,
                options: SupabaseClientOptions(
                    auth: .init(emitLocalSessionAsInitialSession: true)
                )
            )
        } else {
            self.client = nil
        }

        // Start listening to auth state changes reactively.
        // Does NOT block — the first event (.initialSession) fires from local keychain
        // without any network call.
        Task { await startAuthListener() }
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
        guard let client else { return false }
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: email, password: pass)
            applySession(session)
            return true
        } catch {
            authErrorMessage = "Prihlásenie zlyhalo: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Biometric Auth
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authErrorMessage = "Face ID / Biometria nie je dostupná."
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
                authErrorMessage = "Relácia vypršala. Prihlás sa prosím heslom."
            }
        } catch {
            authErrorMessage = "Biometrické overenie zlyhalo."
        }
        return false
    }

    // MARK: - Sign Up
    func signUp(email: String, pass: String, name: String) async -> Bool {
        guard let client else { return false }
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
            return true
        } catch {
            authErrorMessage = "Registrácia zlyhala: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Deep Link (email confirmation)
    func handleDeepLink(_ url: URL) async {
        guard let client else { return }
        do {
            let session = try await client.auth.session(from: url)
            applySession(session)
        } catch {
            print("[AuthManager] Deep link error: \(error)")
        }
    }

    // MARK: - Sign Out
    func signOut() async {
        guard let client else { return }
        try? await client.auth.signOut()
        clearSession()
    }
}
