import Foundation
import Supabase
import SwiftUI
import Combine

// MARK: - Supabase User Auth Manager
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authErrorMessage: String? = nil
    
    @AppStorage("profileName") var userName: String = "Jakub"
    @AppStorage("userEmail") var userEmail: String = ""
    
    private var client: SupabaseClient? {
        guard let url = SupabaseConfig.url, let key = SupabaseConfig.anonKey else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
    
    private init() {
        Task {
            await checkCurrentSession()
        }
    }
    
    /// Checks if a valid session exists in Supabase Local Store
    func checkCurrentSession() async {
        guard let client = client else { return }
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            if let email = session.user.email {
                self.userEmail = email
            }
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    /// Sign in with Email and Password
    func signIn(email: String, pass: String) async -> Bool {
        guard let client = client else { return false }
        self.isLoading = true
        self.authErrorMessage = nil
        
        do {
            let session = try await client.auth.signIn(email: email, password: pass)
            self.currentUser = session.user
            self.userEmail = email
            self.isAuthenticated = true
            self.isLoading = false
            return true
        } catch {
            self.authErrorMessage = "Prihlásenie zlyhalo: \(error.localizedDescription)"
            self.isLoading = false
            return false
        }
    }
    
    /// Register new user account
    func signUp(email: String, pass: String, name: String) async -> Bool {
        guard let client = client else { return false }
        self.isLoading = true
        self.authErrorMessage = nil
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: pass,
                data: ["name": .string(name)]
            )
            self.currentUser = response.user
            self.userEmail = email
            self.userName = name
            self.isAuthenticated = true
            self.isLoading = false
            return true
        } catch {
            self.authErrorMessage = "Registrácia zlyhala: \(error.localizedDescription)"
            self.isLoading = false
            return false
        }
    }
    
    /// Sign Out
    func signOut() async {
        guard let client = client else { return }
        try? await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
