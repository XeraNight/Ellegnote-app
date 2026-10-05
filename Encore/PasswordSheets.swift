import SwiftUI

// MARK: - Shared field style (matches AuthSheetView inputs)
private struct AuthFieldChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
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
}

private extension View {
    func authFieldChrome() -> some View { modifier(AuthFieldChrome()) }
}

private struct SheetBanner: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 13))
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(isError ? .latinRed : .gold400)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isError ? Color.latinRed : Color.gold500).opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke((isError ? Color.latinRed : Color.gold500).opacity(0.45), lineWidth: 1)
        )
    }
}

private struct PrimarySheetButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView().tint(Color.gold400)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isEnabled ? Color.gold400 : Color.white.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.obsidian900)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? Color.gold500 : Color.white.opacity(0.15), lineWidth: 2)
            )
            .shadow(color: isEnabled ? Color.gold500.opacity(0.3) : .clear, radius: 10)
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Forgot Password (from the login screen)
struct ForgotPasswordSheet: View {
    var prefillEmail: String = ""

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var email = ""
    @State private var isSending = false
    @State private var errorText: String?
    @State private var didSend = false

    private var canSend: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }

                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.gold400)
                        .padding(.top, 8)

                    Text("Obnova hesla")
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundColor(.gold400)

                    Text("Zadaj e-mail, s ktorým si sa zaregistroval. Pošleme ti odkaz na nastavenie nového hesla. Odkaz otvor na tomto iPhone.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("", text: $email, prompt: Text("Email Address").foregroundColor(Color.gold300.opacity(0.45)))
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authFieldChrome()
                        .disabled(didSend)

                    if let errorText {
                        SheetBanner(text: errorText, isError: true)
                    }

                    if didSend {
                        SheetBanner(
                            text: "Ak k tomuto e-mailu existuje účet, odkaz je na ceste. Skontroluj aj spam. Odkaz platí približne hodinu.",
                            isError: false
                        )
                        PrimarySheetButton(title: "Hotovo", isLoading: false, isEnabled: true) { dismiss() }
                    } else {
                        PrimarySheetButton(title: "Poslať odkaz", isLoading: isSending, isEnabled: canSend) {
                            send()
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { dismiss() }
                        .foregroundColor(.gold400)
                }
            }
            .onAppear {
                if email.isEmpty { email = prefillEmail }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private func send() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        errorText = nil
        isSending = true
        Task {
            let error = await authManager.sendPasswordReset(email: email)
            isSending = false
            if let error {
                errorText = error
            } else {
                didSend = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Change / Set Password
/// `.change`   – signed-in e-mail user changes the password from Profile (current password required).
/// `.recovery` – user opened a password-recovery link and chooses a new password.
struct PasswordUpdateSheet: View {
    enum Mode { case change, recovery }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var isSaving = false
    @State private var errorText: String?
    @State private var didSucceed = false

    private var mismatch: Bool { !confirm.isEmpty && confirm != newPassword }

    private var canSubmit: Bool {
        newPassword.count >= 6 && newPassword == confirm && (mode == .recovery || !current.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.gold400)
                            .padding(.top, 8)

                        Text(mode == .recovery ? "Nové heslo" : "Zmena hesla")
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(.gold400)

                        Text(mode == .recovery
                             ? "Odkaz je overený. Zvoľ si nové heslo pre svoj účet."
                             : "Pre bezpečnosť najprv zadaj súčasné heslo.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 14) {
                            if mode == .change {
                                SecureField("", text: $current, prompt: Text("Súčasné heslo").foregroundColor(Color.gold300.opacity(0.45)))
                                    .textContentType(.password)
                                    .authFieldChrome()
                            }

                            SecureField("", text: $newPassword, prompt: Text("Nové heslo (min. 6 znakov)").foregroundColor(Color.gold300.opacity(0.45)))
                                .textContentType(.newPassword)
                                .authFieldChrome()

                            SecureField("", text: $confirm, prompt: Text("Zopakuj nové heslo").foregroundColor(Color.gold300.opacity(0.45)))
                                .textContentType(.newPassword)
                                .authFieldChrome()
                        }
                        .disabled(didSucceed)

                        if mismatch {
                            Text("Heslá sa nezhodujú.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.latinRed)
                        }

                        if let errorText {
                            SheetBanner(text: errorText, isError: true)
                        }

                        if didSucceed {
                            SheetBanner(text: "Heslo bolo úspešne zmenené.", isError: false)
                        } else {
                            PrimarySheetButton(
                                title: "Uložiť nové heslo",
                                isLoading: isSaving,
                                isEnabled: canSubmit
                            ) { save() }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode == .recovery ? "Preskočiť" : "Zavrieť") { dismiss() }
                        .foregroundColor(.gold400)
                        .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isSaving)
        .preferredColorScheme(.dark)
    }

    private func save() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        errorText = nil
        isSaving = true
        Task {
            let error: String?
            switch mode {
            case .change:
                error = await authManager.changePassword(current: current, new: newPassword)
            case .recovery:
                error = await authManager.setNewPassword(newPassword)
            }
            isSaving = false
            if let error {
                errorText = error
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                didSucceed = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                try? await Task.sleep(for: .milliseconds(1300))
                dismiss()
            }
        }
    }
}

#Preview("PasswordUpdateSheet") {
    PasswordUpdateSheet(mode: .change)
}

#Preview("ForgotPasswordSheet") {
    ForgotPasswordSheet(prefillEmail: "meno@domena.sk")
}
