import SwiftUI

// MARK: - Competition Tracker & Diary View (KSIS)
public struct CompetitionTrackerView: View {
    @StateObject private var manager = CompetitionManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDisciplineFilter: String = "Všetko"
    @State private var showImportSheet: Bool = false
    @State private var showCoupleSheet: Bool = false
    @State private var showArchivedSheet: Bool = false
    @State private var resultToDelete: CompetitionResult? = nil
    @State private var showDeleteConfirmation: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            EllegancePageBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Couple Header Card
                    coupleSelectorHeaderCard

                    // 2. Class Advancement Progress Card
                    advancementCard

                    // 3. Action Buttons & Filter Bar
                    actionAndFilterSection

                    // 4. Results Diary List
                    resultsListSection

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
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
        }
    }

    // MARK: - 1. Couple Selector Header Card
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

                    Text("Prepojte svoje KSIS ID páru (zo stránky szts.ksis.eu/par.php) pre sledovanie postupov a oficiálny denník.")
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
                // Active couple bar with switcher if 2 couples exist
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LuxuryTheme.gold500.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(LuxuryTheme.gold400)
                    }
                    .overlay(Circle().stroke(LuxuryTheme.gold500.opacity(0.35), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(manager.activeCouple?.displayTitle ?? "Tanečný Pár")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)

                        Text("KSIS Pár ID: \(manager.activeCouple?.coupleId ?? 0) • \(manager.activeCouple?.discipline ?? "STT/LAT")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gold300.opacity(0.7))
                    }

                    Spacer()

                    if manager.couples.count > 1 {
                        Menu {
                            ForEach(manager.couples) { c in
                                Button {
                                    manager.activeCouple = c
                                } label: {
                                    HStack {
                                        Text(c.displayTitle)
                                        if manager.activeCouple?.coupleId == c.coupleId {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(LuxuryTheme.gold400)
                                .padding(8)
                                .background(LuxuryTheme.obsidian700)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(16)
                .background(LuxuryTheme.obsidian800.opacity(0.9))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - 2. Class Advancement Progress Card
    @ViewBuilder
    private var advancementCard: some View {
        let adv = manager.computeAdvancement(
            for: manager.activeCouple?.coupleId,
            discipline: selectedDisciplineFilter == "Všetko" ? nil : selectedDisciplineFilter
        )

        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("STAV POSTUPU V TRIEDE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(LuxuryTheme.gold400)

                    Text(adv.ruleName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                if adv.isAdvancementEarned {
                    Text("SPLNENÉ 🎉")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(LuxuryTheme.obsidian900)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LuxuryTheme.gold400)
                        .cornerRadius(8)
                } else {
                    Text("EŠTE \(adv.pointsNeeded) B")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold300)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LuxuryTheme.obsidian700)
                        .cornerRadius(8)
                }
            }

            Divider().background(Color.gold500.opacity(0.15))

            // Points Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Body na postup")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))

                    Spacer()

                    Text("\(adv.currentPoints) / \(adv.requiredPoints) b")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(adv.currentPoints >= adv.requiredPoints ? Color.syncEmerald : LuxuryTheme.gold400)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LuxuryTheme.obsidian700)
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [LuxuryTheme.gold500, LuxuryTheme.gold300],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(adv.pointsProgress)), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Finals Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Počet finálových umiestnení")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))

                    Spacer()

                    Text("\(adv.currentFinals) / \(adv.requiredFinals) finále")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(adv.currentFinals >= adv.requiredFinals ? Color.syncEmerald : LuxuryTheme.gold400)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LuxuryTheme.obsidian700)
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.syncEmerald, Color(red: 52/255, green: 211/255, blue: 153/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(adv.finalsProgress)), height: 8)
                    }
                }
                .frame(height: 8)
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
            .padding(.top, 4)
        }
        .padding(18)
        .background(LuxuryTheme.obsidian800.opacity(0.95))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [LuxuryTheme.gold500.opacity(0.4), LuxuryTheme.gold400.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 4)
    }

    // MARK: - 3. Action and Filter Section
    @ViewBuilder
    private var actionAndFilterSection: some View {
        VStack(spacing: 12) {
            // Primary Import CTA
            Button {
                showImportSheet = true
            } label: {
                HStack(spacing: 8) {
                    if manager.cooldownRemaining > 0 {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("KSIS Cooldown (\(manager.cooldownRemaining)s)")
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Importovať Výsledok zo Súťaže")
                    }
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(manager.cooldownRemaining > 0 ? Color.white.opacity(0.6) : LuxuryTheme.obsidian900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    manager.cooldownRemaining > 0
                        ? LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian800], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LuxuryTheme.gold400.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: LuxuryTheme.gold500.opacity(0.2), radius: 8, x: 0, y: 3)
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedDisciplineFilter == discipline ? LuxuryTheme.obsidian900 : Color.white.opacity(0.8))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedDisciplineFilter == discipline
                                    ? LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian800], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
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
                            Text("Archív (\(manager.archivedResults.count))")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(LuxuryTheme.gold300.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 4. Results List Section
    @ViewBuilder
    private var resultsListSection: some View {
        let filteredResults = manager.results.filter { r in
            if let active = manager.activeCouple, r.coupleId != active.coupleId {
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
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color.white.opacity(0.5))

                Spacer()

                Text("\(filteredResults.count) záznamov")
                    .font(.system(size: 12, weight: .medium))
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

                    Text("Vložte odkaz na súťaž (sutaz.php?sutaz_id=...) a výsledky sa automaticky naimportujú z oficiálneho KSIS protokolu.")
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
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.eventName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text(result.categoryName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LuxuryTheme.gold400)
                }

                Spacer()

                // Placement Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.displayPlacement)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(result.isFinalPlacement ? LuxuryTheme.obsidian900 : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            result.isFinalPlacement
                                ? LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian700], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)

                    if let total = result.coupleCount {
                        Text("z \(total) párov")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                // Date & City
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                    Text(result.formattedDate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    if let place = result.place, !place.isEmpty {
                        Text("• \(place)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }

                Spacer()

                // Points & Cumulative Stats
                if let pts = result.pointsEarned {
                    Text("+\(pts) b")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold400)
                }

                if let stats = result.cumulativeStats {
                    Text("Stav: \(stats)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.syncEmerald)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.syncEmerald.opacity(0.12))
                        .cornerRadius(6)
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(.leading, 6)
                }
            }
        }
        .padding(14)
        .background(LuxuryTheme.obsidian800.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - KSIS Import Sheet
public struct KSISImportSheet: View {
    @StateObject private var manager = CompetitionManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputUrlOrId: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var localError: String? = nil
    @State private var showConflictRestoreAlert: Bool = false
    @State private var conflictResultIdToRestore: String? = nil

    public init() {}

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

                            Text("Vložte URL odkaz na stránku súťaže z KSIS alebo jej číselné ID.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // Input Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ODKAZ ALEBO ID SÚŤAŽE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(LuxuryTheme.gold400)

                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(LuxuryTheme.gold400)
                                TextField("napr. 12094 alebo szts.ksis.eu/sutaz.php?sutaz_id=12094", text: $inputUrlOrId)
                                    .keyboardType(.URL)
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

                            if let couple = manager.activeCouple {
                                Text("Importujete pre pár: #\(couple.coupleId) (\(couple.discipline))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(LuxuryTheme.gold300.opacity(0.8))
                            } else {
                                Text("⚠️ Najprv prepojte tanečný pár v nastaveniach denníka.")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.latinCrimson)
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
                                    Text(isAnalyzing ? "Overujem na KSIS..." : "Načítať Náhľad z KSIS")
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
                            .disabled(isAnalyzing || inputUrlOrId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.activeCouple == nil)
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
                                    Text("Oficiálne potvrdený výsledok KSIS")
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
            localError = "Neplatné ID alebo URL súťaže. Vložte napr. 12094 alebo celú adresu."
            return
        }
        guard let coupleId = manager.activeCouple?.coupleId else {
            localError = "Vyberte aktívny tanečný pár pred importom."
            return
        }

        localError = nil
        isAnalyzing = true

        Task {
            do {
                _ = try await manager.previewResult(sutazId: sutazId, coupleId: coupleId)
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
        guard let sutazId = manager.previewResult?.sutazId,
              let coupleId = manager.previewResult?.coupleId else { return }

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
    @Environment(\.dismiss) private var dismiss

    @State private var inputCoupleUrlOrId: String = ""
    @State private var partnerName: String = ""
    @State private var selectedDiscipline: String = "STT"
    @State private var partnerConsent: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

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
                                Text("PREPOJENÉ PÁRY (MAX 2)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(LuxuryTheme.gold400)

                                ForEach(manager.couples) { couple in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(couple.displayTitle)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("KSIS ID: \(couple.coupleId) • \(couple.discipline)")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.white.opacity(0.6))
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            Task {
                                                try? await manager.removeCouple(coupleId: couple.coupleId)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(Color.latinCrimson)
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

                        // Section 2: Pridať nový pár
                        if manager.couples.count < 2 {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("PRIDAŤ KSIS PÁR")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(LuxuryTheme.gold400)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Odkaz alebo ID páru z KSIS")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    TextField("napr. 18978 alebo szts.ksis.eu/par.php?id=18978", text: $inputCoupleUrlOrId)
                                        .keyboardType(.URL)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(LuxuryTheme.obsidian700)
                                        .cornerRadius(10)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Meno partnera / partnerky")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    TextField("napr. Nikoletta Kissová", text: $partnerName)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(LuxuryTheme.obsidian700)
                                        .cornerRadius(10)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Disciplína")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.8))

                                    Picker("Disciplína", selection: $selectedDiscipline) {
                                        Text("Štandard (STT)").tag("STT")
                                        Text("Latina (LAT)").tag("LAT")
                                        Text("10 Tancov (10T)").tag("10T")
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
                                        Text(isSaving ? "Ukladám..." : "Prepojiť Pár")
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
                        } else {
                            Text("Dosiahli ste maximálny povolený počet prepojených párov (2). Ak chcete pridať iný, najprv jeden odstráňte.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.horizontal, 10)
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
        }
    }

    private func saveCouple() {
        guard let coupleId = CompetitionManager.extractCoupleId(from: inputCoupleUrlOrId) else {
            errorMessage = "Neplatné KSIS ID páru. Vložte napr. 18978 alebo odkaz."
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
