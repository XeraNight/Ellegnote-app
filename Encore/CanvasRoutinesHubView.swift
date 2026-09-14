import SwiftUI
import SwiftData

// MARK: - Canvas Routines Hub View (Výber mojich zostáv pre Tab 1 "Canvas")
public struct CanvasRoutinesHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.updatedAt, order: .reverse) private var routines: [Routine]
    
    @State private var searchText: String = ""
    @State private var selectedCategoryFilter: String = "Všetky"
    @State private var selectedRoutineForCanvas: Routine? = nil
    
    @State private var showNewRoutineSheet: Bool = false
    @State private var routineForQRExport: Routine? = nil
    @State private var qrCodeImage: UIImage? = nil
    @State private var showQRModal: Bool = false
    
    private let categories = ["Všetky", "Standard", "Latina"]
    
    private var filteredRoutines: [Routine] {
        routines.filter { routine in
            let matchesCategory: Bool
            if selectedCategoryFilter == "Všetky" {
                matchesCategory = true
            } else if selectedCategoryFilter == "Standard" {
                matchesCategory = routine.danceCategory.lowercased() == "standard"
            } else {
                matchesCategory = routine.danceCategory.lowercased() == "latin" || routine.danceCategory.lowercased() == "latina"
            }
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if query.isEmpty {
                return matchesCategory
            }
            
            let matchesName = routine.name.lowercased().contains(query)
            let matchesDance = routine.danceName.lowercased().contains(query)
            return matchesCategory && (matchesName || matchesDance)
        }
    }
    
    private var totalFiguresCount: Int {
        routines.reduce(0) { $0 + $1.canvasNodes.count }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let screenWidth = geo.size.width
                let horizontalMargin = max(screenWidth * 0.08, 22)
                
                ZStack {
                    EllegancePageBackground()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            // ── 1. Top Luxury Header ──
                            topHeaderBar
                                .padding(.top, max(geo.safeAreaInsets.top, 54))
                            
                            // ── 2. Search & Category Filters ──
                            searchAndFiltersBar
                                .padding(.top, 2)
                            
                            // ── 3. Routines List / Empty State ──
                            if filteredRoutines.isEmpty {
                                emptyStateView
                                    .padding(.top, 30)
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(filteredRoutines) { routine in
                                        routineCardView(for: routine)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            // Spacing above bottom dock
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(.horizontal, horizontalMargin)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .frame(width: screenWidth, height: geo.size.height)
            }
            .navigationDestination(item: $selectedRoutineForCanvas) { routine in
                RoutineCanvasView(routine: routine, isPresentedInTab: true)
            }
            .sheet(isPresented: $showNewRoutineSheet) {
                NavigationStack {
                    DanceCategorySelectionSheet(isPresented: $showNewRoutineSheet)
                }
            }
            .sheet(isPresented: $showQRModal) {
                if let routine = routineForQRExport {
                    QRExportSheet(routine: routine, qrImage: qrCodeImage)
                }
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CHOREOGRAFIE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(LuxuryTheme.gold400)
                    .tracking(1.4)
                
                Text("Moje Zostavy")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            
            Spacer(minLength: 8)
            
            // "+ Nová zostava" Liquid Glass CTA Button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                showNewRoutineSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Nová zostava")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [LuxuryTheme.gold400, LuxuryTheme.gold500],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: LuxuryTheme.gold500.opacity(0.35), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
    }
    
    // MARK: - Search & Category Filters
    private var searchAndFiltersBar: some View {
        VStack(spacing: 12) {
            // Search Input
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(LuxuryTheme.gold400)
                
                TextField("Hľadať zostavu alebo tanec...", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.4))
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LuxuryTheme.obsidian800.opacity(0.75))
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            
            // Category Filter Pills & Stats
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = selectedCategoryFilter == cat
                    let catIcon: String? = {
                        if cat.lowercased() == "standard" { return "drop.fill" }
                        if cat.lowercased() == "latin" || cat.lowercased() == "latina" { return "flame.fill" }
                        return nil
                    }()
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedCategoryFilter = cat
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if let icon = catIcon {
                                Image(systemName: icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isSelected ? LuxuryTheme.obsidian900 : (cat.lowercased() == "standard" ? LuxuryTheme.standardBlue : LuxuryTheme.latinCrimson))
                            }
                            Text(cat)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? LuxuryTheme.obsidian900 : Color.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected
                            ? AnyView(
                                LinearGradient(
                                    colors: [LuxuryTheme.gold400, LuxuryTheme.gold500],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyView(
                                ZStack {
                                    Capsule().fill(LuxuryTheme.obsidian800.opacity(0.6))
                                    Capsule().fill(.ultraThinMaterial)
                                }
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 4)
                
                // Figures Count Badge
                if totalFiguresCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 9))
                            .foregroundColor(LuxuryTheme.gold400)
                        Text("\(routines.count) zos. • \(totalFiguresCount) fig.")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    // MARK: - Routine Card View
    private func routineCardView(for routine: Routine) -> some View {
        let isStandard = routine.danceCategory.lowercased() == "standard"
        let disciplineColor = isStandard ? LuxuryTheme.standardBlue : LuxuryTheme.latinCrimson
        let nodeCount = routine.canvasNodes.count
        let videoCount = routine.mediaVault.count
        
        return Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            selectedRoutineForCanvas = routine
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                // Top Metadata Row: Discipline Badge + Quick QR Button
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: isStandard ? "drop.fill" : "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(disciplineColor)
                        
                        Text(isStandard ? "ŠTANDARD" : "LATINA")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(disciplineColor)
                            .tracking(1.0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(disciplineColor.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(disciplineColor.opacity(0.35), lineWidth: 1))
                    
                    Spacer()
                    
                    // Quick QR Code Export Button
                    Button {
                        if let payload = QRGenerator.generatePayload(from: routine),
                           let qrImg = QRGenerator.generateQRCode(from: payload) {
                            self.routineForQRExport = routine
                            self.qrCodeImage = qrImg
                            self.showQRModal = true
                        }
                    } label: {
                        Image(systemName: "qrcode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(7)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
                
                // Middle: Dance Title & Routine Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.danceName.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(LuxuryTheme.gold400)
                        .tracking(1.2)
                    
                    Text(routine.name)
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                // Mini Choreography Constellation Graphic
                miniCanvasSchematic(nodesCount: nodeCount, accentColor: disciplineColor)
                
                // Bottom Row: Figures, Videos & Open Canvas Prompt
                HStack {
                    HStack(spacing: 12) {
                        // Figures count
                        HStack(spacing: 4) {
                            Circle()
                                .fill(disciplineColor)
                                .frame(width: 6, height: 6)
                            Text("\(nodeCount) figúr")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        
                        // Videos count
                        if videoCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "film")
                                    .font(.system(size: 10))
                                    .foregroundColor(LuxuryTheme.gold400)
                                Text("\(videoCount)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // "Otvoriť plátno" Call to Action
                    HStack(spacing: 4) {
                        Text("Otvoriť plátno")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(LuxuryTheme.gold400)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(LuxuryTheme.gold400)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LuxuryTheme.obsidian800.opacity(0.88))
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                disciplineColor.opacity(0.45),
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
            .shadow(color: disciplineColor.opacity(0.12), radius: 14)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedRoutineForCanvas = routine
            } label: {
                Label("Otvoriť plátno", systemImage: "square.grid.2x2")
            }
            
            Button {
                if let payload = QRGenerator.generatePayload(from: routine),
                   let qrImg = QRGenerator.generateQRCode(from: payload) {
                    self.routineForQRExport = routine
                    self.qrCodeImage = qrImg
                    self.showQRModal = true
                }
            } label: {
                Label("Zdieľať QR kód", systemImage: "qrcode")
            }
            
            Button(role: .destructive) {
                deleteRoutine(routine)
            } label: {
                Label("Vymazať zostavu", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Mini Canvas Schematic Graphic
    private func miniCanvasSchematic(nodesCount: Int, accentColor: Color) -> some View {
        let displayCount = min(max(nodesCount, 3), 5)
        return HStack(spacing: 0) {
            ForEach(0..<displayCount, id: \.self) { idx in
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(idx < nodesCount ? accentColor.opacity(0.25) : Color.white.opacity(0.05))
                            .frame(width: 16, height: 16)
                        
                        Circle()
                            .fill(idx < nodesCount ? accentColor : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                    
                    if idx < displayCount - 1 {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        idx < nodesCount ? accentColor.opacity(0.6) : Color.white.opacity(0.15),
                                        (idx + 1) < nodesCount ? accentColor.opacity(0.6) : Color.white.opacity(0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 20, height: 1.5)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))
        )
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(LuxuryTheme.gold500.opacity(0.14))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "figure.dance")
                    .font(.system(size: 38))
                    .foregroundColor(LuxuryTheme.gold400)
            }
            
            VStack(spacing: 6) {
                Text(routines.isEmpty ? "Žiadna tanečná zostava" : "Nenašli sa žiadne zostavy")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text(
                    routines.isEmpty
                    ? "Vytvorte si svoju prvú choreografiu na plátne a naplánujte jednotlivé figúry."
                    : "Skúste upraviť vyhľadávanie alebo zmeniť filter kategórie."
                )
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            }
            
            Button {
                showNewRoutineSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Vytvoriť prvú zostavu")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [LuxuryTheme.gold400, LuxuryTheme.gold500],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: LuxuryTheme.gold500.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(24)
    }
    
    // MARK: - Delete Routine
    private func deleteRoutine(_ routine: Routine) {
        let routineId = routine.id
        modelContext.delete(routine)
        try? modelContext.save()
        
        Task {
            await SupabaseSyncManager.shared.deleteRoutine(routineId)
        }
    }
}
