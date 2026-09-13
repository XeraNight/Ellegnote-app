import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

enum VaultFilter: String, CaseIterable, Identifiable {
    case all = "Všetky"
    case myTake = "🔴 Moje"
    case targetIdol = "🟢 Idoly"
    case coach = "👔 Tréner"
    case favorites = "⭐ Obľúbené"
    
    var id: String { rawValue }
}

struct VideoVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Parent Context
    var routine: Routine?
    var node: CanvasNode?
    
    // Bindings to active comparison slots
    @Binding var activeSlotAPath: String?
    @Binding var activeSlotBPath: String?
    
    // Local State
    @State private var selectedFilter: VaultFilter = .all
    @State private var showCamera: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDuelPlayer: Bool = false
    @State private var previewVideoPath: String? = nil
    @State private var showStorageAlert: Bool = false
    
    // Edit item sheet state
    @State private var editingEntry: VideoMediaEntry? = nil
    @State private var editTitle: String = ""
    @State private var editRole: VideoMediaRole = .myTake
    
    var mediaItems: [VideoMediaEntry] {
        if let routine = routine {
            return routine.mediaVault.sorted { $0.createdAt > $1.createdAt }
        } else if let node = node {
            return node.mediaVault.sorted { $0.createdAt > $1.createdAt }
        }
        return []
    }
    
    var filteredItems: [VideoMediaEntry] {
        mediaItems.filter { item in
            switch selectedFilter {
            case .all:
                return true
            case .myTake:
                return item.role == .myTake
            case .targetIdol:
                return item.role == .targetIdol
            case .coach:
                return item.role == .coach
            case .favorites:
                return item.isFavorite
            }
        }
    }
    
    var entityTitle: String {
        routine?.name ?? node?.figureName ?? "Zostava"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 16)
                    
                    VStack(spacing: 0) {
                        // Top Duel Slot Summary Bar
                        duelSlotsSummaryBar
                            .padding(.horizontal, autoSidePadding)
                            .padding(.vertical, 10)
                            .background(Color.themeCard.opacity(0.8))
                        
                        // Filter Chips Bar
                        filterChipsBar
                            .padding(.horizontal, autoSidePadding)
                            .padding(.vertical, 8)
                        
                        // Media Vault Grid / Empty State
                        if filteredItems.isEmpty {
                            emptyVaultView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                                    ForEach(filteredItems) { entry in
                                        videoCardView(for: entry)
                                    }
                                }
                                .padding(.horizontal, autoSidePadding)
                                .padding(.top, 8)
                                .padding(.bottom, 80) // Spacing for floating bottom bar
                            }
                        }
                    }
                    
                    // Floating Action Bar at Bottom
                    VStack {
                        Spacer()
                        floatingActionBar
                            .padding(.horizontal, autoSidePadding)
                            .padding(.bottom, 12)
                    }
                }
            }
            .navigationTitle("🗄️ Inventár Videí")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zavrieť") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDuelPlayer = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.split.2x1.fill")
                            Text("Duel")
                        }
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.obsidian900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(activeSlotAPath == nil && activeSlotBPath == nil)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                DanceCameraView(ghostVideoPath: activeSlotBPath) { localPath in
                    addNewVideoEntry(filePath: localPath, defaultRole: .myTake, defaultTitle: "Záznam z tréningu")
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoPickerImport(newItem)
            }
            .sheet(isPresented: $showDuelPlayer) {
                DualVideoComparisonView(
                    pathA: $activeSlotAPath,
                    pathB: $activeSlotBPath,
                    titleA: "Moje video (Slot A)",
                    titleB: "Vzor / Idol (Slot B)"
                )
            }
            .sheet(item: $editingEntry) { entry in
                editEntrySheet(entry)
            }
            .alert("Nedostatok miesta v úložisku", isPresented: $showStorageAlert) {
                Button("Rozumiem", role: .cancel) { }
            } message: {
                Text("V iPhone máš menej ako 100 MB voľného miesta. Pre nahrávanie ďalších videí uvoľni miesto v pamäti.")
            }
        }
    }
    
    // MARK: - Duel Slots Summary Bar
    private var duelSlotsSummaryBar: some View {
        HStack(spacing: 10) {
            // Slot A
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SLOT A (Moje)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.red)
                    Text(titleForPath(activeSlotAPath) ?? "Nevybraté")
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.themeDark)
                }
                Spacer()
                if activeSlotAPath != nil {
                    Button {
                        activeSlotAPath = nil
                        saveChanges()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.themeBg)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 1.5))
            .frame(maxWidth: .infinity)
            
            // VS Divider
            Text("⚔️")
                .font(.system(size: 14))
            
            // Slot B
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SLOT B (Idol)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.green)
                    Text(titleForPath(activeSlotBPath) ?? "Nevybraté")
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.themeDark)
                }
                Spacer()
                if activeSlotBPath != nil {
                    Button {
                        activeSlotBPath = nil
                        saveChanges()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.themeBg)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1.5))
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Filter Chips Bar
    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VaultFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: selectedFilter == filter ? .black : .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.gold400 : Color.themeCard)
                            .foregroundColor(selectedFilter == filter ? Color.obsidian900 : Color.white.opacity(0.75))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedFilter == filter ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Video Card View
    private func videoCardView(for entry: VideoMediaEntry) -> some View {
        let isSlotA = activeSlotAPath == entry.filePath
        let isSlotB = activeSlotBPath == entry.filePath
        
        return VStack(alignment: .leading, spacing: 6) {
            // Thumbnail Preview Container
            ZStack(alignment: .topLeading) {
                Color.black
                    .aspectRatio(16/10, contentMode: .fill)
                    .cornerRadius(10)
                
                // Play Icon in Center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.85))
                            .shadow(radius: 4)
                        Spacer()
                    }
                    Spacer()
                }
                
                // Top Tag Badge
                HStack {
                    Label(entry.role.displayName, systemImage: entry.role.iconName)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(entry.role.tagColor.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Button {
                        entry.isFavorite.toggle()
                        saveChanges()
                    } label: {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(entry.isFavorite ? .yellow : .white)
                            .shadow(radius: 2)
                    }
                }
                .padding(6)
                
                // Bottom Duel Status Badges
                VStack {
                    Spacer()
                    HStack {
                        if isSlotA {
                            Text("🔴 V DUELI A")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        if isSlotB {
                            Text("🟢 V DUELI B")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap to preview or set in duel
                showDuelPlayer = true
            }
            
            // Title & Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            // Actions Menu Button
            Menu {
                Button {
                    activeSlotAPath = entry.filePath
                    saveChanges()
                } label: {
                    Label("Nastaviť ako Moje (Slot A)", systemImage: "person.fill")
                }
                
                Button {
                    activeSlotBPath = entry.filePath
                    saveChanges()
                } label: {
                    Label("Nastaviť ako Idol (Slot B)", systemImage: "star.fill")
                }
                
                Divider()
                
                Button {
                    editingEntry = entry
                    editTitle = entry.title
                    editRole = entry.role
                } label: {
                    Label("Upraviť názov a tag", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    deleteEntry(entry)
                } label: {
                    Label("Vymazať video", systemImage: "trash")
                }
            } label: {
                HStack {
                    Text("Možnosti")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(8)
        .background(Color.themeCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSlotA ? Color.latinCrimson : (isSlotB ? Color.syncEmerald : Color.white.opacity(0.08)), lineWidth: (isSlotA || isSlotB) ? 2 : 1)
        )
    }
    
    // MARK: - Empty Vault View
    private var emptyVaultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(Color.gold400.opacity(0.5))
            
            Text("Žiadne videá v inventári")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("Nahraj svoje tréningové video alebo importuj vzor majstrov sveta pre porovnanie.")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Floating Action Bar
    private var floatingActionBar: some View {
        HStack(spacing: 12) {
            // Record Camera Button with storage check
            Button {
                if MediaStorageManager.hasAvailableDiskSpace(minMB: 100) {
                    showCamera = true
                } else {
                    showStorageAlert = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Natočiť")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.obsidian900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
                .shadow(color: Color.gold500.opacity(0.3), radius: 6, y: 3)
            }
            
            // Photos Picker Import Button
            PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Import")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
            }
        }
    }
    
    // MARK: - Edit Entry Sheet
    private func editEntrySheet(_ entry: VideoMediaEntry) -> some View {
        NavigationStack {
            Form {
                Section("Názov videa") {
                    TextField("Napr. Tréning 21.8.", text: $editTitle)
                }
                
                Section("Kategória / Tag") {
                    Picker("Rola videa", selection: $editRole) {
                        ForEach(VideoMediaRole.allCases) { role in
                            Label(role.displayName, systemImage: role.iconName).tag(role)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Upraviť video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušiť") {
                        editingEntry = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložiť") {
                        entry.title = editTitle.isEmpty ? "Video" : editTitle
                        entry.role = editRole
                        saveChanges()
                        editingEntry = nil
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Helper Methods
    private func addNewVideoEntry(filePath: String, defaultRole: VideoMediaRole, defaultTitle: String) {
        let entry = VideoMediaEntry(
            filePath: filePath,
            title: defaultTitle,
            role: defaultRole
        )
        
        if let routine = routine {
            entry.routine = routine
            routine.mediaVault.append(entry)
            if routine.videoPath == nil && defaultRole == .myTake {
                routine.videoPath = filePath
                activeSlotAPath = filePath
            } else if routine.activeTargetVideoPath == nil && defaultRole == .targetIdol {
                routine.activeTargetVideoPath = filePath
                activeSlotBPath = filePath
            }
        } else if let node = node {
            entry.canvasNode = node
            node.mediaVault.append(entry)
            if node.videoPath == nil && defaultRole == .myTake {
                node.videoPath = filePath
                activeSlotAPath = filePath
            } else if node.activeTargetVideoPath == nil && defaultRole == .targetIdol {
                node.activeTargetVideoPath = filePath
                activeSlotBPath = filePath
            }
        }
        
        saveChanges()
    }
    
    private func handlePhotoPickerImport(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            do {
                if let movie = try await item.loadTransferable(type: MovieTransferable.self) {
                    let filename = try MediaStorageManager.copyIntoDocuments(from: movie.url, fileExtension: "mp4")
                    await MainActor.run {
                        addNewVideoEntry(filePath: filename, defaultRole: .targetIdol, defaultTitle: "Importovaný vzor")
                    }
                }
            } catch {
                print("Failed to import video from photos: \(error)")
            }
        }
    }
    
    private func deleteEntry(_ entry: VideoMediaEntry) {
        if activeSlotAPath == entry.filePath { activeSlotAPath = nil }
        if activeSlotBPath == entry.filePath { activeSlotBPath = nil }
        
        MediaStorageManager.removeFile(named: entry.filePath)
        
        if let routine = routine {
            routine.mediaVault.removeAll { $0.id == entry.id }
            if routine.videoPath == entry.filePath { routine.videoPath = nil }
            if routine.activeTargetVideoPath == entry.filePath { routine.activeTargetVideoPath = nil }
        } else if let node = node {
            node.mediaVault.removeAll { $0.id == entry.id }
            if node.videoPath == entry.filePath { node.videoPath = nil }
            if node.activeTargetVideoPath == entry.filePath { node.activeTargetVideoPath = nil }
        }
        
        modelContext.delete(entry)
        saveChanges()
    }
    
    private func titleForPath(_ path: String?) -> String? {
        guard let path = path else { return nil }
        return mediaItems.first { $0.filePath == path }?.title ?? "Aktívne video"
    }
    
    private func saveChanges() {
        try? modelContext.save()
    }
}

// MARK: - Movie Transferable for PhotosPicker
struct MovieTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copyURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mp4")
            try? FileManager.default.removeItem(at: copyURL)
            try FileManager.default.copyItem(at: received.file, to: copyURL)
            return MovieTransferable(url: copyURL)
        }
    }
}
