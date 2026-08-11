import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dance.name) private var dances: [Dance]
    @Query(sort: \Routine.updatedAt, order: .reverse) private var routines: [Routine]
    @State private var showQuickCapture = false
    @State private var showQRScanner = false
    @State private var scanErrorMessage: String? = nil
    @State private var showScanError = false
    @State private var showScanSuccess = false
    @State private var scannedRoutineName = ""
    @State private var showManualCodeSheet = false
    @State private var manualCodeInput = ""
    
    private func handleScannedCode(_ rawCode: String) {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            showError("Neplatné dáta kódového kľúča.")
            return
        }
        
        do {
            let payload = try JSONDecoder().decode(QRSharePayload.self, from: data)
            
            // Extract or fallback routine UUID
            let routineId: UUID
            if let payloadId = payload.id, let parsedUUID = UUID(uuidString: payloadId) {
                routineId = parsedUUID
            } else {
                routineId = UUID()
            }
            
            // Upsert routine (update existing or create new)
            let targetRoutine: Routine
            if let existing = routines.first(where: { $0.id == routineId }) {
                targetRoutine = existing
                targetRoutine.name = payload.n
                targetRoutine.danceName = payload.d
                targetRoutine.danceCategory = payload.c
                targetRoutine.updatedAt = Date()
            } else {
                targetRoutine = Routine(
                    id: routineId,
                    name: payload.n,
                    danceName: payload.d,
                    danceCategory: payload.c
                )
                modelContext.insert(targetRoutine)
            }
            
            // Upsert nodes
            for rawNode in payload.nodes {
                let nodeId: UUID
                if let rawNodeId = rawNode.id, let parsedNodeUUID = UUID(uuidString: rawNodeId) {
                    nodeId = parsedNodeUUID
                } else {
                    nodeId = UUID()
                }
                
                if let existingNode = targetRoutine.canvasNodes.first(where: { $0.id == nodeId }) {
                    existingNode.x = rawNode.x
                    existingNode.y = rawNode.y
                    existingNode.figureName = rawNode.f
                    existingNode.rhythm = rawNode.r ?? ""
                    existingNode.notes = rawNode.n ?? ""
                    existingNode.orderIndex = rawNode.o
                    existingNode.transitionNotes = rawNode.t ?? ""
                } else {
                    let node = CanvasNode(
                        id: nodeId,
                        x: rawNode.x,
                        y: rawNode.y,
                        figureName: rawNode.f,
                        rhythm: rawNode.r ?? "",
                        notes: rawNode.n ?? "",
                        orderIndex: rawNode.o,
                        transitionNotes: rawNode.t ?? ""
                    )
                    node.routine = targetRoutine
                    modelContext.insert(node)
                }
            }
            
            try modelContext.save()
            
            // Background sync to Supabase Database
            SupabaseSyncManager.shared.syncRoutineOnBackground(targetRoutine)
            
            scannedRoutineName = payload.n
            showScanSuccess = true
            
        } catch {
            showError("Nepodarilo sa naimportovať zostavu. Kód nie je kompatibilný s Ellegnote.")
        }
    }
    
    private func showError(_ message: String) {
        scanErrorMessage = message
        showScanError = true
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Warm Cream Background
                Color.themeBg.ignoresSafeArea()
                
                // Subtle warm tint — no heavy blur for perf
                VStack {
                    HStack {
                        RoundedRectangle(cornerRadius: 200)
                            .fill(
                                RadialGradient(
                                    colors: [Color.themeAccent.opacity(0.07), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 320, height: 320)
                            .offset(x: -60, y: -80)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TANEČNÉ ZOSTAVY")
                                    .font(.system(size: 26, weight: .black, design: .serif))
                                    .foregroundColor(.themeDark)
                                    .tracking(1.5)
                                
                                Text("CANVAS EDITOVANIE CHOREOGRAFIÍ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.themeDark.opacity(0.5))
                                    .tracking(1)
                            }
                            Spacer()
                            
                            NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Nová zostava")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.themeAccent)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: Color.themeDark.opacity(0.15), radius: 2, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Category Cards (Standard & Latina)
                        HStack(spacing: 12) {
                            NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.standardBlue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ŠTANDARD")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundColor(.themeDark)
                                        Text("Waltz, Tango...")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.themeDark.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.themeCard)
                                .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: DanceCategoryView(category: "Latin")) {
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.latinPink)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("LATINA")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundColor(.themeDark)
                                        Text("Samba, Cha-Cha...")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.themeDark.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.themeCard)
                                .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        
                        // Zoznam všetkých vytvorených zostáv (Canvas Routines Focus)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("VŠETKY MOJE CHOREOGRAFIE")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.themeDark.opacity(0.6))
                                    .tracking(1)
                                
                                Spacer()
                                
                                Text("\(routines.count) zostáv")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.themeAccent)
                            }
                            .padding(.horizontal, 24)
                            
                            if routines.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "square.grid.2x2.dashed")
                                        .font(.system(size: 34))
                                        .foregroundColor(.themeDark.opacity(0.3))
                                    Text("Zatiaľ nemáš vytvorenú žiadnu zostavu")
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .foregroundColor(.themeDark.opacity(0.5))
                                    
                                    NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                                        Text("Vytvoriť prvú zostavu na canvase ➔")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.themeAccent)
                                            .cornerRadius(20)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .neubrutalistCard(cornerRadius: 20, shadowOffset: 3)
                                .padding(.horizontal, 24)
                            } else {
                                VStack(spacing: 14) {
                                    ForEach(routines) { routine in
                                        NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                                            VStack(spacing: 12) {
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        HStack(spacing: 8) {
                                                            Text(routine.danceName.uppercased())
                                                                .font(.system(size: 10, weight: .black))
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 3)
                                                                .background(
                                                                    routine.danceCategory.lowercased() == "standard"
                                                                        ? Color.standardBlue.opacity(0.15)
                                                                        : Color.latinPink.opacity(0.15)
                                                                )
                                                                .foregroundColor(
                                                                    routine.danceCategory.lowercased() == "standard"
                                                                        ? .standardBlue
                                                                        : .latinPink
                                                                )
                                                                .cornerRadius(6)
                                                            
                                                            Text("•")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.gray)
                                                            
                                                            Text(timeAgo(routine.updatedAt))
                                                                .font(.system(size: 11))
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Text(routine.name)
                                                            .font(.system(size: 17, weight: .bold, design: .serif))
                                                            .foregroundColor(.themeDark)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    // Node count badge
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "square.on.square.dashed")
                                                            .font(.system(size: 11))
                                                        Text("\(routine.canvasNodes.count) figúr")
                                                            .font(.system(size: 11, weight: .bold))
                                                    }
                                                    .foregroundColor(.themeDark.opacity(0.7))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.themeBg)
                                                    .cornerRadius(8)
                                                }
                                                
                                                Divider().background(Color.themeBorder.opacity(0.6))
                                                
                                                // Entry to Canvas button bar
                                                HStack {
                                                    Text("Otvoriť Canvas Zostavy")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.themeAccent)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "arrow.right.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.themeAccent)
                                                }
                                            }
                                            .padding(16)
                                            .background(Color.themeCard)
                                            .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 100)  // clear space above liquid glass dock
                    }
                }
            }
            .sheet(isPresented: $showQuickCapture) {
                CaptureModeView(isPresented: $showQuickCapture)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showQRScanner = true }) {
                            Label("Skenovať QR kód", systemImage: "qrcode.viewfinder")
                        }
                        Button(action: {
                            if let str = UIPasteboard.general.string, !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                handleScannedCode(str)
                            } else {
                                showError("Schránka je prázdna alebo neobsahuje platný textový kód.")
                            }
                        }) {
                            Label("Vložiť zo schránky", systemImage: "doc.on.clipboard")
                        }
                        Button(action: { showManualCodeSheet = true }) {
                            Label("Zadať kód ručne", systemImage: "keyboard")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Sken / Kód")
                        }
                        .font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(.neubrutalistSecondary(cornerRadius: 10))
                }
            }
            .qrScanner(isPresented: $showQRScanner, onScan: handleScannedCode)
            .sheet(isPresented: $showManualCodeSheet) {
                NavigationStack {
                    ZStack {
                        Color.themeBg.ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Vloženie kódu zostavy")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                                .padding(.top, 20)
                            
                            Text("Skopíruj textový kód zo zostavy na druhom zariadení a vlož ho sem.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.themeDark.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            TextEditor(text: $manualCodeInput)
                                .scrollContentBackground(.hidden)
                                .frame(height: 150)
                                .padding(8)
                                .background(Color.themeCard)
                                .foregroundColor(.themeDark)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 2))
                                .padding(.horizontal, 24)
                            
                            Button(action: {
                                let codeToProcess = manualCodeInput
                                manualCodeInput = ""
                                showManualCodeSheet = false
                                handleScannedCode(codeToProcess)
                            }) {
                                Text("Naimportovať zostavu")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.neubrutalist(accentColor: Color.themeDark))
                            .padding(.horizontal, 24)
                            .disabled(manualCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Spacer()
                        }
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Zrušiť") { showManualCodeSheet = false }
                                    .foregroundColor(.themeDark)
                            }
                        }
                    }
                }
            }
            .alert("Chyba skenovania", isPresented: $showScanError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(scanErrorMessage ?? "Neznáma chyba")
            })
            .alert("Zostava naimportovaná", isPresented: $showScanSuccess, actions: {
                Button("Skvelé", role: .cancel) {}
            }, message: {
                Text("Zostava \"\(scannedRoutineName)\" bola úspešne naimportovaná do tvojej knižnice.")
            })
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "sk")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Category Tile View
struct CategoryTileView: View {
    let title: String
    let description: String
    let accentColor: Color
    let iconName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Accent Bar matching the style (Standard or Latin)
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 5)
                .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.themeDark)
                        .tracking(0.5)
                }
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.themeDark.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeDark.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(height: 120)
        .neubrutalistCard(cornerRadius: 20, shadowOffset: 4)
    }
}

// MARK: - Dance Category View
struct DanceCategoryView: View {
    let category: String
    @Query(sort: \Dance.name) private var allDances: [Dance]
    
    var filteredDances: [Dance] {
        allDances.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(category == "Standard" ? "Štandardné tance" : "Latinsko-americké tance")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.themeDark)
                        .padding(.top, 16)
                    
                    VStack(spacing: 12) {
                        ForEach(filteredDances) { dance in
                            NavigationLink(destination: DanceDetailView(dance: dance)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(dance.name)
                                            .font(.system(size: 18, weight: .bold, design: .serif))
                                            .foregroundColor(.themeDark)
                                        Text(dance.tempo)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.themeAccent)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.themeDark.opacity(0.3))
                                }
                                .padding(20)
                                .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Dance Detail View
struct DanceDetailView: View {
    let dance: Dance
    @Environment(\.modelContext) private var modelContext
    @Query private var allRoutines: [Routine]
    @Query private var allFigures: [FigureLibraryItem]
    
    @State private var showCreateRoutineSheet = false
    @State private var newRoutineName = ""
    @State private var cacheTrigger = false
    @AppStorage("profileName") private var userName = "Tanečník"
    
    @State private var showAddCustomFigure = false
    @State private var customFigureName = ""
    @State private var customFigureRhythm = ""
    @State private var customFigureNotes = ""
    
    // Deletion confirmation state
    @State private var routineToDelete: Routine? = nil
    @State private var showDeleteConfirmation = false
    
    // Edit dance state
    @State private var showEditDance = false
    
    var routinesForDance: [Routine] {
        let normalizedDanceName = dance.name.lowercased()
        return allRoutines
            .filter { $0.danceName.lowercased() == normalizedDanceName }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    var figuresForDance: [FigureLibraryItem] {
        let normalizedDanceName = dance.name.lowercased()
        return allFigures.filter { $0.danceName.lowercased() == normalizedDanceName }
    }
    
    var body: some View {
        let isStandard = dance.category.lowercased() == "standard"
        let accentColor = isStandard ? Color.standardBlue : Color.latinPink
        
        ZStack {
            Color.themeBg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Illustration Image (if present)
                    if let imagePath = dance.imagePath,
                       let uiImage = MediaResolver.resolveImage(path: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .cornerRadius(18)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.themeBorder, lineWidth: 1)
                            )
                    }
                    
                    // General Reference Video (if present)
                    if let videoPath = dance.videoPath,
                       let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                        LoopingVideoPlayer(videoURL: videoURL, rate: 1.0)
                            .frame(height: 180)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.themeBorder, lineWidth: 1)
                            )
                    }
                    
                    // Style Information Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(dance.name)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            Spacer()
                            Text(dance.tempo)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                        
                        Text(dance.info)
                            .font(.system(size: 13))
                            .foregroundColor(.themeDark.opacity(0.7))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(20)
                    .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
                    
                    // Routines List Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Moje zostavy")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            Spacer()
                            Button(action: { showCreateRoutineSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Nová")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.neubrutalist(accentColor: accentColor, cornerRadius: 10))
                        }
                        
                        if routinesForDance.isEmpty {
                            Text("Zatiaľ nemáš vytvorenú žiadnu zostavu pre \(dance.name).")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .neubrutalistCard(cornerRadius: 12, shadowOffset: 0)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(routinesForDance) { routine in
                                    HStack {
                                        NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(routine.name)
                                                        .font(.system(size: 15, weight: .bold, design: .serif))
                                                        .foregroundColor(.themeDark)
                                                    Text("\(routine.canvasNodes.count) figúr")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.themeDark.opacity(0.3))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Divider()
                                            .frame(height: 24)
                                            .background(Color.themeBorder)
                                            .padding(.horizontal, 4)
                                        
                                        // Delete Routine Option
                                        Button(action: {
                                            routineToDelete = routine
                                            showDeleteConfirmation = true
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color.latinRed)
                                                .padding(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding()
                                    .neubrutalistCard(cornerRadius: 12, shadowOffset: 3)
                                }
                             }
                        }
                    }
                    
                    // Figures Library Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Zoznam figúr")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            Spacer()
                            Button(action: { showAddCustomFigure = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Figúra")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeDark)
                            }
                            .buttonStyle(.neubrutalistSecondary(cornerRadius: 10))
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(figuresForDance) { fig in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(fig.name)
                                            .font(.system(size: 14, weight: .bold, design: .serif))
                                            .foregroundColor(.themeDark)
                                        Spacer()
                                        if !fig.rhythm.isEmpty {
                                            Text(fig.rhythm)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.themeAccent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.themeAccent.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                    }
                                    if !fig.techniqueNotes.isEmpty {
                                        Text(fig.techniqueNotes)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                }
                                .padding()
                                .neubrutalistCard(cornerRadius: 12, shadowOffset: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle(dance.name)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MediaCacheDidUpdate"))) { _ in
            cacheTrigger.toggle()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Upraviť") {
                    showEditDance = true
                }
                .foregroundColor(accentColor)
                .font(.system(size: 15, weight: .bold))
            }
        }
        .sheet(isPresented: $showCreateRoutineSheet) {
            NavigationStack {
                ZStack {
                    Color.themeBg.ignoresSafeArea()
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Názov zostavy")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            TextField("napr. Jarná súťaž 2026", text: $newRoutineName)
                                .padding()
                                .background(Color.themeCard)
                                .foregroundColor(.themeDark)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeDark, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            createRoutine()
                        }) {
                            Text("Vytvoriť")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.neubrutalist(accentColor: newRoutineName.isEmpty ? Color.gray.opacity(0.6) : Color.themeAccent))
                        .disabled(newRoutineName.isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
                .navigationTitle("Nová zostava \(dance.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.themeBg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zrušiť") { showCreateRoutineSheet = false }
                            .foregroundColor(.themeDark)
                    }
                    
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Hotovo") {
                            UIApplication.shared.endEditing()
                        }
                        .foregroundColor(.themeAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCustomFigure) {
            NavigationStack {
                ZStack {
                    Color.themeBg.ignoresSafeArea()
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Názov figúry")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                TextField("napr. Double Reverse Spin", text: $customFigureName)
                                    .padding()
                                    .background(Color.themeCard)
                                    .foregroundColor(.themeDark)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Rytmizácia")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                TextField("napr. 1, 2, 3", text: $customFigureRhythm)
                                    .padding()
                                    .background(Color.themeCard)
                                    .foregroundColor(.themeDark)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Technika / Popis")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                TextEditor(text: $customFigureNotes)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 100)
                                    .padding(6)
                                    .background(Color.themeCard)
                                    .foregroundColor(.themeDark)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            addCustomFigure()
                        }) {
                            Text("Uložiť figúru")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.neubrutalist(accentColor: customFigureName.isEmpty ? Color.gray.opacity(0.6) : Color.themeAccent))
                        .disabled(customFigureName.isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
                .navigationTitle("Pridať figúru do \(dance.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.themeBg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zrušiť") { showAddCustomFigure = false }
                            .foregroundColor(.themeDark)
                    }
                    
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Hotovo") {
                            UIApplication.shared.endEditing()
                        }
                        .foregroundColor(.themeAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditDance) {
            EditDanceSheet(dance: dance)
        }
        .confirmationDialog(
            "Určite vymazať zostavu?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Vymazať zostavu", role: .destructive) {
                if let routine = routineToDelete {
                    deleteRoutine(routine)
                }
            }
            Button("Zrušiť", role: .cancel) {}
        } message: {
            Text("Vymazaním zostavy prídete o celé plátno a všetky nahrané videá k tejto zostave.")
        }
    }
    
    private func createRoutine() {
        let trimmedName = newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newRoutine = Routine(
            name: trimmedName,
            danceName: dance.name,
            danceCategory: dance.category
        )
        newRoutine.lastModifiedBy = userName
        modelContext.insert(newRoutine)
        try? modelContext.save()
        
        // Sync creation to Supabase
        SupabaseSyncManager.shared.syncRoutineOnBackground(newRoutine)
        
        newRoutineName = ""
        showCreateRoutineSheet = false
    }
    
    private func addCustomFigure() {
        guard !customFigureName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newFigure = FigureLibraryItem(
            name: customFigureName,
            danceName: dance.name,
            rhythm: customFigureRhythm,
            techniqueNotes: customFigureNotes,
            isCustom: true
        )
        modelContext.insert(newFigure)
        try? modelContext.save()
        
        customFigureName = ""
        customFigureRhythm = ""
        customFigureNotes = ""
        showAddCustomFigure = false
    }
    
    private func deleteRoutine(_ routine: Routine) {
        for node in routine.canvasNodes {
            if let videoPath = node.videoPath {
                MediaStorageManager.removeFile(named: videoPath)
            }
        }
        
        modelContext.delete(routine)
        try? modelContext.save()
        routineToDelete = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Edit Dance Details Sheet

struct EditDanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var dance: Dance
    
    @State private var nameText = ""
    @State private var tempoText = ""
    @State private var infoText = ""
    @State private var playbackRate: Float = 1.0
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Názov tanca")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("Názov", text: $nameText)
                                    .padding()
                                    .background(Color.themeCard)
                                    .cornerRadius(10)
                                    .foregroundColor(.themeDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeBorder, lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tempo")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("Tempo (napr. 28t/m)", text: $tempoText)
                                    .padding()
                                    .background(Color.themeCard)
                                    .cornerRadius(10)
                                    .foregroundColor(.themeDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeBorder, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Image section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ilustračná fotografia tanca")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark.opacity(0.8))
                            
                            if let imagePath = dance.imagePath,
                               let uiImage = MediaResolver.resolveImage(path: imagePath) {
                                
                                VStack(spacing: 12) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.themeBorder, lineWidth: 1)
                                        )
                                    
                                    Button(action: deletePhoto) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Odstrániť fotku")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.latinRed)
                                    }
                                }
                            } else {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack {
                                        Image(systemName: "photo.badge.plus")
                                        Text("Vybrať fotku z galérie")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.themeDark)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.themeCard)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.themeBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Video section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Všeobecné tréningové video")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark.opacity(0.8))
                            
                            if let videoPath = dance.videoPath,
                               let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                                VStack(spacing: 12) {
                                    LoopingVideoPlayer(videoURL: videoURL, rate: playbackRate)
                                        .frame(height: 200)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.themeBorder, lineWidth: 1)
                                        )
                                    
                                    HStack(spacing: 12) {
                                        Text("Rýchlosť:")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                        
                                        ForEach([0.5, 0.75, 1.0, 1.5], id: \.self) { speed in
                                            Button(action: { playbackRate = Float(speed) }) {
                                                Text(String(format: "%.2fx", speed))
                                                    .font(.system(size: 11, weight: .black))
                                                    .foregroundColor(playbackRate == Float(speed) ? .white : .themeDark)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(playbackRate == Float(speed) ? Color.themeAccent : Color.themeCard)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(playbackRate == Float(speed) ? Color.clear : Color.themeBorder, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: deleteVideo) {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(Color.latinRed)
                                        }
                                    }
                                }
                            } else {
                                Button(action: { showCamera = true }) {
                                    HStack {
                                        Image(systemName: "video.badge.plus.fill")
                                        Text("Nahrať tréningové video")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.themeDark)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.themeCard)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.themeBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Text description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Popis tanca / Charakteristika")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark.opacity(0.8))
                            
                            TextEditor(text: $infoText)
                                .scrollContentBackground(.hidden)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.themeCard)
                                .foregroundColor(.themeDark)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeBorder, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Upraviť \(dance.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundColor(.themeDark)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Uložiť") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeAccent)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        UIApplication.shared.endEditing()
                    }
                    .foregroundColor(.themeAccent)
                }
            }
            .onAppear {
                nameText = dance.name
                tempoText = dance.tempo
                infoText = dance.info
            }
            .fullScreenCover(isPresented: $showCamera) {
                VideoRecorderView { localPath in
                    dance.videoPath = localPath
                    try? modelContext.save()
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let filename = try? MediaStorageManager.store(data: data, prefix: "dance_img", fileExtension: "jpg") {
                            await MainActor.run {
                                MediaStorageManager.removeFile(named: dance.imagePath)
                                dance.imagePath = filename
                                try? modelContext.save()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        dance.name = nameText
        dance.tempo = tempoText
        dance.info = infoText
        try? modelContext.save()
    }
    
    private func deletePhoto() {
        if let path = dance.imagePath {
            MediaStorageManager.removeFile(named: path)
        }
        dance.imagePath = nil
        try? modelContext.save()
    }
    
    private func deleteVideo() {
        if let path = dance.videoPath {
            MediaStorageManager.removeFile(named: path)
        }
        dance.videoPath = nil
        try? modelContext.save()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
