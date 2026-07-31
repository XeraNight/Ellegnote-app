import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct GlobalLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FigureLibraryItem.name) private var allFigures: [FigureLibraryItem]
    
    @State private var searchText = ""
    @State private var selectedDanceFilter = "Všetky"
    
    @State private var showAddFigure = false
    @State private var newFigureName = ""
    @State private var newFigureDance = "Waltz"
    @State private var newFigureRhythm = ""
    @State private var newFigureNotes = ""
    
    // Selection state for editing a figure
    @State private var selectedFigureForEdit: FigureLibraryItem?
    
    let danceNames = ["Waltz", "Tango", "Viennese Waltz", "Slowfoxtrot", "Quickstep", "Samba", "Cha-Cha-Cha", "Rumba", "Paso Doble", "Jive"]
    
    var filteredFigures: [FigureLibraryItem] {
        allFigures.filter { fig in
            let matchesSearch = searchText.isEmpty || fig.name.localizedCaseInsensitiveContains(searchText)
            let matchesDance = selectedDanceFilter == "Všetky" || fig.danceName.lowercased() == selectedDanceFilter.lowercased()
            return matchesSearch && matchesDance
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Hľadať figúru...", text: $searchText)
                            .foregroundColor(.themeDark)
                    }
                    .padding()
                    .neubrutalistCard(cornerRadius: 12, shadowOffset: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Horizontal scroll filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "Všetky", isSelected: selectedDanceFilter == "Všetky") {
                                selectedDanceFilter = "Všetky"
                            }
                            
                            ForEach(danceNames, id: \.self) { dance in
                                FilterChip(title: dance, isSelected: selectedDanceFilter == dance) {
                                    selectedDanceFilter = dance
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    
                    // Figures list
                    if filteredFigures.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("Nenašli sa žiadne figúry")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .neubrutalistCard(cornerRadius: 16, shadowOffset: 0)
                        .padding(.horizontal, 20)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFigures) { fig in
                                    Button(action: { selectedFigureForEdit = fig }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(fig.name)
                                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                                    .foregroundColor(.themeDark)
                                                Spacer()
                                                Text(fig.danceName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        fig.danceName.lowercased() == "waltz" || fig.danceName.lowercased() == "tango" || fig.danceName.lowercased() == "viennese waltz" || fig.danceName.lowercased() == "slowfoxtrot" || fig.danceName.lowercased() == "quickstep" ? Color.standardBlue : Color.latinPink
                                                    )
                                                    .cornerRadius(6)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.themeDark, lineWidth: 1.5)
                                                    )
                                            }
                                            
                                            HStack {
                                                if !fig.rhythm.isEmpty {
                                                    Text("Rytmus: \(fig.rhythm)")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.themeAccent)
                                                }
                                                
                                                Spacer()
                                                
                                                // Media indicators
                                                HStack(spacing: 8) {
                                                    if fig.imagePath != nil {
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.themeAccent)
                                                    }
                                                    if fig.videoPath != nil {
                                                        Image(systemName: "video.fill")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.themeAccent)
                                                    }
                                                }
                                            }
                                            
                                            if !fig.techniqueNotes.isEmpty {
                                                Text(fig.techniqueNotes)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        .padding()
                                        .neubrutalistCard(cornerRadius: 14, shadowOffset: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Knižnica Figúr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddFigure = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.themeDark)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.neubrutalistSecondary(cornerRadius: 10))
                }
            }
            .sheet(isPresented: $showAddFigure) {
                NavigationStack {
                    ZStack {
                        Color.themeBg.ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Názov figúry")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.themeDark.opacity(0.55))
                                        TextField("napr. Spin Turn", text: $newFigureName)
                                            .padding()
                                            .background(Color.themeCard)
                                            .cornerRadius(10)
                                            .foregroundColor(.themeDark)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.themeDark, lineWidth: 2)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Tanec")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.themeDark.opacity(0.55))
                                        
                                        Picker("Priradiť k tancu", selection: $newFigureDance) {
                                            ForEach(danceNames, id: \.self) { dance in
                                                Text(dance).tag(dance)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.themeCard)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.themeDark, lineWidth: 2)
                                        )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Rytmizácia")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.themeDark.opacity(0.55))
                                        TextField("napr. 1, 2, 3", text: $newFigureRhythm)
                                            .padding()
                                            .background(Color.themeCard)
                                            .cornerRadius(10)
                                            .foregroundColor(.themeDark)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.themeDark, lineWidth: 2)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Technika / Popis")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.themeDark.opacity(0.55))
                                        TextEditor(text: $newFigureNotes)
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
                                
                                Button(action: saveFigure) {
                                    Text("Uložiť do knižnice")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.neubrutalist(accentColor: newFigureName.isEmpty ? Color.gray.opacity(0.6) : Color.themeAccent))
                                .disabled(newFigureName.isEmpty)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                            .padding(.top, 20)
                        }
                    }
                    .navigationTitle("Pridať novú figúru")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Zrušiť") { showAddFigure = false }
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
            .sheet(item: $selectedFigureForEdit) { fig in
                LibraryFigureDetailSheet(figure: fig)
            }
        }
    }
    
    private func saveFigure() {
        guard !newFigureName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let fig = FigureLibraryItem(
            name: newFigureName,
            danceName: newFigureDance,
            rhythm: newFigureRhythm,
            techniqueNotes: newFigureNotes,
            isCustom: true
        )
        modelContext.insert(fig)
        try? modelContext.save()
        
        // Background sync to Supabase Database
        let figId = fig.id
        let name = fig.name
        let dance = fig.danceName
        let rhythm = fig.rhythm
        let technique = fig.techniqueNotes
        let isCust = fig.isCustom
        Task.detached(priority: .background) {
            await SupabaseSyncManager.shared.syncFigure(
                figId,
                name: name,
                danceName: dance,
                rhythm: rhythm,
                notes: technique,
                imagePath: nil,
                videoPath: nil,
                isCustom: isCust
            )
        }
        
        // Reset states
        newFigureName = ""
        newFigureRhythm = ""
        newFigureNotes = ""
        showAddFigure = false
    }
}

// MARK: - Library Figure Detail / Edit Sheet
struct LibraryFigureDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var figure: FigureLibraryItem
    @AppStorage("defaultPlaybackRate") private var defaultPlaybackRate = 1.0
    @State private var cacheTrigger = false
    
    @State private var nameText = ""
    @State private var rhythmText = ""
    @State private var notesText = ""
    @State private var playbackRate: Float = 1.0
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Edit inputs
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Názov figúry")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("Názov", text: $nameText)
                                    .padding()
                                    .background(Color.themeCard)
                                    .cornerRadius(10)
                                    .foregroundColor(.themeDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Rytmizácia")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.themeDark.opacity(0.55))
                                TextField("Rytmus", text: $rhythmText)
                                    .padding()
                                    .background(Color.themeCard)
                                    .cornerRadius(10)
                                    .foregroundColor(.themeDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Image section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fotografia")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            
                            if let imagePath = figure.imagePath,
                               let uiImage = MediaResolver.resolveImage(path: imagePath) {
                                
                                VStack(spacing: 12) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.themeDark, lineWidth: 2)
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
                                }
                                .buttonStyle(.neubrutalistSecondary(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Video section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Video ukážka")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            
                            if let videoPath = figure.videoPath,
                               let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                                
                                VStack(spacing: 12) {
                                    LoopingVideoPlayer(videoURL: videoURL, rate: playbackRate)
                                        .frame(height: 200)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.themeDark, lineWidth: 2)
                                        )
                                    
                                    HStack(spacing: 12) {
                                        Text("Rýchlosť:")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.themeDark.opacity(0.55))
                                        
                                        ForEach([0.5, 0.75, 1.0, 1.5], id: \.self) { speed in
                                            Button(action: { playbackRate = Float(speed) }) {
                                                Text(String(format: "%.2fx", speed))
                                                    .font(.system(size: 11, weight: .black))
                                            }
                                            .buttonStyle(.neubrutalistToggle(isActive: playbackRate == Float(speed), activeColor: Color.themeAccent, cornerRadius: 8))
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
                                }
                                .buttonStyle(.neubrutalistSecondary(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Text notes section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Technika / Popis")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            
                            TextEditor(text: $notesText)
                                .scrollContentBackground(.hidden)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.themeCard)
                                .foregroundColor(.themeDark)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeDark, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Instant Notes Inbox Section
                        InstantNotesInboxSection(
                            onImportText: { text in
                                if !notesText.isEmpty {
                                    notesText += "\n" + text
                                } else {
                                    notesText = text
                                }
                            },
                            onImportVideo: { videoPath in
                                figure.videoPath = videoPath
                                try? modelContext.save()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Delete Button
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Odstrániť figúru z knižnice")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.neubrutalist(accentColor: Color.latinRed))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(figure.name)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MediaCacheDidUpdate"))) { _ in
                cacheTrigger.toggle()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .confirmationDialog("Naozaj chcete vymazať túto figúru z knižnice?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Vymazať figúru", role: .destructive) {
                    deleteFigureItem()
                }
                Button("Zrušiť", role: .cancel) {}
            }
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
                nameText = figure.name
                rhythmText = figure.rhythm
                notesText = figure.techniqueNotes
                playbackRate = Float(defaultPlaybackRate)
            }
            .fullScreenCover(isPresented: $showCamera) {
                VideoRecorderView { localPath in
                    figure.videoPath = localPath
                    try? modelContext.save()
                    showCamera = false
                    
                    // Background Sync to Supabase Storage & Database
                    let figId = figure.id
                    let name = figure.name
                    let dance = figure.danceName
                    let rhythm = figure.rhythm
                    let technique = figure.techniqueNotes
                    let imagePath = figure.imagePath
                    let videoPath = figure.videoPath
                    let isCust = figure.isCustom
                    Task.detached(priority: .background) {
                        if let videoPath {
                            await SupabaseSyncManager.shared.uploadFileAsync(localFileName: videoPath)
                        }
                        await SupabaseSyncManager.shared.syncFigure(
                            figId,
                            name: name,
                            danceName: dance,
                            rhythm: rhythm,
                            notes: technique,
                            imagePath: imagePath,
                            videoPath: videoPath,
                            isCustom: isCust
                        )
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let filename = try? MediaStorageManager.store(data: data, prefix: "fig_img", fileExtension: "jpg") {
                            await MainActor.run {
                                MediaStorageManager.removeFile(named: figure.imagePath)
                                figure.imagePath = filename
                                try? modelContext.save()
                                
                                // Background Sync to Supabase Storage & Database
                                let figId = figure.id
                                let name = figure.name
                                let dance = figure.danceName
                                let rhythm = figure.rhythm
                                let technique = figure.techniqueNotes
                                let imagePath = figure.imagePath
                                let videoPath = figure.videoPath
                                let isCust = figure.isCustom
                                Task.detached(priority: .background) {
                                    if let imagePath {
                                        await SupabaseSyncManager.shared.uploadFileAsync(localFileName: imagePath)
                                    }
                                    await SupabaseSyncManager.shared.syncFigure(
                                        figId,
                                        name: name,
                                        danceName: dance,
                                        rhythm: rhythm,
                                        notes: technique,
                                        imagePath: imagePath,
                                        videoPath: videoPath,
                                        isCustom: isCust
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        figure.name = nameText
        figure.rhythm = rhythmText
        figure.techniqueNotes = notesText
        try? modelContext.save()
        
        // Background Sync to Supabase Database
        let figId = figure.id
        let name = figure.name
        let dance = figure.danceName
        let rhythm = figure.rhythm
        let technique = figure.techniqueNotes
        let imagePath = figure.imagePath
        let videoPath = figure.videoPath
        let isCust = figure.isCustom
        Task.detached(priority: .background) {
            await SupabaseSyncManager.shared.syncFigure(
                figId,
                name: name,
                danceName: dance,
                rhythm: rhythm,
                notes: technique,
                imagePath: imagePath,
                videoPath: videoPath,
                isCustom: isCust
            )
        }
    }
    
    private func deletePhoto() {
        if let path = figure.imagePath {
            MediaStorageManager.removeFile(named: path)
        }
        figure.imagePath = nil
        try? modelContext.save()
        
        // Background Sync to Supabase Database
        let figId = figure.id
        let name = figure.name
        let dance = figure.danceName
        let rhythm = figure.rhythm
        let technique = figure.techniqueNotes
        let videoPath = figure.videoPath
        let isCust = figure.isCustom
        Task.detached(priority: .background) {
            await SupabaseSyncManager.shared.syncFigure(
                figId,
                name: name,
                danceName: dance,
                rhythm: rhythm,
                notes: technique,
                imagePath: nil,
                videoPath: videoPath,
                isCustom: isCust
            )
        }
    }
    
    private func deleteVideo() {
        if let path = figure.videoPath {
            MediaStorageManager.removeFile(named: path)
        }
        figure.videoPath = nil
        try? modelContext.save()
        
        // Background Sync to Supabase Database
        let figId = figure.id
        let name = figure.name
        let dance = figure.danceName
        let rhythm = figure.rhythm
        let technique = figure.techniqueNotes
        let imagePath = figure.imagePath
        let isCust = figure.isCustom
        Task.detached(priority: .background) {
            await SupabaseSyncManager.shared.syncFigure(
                figId,
                name: name,
                danceName: dance,
                rhythm: rhythm,
                notes: technique,
                imagePath: imagePath,
                videoPath: nil,
                isCustom: isCust
            )
        }
    }
    
    private func deleteFigureItem() {
        let figId = figure.id
        
        // First delete any image/video files on disk
        if let imagePath = figure.imagePath {
            MediaStorageManager.removeFile(named: imagePath)
        }
        if let videoPath = figure.videoPath {
            MediaStorageManager.removeFile(named: videoPath)
        }
        
        modelContext.delete(figure)
        try? modelContext.save()
        
        // Background Delete from Supabase Database
        Task.detached(priority: .background) {
            await SupabaseSyncManager.shared.deleteFigure(figId)
        }
        
        dismiss()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Filter Chip View
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : .themeDark)
        }
        .buttonStyle(.neubrutalistToggle(isActive: isSelected, activeColor: Color.themeAccent, cornerRadius: 20))
    }
}
