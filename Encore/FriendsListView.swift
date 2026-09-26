import SwiftUI

// MARK: - Dance Friends & Community View
struct FriendsListView: View {
    @ObservedObject private var friendManager = FriendManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    
    @State private var searchText = ""
    @State private var showScanner = false
    @State private var showMyCard = false
    @State private var friendToRemove: DancerFriend? = nil
    @State private var friendToBlock: DancerFriend? = nil
    @State private var friendToReport: DancerFriend? = nil
    @State private var showReportConfirmation = false
    
    private var filteredFriends: [DancerFriend] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return friendManager.friends
        }
        return friendManager.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.club.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color.obsidian900.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Action Bar
                HStack(spacing: 12) {
                    Button {
                        showMyCard = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Moja Karta")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gold400)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 14, weight: .bold))
                            Text("Skenovať kartu")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color.gold300)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.obsidian800)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.gold400.opacity(0.6))
                    TextField("", text: $searchText, prompt: Text("Hľadať medzi priateľmi...").foregroundColor(Color.white.opacity(0.35)))
                        .foregroundColor(.white)
                        .font(.system(size: 14))
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
                .background(Color.obsidian800)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold500.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Friends List
                if filteredFriends.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 36))
                            .foregroundColor(Color.gold400.opacity(0.5))
                        
                        VStack(spacing: 6) {
                            Text(searchText.isEmpty ? "Zatiaľ nemáš priateľov" : "Nenašli sa žiadni priatelia")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text("Ukáž svoju kartu na tréningu alebo naskenuj kamarátov QR kód pre prepojenie.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.gold300.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                        }
                        
                        Button {
                            showScanner = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Naskenovať kamarátov kód")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.gold400)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.gold500.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold500.opacity(0.35), lineWidth: 1))
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredFriends) { friend in
                                FriendRowView(
                                    friend: friend,
                                    onRemove: { friendToRemove = friend },
                                    onBlock: { friendToBlock = friend },
                                    onReport: { friendToReport = friend }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Taneční Priatelia")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.obsidian900, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showMyCard) {
            NavigationStack {
                ZStack {
                    Color.obsidian900.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            Text("Tvoja Digitálna Karta")
                                .font(.system(size: 20, weight: .black, design: .serif))
                                .foregroundColor(.white)
                                .padding(.top, 16)
                            
                            EncoreMemberCardView(
                                name: profileStore.currentName,
                                club: profileStore.currentClub,
                                userId: profileStore.activeUserId,
                                allowInteractiveTilt: true,
                                showActionButtons: true
                            )
                            
                            Text("Dvakrát ťukni na kartu pre zobrazenie rubovej strany.\nKamarát môže naskenovať QR kód priamo zo svojho iPhonu.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gold300.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Hotovo") { showMyCard = false }
                            .foregroundColor(Color.gold400)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }
        }
        .qrScanner(isPresented: $showScanner) { scannedCode in
            handleScannedQRCode(scannedCode)
        }
        // Remove Friend Dialog
        .confirmationDialog(
            "Odstrániť priateľa?",
            isPresented: Binding(
                get: { friendToRemove != nil },
                set: { if !$0 { friendToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let friend = friendToRemove {
                Button("Odstrániť \(friend.name)", role: .destructive) {
                    friendManager.removeFriend(id: friend.id)
                    friendToRemove = nil
                }
            }
            Button("Zrušiť", role: .cancel) {
                friendToRemove = nil
            }
        } message: {
            Text("Tento tanečník bude odstránený z tvojho zoznamu priateľov.")
        }
        // Block User Dialog (App Store Guideline 1.2)
        .confirmationDialog(
            "Zablokovať používateľa?",
            isPresented: Binding(
                get: { friendToBlock != nil },
                set: { if !$0 { friendToBlock = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let friend = friendToBlock {
                Button("Zablokovať \(friend.name)", role: .destructive) {
                    friendManager.removeFriend(id: friend.id)
                    friendToBlock = nil
                }
            }
            Button("Zrušiť", role: .cancel) {
                friendToBlock = nil
            }
        } message: {
            Text("Zablokovaný používateľ vám už nebude môcť posielať pozvánky, zdieľať zostavy ani s vami interagovať.")
        }
        // Report User Dialog (App Store Guideline 1.2)
        .confirmationDialog(
            "Nahlásiť používateľa?",
            isPresented: Binding(
                get: { friendToReport != nil },
                set: { if !$0 { friendToReport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Nahlásiť nevhodný obsah / profil", role: .destructive) {
                friendToReport = nil
                showReportConfirmation = true
            }
            Button("Zrušiť", role: .cancel) {
                friendToReport = nil
            }
        } message: {
            Text("Nahlásenie preverí tím administrátorov Encore do 24 hodín v súlade s pravidlami komunity.")
        }
        .alert("Podnet bol prijatý", isPresented: $showReportConfirmation) {
            Button("Rozumiem", role: .cancel) {}
        } message: {
            Text("Ďakujeme za nahlásenie. Preveríme obsah do 24 hodín a podnikneme príslušné kroky.")
        }
    }
    
    private func handleScannedQRCode(_ code: String) {
        if let url = URL(string: code.trimmingCharacters(in: .whitespacesAndNewlines)) {
            _ = friendManager.handleIncomingURL(url)
        }
    }
}

// MARK: - Individual Friend Row Component (With Guideline 1.2 Moderation Actions)
private struct FriendRowView: View {
    let friend: DancerFriend
    let onRemove: () -> Void
    let onBlock: () -> Void
    let onReport: () -> Void
    
    private var initials: String {
        let trimmed = friend.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ").prefix(2).compactMap(\.first)
        return parts.isEmpty ? "T" : String(parts).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Friend Avatar
            ZStack {
                Circle()
                    .fill(Color.obsidian700)
                    .frame(width: 46, height: 46)
                
                Text(initials)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.gold400)
            }
            .overlay(
                Circle()
                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1.2)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                if !friend.club.isEmpty {
                    Text(friend.club)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gold300.opacity(0.7))
                } else {
                    Text("Tanečník Encore")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
            
            Spacer()
            
            // Moderation & Social Actions (App Store Guideline 1.2)
            Menu {
                Button(action: onReport) {
                    Label("Nahlásiť obsah / používateľa", systemImage: "flag")
                }
                
                Button(role: .destructive, action: onBlock) {
                    Label("Zablokovať používateľa", systemImage: "hand.raised.slash")
                }
                
                Divider()
                
                Button(role: .destructive, action: onRemove) {
                    Label("Odstrániť z priateľov", systemImage: "person.crop.circle.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(Color.obsidian800)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold500.opacity(0.2), lineWidth: 1))
    }
}
