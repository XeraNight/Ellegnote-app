import SwiftUI
import SwiftData

// MARK: - Dance Detail View
struct DanceDetailView: View {
    let dance: Dance
    @Environment(\.modelContext) private var modelContext
    @Query private var allRoutines: [Routine]
    @Query private var allFigures: [FigureLibraryItem]
    
    @State private var showCreateRoutineSheet = false
    @State private var showPaywallSheet = false
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
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 22)
                
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
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        
                        // General Reference Video (if present)
                        if let videoPath = dance.videoPath {
                            LoopingVideoPlayer(videoPath: videoPath, rate: 1.0)
                                .frame(height: 180)
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        
                        // Style Information Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(dance.name)
                                    .font(.system(size: 26, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(dance.tempo)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.gold400)
                            }
                            
                            Text(dance.info)
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.75))
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(20)
                        .luxurySmokedCard(cornerRadius: 18, accentColor: accentColor)
                        
                        // Routines List Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Moje zostavy")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    if !SubscriptionManager.shared.canCreateRoutine(existingCountForDance: routinesForDance.count) {
                                        AnalyticsManager.shared.routineLimitHit(danceName: dance.name)
                                        showPaywallSheet = true
                                    } else {
                                        showCreateRoutineSheet = true
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Nová")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(accentColor)
                                    .cornerRadius(10)
                                }
                            }
                            
                            if !SubscriptionManager.shared.canCreateRoutine(existingCountForDance: routinesForDance.count) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(LuxuryTheme.gold400)
                                    Text("Free účet: 1 zostava na tanec aktívna.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Button {
                                        AnalyticsManager.shared.paywallViewed(source: "dance_detail_limit_banner", initialTier: "Plus")
                                        showPaywallSheet = true
                                    } label: {
                                        Text("Odomknúť Plus")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(LuxuryTheme.obsidian900)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(LuxuryTheme.gold400)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(LuxuryTheme.obsidian800.opacity(0.85))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LuxuryTheme.gold500.opacity(0.35), lineWidth: 1)
                                )
                            }
                            
                            if routinesForDance.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.dashed")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.gold400.opacity(0.7))
                                    Text("Zatiaľ nemáš vytvorenú žiadnu zostavu pre \(dance.name).")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.65))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .luxurySmokedCard(cornerRadius: 14, accentColor: Color.gold400.opacity(0.4))
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(routinesForDance) { routine in
                                        HStack {
                                            NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(routine.name)
                                                            .font(.system(size: 15, weight: .bold, design: .serif))
                                                            .foregroundColor(.white)
                                                        Text("\(routine.canvasNodes.count) figúr")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(Color.white.opacity(0.5))
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(Color.white.opacity(0.3))
                                                }
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Divider()
                                                .frame(height: 24)
                                                .background(Color.white.opacity(0.12))
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
                                        .luxurySmokedCard(cornerRadius: 14, accentColor: accentColor)
                                    }
                                }
                            }
                        }
                        
                        // Figures Library Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Zoznam figúr")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { showAddCustomFigure = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Figúra")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(10)
                                }
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(figuresForDance) { fig in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(fig.name)
                                                .font(.system(size: 14, weight: .bold, design: .serif))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if !fig.rhythm.isEmpty {
                                                Text(fig.rhythm)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Color.gold400)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color.gold500.opacity(0.15))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        if !fig.techniqueNotes.isEmpty {
                                            Text(fig.techniqueNotes)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.white.opacity(0.6))
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding()
                                    .luxurySmokedCard(cornerRadius: 12, accentColor: Color.gold400)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 60)
                }
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
                    Color.obsidian800.ignoresSafeArea()
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
                        .buttonStyle(.neubrutalist(accentColor: newRoutineName.isEmpty ? Color.obsidian800 : Color.themeAccent))
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
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zrušiť") { showCreateRoutineSheet = false }
                            .foregroundColor(.gold400)
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
                    Color.obsidian800.ignoresSafeArea()
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
                        .buttonStyle(.neubrutalist(accentColor: customFigureName.isEmpty ? Color.obsidian800 : Color.themeAccent))
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
                .toolbarColorScheme(.dark, for: .navigationBar)
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
        .sheet(isPresented: $showPaywallSheet) {
            SubscriptionPaywallView(initialTier: .plus)
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
