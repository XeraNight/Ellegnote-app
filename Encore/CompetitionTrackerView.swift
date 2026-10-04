import SwiftUI

// MARK: - Competition Tracker & Diary View (KSIS)
public struct CompetitionTrackerView: View {
    @StateObject private var manager = CompetitionManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDisciplineFilter: String = "Všetko"
    @State private var advancementDiscipline: String = "STT"
    @State private var showImportSheet: Bool = false
    @State private var showCoupleSheet: Bool = false
    @State private var showArchivedSheet: Bool = false
    @State private var resultToDelete: CompetitionResult? = nil
    @State private var showDeleteConfirmation: Bool = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywallSheet: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            EllegancePageBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 0. Prominent Membership & Tier Status Bar
                    membershipStatusHeader

                    // 1. Couple Header Card
                    coupleSelectorHeaderCard

                    // 2. Class Advancement Progress Card (Gated for Plus/Studio)
                    if !subscriptionManager.canTrackOwnPoints {
                        freeTierPaywallCard
                    } else {
                        advancementCard
                    }

                    // 3. Action Buttons & Filter Bar
                    actionAndFilterSection

                    // 4. Results Diary List
                    resultsListSection

                    // Official Data Attribution (Fair Use & Legal Transparency)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(LuxuryTheme.gold400.opacity(0.7))
                        Text("Zdroj dát: ksis.eu • Oficiálne výsledky a postupové body eviduje Slovenský zväz tanečného športu (SZTŠ)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                    // Generous bottom clearance so floating dock never obscures cards
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Súťažný Denník")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCoupleSheet = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold400)
                }
            }
        }
        .sheet(isPresented: $showImportSheet) {
            KSISImportSheet()
        }
        .sheet(isPresented: $showCoupleSheet) {
            KSISCoupleManagementSheet()
        }
        .sheet(isPresented: $showArchivedSheet) {
            KSISArchivedResultsSheet()
        }
        .sheet(isPresented: $showPaywallSheet) {
            SubscriptionPaywallView(initialTier: .plus)
        }
        .confirmationDialog(
            "Naozaj archivovať tento výsledok?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archivovať", role: .destructive) {
                if let r = resultToDelete {
                    Task {
                        try? await manager.softDeleteResult(resultId: r.id)
                    }
                }
            }
            Button("Zrušiť", role: .cancel) {
                resultToDelete = nil
            }
        } message: {
            Text("Výsledok sa presunie do archívu a body nebudú započítavané do postupu. Kedykoľvek ho môžete obnoviť.")
        }
        .task {
            await manager.loadAllData()
            if let active = manager.activeCouple {
                if active.discipline == "LAT" {
                    advancementDiscipline = "LAT"
                } else {
                    advancementDiscipline = "STT"
                }
            }
        }
    }

    // MARK: - 0. Prominent Membership & Tier Status Header
    @ViewBuilder
    private var membershipStatusHeader: some View {
        Button {
            showPaywallSheet = true
        } label: {
            HStack(spacing: 10) {
                // Tier Icon Disc
                ZStack {
                    Circle()
                        .fill(
                            subscriptionManager.currentTier == .studio
                                ? LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : (subscriptionManager.currentTier == .plus
                                    ? LinearGradient(colors: [Color.amberGold, LuxuryTheme.gold400], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: subscriptionManager.currentTier.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(subscriptionManager.currentTier == .free ? .white : LuxuryTheme.obsidian900)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(
                            subscriptionManager.currentTier == .studio
                                ? "ENCORE STUDIO"
                                : (subscriptionManager.currentTier == .plus ? "ENCORE PLUS" : "ENCORE FREE")
                        )
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(subscriptionManager.currentTier == .free ? .white.opacity(0.9) : LuxuryTheme.gold300)

                        if subscriptionManager.isAppOwner {
                            Text("DEVELOPER")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundColor(LuxuryTheme.obsidian900)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(LuxuryTheme.gold400)
                                .clipShape(Capsule())
                        } else if subscriptionManager.entitlementSource == .ownerGrant {
                            Text("VIP")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundColor(LuxuryTheme.obsidian900)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.syncEmerald)
                                .clipShape(Capsule())
                        }
                    }

                    Text(
                        subscriptionManager.currentTier == .studio
                            ? "Plný prístup • KSIS Radar súperov, Roster a Posture duel"
                            : (subscriptionManager.currentTier == .plus
                                ? "Odomknuté • Sledovanie bodov & Apple Kalendár súťaží"
                                : "Základný denník • Ťuknite pre odomknutie postupových bodov")
                    )
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))
                    .lineLimit(1)
                }

                Spacer()

                // Action Tag
                HStack(spacing: 3) {
                    Text(subscriptionManager.currentTier == .free ? "UPGRADE" : "VÝHODY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(subscriptionManager.currentTier == .free ? LuxuryTheme.gold400 : Color.white.opacity(0.65))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LuxuryTheme.obsidian800.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        subscriptionManager.currentTier == .free
                            ? Color.white.opacity(0.12)
                            : LuxuryTheme.gold500.opacity(0.35),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1. Couple Selector Header Card (Obsidian & Gold)
    @ViewBuilder
    private var coupleSelectorHeaderCard: some View {
        VStack(spacing: 12) {
            if manager.couples.isEmpty {
                // Empty state - Prompt to link couple
                VStack(spacing: 12) {
                    Image(systemName: "figure.dance")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(LuxuryTheme.gold400)

                    Text("Žiadny prepojený tanečný pár")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("Prepojte svoje KSIS ID páru (napr. 18978 zo szts.ksis.eu/par.php) pre automatické načítanie výsledkov a sledovanie postupov.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)

                    Button {
                        showCoupleSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "link.badge.plus")
                            Text("Prepojiť KSIS Pár")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(LuxuryTheme.obsidian900)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(LuxuryTheme.obsidian800.opacity(0.9))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1.2)
                )
            } else {
                // Active couple card with names, badges and switcher
                let couple = manager.activeCouple ?? manager.couples.first!
                let coupleTitle = couple.fullCoupleTitle(myUserName: profileStore.currentName)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LuxuryTheme.gold500.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(LuxuryTheme.gold400)
                        }
                        .overlay(Circle().stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(coupleTitle)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            HStack(spacing: 6) {
                                Text("Pár #\(couple.coupleId)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(LuxuryTheme.gold300)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(LuxuryTheme.gold500.opacity(0.12))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 0.8))

                                if couple.isAllDisciplines {
                                    Text("STT")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 147/255, green: 197/255, blue: 253/255))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(Color.standardBlue.opacity(0.30))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.standardBlue.opacity(0.4), lineWidth: 0.8))

                                    Text("LAT")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 253/255, green: 164/255, blue: 175/255))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(Color.latinCrimson.opacity(0.30))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.latinCrimson.opacity(0.4), lineWidth: 0.8))
                                } else {
                                    Text(couple.discipline)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(LuxuryTheme.obsidian700)
                                        .clipShape(Capsule())
                                }

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.syncEmerald)
                                        .frame(width: 5, height: 5)
                                    Text("Prepojený pár")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.syncEmerald)
                                }
                            }
                        }

                        Spacer()

                        // Manage or Switch Button
                        Button {
                            showCoupleSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(LuxuryTheme.gold400)
                                .padding(9)
                                .background(LuxuryTheme.obsidian700)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1))
                        }
                    }

                    if manager.couples.count > 1 {
                        Divider().background(Color.white.opacity(0.08))

                        HStack {
                            Text("Prepnúť pár:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.6))

                            Spacer()

                            ForEach(manager.couples) { c in
                                Button {
                                    manager.activeCouple = c
                                } label: {
                                    Text("#\(c.coupleId) (\(c.discipline))")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(manager.activeCouple?.coupleId == c.coupleId ? LuxuryTheme.obsidian900 : Color.white.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            manager.activeCouple?.coupleId == c.coupleId
                                                ? LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian700], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .background(LuxuryTheme.obsidian800.opacity(0.92))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LuxuryTheme.gold500.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
            }
        }
    }

    // MARK: - 2. Class Advancement Progress Card
    @ViewBuilder
    private var freeTierPaywallCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LuxuryTheme.gold500.opacity(0.18))
                    .frame(width: 50, height: 50)
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(LuxuryTheme.gold400)
            }
            
            Text("Sledovanie bodov & postupov")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            Text("Sledujte svoje body, finálové umiestnenia a postupové triedy zo súťaží ksis.eu priamo vo vašom denníku. Táto funkcia je súčasťou predplatného Encore Plus.")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            
            Button {
                showPaywallSheet = true
            } label: {
                HStack(spacing: 6) {
                    Text("Odomknúť Encore Plus")
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(LuxuryTheme.obsidian800.opacity(0.9))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1.2)
        )
    }

    @ViewBuilder
    private var advancementCard: some View {
        let couple = manager.activeCouple ?? manager.couples.first
        let adv = manager.computeAdvancement(
            for: couple?.coupleId,
            discipline: advancementDiscipline
        )

        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("STAV POSTUPU V TRIEDE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(LuxuryTheme.gold400)

                    Text(adv.ruleName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if adv.isAdvancementEarned {
                    Text("SPLNENÉ 🎉")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(LuxuryTheme.obsidian900)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(LuxuryTheme.gold400)
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Text("EŠTE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                        Text("\(adv.pointsNeeded) B")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(LuxuryTheme.gold300)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(LuxuryTheme.obsidian700)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(LuxuryTheme.gold400.opacity(0.25), lineWidth: 0.8))
                }
            }

            // Sleek Unified Segmented Control (STT vs LAT) - No Emojis
            HStack(spacing: 0) {
                Button {
                    advancementDiscipline = "STT"
                } label: {
                    Text("Štandard (STT)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(advancementDiscipline == "STT" ? LuxuryTheme.obsidian900 : Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            advancementDiscipline == "STT"
                                ? LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    advancementDiscipline = "LAT"
                } label: {
                    Text("Latina (LAT)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(advancementDiscipline == "LAT" ? LuxuryTheme.obsidian900 : Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            advancementDiscipline == "LAT"
                                ? LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(3)
            .background(Color.black.opacity(0.35))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))

            Divider().background(Color.white.opacity(0.08))

            // Points Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Body na postup (\(advancementDiscipline))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.75))

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(adv.currentPoints)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(adv.currentPoints >= adv.requiredPoints ? Color.syncEmerald : LuxuryTheme.gold300)
                        Text("/ \(adv.requiredPoints) b")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [LuxuryTheme.gold500, LuxuryTheme.gold300],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(7, geo.size.width * CGFloat(min(1.0, adv.pointsProgress))), height: 7)
                            .shadow(color: LuxuryTheme.gold500.opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 7)
            }

            // Finals Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Finálové umiestnenia (\(advancementDiscipline))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.75))

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(adv.currentFinals)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(Color.syncEmerald)
                        Text("/ \(adv.requiredFinals) finále")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                        if adv.currentFinals >= adv.requiredFinals {
                            Text("✓")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.syncEmerald)
                        }
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.syncEmerald, Color(red: 52/255, green: 211/255, blue: 153/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(7, geo.size.width * CGFloat(min(1.0, adv.finalsProgress))), height: 7)
                            .shadow(color: Color.syncEmerald.opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 7)
            }

            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
                Text("Zdroj stavu: Oficiálny KSIS kumulatívny register SZTŠ")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.5))
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(LuxuryTheme.obsidian800.opacity(0.92))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [LuxuryTheme.gold500.opacity(0.35), LuxuryTheme.gold400.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    // MARK: - 3. Action and Filter Section
    @ViewBuilder
    private var actionAndFilterSection: some View {
        VStack(spacing: 12) {
            // Primary Import CTA - Satin Champagne & Obsidian
            Button {
                showImportSheet = true
            } label: {
                HStack(spacing: 8) {
                    if manager.cooldownRemaining > 0 {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .bold))
                        Text("KSIS Cooldown (\(manager.cooldownRemaining)s)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Importovať Výsledok zo Súťaže")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(manager.cooldownRemaining > 0 ? Color.white.opacity(0.5) : LuxuryTheme.obsidian900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    manager.cooldownRemaining > 0
                        ? LinearGradient(colors: [LuxuryTheme.obsidian800, LuxuryTheme.obsidian700], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            manager.cooldownRemaining > 0
                                ? Color.white.opacity(0.1)
                                : LuxuryTheme.gold300.opacity(0.6),
                            lineWidth: 1
                        )
                )
                .shadow(color: manager.cooldownRemaining > 0 ? Color.clear : LuxuryTheme.gold500.opacity(0.22), radius: 10, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(manager.cooldownRemaining > 0)

            // Filter Pills & Archive Link
            HStack(spacing: 8) {
                ForEach(["Všetko", "STT", "LAT"], id: \.self) { discipline in
                    Button {
                        selectedDisciplineFilter = discipline
                    } label: {
                        Text(discipline)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(selectedDisciplineFilter == discipline ? LuxuryTheme.obsidian900 : Color.white.opacity(0.75))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedDisciplineFilter == discipline
                                    ? LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    selectedDisciplineFilter == discipline
                                        ? LuxuryTheme.gold300.opacity(0.5)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 0.8
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if !manager.archivedResults.isEmpty {
                    Button {
                        showArchivedSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 11))
                            Text("Archív (\(manager.archivedResults.count))")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(LuxuryTheme.gold300.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 4. Results List Section
    @ViewBuilder
    private var resultsListSection: some View {
        let activeCoupleId = manager.activeCouple?.coupleId ?? manager.couples.first?.coupleId
        let filteredResults = manager.results.filter { r in
            if let activeId = activeCoupleId, r.coupleId != activeId {
                return false
            }
            if selectedDisciplineFilter != "Všetko" && r.discipline.uppercased() != selectedDisciplineFilter.uppercased() {
                return false
            }
            return true
        }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HISTÓRIA VÝSLEDKOV")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(Color.white.opacity(0.5))

                Spacer()

                Text("\(filteredResults.count) záznamov")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            if filteredResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.top, 20)

                    Text("Žiadne zaznamenané výsledky")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Vložte odkaz alebo číslo súťaže (napr. 12094) a výsledky sa automaticky naimportujú z oficiálneho KSIS protokolu.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(LuxuryTheme.obsidian800.opacity(0.6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                ForEach(filteredResults) { result in
                    CompetitionResultRowView(result: result) {
                        resultToDelete = result
                        showDeleteConfirmation = true
                    }
                }
            }
        }
    }
}

// MARK: - Competition Result Row View
public struct CompetitionResultRowView: View {
    public let result: CompetitionResult
    public let onDelete: () -> Void

    public init(result: CompetitionResult, onDelete: @escaping () -> Void) {
        self.result = result
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.eventName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(result.categoryName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(LuxuryTheme.gold300)
                    }
                }

                Spacer()

                // Placement Badge
                placementBadgeView
            }

            Divider().background(Color.white.opacity(0.06))

            HStack {
                // Date & City
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.4))
                    Text(result.formattedDate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.55))
                    if let place = result.place, !place.isEmpty {
                        Text("• \(place)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Points & Cumulative Stats
                if let pts = result.pointsEarned {
                    Text("+\(pts) b")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(LuxuryTheme.gold300)
                }

                if let stats = result.cumulativeStats {
                    Text("Stav: \(stats)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.syncEmerald)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.syncEmerald.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.syncEmerald.opacity(0.3), lineWidth: 0.8))
                }

                // Delete Menu
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Archivovať výsledok", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.45))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LuxuryTheme.obsidian800.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var isTopThree: Bool {
        guard let p = result.placement else { return false }
        return result.isFinalPlacement && p <= 3
    }

    private func placementMedalColor(placement: Int?) -> Color {
        guard let p = placement else { return LuxuryTheme.gold300 }
        switch p {
        case 1:
            return LuxuryTheme.gold300
        case 2:
            return Color(red: 220/255, green: 220/255, blue: 230/255)
        default:
            return Color(red: 205/255, green: 127/255, blue: 50/255)
        }
    }

    @ViewBuilder
    private var placementBadgeBackground: some View {
        if result.isFinalPlacement {
            if let p = result.placement, p <= 3 {
                LinearGradient(
                    colors: [LuxuryTheme.gold400, LuxuryTheme.gold500],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.syncEmerald, Color.syncEmerald.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var placementBadgeView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 3) {
                if isTopThree {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(placementMedalColor(placement: result.placement))
                }
                Text(result.displayPlacement)
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundColor(result.isFinalPlacement ? LuxuryTheme.obsidian900 : .white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(placementBadgeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(result.isFinalPlacement ? LuxuryTheme.gold300.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.8)
            )

            if let total = result.coupleCount {
                Text("z \(total) párov")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))
            }
        }
    }
}

// MARK: - KSIS Import Sheet
public struct KSISImportSheet: View {
    @StateObject private var manager = CompetitionManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputUrlOrId: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var localError: String? = nil
    @State private var showConflictRestoreAlert: Bool = false
    @State private var conflictResultIdToRestore: String? = nil
    @State private var showCoupleSheet: Bool = false

    public init() {}

    private var targetCouple: UserCouple? {
        manager.activeCouple ?? manager.couples.first
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Text("Import Výsledku zo Súťaže")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("Zadajte číslo súťaže (napr. 12094) alebo vložte celý URL odkaz z KSIS.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // Input Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ČÍSLO ALEBO ODKAZ SÚŤAŽE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(LuxuryTheme.gold400)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(LuxuryTheme.gold400)
                                TextField("napr. 12094 alebo szts.ksis.eu/sutaz.php?sutaz_id=12094", text: $inputUrlOrId)
                                    .keyboardType(.numbersAndPunctuation)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))

                                if !inputUrlOrId.isEmpty {
                                    Button {
                                        inputUrlOrId = ""
                                        manager.previewResult = nil
                                        localError = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.white.opacity(0.4))
                                    }
                                }
                            }
                            .padding(14)
                            .background(LuxuryTheme.obsidian700)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1)
                            )

                            // Couple indicator banner
                            if let couple = targetCouple {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(LuxuryTheme.gold400)

                                    Text("Import pre: \(couple.fullCoupleTitle(myUserName: profileStore.currentName)) (#\(couple.coupleId))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(LuxuryTheme.gold300)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(10)
                                .background(LuxuryTheme.obsidian900.opacity(0.5))
                                .cornerRadius(8)
                            } else {
                                HStack {
                                    Text("⚠️ Nemáte prepojený tanečný pár.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.latinCrimson)

                                    Spacer()

                                    Button("Prepojiť pár") {
                                        showCoupleSheet = true
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(LuxuryTheme.gold400)
                                }
                                .padding(10)
                                .background(Color.latinCrimson.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .background(LuxuryTheme.obsidian800.opacity(0.9))
                        .cornerRadius(16)

                        // Action Button (Preview)
                        if manager.previewResult == nil {
                            Button {
                                analyzeCompetition()
                            } label: {
                                HStack(spacing: 8) {
                                    if isAnalyzing {
                                        ProgressView().tint(LuxuryTheme.obsidian900)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(isAnalyzing ? "Vyhľadávam výsledok na KSIS..." : "Vyhľadať a Načítať Náhľad")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(LuxuryTheme.obsidian900)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                            }
                            .disabled(isAnalyzing || inputUrlOrId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        // Preview Card (when loaded)
                        if let preview = manager.previewResult {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("NÁHĽAD VÝSLEDKU (KSIS)")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(LuxuryTheme.gold400)

                                        Text(preview.eventName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Text(preview.displayPlacement)
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(LuxuryTheme.obsidian900)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(LuxuryTheme.gold400)
                                        .cornerRadius(8)
                                }

                                Divider().background(Color.white.opacity(0.1))

                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Kategória:")
                                            .foregroundColor(Color.white.opacity(0.6))
                                        Spacer()
                                        Text(preview.categoryName)
                                            .foregroundColor(.white).bold()
                                    }
                                    HStack {
                                        Text("Dátum a miesto:")
                                            .foregroundColor(Color.white.opacity(0.6))
                                        Spacer()
                                        Text("\(preview.formattedDate) \(preview.place != nil ? "• " + preview.place! : "")")
                                            .foregroundColor(.white)
                                    }
                                    HStack {
                                        Text("Počet zúčastnených párov:")
                                            .foregroundColor(Color.white.opacity(0.6))
                                        Spacer()
                                        Text("\(preview.coupleCount ?? 0) párov")
                                            .foregroundColor(.white)
                                    }
                                    HStack {
                                        Text("Získané body:")
                                            .foregroundColor(Color.white.opacity(0.6))
                                        Spacer()
                                        Text("+\(preview.pointsEarned ?? 0) b")
                                            .foregroundColor(LuxuryTheme.gold400).bold()
                                    }
                                    if let stats = preview.cumulativeStats {
                                        HStack {
                                            Text("Nový kumulatívny stav:")
                                                .foregroundColor(Color.white.opacity(0.6))
                                            Spacer()
                                            Text(stats)
                                                .foregroundColor(Color.syncEmerald).bold()
                                        }
                                    }
                                }
                                .font(.system(size: 13))

                                // Official Verification Banner
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(Color.syncEmerald)
                                    Text("Oficiálne overený výsledok KSIS")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.syncEmerald)
                                }
                                .padding(.top, 4)

                                // Confirm Import Button
                                Button {
                                    confirmImport()
                                } label: {
                                    HStack(spacing: 8) {
                                        if manager.isImporting {
                                            ProgressView().tint(LuxuryTheme.obsidian900)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                        Text(manager.isImporting ? "Ukladám do denníka..." : "Potvrdiť a Uložiť do Denníka")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(LuxuryTheme.obsidian900)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(14)
                                }
                                .disabled(manager.isImporting)
                            }
                            .padding(18)
                            .background(LuxuryTheme.obsidian800)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(LuxuryTheme.gold500.opacity(0.4), lineWidth: 1.2)
                            )
                        }

                        // Error message
                        if let err = localError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.latinCrimson)
                                Text(err)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.latinCrimson.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.latinCrimson.opacity(0.4), lineWidth: 1)
                            )
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Nový Výsledok")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zatvoriť") {
                        manager.previewResult = nil
                        dismiss()
                    }
                    .foregroundColor(LuxuryTheme.gold400)
                }
            }
            .sheet(isPresented: $showCoupleSheet) {
                KSISCoupleManagementSheet()
            }
            .alert("Výsledok bol nájdený v archíve", isPresented: $showConflictRestoreAlert) {
                Button("Obnoviť výsledok") {
                    if let idStr = conflictResultIdToRestore, let uuid = UUID(uuidString: idStr) {
                        Task {
                            try? await manager.restoreResult(resultId: uuid)
                            dismiss()
                        }
                    }
                }
                Button("Zrušiť", role: .cancel) {}
            } message: {
                Text("Tento výsledok už máte v denníku, ale bol archivovaný. Chcete ho obnoviť späť do aktívnych výsledkov?")
            }
        }
    }

    private func analyzeCompetition() {
        guard let sutazId = CompetitionManager.extractSutazId(from: inputUrlOrId) else {
            localError = "Neplatné číslo alebo URL súťaže. Zadajte napríklad 12094."
            return
        }

        // Verify that user has a couple selected/linked
        guard let couple = targetCouple, couple.coupleId > 0 else {
            localError = "Pred vyhľadaním súťaže si najprv prepojte váš tanečný pár (kliknite na 'Prepojiť pár')."
            showCoupleSheet = true
            return
        }

        localError = nil
        isAnalyzing = true

        Task {
            do {
                _ = try await manager.previewResult(sutazId: sutazId, coupleId: couple.coupleId)
                isAnalyzing = false
            } catch {
                isAnalyzing = false
                if let conflict = manager.conflictRestorePayload {
                    conflictResultIdToRestore = conflict.resultId
                    showConflictRestoreAlert = true
                } else {
                    localError = error.localizedDescription
                }
            }
        }
    }

    private func confirmImport() {
        guard let sutazId = manager.previewResult?.sutazId else { return }
        let coupleId = manager.previewResult?.coupleId

        Task {
            do {
                _ = try await manager.confirmImport(sutazId: sutazId, coupleId: coupleId)
                dismiss()
            } catch {
                if let conflict = manager.conflictRestorePayload {
                    conflictResultIdToRestore = conflict.resultId
                    showConflictRestoreAlert = true
                } else {
                    localError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - KSIS Couple Management Sheet
public struct KSISCoupleManagementSheet: View {
    @StateObject private var manager = CompetitionManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputCoupleUrlOrId: String = ""
    @State private var partnerName: String = ""
    @State private var selectedDiscipline: String = "ALL" // Default: Štandard aj Latina
    @State private var partnerConsent: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywallSheet: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Prepojené páry
                        if !manager.couples.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AKTUÁLNE PREPOJENÉ PÁRY")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(LuxuryTheme.gold400)

                                ForEach(manager.couples) { couple in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(couple.fullCoupleTitle(myUserName: profileStore.currentName))
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)

                                            HStack(spacing: 6) {
                                                Text("KSIS ID: \(couple.coupleId)")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(LuxuryTheme.gold300)

                                                Text("• \(couple.disciplineTitle)")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(Color.white.opacity(0.7))
                                            }
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            Task {
                                                try? await manager.removeCouple(coupleId: couple.coupleId)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(Color.latinCrimson)
                                                .padding(8)
                                                .background(Color.latinCrimson.opacity(0.15))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(14)
                                    .background(LuxuryTheme.obsidian700)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(16)
                            .background(LuxuryTheme.obsidian800)
                            .cornerRadius(16)
                        }

                        // Section 2: Pridať alebo Aktualizovať pár
                        if manager.couples.count >= 1 && !subscriptionManager.canTrackRosterPoints {
                            // Studio Tier Upsell Card for Roster & Tracking other couples
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "building.columns.fill")
                                        .foregroundColor(LuxuryTheme.gold400)
                                    Text("Sledovanie viacerých párov & zverencov")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Text("V balíku Encore Plus môžete sledovať 1 svoj vlastný tanečný pár. Sledovanie celého rosteru zverencov v klube alebo sledovanie priateľov je súčasťou prémiového balíka Encore Studio.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.75))
                                
                                Button {
                                    showPaywallSheet = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Prejsť na Encore Studio")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(LuxuryTheme.obsidian900)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(LuxuryTheme.gold400)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(16)
                            .background(LuxuryTheme.obsidian800)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(LuxuryTheme.gold500.opacity(0.35), lineWidth: 1))
                        } else if manager.couples.count < 2 || !manager.couples.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(manager.couples.isEmpty ? "PREPOJIŤ KSIS PÁR" : "PRIDAŤ ALEBO UPRAVIŤ PÁR")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(LuxuryTheme.gold400)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Číslo alebo odkaz na pár z KSIS")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    TextField("napr. 18978 alebo szts.ksis.eu/par.php?id=18978", text: $inputCoupleUrlOrId)
                                        .keyboardType(.numbersAndPunctuation)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(LuxuryTheme.obsidian700)
                                        .cornerRadius(10)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Meno tanečného partnera / partnerky")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    TextField("napr. Nikoletta Kissová", text: $partnerName)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(LuxuryTheme.obsidian700)
                                        .cornerRadius(10)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tanečná disciplína")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    Picker("Disciplína", selection: $selectedDiscipline) {
                                        Text("ŠTT aj LAT (Obe)").tag("ALL")
                                        Text("Štandard (STT)").tag("STT")
                                        Text("Latina (LAT)").tag("LAT")
                                        Text("10 Tancov").tag("10T")
                                    }
                                    .pickerStyle(.segmented)
                                }

                                // GDPR & Partner Consent Checkbox
                                Toggle(isOn: $partnerConsent) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Súhlas partnera so spracovaním údajov")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Potvrdzujem, že partner(ka) súhlasí so spracovaním súťažných údajov pre účely tohto denníka.")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(Color.white.opacity(0.65))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: LuxuryTheme.gold500))
                                .padding(.vertical, 4)

                                // Add Button
                                Button {
                                    saveCouple()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isSaving {
                                            ProgressView().tint(LuxuryTheme.obsidian900)
                                        }
                                        Text(isSaving ? "Ukladám..." : "Uložiť a Prepojiť Pár")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(LuxuryTheme.obsidian900)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        partnerConsent && !inputCoupleUrlOrId.isEmpty
                                            ? LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian700], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(12)
                                }
                                .disabled(!partnerConsent || inputCoupleUrlOrId.isEmpty || isSaving)
                            }
                            .padding(16)
                            .background(LuxuryTheme.obsidian800)
                            .cornerRadius(16)
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.latinCrimson)
                                .padding(10)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tanečné Páry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") {
                        dismiss()
                    }
                    .foregroundColor(LuxuryTheme.gold400)
                }
            }
            .onAppear {
                if let existing = manager.activeCouple ?? manager.couples.first {
                    inputCoupleUrlOrId = "\(existing.coupleId)"
                    partnerName = existing.partnerName ?? ""
                    selectedDiscipline = existing.discipline
                    partnerConsent = existing.partnerConsent
                }
            }
            .sheet(isPresented: $showPaywallSheet) {
                SubscriptionPaywallView(initialTier: .studio)
            }
        }
    }

    private func saveCouple() {
        guard let coupleId = CompetitionManager.extractCoupleId(from: inputCoupleUrlOrId) else {
            errorMessage = "Neplatné KSIS ID páru. Vložte napríklad 18978."
            return
        }

        errorMessage = nil
        isSaving = true

        Task {
            do {
                try await manager.addCouple(
                    coupleId: coupleId,
                    discipline: selectedDiscipline,
                    partnerName: partnerName.trimmingCharacters(in: .whitespacesAndNewlines),
                    partnerConsent: partnerConsent
                )
                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - KSIS Archived Results Sheet
public struct KSISArchivedResultsSheet: View {
    @StateObject private var manager = CompetitionManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Archivované Výsledky")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 10)

                        Text("Tieto výsledky boli vymazané z aktívneho denníka a nezapočítavajú sa do postupu. Môžete ich kedykoľvek obnoviť.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        ForEach(manager.archivedResults) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.eventName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(item.categoryName) • \(item.displayPlacement)")
                                        .font(.system(size: 12))
                                        .foregroundColor(LuxuryTheme.gold300.opacity(0.8))
                                }

                                Spacer()

                                Button {
                                    Task {
                                        try? await manager.restoreResult(resultId: item.id)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.uturn.backward")
                                        Text("Obnoviť")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(LuxuryTheme.obsidian900)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(LuxuryTheme.gold400)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(14)
                            .background(LuxuryTheme.obsidian800)
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Archív")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") {
                        dismiss()
                    }
                    .foregroundColor(LuxuryTheme.gold400)
                }
            }
        }
    }
}
