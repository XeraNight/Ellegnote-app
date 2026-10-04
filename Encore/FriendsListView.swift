import SwiftUI

// MARK: - Connections & Community View (Unified Partners, Coaches & Students)
struct FriendsListView: View {
    @ObservedObject private var connectionManager = ConnectionManager.shared
    @ObservedObject private var friendManager = FriendManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    enum ConnectionTab: String, CaseIterable, Identifiable {
        case partners = "Partneri"
        case coaches = "Tréneri"
        case students = "Zverenci"
        case requests = "Žiadosti"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .partners: return "figure.dance"
            case .coaches: return "graduationcap.fill"
            case .students: return "person.3.sequence.fill"
            case .requests: return "bell.badge.fill"
            }
        }
    }
    
    @State private var selectedTab: ConnectionTab = .partners
    @State private var searchText = ""
    @State private var showScanner = false
    @State private var showMyCard = false
    @State private var showAddConnectionSheet = false
    @State private var showPaywallSheet = false
    
    @State private var connectionToRevoke: DancerConnection? = nil
    @State private var showRevokeConfirmation = false
    @State private var selectedReportName: String? = nil
    @State private var showReportConfirmation = false
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            VStack(spacing: 0) {
                // 1. Top Action Bar
                topActionBar
                
                // 2. Segmented Navigation Tabs
                segmentedTabsSection
                
                // 3. Search Bar
                searchBarSection
                
                // 4. Content List for Selected Tab
                contentSection
            }
        }
        .navigationTitle("Tanečné Prepojenia")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddConnectionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Prepojiť")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LuxuryTheme.gold400)
                }
            }
        }
        .sheet(isPresented: $showMyCard) {
            myCardSheet
        }
        .sheet(isPresented: $showAddConnectionSheet) {
            AddConnectionSheetView()
        }
        .sheet(isPresented: $showPaywallSheet) {
            SubscriptionPaywallView(initialTier: .studio)
        }
        .qrScanner(isPresented: $showScanner) { scannedCode in
            handleScannedQRCode(scannedCode)
        }
        .confirmationDialog(
            "Zrušiť prepojenie?",
            isPresented: $showRevokeConfirmation,
            titleVisibility: .visible
        ) {
            if let conn = connectionToRevoke {
                Button("Zrušiť prepojenie s \(conn.otherUserName)", role: .destructive) {
                    Task {
                        try? await connectionManager.revokeConnection(connectionId: conn.id)
                        connectionToRevoke = nil
                    }
                }
            }
            Button("Zrušiť", role: .cancel) {
                connectionToRevoke = nil
            }
        } message: {
            Text("Používateľ stratí prístup k vašim spoločným choreografiám a poznámkam. Kedykoľvek sa môžete prepojiť znova.")
        }
        .alert("Podnet bol prijatý", isPresented: $showReportConfirmation) {
            Button("Rozumiem", role: .cancel) {}
        } message: {
            Text("Ďakujeme za nahlásenie. Tím administrátorov Encore preverí obsah do 24 hodín v súlade s pravidlami komunity.")
        }
        .task {
            await connectionManager.fetchAllConnections()
        }
    }
    
    // MARK: - 1. Top Action Bar
    private var topActionBar: some View {
        HStack(spacing: 12) {
            Button {
                showMyCard = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Moja Karta & ID")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [LuxuryTheme.gold500, LuxuryTheme.gold400],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                showScanner = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 13, weight: .bold))
                    Text("Skenovať QR")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(LuxuryTheme.gold300)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(LuxuryTheme.obsidian800)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LuxuryTheme.gold500.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
    
    // MARK: - 2. Segmented Tabs
    private var segmentedTabsSection: some View {
        HStack(spacing: 6) {
            ForEach(ConnectionTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .bold))
                        
                        if tab == .requests && !connectionManager.incomingRequests.isEmpty {
                            Text("\(connectionManager.incomingRequests.count)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.latinCrimson)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(isSelected ? LuxuryTheme.obsidian900 : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? LuxuryTheme.gold400 : Color.white.opacity(0.05))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(LuxuryTheme.obsidian800)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - 3. Search Bar
    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LuxuryTheme.gold400.opacity(0.7))
            
            TextField("", text: $searchText, prompt: Text("Filtrovať podľa mena, klubu alebo Dancer ID...").foregroundColor(Color.white.opacity(0.35)))
                .foregroundColor(.white)
                .font(.system(size: 13))
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LuxuryTheme.obsidian800)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LuxuryTheme.gold500.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - 4. Content Section
    @ViewBuilder
    private var contentSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                switch selectedTab {
                case .partners:
                    partnersTabContent
                case .coaches:
                    coachesTabContent
                case .students:
                    studentsTabContent
                case .requests:
                    requestsTabContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Partners Tab Content
    @ViewBuilder
    private var partnersTabContent: some View {
        let list = filtered(connections: connectionManager.activePartners)
        if list.isEmpty {
            emptyStateView(
                icon: "figure.dance",
                title: "Žiadny aktívny partner",
                subtitle: "Pripojte svojho tanečného partnera a synchronizujte si choreografie naživo v cloude.",
                actionTitle: "Pripojiť partnera",
                action: { showAddConnectionSheet = true }
            )
        } else {
            ForEach(list) { conn in
                connectionRow(conn: conn, badgeTitle: "Partner", badgeColor: LuxuryTheme.gold400)
            }
        }
    }
    
    // MARK: - Coaches Tab Content
    @ViewBuilder
    private var coachesTabContent: some View {
        let list = filtered(connections: connectionManager.activeCoaches)
        if list.isEmpty {
            emptyStateView(
                icon: "graduationcap.fill",
                title: "Žiaden pripojený tréner",
                subtitle: "Udeľte svojmu trénerovi prístup k vašim zostavám, aby vám mohol pomáhať s revíziou figúr a techniky.",
                actionTitle: "Pozvať trénera",
                action: { showAddConnectionSheet = true }
            )
        } else {
            ForEach(list) { conn in
                connectionRow(conn: conn, badgeTitle: "Tréner", badgeColor: Color.blue)
            }
        }
    }
    
    // MARK: - Students Tab Content (Gated for Studio Tier)
    @ViewBuilder
    private var studentsTabContent: some View {
        if !subscriptionManager.canAccessStudioRoster {
            // Upsell prompt to unlock Studio
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.gold500.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold400)
                }
                
                Text("Trénerský Roster Zverencov")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Správa viacerých párov, dohľad nad zostavami žiakov a sledovanie ich postupových bodov je súčasťou prémiového balíka Encore Studio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button {
                    showPaywallSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Prejsť na Encore Studio")
                        Image(systemName: "crown.fill")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(LuxuryTheme.obsidian900)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(LuxuryTheme.gold400)
                    .cornerRadius(12)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(LuxuryTheme.obsidian800)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1))
            .padding(.top, 16)
        } else {
            let list = filtered(connections: connectionManager.activeStudents)
            
            // Trénerské centrum / Roster banner
            NavigationLink {
                StudioCoachRosterView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(LuxuryTheme.obsidian900)
                        .frame(width: 36, height: 36)
                        .background(LuxuryTheme.gold400)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trénerský Roster & Zostavy")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Otvoriť kompletný prehľad zverencov a ich choreografií")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold400)
                }
                .padding(14)
                .background(LuxuryTheme.obsidian800)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
            
            if list.isEmpty {
                emptyStateView(
                    icon: "person.3.sequence.fill",
                    title: "Zatiaľ žiadni zverenci",
                    subtitle: "Pridajte svojich zverencov a páry z klubu cez ich Dancer ID pre dohľad nad ich zostavami.",
                    actionTitle: "Pridať zverenca",
                    action: { showAddConnectionSheet = true }
                )
            } else {
                ForEach(list) { conn in
                    connectionRow(conn: conn, badgeTitle: "Zverenec", badgeColor: Color.syncEmerald)
                }
            }
        }
    }
    
    // MARK: - Requests Tab Content
    @ViewBuilder
    private var requestsTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. Incoming Requests
            if !connectionManager.incomingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PRICHÁDZAJÚCE ŽIADOSTI (\(connectionManager.incomingRequests.count))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(LuxuryTheme.gold400)
                    
                    ForEach(connectionManager.incomingRequests) { req in
                        incomingRequestCard(req: req)
                    }
                }
            }
            
            // 2. Outgoing Requests
            if !connectionManager.outgoingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ČAKAJÚCE ODCHÁDZAJÚCE ŽIADOSTI (\(connectionManager.outgoingRequests.count))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                    
                    ForEach(connectionManager.outgoingRequests) { req in
                        outgoingRequestCard(req: req)
                    }
                }
            }
            
            if connectionManager.incomingRequests.isEmpty && connectionManager.outgoingRequests.isEmpty {
                emptyStateView(
                    icon: "tray.fill",
                    title: "Žiadne čakajúce žiadosti",
                    subtitle: "Keď vám niekto pošle žiadosť o prepojenie cez Dancer ID alebo QR kód, objaví sa tu.",
                    actionTitle: "Vyhľadať tanečníka",
                    action: { showAddConnectionSheet = true }
                )
            }
        }
    }
    
    // MARK: - Row Components
    private func connectionRow(conn: DancerConnection, badgeTitle: String, badgeColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: conn.relationshipType.badgeIcon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(badgeColor)
            }
            .overlay(Circle().stroke(badgeColor.opacity(0.4), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(conn.otherUserName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(badgeTitle)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.18))
                        .cornerRadius(5)
                }
                
                HStack(spacing: 6) {
                    if !conn.otherUserDancerCode.isEmpty {
                        Text(conn.otherUserDancerCode)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(LuxuryTheme.gold300)
                    }
                    if !conn.otherUserClub.isEmpty {
                        Text("• \(conn.otherUserClub)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button(role: .destructive) {
                    connectionToRevoke = conn
                    showRevokeConfirmation = true
                } label: {
                    Label("Zrušiť prepojenie", systemImage: "link.badge.slash")
                }
                
                Button(role: .destructive) {
                    selectedReportName = conn.otherUserName
                    showReportConfirmation = true
                } label: {
                    Label("Nahlásiť používateľa", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(LuxuryTheme.obsidian800)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LuxuryTheme.gold500.opacity(0.2), lineWidth: 1))
    }
    
    private func incomingRequestCard(req: DancerConnection) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: "envelope.badge.fill")
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(req.otherUserName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Chce sa prepojiť ako: \(req.relationshipType.title)")
                        .font(.system(size: 12))
                        .foregroundColor(LuxuryTheme.gold300)
                }
                
                Spacer()
            }
            
            HStack(spacing: 10) {
                Button {
                    Task { try? await connectionManager.acceptRequest(connectionId: req.id) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Prijať")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LuxuryTheme.obsidian900)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.syncEmerald)
                    .cornerRadius(8)
                }
                
                Button {
                    Task { try? await connectionManager.rejectRequest(connectionId: req.id) }
                } label: {
                    Text("Odmietnuť")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.latinCrimson)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.latinCrimson.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(LuxuryTheme.obsidian800)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.4), lineWidth: 1))
    }
    
    private func outgoingRequestCard(req: DancerConnection) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(req.otherUserName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Čaká na potvrdenie (\(req.relationshipType.title))")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button("Zrušiť") {
                Task { try? await connectionManager.revokeConnection(connectionId: req.id) }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
        }
        .padding(12)
        .background(LuxuryTheme.obsidian800.opacity(0.7))
        .cornerRadius(12)
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 38))
                .foregroundColor(LuxuryTheme.gold400.opacity(0.6))
                .padding(.top, 16)
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(actionTitle)
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(LuxuryTheme.gold400)
                .cornerRadius(10)
            }
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(LuxuryTheme.obsidian800.opacity(0.5))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LuxuryTheme.gold500.opacity(0.2), lineWidth: 1))
    }
    
    private func filtered(connections: [DancerConnection]) -> [DancerConnection] {
        let clean = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return connections }
        return connections.filter {
            $0.otherUserName.localizedCaseInsensitiveContains(clean) ||
            $0.otherUserClub.localizedCaseInsensitiveContains(clean) ||
            $0.otherUserDancerCode.localizedCaseInsensitiveContains(clean)
        }
    }
    
    // MARK: - My Card Modal Sheet
    private var myCardSheet: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Tvoja Digitálna Karta")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .padding(.top, 16)
                        
                        EncoreMemberCardView(
                            name: profileStore.currentName,
                            club: profileStore.currentClub,
                            userId: profileStore.activeUserId,
                            allowInteractiveTilt: true,
                            showActionButtons: true
                        )
                        
                        VStack(spacing: 8) {
                            Text("DANCER ID: \(profileStore.dancerCode)")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(LuxuryTheme.gold300)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(LuxuryTheme.gold500.opacity(0.18))
                                .cornerRadius(8)
                            
                            Text("Ťukni dvakrát na kartu pre zobrazenie druhej strany.\nIní tanečníci ťa môžu vyhľadať zadaním tvojho Dancer ID alebo naskenovaním QR kódu.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") { showMyCard = false }
                        .foregroundColor(LuxuryTheme.gold400)
                        .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
    
    private func handleScannedQRCode(_ code: String) {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.starts(with: "DNC-") {
            // Direct Dancer ID scanned!
            Task {
                try? await connectionManager.sendRequestByDancerCode(code: clean, type: .partner)
            }
        } else if let url = URL(string: clean) {
            _ = friendManager.handleIncomingURL(url)
        }
    }
}

// MARK: - Xcode Canvas Preview
#Preview("FriendsListView - Tanečné Prepojenia") {
    NavigationStack {
        FriendsListView()
    }
    .previewWithSampleData()
}
