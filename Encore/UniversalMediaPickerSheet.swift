import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct UniversalMediaPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let slotTitle: String
    let currentPath: String?
    let onSelectMedia: (String) -> Void
    var onClearMedia: (() -> Void)? = nil
    
    // Queries from SwiftData to find all available media in the app
    @Query(sort: \VideoMediaEntry.createdAt, order: .reverse) private var allVaultEntries: [VideoMediaEntry]
    @Query(sort: \Routine.createdAt, order: .reverse) private var allRoutines: [Routine]
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var allNotes: [InstantNote]
    @Query(sort: \Dance.name) private var allDances: [Dance]
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraModal: Bool = false
    @State private var selectedMediaTypeFilter: MediaFilterType = .all
    @State private var searchText: String = ""
    @State private var isImporting: Bool = false
    
    enum MediaFilterType: String, CaseIterable, Identifiable {
        case all = "Všetko"
        case videos = "🎬 Videá"
        case photos = "📷 Fotky"
        case idols = "🟢 Idoly / Vzory"
        case myTakes = "🔴 Moje pokusy"
        
        var id: String { rawValue }
    }
    
    struct MediaItemRecord: Identifiable {
        let id: String
        let title: String
        let path: String
        let role: String
        let isImage: Bool
        let date: Date?
    }
    
    var aggregatedItems: [MediaItemRecord] {
        var items: [MediaItemRecord] = []
        var seenPaths = Set<String>()
        
        // 1. Vault Entries
        for entry in allVaultEntries {
            guard !seenPaths.contains(entry.filePath) else { continue }
            seenPaths.insert(entry.filePath)
            items.append(
                MediaItemRecord(
                    id: entry.id.uuidString,
                    title: entry.title.isEmpty ? "Záznam" : entry.title,
                    path: entry.filePath,
                    role: entry.role.displayName,
                    isImage: MediaResolver.isImagePath(path: entry.filePath),
                    date: entry.createdAt
                )
            )
        }
        
        // 2. Routines with video/image
        for routine in allRoutines {
            if let p = routine.videoPath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "rt_v_\(routine.id)",
                        title: "\(routine.name) (Moje)",
                        path: p,
                        role: "Zostava",
                        isImage: MediaResolver.isImagePath(path: p),
                        date: routine.updatedAt
                    )
                )
            }
            if let p = routine.activeTargetVideoPath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "rt_tgt_\(routine.id)",
                        title: "\(routine.name) (Vzor)",
                        path: p,
                        role: "Vzor idol",
                        isImage: MediaResolver.isImagePath(path: p),
                        date: routine.updatedAt
                    )
                )
            }
        }
        
        // 3. Notes with media
        for note in allNotes {
            if let p = note.videoPath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "note_v_\(note.id)",
                        title: note.text.isEmpty ? "Video z poznámky" : note.text,
                        path: p,
                        role: "Poznámka",
                        isImage: false,
                        date: note.createdAt
                    )
                )
            }
            if let p = note.imagePath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "note_img_\(note.id)",
                        title: note.text.isEmpty ? "Fotka z poznámky" : note.text,
                        path: p,
                        role: "Poznámka",
                        isImage: true,
                        date: note.createdAt
                    )
                )
            }
        }
        
        // 4. Standard/Latin dances vzory
        for dance in allDances {
            if let p = dance.videoPath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "dance_v_\(dance.id)",
                        title: "\(dance.name) (Vzor)",
                        path: p,
                        role: "Vzor tanca",
                        isImage: false,
                        date: nil
                    )
                )
            }
            if let p = dance.imagePath, !seenPaths.contains(p) {
                seenPaths.insert(p)
                items.append(
                    MediaItemRecord(
                        id: "dance_img_\(dance.id)",
                        title: "\(dance.name) (Foto)",
                        path: p,
                        role: "Foto tanca",
                        isImage: true,
                        date: nil
                    )
                )
            }
        }
        
        return items
    }
    
    var filteredItems: [MediaItemRecord] {
        aggregatedItems.filter { item in
            // Search filter
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let matches = item.title.lowercased().contains(q) || item.role.lowercased().contains(q)
                if !matches { return false }
            }
            
            // Category filter
            switch selectedMediaTypeFilter {
            case .all:
                return true
            case .videos:
                return !item.isImage
            case .photos:
                return item.isImage
            case .idols:
                return item.role.localizedCaseInsensitiveContains("vzor") || item.role.localizedCaseInsensitiveContains("idol")
            case .myTakes:
                return item.role.localizedCaseInsensitiveContains("moje") || item.role.localizedCaseInsensitiveContains("pokus")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                VStack(spacing: 0) {
                    // Top Action Buttons (Camera + iOS Photos Gallery)
                    topActionBar
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.gold400)
                        TextField("Hľadať podľa názvu...", text: $searchText)
                            .foregroundColor(.white)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.themeCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    
                    // Filter Chips Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MediaFilterType.allCases) { filter in
                                Button {
                                    selectedMediaTypeFilter = filter
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.system(size: 12, weight: selectedMediaTypeFilter == filter ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedMediaTypeFilter == filter ? Color.gold400 : Color.themeCard)
                                        .foregroundColor(selectedMediaTypeFilter == filter ? Color.obsidian900 : Color.white.opacity(0.75))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                    
                    // Content Grid / Empty state
                    if filteredItems.isEmpty {
                        emptyStateView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(filteredItems) { item in
                                    mediaCard(for: item)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 32)
                        }
                    }
                }
                
                if isImporting {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color.gold400)
                            .scaleEffect(1.3)
                        Text("Spracovávam súbor...")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.obsidian800)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gold400.opacity(0.4), lineWidth: 1))
                }
            }
            .navigationTitle("Zvoliť pre: \(slotTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundColor(Color.gold400)
                }
                
                if currentPath != nil, let onClear = onClearMedia {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Vyčistiť slot") {
                            onClear()
                            dismiss()
                        }
                        .foregroundColor(Color.latinCrimson)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCameraModal) {
                DanceCameraView { localPath in
                    onSelectMedia(localPath)
                    dismiss()
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoLibraryImport(newItem)
            }
        }
    }
    
    // MARK: - Top Quick Actions (Camera & Gallery)
    private var topActionBar: some View {
        HStack(spacing: 10) {
            // Camera Button
            Button {
                showCameraModal = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "video.badge.plus.fill")
                        .font(.system(size: 13))
                    Text("Natočiť kamerou")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color.obsidian900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Photos & Videos Picker (Any: Videos + Images!)
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .any(of: [.videos, .images]),
                photoLibrary: .shared()
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 13))
                    Text("Z fotiek & videí")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Media Item Card
    private func mediaCard(for item: MediaItemRecord) -> some View {
        let isSelected = currentPath == item.path
        
        return Button {
            onSelectMedia(item.path)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    MediaThumbnailView(path: item.path, placeholderIcon: item.isImage ? "photo" : "film", cornerRadius: 10)
                        .aspectRatio(16/11, contentMode: .fill)
                        .clipped()
                    
                    // Tag Badge
                    HStack {
                        Text(item.role)
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(item.isImage ? Color.blue.opacity(0.85) : Color.gold500.opacity(0.9))
                            .foregroundColor(item.isImage ? .white : Color.obsidian900)
                            .cornerRadius(5)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.syncEmerald)
                                .background(Color.black.clipShape(Circle()))
                        }
                    }
                    .padding(6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: item.isImage ? "camera.metering.center.weighted" : "video")
                            .font(.system(size: 9))
                            .foregroundColor(Color.gold400.opacity(0.8))
                        Text(item.isImage ? "Fotografia" : "Video záznam")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
            .background(Color.themeCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.gold400 : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 42))
                .foregroundColor(Color.gold400.opacity(0.4))
            
            Text("Žiadne zodpovedajúce médiá")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            Text("Nahraj video kamerou alebo vyber fotku/video z galérie tvojho iPhonu pomocou tlačidiel hore.")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Import Logic
    private func handlePhotoLibraryImport(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isImporting = true
        
        Task {
            // Check if movie
            if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
                if let filename = try? MediaStorageManager.copyIntoDocuments(from: movie.url, fileExtension: "mp4") {
                    await MainActor.run {
                        isImporting = false
                        onSelectMedia(filename)
                        dismiss()
                    }
                    return
                }
            }
            
            // Check if photo / image data
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let filename = try? MediaStorageManager.store(data: data, prefix: "import_photo", fileExtension: "jpg") {
                    await MainActor.run {
                        isImporting = false
                        onSelectMedia(filename)
                        dismiss()
                    }
                    return
                }
            }
            
            await MainActor.run {
                isImporting = false
            }
        }
    }
}
