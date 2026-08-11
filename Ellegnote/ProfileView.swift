import Foundation
import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]
    @Query private var dances: [Dance]
    @Query private var figures: [FigureLibraryItem]
    @Query private var nodes: [CanvasNode]
    
    @AppStorage("profileName") private var profileName = "Jakub"
    @AppStorage("profileClub") private var profileClub = "ELEGANCE KOŠICE"
    @AppStorage("profileImagePath") private var profileImagePath = ""
    @AppStorage("defaultDictationLanguage") private var defaultLanguage = "sk-SK"
    @AppStorage("defaultPlaybackRate") private var defaultPlaybackRate = 1.0
    
    @State private var showEditProfile = false
    @State private var showResetConfirmation = false
    @State private var pendingMaintenanceAction: MaintenanceAction?
    @State private var editedName = ""
    @State private var editedClub = ""
    @State private var selectedProfilePhotoItem: PhotosPickerItem?
    @State private var isSavingProfilePhoto = false
    // FIX: storage loaded async to avoid file I/O on main thread
    @State private var storageUsageBytes: Int64 = 0
    @State private var storageLoading = true

    // Cached stats — only recalculated when @Query data changes (not every render)
    @State private var cachedStats: (videos: Int, notes: Int, customFigures: Int, standard: Int, latin: Int) = (0, 0, 0, 0, 0)

    private func computeStats() -> (videos: Int, notes: Int, customFigures: Int, standard: Int, latin: Int) {
        var videos = 0, notes = 0, custom = 0, standard = 0, latin = 0
        for node in nodes {
            if node.videoPath != nil { videos += 1 }
            if !node.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { notes += 1 }
        }
        for figure in figures {
            if figure.videoPath != nil { videos += 1 }
            if !figure.techniqueNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { notes += 1 }
            if figure.isCustom { custom += 1 }
        }
        for dance in dances {
            if dance.videoPath != nil { videos += 1 }
            if !dance.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { notes += 1 }
        }
        for routine in routines {
            switch routine.danceCategory.lowercased() {
            case "standard": standard += 1
            case "latin":    latin += 1
            default: break
            }
        }
        return (videos, notes, custom, standard, latin)
    }

    private var recentRoutines: [Routine] {
        routines.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var profileStats: (videos: Int, notes: Int, customFigures: Int, standard: Int, latin: Int) { cachedStats }

    private var videoCount:         Int    { cachedStats.videos }
    private var notesCount:         Int    { cachedStats.notes }
    private var customFiguresCount: Int    { cachedStats.customFigures }
    private var standardCount:      Int    { cachedStats.standard }
    private var latinCount:         Int    { cachedStats.latin }

    private var mostUsedDanceName: String {
        Dictionary(grouping: routines, by: \.danceName)
            .max { $0.value.count < $1.value.count }?.key ?? "Zatiaľ nič"
    }

    private var storageUsageText: String {
        storageLoading ? "…" : ByteCountFormatter.string(fromByteCount: storageUsageBytes, countStyle: .file)
    }
    
    // ENHANCEMENT: app version string for the footer
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Verzia \(version) (\(build))"
    }

    // MARK: - Body sections (split to fix Swift type-check timeout)

    @ViewBuilder private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moje Štatistiky").sectionHeader()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCardView(title: "Zostavy", value: "\(routines.count)", icon: "figure.dance")
                StatCardView(title: "Moje figúry", value: "\(customFiguresCount)", icon: "book.closed.fill")
                StatCardView(title: "Videá", value: "\(videoCount)", icon: "video.fill")
                StatCardView(title: "Poznámky", value: "\(notesCount)", icon: "mic.fill")
                StatCardView(title: "Standard", value: "\(standardCount)", icon: "star.fill")
                StatCardView(title: "Latin", value: "\(latinCount)", icon: "flame.fill")
                StatCardView(title: "Najviac cvičené", value: mostUsedDanceName, icon: "chart.line.uptrend.xyaxis")
                StatCardView(title: "Úložisko", value: storageUsageText, icon: "internaldrive.fill")
            }
        }
    }

    @ViewBuilder private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Odkazy v Nastaveniach").sectionHeader()
            VStack(spacing: 1) {
                NavigationLink(destination: ProfileRoutinesListView(routines: recentRoutines)) {
                    SettingsNavigationRow(icon: "figure.dance", title: "Všetky zostavy", detail: "\(routines.count)")
                }
                .buttonStyle(.plain)
                Divider().background(Color.themeBorder)
                NavigationLink(destination: ProfileFiguresListView(figures: figures.sorted { $0.name < $1.name })) {
                    SettingsNavigationRow(icon: "book.closed.fill", title: "Knižnica figúr", detail: "\(figures.count)")
                }
                .buttonStyle(.plain)
                Divider().background(Color.themeBorder)
                NavigationLink(destination: ProfileMediaListView(dances: dances, figures: figures, nodes: nodes)) {
                    SettingsNavigationRow(icon: "video.fill", title: "Videá a poznámky", detail: "\(videoCount + notesCount)")
                }
                .buttonStyle(.plain)
            }
            .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
        }
    }

    @ViewBuilder private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nedávne Zostavy").sectionHeader()
            if recentRoutines.isEmpty {
                EmptyProfileSectionView(icon: "rectangle.dashed", title: "Zatiaľ nemáš žiadne zostavy")
            } else {
                VStack(spacing: 1) {
                    ForEach(Array(recentRoutines.prefix(3))) { routine in
                        NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                            RecentRoutineRow(routine: routine)
                        }
                        .buttonStyle(.plain)
                        if routine.id != recentRoutines.prefix(3).last?.id {
                            Divider().background(Color.themeBorder)
                        }
                    }
                }
                .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
            }
        }
    }

    @ViewBuilder private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predvoľby Aplikácie").sectionHeader()
            VStack(spacing: 1) {
                SettingsPickerRow(icon: "globe", title: "Jazyk diktovania") {
                    Picker("", selection: $defaultLanguage) {
                        Text("Slovenčina").tag("sk-SK")
                        Text("English").tag("en-US")
                    }
                    .pickerStyle(.menu)
                }
                Divider().background(Color.themeBorder)
                SettingsPickerRow(icon: "play.circle", title: "Rýchlosť videa") {
                    Picker("", selection: $defaultPlaybackRate) {
                        Text("0.5x").tag(0.5)
                        Text("0.75x").tag(0.75)
                        Text("1.0x").tag(1.0)
                        Text("1.5x").tag(1.5)
                    }
                    .pickerStyle(.menu)
                }
            }
            .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
        }
    }

    @ViewBuilder private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Údržba a Dáta").sectionHeader()
            VStack(spacing: 1) {
                MaintenanceButton(icon: "arrow.counterclockwise.circle.fill",
                                  title: "Obnoviť predvolenú knižnicu figúr",
                                  isDestructive: false) { showResetConfirmation = true }
                Divider().background(Color.themeBorder)
                MaintenanceButton(icon: "square.and.arrow.up",
                                  title: "Exportovať zostavy (JSON)",
                                  isDestructive: false) { exportRoutines() }
                Divider().background(Color.themeBorder)
                MaintenanceButton(icon: "video.slash.fill",
                                  title: "Vymazať všetky videá",
                                  isDestructive: true) { pendingMaintenanceAction = .clearVideos }
                Divider().background(Color.themeBorder)
                MaintenanceButton(icon: "text.badge.xmark",
                                  title: "Vymazať všetky poznámky",
                                  isDestructive: true) { pendingMaintenanceAction = .clearNotes }
            }
            .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
        }
    }

    @StateObject private var authManager = AuthManager.shared
    @State private var showAuthSheet = false

    @ViewBuilder private var authCardSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.badge.key.fill")
                    .foregroundColor(.themeAccent)
                Text("TANEČNÝ ÚČET A REALTIME SYNC")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.themeDark.opacity(0.6))
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    let emailText = authManager.userEmail.isEmpty ? "Prihlásený používateľ" : authManager.userEmail
                    if authManager.isAuthenticated {
                        Text(emailText)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                        Text("Synchrónne úpravy aktívne")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("Používaš lokálny režim")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                        Text("Prihlás sa pre synchronizáciu s partnerom")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeDark.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if authManager.isAuthenticated {
                        Task { await authManager.signOut() }
                    } else {
                        showAuthSheet = true
                    }
                }) {
                    let btnText = authManager.isAuthenticated ? "Odhlásiť" : "Prihlásiť ➔"
                    Text(btnText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(authManager.isAuthenticated ? .latinRed : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(authManager.isAuthenticated ? Color.latinRed.opacity(0.12) : Color.themeAccent)
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.themeCard)
        .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
    }

    var body: some View {

        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        authCardSection
                            .sheet(isPresented: $showAuthSheet) {
                                AuthSheetView()
                            }
                        
                        ProfileHeaderView(
                            name: profileName,
                            club: profileClub,
                            imagePath: profileImagePath.isEmpty ? nil : profileImagePath,
                            routineCount: routines.count,
                            customFiguresCount: customFiguresCount
                        ) {
                            editedName = profileName
                            editedClub = profileClub
                            showEditProfile = true
                        }
                        statsSection
                        linksSection
                        routinesSection
                        preferencesSection
                        maintenanceSection
                        Text(appVersion)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.themeDark.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 90)  // clear space above liquid glass dock
                }
            }
            .navigationTitle("Môj Profil")
            .navigationBarTitleDisplayMode(.inline)
            // Compute stats once on appear, then only when data changes
            .onAppear { cachedStats = computeStats() }
            .onChange(of: nodes.count)    { cachedStats = computeStats() }
            .onChange(of: figures.count)  { cachedStats = computeStats() }
            .onChange(of: dances.count)   { cachedStats = computeStats() }
            .onChange(of: routines.count) { cachedStats = computeStats() }
            // Load file sizes off the main thread
            .task { refreshStorageUsage() }
            .sheet(isPresented: $showEditProfile) {
                NavigationStack {
                    ZStack {
                        Color.themeBg.ignoresSafeArea()
                        
                        VStack(spacing: 18) {
                            VStack(spacing: 12) {
                                ProfileAvatarView(
                                    name: editedName.isEmpty ? profileName : editedName,
                                    imagePath: profileImagePath.isEmpty ? nil : profileImagePath,
                                    size: 104
                                )
                                
                                PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images) {
                                    Label(isSavingProfilePhoto ? "Ukladám..." : "Zmeniť fotku", systemImage: "photo")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.themeDark)
                                }
                                .disabled(isSavingProfilePhoto)
                                
                                if !profileImagePath.isEmpty {
                                    Button(role: .destructive) {
                                        removeProfilePhoto()
                                    } label: {
                                        Label("Odstrániť fotku", systemImage: "trash")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.latinRed)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Meno")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.themeDark.opacity(0.55))
                                TextField("Tvoje meno", text: $editedName)
                                    .profileTextField()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tanečný klub")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.themeDark.opacity(0.55))
                                TextField("Názov klubu", text: $editedClub)
                                    .profileTextField()
                            }
                            
                            Spacer()
                        }
                        .padding(24)
                    }
                    .navigationTitle("Upraviť profil")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color.themeBg, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Zrušiť") { showEditProfile = false }
                                .foregroundColor(.themeDark)
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Uložiť") { saveProfile() }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Hotovo") { UIApplication.shared.endEditing() }
                                .foregroundColor(.themeAccent)
                        }
                    }
                    .onChange(of: selectedProfilePhotoItem) { _, newItem in
                        guard let newItem else { return }
                        saveProfilePhoto(from: newItem)
                    }
                }
            }
            .confirmationDialog("Naozaj obnoviť knižnicu?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Obnoviť knižnicu", role: .destructive) { resetFiguresDatabase() }
                Button("Zrušiť", role: .cancel) {}
            } message: {
                Text("Všetky vaše vlastné figúry budú zachované, ale predvolené figúry budú znova načítané.")
            }
            .confirmationDialog(
                pendingMaintenanceAction?.title ?? "",
                isPresented: Binding(
                    get: { pendingMaintenanceAction != nil },
                    set: { if !$0 { pendingMaintenanceAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let action = pendingMaintenanceAction {
                    Button(action.buttonTitle, role: .destructive) { runMaintenance(action) }
                }
                Button("Zrušiť", role: .cancel) { pendingMaintenanceAction = nil }
            } message: {
                Text(pendingMaintenanceAction?.message ?? "")
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClub = editedClub.trimmingCharacters(in: .whitespacesAndNewlines)
        profileName = trimmedName.isEmpty ? "Tanečník" : trimmedName
        profileClub = trimmedClub.isEmpty ? "Bez klubu" : trimmedClub
        showEditProfile = false
    }
    
    private func saveProfilePhoto(from item: PhotosPickerItem) {
        isSavingProfilePhoto = true
        Task {
            defer {
                selectedProfilePhotoItem = nil
                isSavingProfilePhoto = false
            }
            
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let oldPath = profileImagePath.isEmpty ? nil : profileImagePath
            
            do {
                let filename = try await Task.detached(priority: .userInitiated) {
                    try MediaStorageManager.store(data: data, prefix: "profile", fileExtension: "jpg")
                }.value
                
                profileImagePath = filename
                MediaStorageManager.removeFile(named: oldPath)
                refreshStorageUsage()
            } catch {
                print("Failed to save profile photo: \(error)")
            }
        }
    }
    
    private func removeProfilePhoto() {
        MediaStorageManager.removeFile(named: profileImagePath.isEmpty ? nil : profileImagePath)
        profileImagePath = ""
        refreshStorageUsage()
    }
    
    private func resetFiguresDatabase() {
        let descriptor = FetchDescriptor<FigureLibraryItem>(predicate: #Predicate { !$0.isCustom })
        if let standardFigures = try? modelContext.fetch(descriptor) {
            for fig in standardFigures {
                if let imagePath = fig.imagePath {
                    MediaStorageManager.removeFile(named: imagePath)
                }
                if let videoPath = fig.videoPath {
                    MediaStorageManager.removeFile(named: videoPath)
                }
                modelContext.delete(fig)
            }
        }
        FigureLibraryItem.seedDefaultFigures(in: modelContext)
    }
    
    private func runMaintenance(_ action: MaintenanceAction) {
        switch action {
        case .clearVideos: clearAllVideos()
        case .clearNotes:  clearAllNotes()
        }
        pendingMaintenanceAction = nil
        refreshStorageUsage()
    }
    
    private func refreshStorageUsage() {
        let paths = mediaStoragePaths
        storageLoading = true
        Task.detached(priority: .background) {
            let bytes = self.calculateStorageUsage(for: paths)
            await MainActor.run {
                self.storageUsageBytes = bytes
                self.storageLoading = false
            }
        }
    }
    
    private var mediaStoragePaths: [String] {
        var paths = nodes.compactMap(\.videoPath)
            + figures.compactMap(\.videoPath)
            + figures.compactMap(\.imagePath)
            + dances.compactMap(\.videoPath)
            + dances.compactMap(\.imagePath)
        if !profileImagePath.isEmpty {
            paths.append(profileImagePath)
        }
        return paths
    }
    
    private func clearAllVideos() {
        for node   in nodes   { removeMediaFile(at: node.videoPath);   node.videoPath = nil }
        for figure in figures { removeMediaFile(at: figure.videoPath); figure.videoPath = nil }
        for dance  in dances  { removeMediaFile(at: dance.videoPath);  dance.videoPath = nil }
        try? modelContext.save()
    }
    
    private func clearAllNotes() {
        for node   in nodes   { node.notes = ""; node.transitionNotes = "" }
        for figure in figures { figure.techniqueNotes = "" }
        for dance  in dances  { dance.info = "" }
        try? modelContext.save()
    }
    
    // ENHANCEMENT: simple JSON export of routine names + dance names
    private func exportRoutines() {
        let payload = routines.map { ["name": $0.name, "dance": $0.danceName, "updated": $0.updatedAt.ISO8601Format()] }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("zostavy.json")
        try? json.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root  = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
    
    // MARK: - Storage helpers (safe to call off main thread)
    
    nonisolated private func calculateStorageUsage(for paths: [String]) -> Int64 {
        MediaStorageManager.totalSize(for: paths)
    }
    
    private func removeMediaFile(at path: String?) {
        guard let path else { return }
        MediaStorageManager.removeFile(named: path)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - MaintenanceAction

private enum MaintenanceAction: Identifiable {
    case clearVideos
    case clearNotes
    
    var id: String {
        switch self {
        case .clearVideos: return "clearVideos"
        case .clearNotes:  return "clearNotes"
        }
    }
    var title: String {
        switch self {
        case .clearVideos: return "Naozaj vymazať všetky videá?"
        case .clearNotes:  return "Naozaj vymazať všetky poznámky?"
        }
    }
    var message: String {
        switch self {
        case .clearVideos: return "Videá zo zostáv, tancov a figúr budú odstránené z aplikácie."
        case .clearNotes:  return "Poznámky zo zostáv, vlastných figúr a tancov budú vymazané."
        }
    }
    var buttonTitle: String {
        switch self {
        case .clearVideos: return "Vymazať videá"
        case .clearNotes:  return "Vymazať poznámky"
        }
    }
}

// MARK: - Subviews

private struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.themeAccent)
                .frame(width: 28, height: 28)
                .background(Color.themeAccent.opacity(0.08))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.themeDark)
            Spacer()
            Text(detail)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeDark.opacity(0.5))
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeDark.opacity(0.25))
        }
        .padding()
        .background(Color.themeCard)
    }
}

private struct ProfileRoutinesListView: View {
    let routines: [Routine]
    
    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()
            if routines.isEmpty {
                EmptyProfileSectionView(icon: "rectangle.dashed", title: "Zatiaľ nemáš žiadne zostavy").padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                                RecentRoutineRow(routine: routine)
                                    .cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.themeBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Všetky zostavy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileFiguresListView: View {
    let figures: [FigureLibraryItem]
    @State private var selectedFigure: FigureLibraryItem? = nil
    
    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()
            if figures.isEmpty {
                EmptyProfileSectionView(icon: "book.closed", title: "Knižnica je zatiaľ prázdna").padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(figures) { figure in
                            Button(action: { selectedFigure = figure }) {
                                ProfileFigureRow(figure: figure)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Knižnica figúr")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFigure) { figure in
            LibraryFigureDetailSheet(figure: figure)
        }
    }
}

private struct ProfileFigureRow: View {
    let figure: FigureLibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(figure.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.themeDark)
                    .lineLimit(1)
                Spacer()
                Text(figure.isCustom ? "Vlastná" : "Default")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(figure.isCustom ? Color.themeAccent : Color.standardBlue)
                    .cornerRadius(8)
            }
            HStack(spacing: 10) {
                Text(figure.danceName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeDark.opacity(0.55))
                if !figure.rhythm.isEmpty {
                    Text(figure.rhythm)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.themeAccent)
                }
                Spacer()
                if figure.imagePath != nil { Image(systemName: "photo").foregroundColor(.themeDark.opacity(0.5)) }
                if figure.videoPath != nil { Image(systemName: "video.fill").foregroundColor(.themeDark.opacity(0.5)) }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.themeBorder, lineWidth: 1))
    }
}

private struct ProfileMediaListView: View {
    let dances: [Dance]
    let figures: [FigureLibraryItem]
    let nodes: [CanvasNode]
    
    @State private var selectedNode: CanvasNode? = nil
    @State private var selectedFigure: FigureLibraryItem? = nil
    @State private var selectedDance: Dance? = nil
    
    private var videoTotal: Int {
        dances.filter { $0.videoPath != nil }.count
        + figures.filter { $0.videoPath != nil }.count
        + nodes.filter { $0.videoPath != nil }.count
    }
    private var noteTotal: Int {
        dances.filter { !$0.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        + figures.filter { !$0.techniqueNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        + nodes.filter { !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    private var nodesWithMedia: [CanvasNode] {
        nodes.filter { $0.videoPath != nil || !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private var figuresWithMedia: [FigureLibraryItem] {
        figures.filter { $0.videoPath != nil || !$0.techniqueNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private var dancesWithMedia: [Dance] {
        dances.filter { $0.videoPath != nil || !$0.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        ZStack {
            Color.themeBg.ignoresSafeArea()
            if videoTotal + noteTotal == 0 {
                EmptyProfileSectionView(icon: "tray", title: "Zatiaľ tu nie sú videá ani poznámky").padding(24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ProfileMediaSummary(videoTotal: videoTotal, noteTotal: noteTotal)
                        
                        if !nodesWithMedia.isEmpty {
                            ProfileMediaSection(title: "Zostavy", icon: "figure.dance") {
                                ForEach(nodesWithMedia) { node in
                                    Button(action: { selectedNode = node }) {
                                        ProfileMediaRow(
                                            title: node.figureName,
                                            subtitle: node.routine?.name ?? "Zostava",
                                            hasVideo: node.videoPath != nil,
                                            hasNote: !node.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if !figuresWithMedia.isEmpty {
                            ProfileMediaSection(title: "Figúry", icon: "book.closed.fill") {
                                ForEach(figuresWithMedia) { figure in
                                    Button(action: { selectedFigure = figure }) {
                                        ProfileMediaRow(
                                            title: figure.name,
                                            subtitle: figure.danceName,
                                            hasVideo: figure.videoPath != nil,
                                            hasNote: !figure.techniqueNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if !dancesWithMedia.isEmpty {
                            ProfileMediaSection(title: "Tance", icon: "music.note") {
                                ForEach(dancesWithMedia) { dance in
                                    Button(action: { selectedDance = dance }) {
                                        ProfileMediaRow(
                                            title: dance.name,
                                            subtitle: dance.category,
                                            hasVideo: dance.videoPath != nil,
                                            hasNote: !dance.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Videá a poznámky")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedNode)   { node   in FigureDetailCard(node: node) }
        .sheet(item: $selectedFigure) { figure in LibraryFigureDetailSheet(figure: figure) }
        .sheet(item: $selectedDance)  { dance  in EditDanceSheet(dance: dance) }
    }
}

private struct ProfileMediaSummary: View {
    let videoTotal: Int
    let noteTotal: Int
    var body: some View {
        HStack(spacing: 12) {
            StatCardView(title: "Videá",    value: "\(videoTotal)", icon: "video.fill")
            StatCardView(title: "Poznámky", value: "\(noteTotal)",  icon: "mic.fill")
        }
    }
}

private struct ProfileMediaSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(.themeDark.opacity(0.7))
            VStack(spacing: 1) { content }
                .background(Color.themeCard)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.themeBorder, lineWidth: 1))
        }
    }
}

private struct ProfileMediaRow: View {
    let title: String
    let subtitle: String
    let hasVideo: Bool
    let hasNote: Bool
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.themeDark).lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.themeDark.opacity(0.55)).lineLimit(1)
            }
            Spacer()
            if hasVideo { Image(systemName: "video.fill").foregroundColor(.themeAccent) }
            if hasNote  { Image(systemName: "text.alignleft").foregroundColor(.themeAccent) }
        }
        .padding()
        .background(Color.themeCard)
    }
}

private struct ProfileHeaderView: View {
    let name: String
    let club: String
    let imagePath: String?
    let routineCount: Int
    let customFiguresCount: Int
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            ProfileAvatarView(name: name, imagePath: imagePath, size: 82)
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.themeDark)
                Text("Tanečný klub: \(club)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.themeDark.opacity(0.55))
            }
            HStack(spacing: 10) {
                ProfilePill(title: "\(routineCount) zostáv",          icon: "figure.dance")
                ProfilePill(title: "\(customFiguresCount) vlastných figúr", icon: "book.closed.fill")
            }
            Button(action: onEdit) {
                Label("Upraviť profil", systemImage: "pencil")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.themeDark)
            }
            .buttonStyle(NeubrutalistButtonStyle(fillColor: .themeCard, textColor: .themeDark, cornerRadius: 18))
        }
        .padding(.vertical, 18)
    }
}

private struct ProfileAvatarView: View {
    let name: String
    let imagePath: String?
    let size: CGFloat
    
    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.themeAccent.opacity(0.15))
            
            if let imagePath, let uiImage = MediaResolver.resolveImage(path: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: size * 0.39, weight: .black, design: .serif))
                    .foregroundColor(.themeAccent)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.themeDark, lineWidth: 2))
        .shadow(color: Color.themeDark.opacity(0.16), radius: 0, x: 3, y: 3)
    }
}

private struct ProfilePill: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.themeDark.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.themeAccent.opacity(0.08))
            .cornerRadius(14)
    }
}

private struct RecentRoutineRow: View {
    let routine: Routine
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: routine.danceCategory.lowercased() == "standard" ? "star.fill" : "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(routine.danceCategory.lowercased() == "standard" ? .standardBlue : .latinPink)
                .frame(width: 28, height: 28)
                .background(Color.themeAccent.opacity(0.08))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.themeDark).lineLimit(1)
                Text("\(routine.danceName) • \(routine.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.themeDark.opacity(0.55)).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeDark.opacity(0.25))
        }
        .padding()
        .background(Color.themeCard)
    }
}

private struct EmptyProfileSectionView: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(.themeDark.opacity(0.45))
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.themeDark.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .neubrutalistCard(cornerRadius: 16, shadowOffset: 0)
    }
}

private struct SettingsPickerRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.themeAccent).frame(width: 24)
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.themeDark)
            Spacer()
            content
        }
        .padding()
        .background(Color.themeCard)
    }
}

private struct MaintenanceButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    private var tint: Color { isDestructive ? .latinRed : .themeAccent }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(tint)
                Spacer()
            }
            .padding()
            .background(isDestructive ? Color.latinRed.opacity(0.04) : Color.themeCard)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View extensions

private extension View {
    func profileTextField() -> some View {
        self
            .padding()
            .background(Color.themeCard)
            .cornerRadius(12)
            .foregroundColor(.themeDark)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 2))
    }
}

private extension Text {
    func sectionHeader() -> some View {
        self
            .font(.system(size: 14, weight: .bold, design: .serif))
            .foregroundColor(.themeDark.opacity(0.7))
            .padding(.horizontal, 4)
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    
    private var iconView: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeAccent)
            Spacer()
        }
    }
    
    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundColor(.themeDark)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.themeDark.opacity(0.55))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            iconView
            labelStack
        }
        .padding(16)
        .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
    }
}
