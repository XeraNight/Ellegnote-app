import SwiftUI
import Supabase
import OSLog

// MARK: - Owner Admin Console (God-Mode Management for App Owner)
struct OwnerAdminConsoleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    enum AdminMode: String, CaseIterable {
        case directEmail = "Podľa e-mailu"
        case searchProfile = "Vyhľadať profil"
    }
    
    @State private var adminMode: AdminMode = .directEmail
    @State private var directEmail: String = ""
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [AdminUserSearchItem] = []
    @State private var selectedUser: AdminUserSearchItem? = nil
    
    // Grant Form States
    @State private var grantTier: SubscriptionTier = .premium
    @State private var grantDurationMonths: Int = 0 // 0 = Doživotne (Lifetime)
    @State private var grantNote: String = "VIP Darovanie od majiteľa"
    @State private var isActionInProgress: Bool = false
    @State private var statusAlertMessage: String? = nil
    @State private var showStatusAlert: Bool = false
    
    // Ban Form States
    @State private var showBanDialog: Bool = false
    @State private var banReasonText: String = "Porušenie pravidiel komunity"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Owner Status Card
                        ownerHeaderCard
                        
                        // 2. Mode Switcher
                        Picker("Režim administrácie", selection: $adminMode) {
                            ForEach(AdminMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // 3. Mode Content
                        if adminMode == .directEmail {
                            directEmailGrantSection
                        } else {
                            userSearchSection
                            
                            if let user = selectedUser {
                                userManagementCard(for: user)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Majiteľská Konzola")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") {
                        dismiss()
                    }
                    .foregroundColor(Color.gold400)
                }
            }
            .alert("Admin Oznam", isPresented: $showStatusAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusAlertMessage ?? "")
            }
        }
    }
    
    // MARK: - Owner Header Card
    private var ownerHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.gold500.opacity(0.18))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.gold400)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("SuperAdmin Prístup")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("MAJITEĽ")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gold400)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
                
                Text(authManager.userEmail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gold500.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Direct Email Grant Section
    private var directEmailGrantSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .foregroundColor(Color.gold400)
                    .font(.system(size: 16, weight: .bold))
                Text("Priame VIP udelenie cez E-mail")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text("Zadaj e-mail kamaráta, partnerky alebo trénera. Po potvrdení sa mu okamžite odomkne zvolený plán bez platenia.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 6) {
                Text("E-mail používateľa v Encore")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                
                TextField("napr. meno@domena.sk", text: $directEmail)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Úroveň predplatného")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                
                Picker("Plán", selection: $grantTier) {
                    Text("Premium (VIP)").tag(SubscriptionTier.premium)
                    Text("Plus").tag(SubscriptionTier.plus)
                    Text("Free (Zrušiť VIP)").tag(SubscriptionTier.free)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Trvanie prístupu")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                
                Picker("Trvanie", selection: $grantDurationMonths) {
                    Text("Doživotne").tag(0)
                    Text("1 Rok").tag(12)
                    Text("6 Mesiacov").tag(6)
                    Text("1 Mesiac").tag(1)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Interná poznámka")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                
                TextField("Poznámka (napr. Skúšobný účet / VIP kamarát)", text: $grantNote)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
            }

            Button {
                executeDirectEmailGrant()
            } label: {
                HStack(spacing: 8) {
                    if isActionInProgress {
                        ProgressView().tint(Color.black)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Udeliť VIP Prístup")
                    }
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    LinearGradient(
                        colors: [Color.gold400, Color.gold500],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isActionInProgress || directEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(directEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gold500.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - User Search Section
    private var userSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vyhľadať používateľa")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Zadaj meno, Dancer ID alebo e-mail...", text: $searchQuery)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        performSearch()
                    }
                
                if isSearching {
                    ProgressView()
                        .tint(Color.gold400)
                } else if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            
            // Search Results List
            if !searchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(searchResults) { item in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedUser = item
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 6) {
                                        if let code = item.dancerCode {
                                            Text(code)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(Color.amberGold)
                                        }
                                        if let club = item.club, !club.isEmpty {
                                            Text("• \(club)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if item.accountStatus == "banned" {
                                    Text("ZABLOKOVANÝ")
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.red.opacity(0.2))
                                        .foregroundColor(.red)
                                        .cornerRadius(6)
                                } else {
                                    Text(selectedUser?.id == item.id ? "Vybraný" : "Zvoliť")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.gold400)
                                }
                            }
                            .padding(12)
                            .background(selectedUser?.id == item.id ? Color.gold400.opacity(0.15) : Color.white.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
    }
    
    // MARK: - Selected User Management Card
    private func userManagementCard(for user: AdminUserSearchItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("ID: \(user.id.uuidString)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button {
                    selectedUser = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Divider().background(Color.white.opacity(0.15))
            
            // Tier Grant Controls
            VStack(alignment: .leading, spacing: 10) {
                Label("Udeliť prémiový prístup (Comped VIP)", systemImage: "gift.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.gold400)
                
                // Tier Picker
                Picker("Plán", selection: $grantTier) {
                    Text("Premium (€14.99)").tag(SubscriptionTier.premium)
                    Text("Plus (€5.99)").tag(SubscriptionTier.plus)
                    Text("Free (Zrušiť VIP)").tag(SubscriptionTier.free)
                }
                .pickerStyle(.segmented)
                
                // Duration Picker
                Picker("Trvanie", selection: $grantDurationMonths) {
                    Text("Doživotne").tag(0)
                    Text("1 Rok").tag(12)
                    Text("6 Mesiacov").tag(6)
                    Text("1 Mesiac").tag(1)
                }
                .pickerStyle(.segmented)
                
                // Notes
                TextField("Poznámka (napr. Partnerka, Tréner)", text: $grantNote)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                
                // Grant Button
                Button {
                    executeGrantEntitlement(for: user)
                } label: {
                    HStack {
                        if isActionInProgress {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Potvrdiť a udeliť prístup")
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.gold400)
                    .cornerRadius(12)
                }
                .disabled(isActionInProgress)
            }
            
            Divider().background(Color.white.opacity(0.15))
            
            // Ban / Moderation Controls
            VStack(alignment: .leading, spacing: 10) {
                Label("Bezpečnosť a Moderovanie účtu", systemImage: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
                
                if user.accountStatus == "banned" {
                    Button {
                        executeUnban(for: user)
                    } label: {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Odblokovať používateľa (Zrušiť BAN)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.6), lineWidth: 1))
                    }
                } else {
                    TextField("Dôvod zablokovania...", text: $banReasonText)
                        .font(.system(size: 13))
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                    
                    Button {
                        executeBan(for: user)
                    } label: {
                        HStack {
                            Image(systemName: "slash.circle.fill")
                            Text("Zablokovať účet (BAN)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gold500.opacity(0.4), lineWidth: 1))
    }
    
    // MARK: - Search Execution
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        
        Task {
            defer { isSearching = false }
            let client = SupabaseConfig.client
            
            do {
                struct SearchDTO: Decodable {
                    let id: UUID
                    let full_name: String?
                    let club: String?
                    let dancer_code: String?
                    let account_status: String?
                }
                
                let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                let res: [SearchDTO] = try await client
                    .from("profiles")
                    .select("id, full_name, club, dancer_code, account_status")
                    .or("full_name.ilike.%\(q)%,dancer_code.ilike.%\(q)%,club.ilike.%\(q)%")
                    .limit(10)
                    .execute()
                    .value
                
                self.searchResults = res.map {
                    AdminUserSearchItem(
                        id: $0.id,
                        name: $0.full_name ?? "Tanečník",
                        club: $0.club,
                        dancerCode: $0.dancer_code,
                        accountStatus: $0.account_status ?? "active"
                    )
                }
            } catch {
                Logger.general.error("Admin search failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Actions
    private func executeDirectEmailGrant() {
        let email = directEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        isActionInProgress = true
        
        Task {
            defer { isActionInProgress = false }
            do {
                let months = grantDurationMonths == 0 ? nil : grantDurationMonths
                let msg = try await subscriptionManager.grantEntitlementByEmailAsOwner(
                    targetEmail: email,
                    tier: grantTier,
                    durationMonths: months,
                    notes: grantNote
                )
                statusAlertMessage = msg
                showStatusAlert = true
                directEmail = ""
            } catch {
                statusAlertMessage = "Chyba: \(error.localizedDescription)"
                showStatusAlert = true
            }
        }
    }
    
    private func executeGrantEntitlement(for user: AdminUserSearchItem) {
        isActionInProgress = true
        Task {
            defer { isActionInProgress = false }
            do {
                let months = grantDurationMonths == 0 ? nil : grantDurationMonths
                try await subscriptionManager.grantEntitlementAsOwner(
                    targetUserId: user.id,
                    tier: grantTier,
                    durationMonths: months,
                    notes: grantNote
                )
                statusAlertMessage = "Úspešne udelený plán \(grantTier.rawValue) pre \(user.name)!"
                showStatusAlert = true
            } catch {
                statusAlertMessage = "Chyba pri udeľovaní prístupu: \(error.localizedDescription)"
                showStatusAlert = true
            }
        }
    }
    
    private func executeBan(for user: AdminUserSearchItem) {
        isActionInProgress = true
        Task {
            defer { isActionInProgress = false }
            do {
                try await subscriptionManager.setAccountBanStatusAsOwner(
                    targetUserId: user.id,
                    isBanned: true,
                    reason: banReasonText
                )
                statusAlertMessage = "Účet používateľa \(user.name) bol úspešne ZABLOKOVANÝ."
                showStatusAlert = true
                performSearch()
            } catch {
                statusAlertMessage = "Chyba pri blokovaní účtu: \(error.localizedDescription)"
                showStatusAlert = true
            }
        }
    }
    
    private func executeUnban(for user: AdminUserSearchItem) {
        isActionInProgress = true
        Task {
            defer { isActionInProgress = false }
            do {
                try await subscriptionManager.setAccountBanStatusAsOwner(
                    targetUserId: user.id,
                    isBanned: false,
                    reason: ""
                )
                statusAlertMessage = "Účet používateľa \(user.name) bol ODBLOKOVANÝ."
                showStatusAlert = true
                performSearch()
            } catch {
                statusAlertMessage = "Chyba: \(error.localizedDescription)"
                showStatusAlert = true
            }
        }
    }
}

// MARK: - Admin User Search Item
struct AdminUserSearchItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let club: String?
    let dancerCode: String?
    var accountStatus: String
}
