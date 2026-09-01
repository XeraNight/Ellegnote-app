import SwiftUI
import LocalAuthentication
import GoogleSignIn
import GoogleSignInSwift

// MARK: - Warm Cream User Authentication View / Sheet
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
                EllegancePageBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Logo
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.obsidian800)
                                    .frame(width: 84, height: 84)
                                    .overlay(Circle().stroke(Color.gold400.opacity(0.35), lineWidth: 1.5))
                                    .shadow(color: Color.black.opacity(0.40), radius: 10, x: 0, y: 5)
                                
                                Image("EllegnoteLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                            }
                            
                            Text("ELLEGNOTE")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(.themeDark)
                                .tracking(1.5)
                            
                            Text(selectedTab == .signIn ? "Prihlásenie do tanečného účtu" : "Vytvorenie nového účtu")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.themeDark.opacity(0.65))
                        }
                        .padding(.top, 16)
                        
                        // Segmented Tab Switcher (Prihlásenie / Registrácia)
                        HStack(spacing: 0) {
                            ForEach(AuthTab.allCases, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedTab = tab
                                        authManager.authErrorMessage = nil
                                    }
                                }) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? .white : .themeDark)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedTab == tab ? Color.themeAccent : Color.clear)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.themeCard)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 24)
                        
                        // Google 1-Tap Sign In Button
                        Button(action: handleGoogleAuth) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.themeAccent)
                                Text(selectedTab == .signIn ? "Pokračovať cez Google" : "Zaregistrovať sa cez Google")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.themeCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
                        }
                        .padding(.horizontal, 24)
                        
                        // Face ID Fast Sign-In (Only visible on Sign In tab if credentials are saved)
                        if selectedTab == .signIn && authManager.hasSavedCredentials {
                            Button(action: handleFaceIDAuth) {
                                HStack(spacing: 8) {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 20))
                                        .foregroundColor(.themeDark)
                                    Text("Prihlásiť sa cez Face ID")
                                        .font(.system(size: 13, weight: .bold))
                                    if let saved = authManager.savedEmail, !saved.isEmpty {
                                        Text("(\(saved))")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.themeDark.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.themeCard)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.themeBorder)
                                .frame(height: 1)
                            Text("ALEBO E-MAILOM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.themeDark.opacity(0.5))
                                .tracking(1)
                            Rectangle()
                                .fill(Color.themeBorder)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                        
                        // Form Fields
                        VStack(spacing: 14) {
                            if selectedTab == .signUp {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("MENO / PREZÝVKA TANEČNÍKA")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.themeDark.opacity(0.7))
                                    TextField("Napr. Jakub, Niki, Tréner...", text: $nickname)
                                        .textContentType(.name)
                                        .autocorrectionDisabled()
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("E-MAIL")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white.opacity(0.70))
                                TextField("tvoj@email.com", text: $email)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.themeCard)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("HESLO \(selectedTab == .signUp ? "(min. 6 znakov)" : "")")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white.opacity(0.70))
                                SecureField("••••••••", text: $password)
                                    .textContentType(selectedTab == .signUp ? .newPassword : .password)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.themeCard)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                            }
                            
                            if let errorMsg = authManager.authErrorMessage {
                                VStack(spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.latinRed)
                                        Text(errorMsg)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.latinRed)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    // Quick Action shortcuts for intuitive flow
                                    if selectedTab == .signIn && (errorMsg.contains("neexistuje") || errorMsg.contains("zaregistruj")) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                selectedTab = .signUp
                                                authManager.authErrorMessage = nil
                                            }
                                        }) {
                                            Text("Prejsť na vytvorenie účtu (Registrácia) ➔")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color.latinRed)
                                                .cornerRadius(8)
                                        }
                                        .padding(.top, 2)
                                    } else if selectedTab == .signUp && errorMsg.contains("už existuje") {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                selectedTab = .signIn
                                                authManager.authErrorMessage = nil
                                            }
                                        }) {
                                            Text("Prejsť na Prihlásenie ➔")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color.latinRed)
                                                .cornerRadius(8)
                                        }
                                        .padding(.top, 2)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.latinRed.opacity(0.12))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.latinRed.opacity(0.4), lineWidth: 1.5))
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Submit Button
                        Button(action: handleAuthSubmit) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(selectedTab == .signUp ? "Vytvoriť Účet ➔" : "Prihlásiť Sa ➔")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .foregroundColor(canSubmit ? Color.obsidian900 : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                canSubmit
                                ? LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.obsidian700, Color.obsidian800], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(16)
                            .shadow(color: canSubmit ? Color.gold500.opacity(0.25) : Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
                        }
                        .disabled(!canSubmit || authManager.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zatvoriť") { dismiss() }
                            .foregroundColor(.themeDark)
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
    
    private func handleFaceIDAuth() {
        Task {
            let success = await authManager.authenticateWithBiometrics()
            if success && isSheet { dismiss() }
        }
    }
}
