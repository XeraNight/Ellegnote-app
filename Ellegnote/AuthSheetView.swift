import SwiftUI

// MARK: - Warm Cream User Authentication Sheet (Supabase Auth)
struct AuthSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header Logo
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.themeCard)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(.themeAccent)
                            )
                            .neubrutalistCard(cornerRadius: 36, shadowOffset: 3)
                        
                        Text(isSignUp ? "VYTVORIŤ TANEČNÝ ÚČET" : "PRIHLÁSENIE DO ELLEGNOTE")
                            .font(.system(size: 20, weight: .black, design: .serif))
                            .foregroundColor(.themeDark)
                            .tracking(1)
                        
                        Text("Prepojenie partnera a trénera v reálnom čase")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeDark.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MENO / PREZÝVKA TANEČNÍKA")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.themeDark.opacity(0.6))
                                TextField("Napr. Jakub, Niki, Tréner...", text: $nickname)
                                    .padding(12)
                                    .background(Color.themeCard)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 1.5))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-MAIL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.themeDark.opacity(0.6))
                            TextField("tvoj@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(Color.themeCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 1.5))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HESLO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.themeDark.opacity(0.6))
                            SecureField("••••••••", text: $password)
                                .padding(12)
                                .background(Color.themeCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 1.5))
                        }
                        
                        if let errorMsg = authManager.authErrorMessage {
                            Text(errorMsg)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.latinRed)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Submit Button
                    Button(action: handleAuthSubmit) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Vytvoriť Účet ➔" : "Prihlásiť Sa ➔")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themeAccent)
                        .cornerRadius(16)
                        .shadow(color: Color.themeDark.opacity(0.15), radius: 0, x: 2, y: 3)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)
                    
                    // Mode Toggle (Sign In <-> Sign Up)
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Už máš účet? Prihlás sa" : "Nemáš účet? Zaregistruj sa")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeDark.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zatvoriť") { dismiss() }
                        .foregroundColor(.themeDark)
                }
            }
        }
    }
    
    private func handleAuthSubmit() {
        Task {
            if isSignUp {
                let success = await authManager.signUp(email: email, pass: password, name: nickname)
                if success { dismiss() }
            } else {
                let success = await authManager.signIn(email: email, pass: password)
                if success { dismiss() }
            }
        }
    }
}
