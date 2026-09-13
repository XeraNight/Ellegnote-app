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
    
    // MARK: - Per-Account Profile Store (prevents cross-user profile leaks)
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var showEditProfile = false
    @State private var showResetConfirmation = false
    @State private var pendingMaintenanceAction: MaintenanceAction?
    @State private var editedName = ""
    @State private var editedClub = ""
    @State private var selectedProfilePhotoItem: PhotosPickerItem?
    @State private var isSavingProfilePhoto = false
    @State private var imageToCrop: UIImage? = nil
    @State private var showCropSheet = false
    @State private var showAuthSheet = false
    
    // Storage loaded async to avoid file I/O on main thread
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
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Encore v\(version) (\(build)) • Crimson & Gold"
    }

    // MARK: - Body sections (Luxury Obsidian & Gold Styling)

    @ViewBuilder private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Moje Štatistiky").sectionHeader()
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                StatCardView(title: "Zostavy", value: "\(routines.count)", icon: "figure.dance")
                StatCardView(title: "Moje figúry", value: "\(customFiguresCount)", icon: "book.closed.fill")
                StatCardView(title: "Videá", value: "\(videoCount)", icon: "video.fill")
                StatCardView(title: "Poznámky", value: "\(notesCount)", icon: "mic.fill")
                StatCardView(title: "Standard", value: "\(standardCount)", icon: "drop.fill", tintColor: .standardBlue)
                StatCardView(title: "Latin", value: "\(latinCount)", icon: "flame.fill", tintColor: .latinPink)
                StatCardView(title: "Najviac cvičené", value: mostUsedDanceName, icon: "chart.line.uptrend.xyaxis")
                StatCardView(title: "Úložisko", value: storageUsageText, icon: "internaldrive.fill")
            }
        }
    }

    @ViewBuilder private var linksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Odkazy v Nastaveniach").sectionHeader()
            VStack(spacing: 1) {
                NavigationLink(destination: ProfileRoutinesListView(routines: recentRoutines)) {
                    SettingsNavigationRow(icon: "figure.dance", title: "Všetky zostavy", detail: "\(routines.count)")
                }
                .buttonStyle(.plain)
                
                Divider().background(Color.gold500.opacity(0.15))
                
                NavigationLink(destination: ProfileFiguresListView(figures: figures.sorted { $0.name < $1.name })) {
                    SettingsNavigationRow(icon: "book.closed.fill", title: "Knižnica figúr", detail: "\(figures.count)")
                }
                .buttonStyle(.plain)
                
                Divider().background(Color.gold500.opacity(0.15))
                
                NavigationLink(destination: ProfileMediaListView(dances: dances, figures: figures, nodes: nodes)) {
                    SettingsNavigationRow(icon: "video.fill", title: "Videá a poznámky", detail: "\(videoCount + notesCount)")
                }
                .buttonStyle(.plain)
            }
            .luxuryProfileCard(cornerRadius: 18)
        }
    }
    
    @ViewBuilder private var trainingToolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trénerské Štúdio").sectionHeader()
            NavigationLink(destination: StudioToolsView()) {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gold400)
                        .frame(width: 44, height: 44)
                        .background(Color.gold500.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gold500.opacity(0.3), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trénerské & Súťažné Štúdio")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Simulátor finále, Organizér, Speed trainer, Splitter")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gold300.opacity(0.65))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gold400.opacity(0.6))
                }
                .padding(16)
                .luxuryProfileCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                            Divider().background(Color.gold500.opacity(0.15))
                        }
                    }
                }
                .luxuryProfileCard(cornerRadius: 18)
            }
        }
    }

    @ViewBuilder private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Predvoľby Aplikácie").sectionHeader()
            VStack(spacing: 1) {
                SettingsPickerRow(icon: "globe", title: "Jazyk diktovania") {
                    Picker("", selection: Binding(
                        get: { profileStore.currentLanguage },
                        set: { profileStore.setLanguage($0) }
                    )) {
                        Text("Slovenčina").tag("sk-SK")
                        Text("English").tag("en-US")
                    }
                    .pickerStyle(.menu)
                    .tint(Color.gold400)
                }
                
                Divider().background(Color.gold500.opacity(0.15))
                
                SettingsPickerRow(icon: "play.circle", title: "Rýchlosť videa") {
                    Picker("", selection: Binding(
                        get: { profileStore.currentPlaybackRate },
                        set: { profileStore.setPlaybackRate($0) }
                    )) {
                        Text("0.5x").tag(0.5)
                        Text("0.75x").tag(0.75)
                        Text("1.0x").tag(1.0)
                        Text("1.5x").tag(1.5)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.gold400)
                }
                
                Divider().background(Color.gold500.opacity(0.15))
                
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.gold400)
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.gold500.opacity(0.12))
                        .clipShape(Circle())
                    Text("Upozornenia a tréningy")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $notificationManager.notificationsEnabled)
                        .labelsHidden()
                        .tint(Color.gold500)
                        .onChange(of: notificationManager.notificationsEnabled) { _, isEnabled in
                            if isEnabled && !notificationManager.isAuthorized {
                                Task { await notificationManager.requestAuthorization() }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.obsidian800)
                
                Divider().background(Color.gold500.opacity(0.15))
                
                HStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .foregroundColor(.gold400)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.gold500.opacity(0.12))
                        .clipShape(Circle())
                    Text("Prihlásenie cez Face ID")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Nastavenia")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.gold400)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gold500.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.obsidian800)
            }
            .luxuryProfileCard(cornerRadius: 18)
        }
    }

    @ViewBuilder private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Údržba a Dáta").sectionHeader()
            VStack(spacing: 1) {
                MaintenanceButton(icon: "arrow.counterclockwise.circle.fill",
                                  title: "Obnoviť predvolenú knižnicu figúr",
                                  isDestructive: false) { showResetConfirmation = true }
                Divider().background(Color.gold500.opacity(0.15))
                MaintenanceButton(icon: "square.and.arrow.up",
                                  title: "Exportovať zostavy (JSON)",
                                  isDestructive: false) { exportRoutines() }
                Divider().background(Color.gold500.opacity(0.15))
                MaintenanceButton(icon: "video.slash.fill",
                                  title: "Vymazať všetky videá",
                                  isDestructive: true) { pendingMaintenanceAction = .clearVideos }
                Divider().background(Color.gold500.opacity(0.15))
                MaintenanceButton(icon: "text.badge.xmark",
                                  title: "Vymazať všetky poznámky",
                                  isDestructive: true) { pendingMaintenanceAction = .clearNotes }
            }
            .luxuryProfileCard(cornerRadius: 18)
        }
    }

    // MARK: - Top Auth & Sync Card (Matching AuthSheetView)
    @ViewBuilder private var authCardSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .foregroundColor(.gold400)
                    .font(.system(size: 13, weight: .bold))
                Text("TANEČNÝ ÚČET A REALTIME SYNC")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(Color.gold400.opacity(0.85))
                    .tracking(0.5)
                Spacer()
            }
            
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    let emailText = authManager.userEmail.isEmpty ? "Lokálny profil" : authManager.userEmail
                    if authManager.isAuthenticated {
                        Text(emailText)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        HStack(spacing: 5) {
                            Circle().fill(Color.syncEmerald).frame(width: 6, height: 6)
                                .shadow(color: Color.syncEmerald.opacity(0.8), radius: 3)
                            Text("Synchrónne úpravy aktívne")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.syncEmerald)
                        }
                    } else {
                        Text("Používaš lokálny režim")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Prihlás sa pre synchronizáciu zostáv")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.gold300.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                Button(action: {
                    if authManager.isAuthenticated {
                        Task { await authManager.signOut() }
                    } else {
                        showAuthSheet = true
                    }
                }) {
                    if authManager.isAuthenticated {
                        Text("Odhlásiť")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.latinRed)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.latinRed.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.latinRed.opacity(0.35), lineWidth: 1)
                            )
                    } else {
                        HStack(spacing: 4) {
                            Text("Prihlásiť")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.obsidian900)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.gold500, Color.gold400],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.gold500.opacity(0.3), radius: 6, x: 0, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .luxuryProfileCard(cornerRadius: 20)
    }

    private func handleOnAppear() {
        cachedStats = computeStats()
        profileStore.refreshForActiveUser()
    }

    @ViewBuilder
    private func profileContent(screenWidth: CGFloat, autoSidePadding: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top safe spacing so card doesn't hit dynamic island
                Spacer(minLength: 4)
                
                authCardSection
                    .sheet(isPresented: $showAuthSheet) {
                        AuthSheetView()
                    }
                
                ProfileHeaderView(
                    name: profileStore.currentName,
                    club: profileStore.currentClub,
                    imagePath: profileStore.currentAvatarPath,
                    avatarURL: authManager.userAvatarURL,
                    routineCount: routines.count,
                    customFiguresCount: customFiguresCount
                ) {
                    editedName = profileStore.currentName
                    editedClub = profileStore.currentClub
                    showEditProfile = true
                }
                
                statsSection
                trainingToolsSection
                linksSection
                routinesSection
                preferencesSection
                maintenanceSection
                
                Text(appVersion)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gold300.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
                // Bottom spacing above floating liquid glass dock
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, autoSidePadding)
            .padding(.top, 14)
            .frame(width: screenWidth)
        }
    }

    private var isMaintenanceActionPresented: Binding<Bool> {
        Binding(
            get: { self.pendingMaintenanceAction != nil },
            set: { if !$0 { self.pendingMaintenanceAction = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Unified Luxury Obsidian Canvas & Blooms
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    let autoSidePadding = max(screenWidth * 0.08, 22)
                    profileContent(screenWidth: screenWidth, autoSidePadding: autoSidePadding)
                }
            }
            .navigationTitle("Môj Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { handleOnAppear() }
            .onChange(of: nodes.count)    { _, _ in self.cachedStats = self.computeStats() }
            .onChange(of: figures.count)  { _, _ in self.cachedStats = self.computeStats() }
            .onChange(of: dances.count)   { _, _ in self.cachedStats = self.computeStats() }
            .onChange(of: routines.count) { _, _ in self.cachedStats = self.computeStats() }
            .task { refreshStorageUsage() }
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .confirmationDialog("Naozaj obnoviť knižnicu?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Obnoviť knižnicu", role: .destructive) { resetFiguresDatabase() }
                Button("Zrušiť", role: .cancel) {}
            } message: {
                Text("Všetky vaše vlastné figúry budú zachované, ale predvolené figúry budú znova načítané.")
            }
            .confirmationDialog(
                pendingMaintenanceAction?.title ?? "",
                isPresented: isMaintenanceActionPresented,
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
    
    // MARK: - Edit Profile Sheet
    @ViewBuilder private var editProfileSheet: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [Color.gold500.opacity(0.14), Color.clear]),
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 320
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 12) {
                            ProfileAvatarView(
                                name: editedName.isEmpty ? profileStore.currentName : editedName,
                                imagePath: profileStore.currentAvatarPath,
                                avatarURL: authManager.userAvatarURL,
                                size: 104
                            )
                            
                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 13, weight: .bold))
                                        Text(isSavingProfilePhoto ? "Ukladám..." : "Zmeniť fotku")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(.gold400)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.gold500.opacity(0.12))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                                    )
                                }
                                .disabled(isSavingProfilePhoto)
                                
                                if let path = profileStore.currentAvatarPath,
                                   let currentImg = MediaResolver.resolveImage(path: path) {
                                    Button {
                                        imageToCrop = currentImg
                                        showCropSheet = true
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "crop")
                                                .font(.system(size: 12, weight: .bold))
                                            Text("Upraviť výrez")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(.gold400)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.gold500.opacity(0.12))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            if profileStore.currentAvatarPath != nil {
                                Button(role: .destructive) {
                                    removeProfilePhoto()
                                } label: {
                                    Label("Odstrániť fotku", systemImage: "trash")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.latinRed)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meno")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.gold400)
                            TextField("", text: $editedName, prompt: Text("Tvoje meno").foregroundColor(Color.gold300.opacity(0.45)))
                                .profileTextField()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tanečný klub")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.gold400)
                            TextField("", text: $editedClub, prompt: Text("Názov tanečného klubu").foregroundColor(Color.gold300.opacity(0.45)))
                                .profileTextField()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Upraviť profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.obsidian900, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { showEditProfile = false }
                        .foregroundColor(Color.white.opacity(0.7))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Uložiť") { saveProfile() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.gold400)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") { UIApplication.shared.endEditing() }
                        .foregroundColor(.gold400)
                }
            }
            .onChange(of: selectedProfilePhotoItem) { _, newItem in
                guard let newItem else { return }
                handleSelectedPhoto(from: newItem)
            }
            .sheet(isPresented: $showCropSheet) {
                if let imageToCrop {
                    AvatarCropperSheet(
                        originalImage: imageToCrop,
                        onSave: { cropped in
                            saveCroppedAvatar(cropped)
                        },
                        onCancel: {
                            showCropSheet = false
                            self.imageToCrop = nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        profileStore.saveProfile(name: editedName, club: editedClub)
        showEditProfile = false
    }
    
    private func handleSelectedPhoto(from item: PhotosPickerItem) {
        isSavingProfilePhoto = true
        Task {
            defer {
                selectedProfilePhotoItem = nil
                isSavingProfilePhoto = false
            }
            
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImg = UIImage(data: data) else { return }
            
            await MainActor.run {
                self.imageToCrop = uiImg
                self.showCropSheet = true
            }
        }
    }
    
    private func saveCroppedAvatar(_ image: UIImage) {
        isSavingProfilePhoto = true
        showCropSheet = false
        imageToCrop = nil
        Task {
            defer {
                isSavingProfilePhoto = false
            }
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            let oldPath = profileStore.currentAvatarPath
            let uid = profileStore.activeUserId
            
            do {
                let filename = try await Task.detached(priority: .userInitiated) {
                    try MediaStorageManager.store(data: data, prefix: "profile_\(uid)", fileExtension: "jpg")
                }.value
                
                await MainActor.run {
                    profileStore.setAvatarPath(filename)
                    MediaStorageManager.removeFile(named: oldPath)
                    refreshStorageUsage()
                }
            } catch {
                print("Failed to save cropped profile avatar: \(error)")
            }
        }
    }
    
    private func removeProfilePhoto() {
        if let oldPath = profileStore.currentAvatarPath {
            MediaStorageManager.removeFile(named: oldPath)
        }
        profileStore.setAvatarPath(nil)
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
        if let currentAvatar = profileStore.currentAvatarPath, !currentAvatar.isEmpty {
            paths.append(currentAvatar)
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
    
    nonisolated private func calculateStorageUsage(for paths: [String]) -> Int64 {
        MediaStorageManager.totalSize(for: paths)
    }
    
    private func removeMediaFile(at path: String?) {
        guard let path else { return }
        MediaStorageManager.removeFile(named: path)
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

// MARK: - Subviews & Components

private struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.gold400)
                .frame(width: 32, height: 32)
                .background(Color.gold500.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(detail)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.gold400)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gold400.opacity(0.4))
        }
        .padding(16)
        .background(Color.obsidian800)
    }
}

private struct ProfileRoutinesListView: View {
    let routines: [Routine]
    
    var body: some View {
        ZStack {
            Color.obsidian900.ignoresSafeArea()
            if routines.isEmpty {
                EmptyProfileSectionView(icon: "rectangle.dashed", title: "Zatiaľ nemáš žiadne zostavy").padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineCanvasView(routine: routine)) {
                                RecentRoutineRow(routine: routine)
                                    .cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold500.opacity(0.25), lineWidth: 1))
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
            Color.obsidian900.ignoresSafeArea()
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
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(figure.isCustom ? "Vlastná" : "Default")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.obsidian900)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(figure.isCustom ? Color.gold400 : Color.standardBlue)
                    .cornerRadius(8)
            }
            HStack(spacing: 10) {
                Text(figure.danceName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.gold300.opacity(0.65))
                if !figure.rhythm.isEmpty {
                    Text(figure.rhythm)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gold400)
                }
                Spacer()
                if figure.imagePath != nil { Image(systemName: "photo").foregroundColor(Color.white.opacity(0.5)) }
                if figure.videoPath != nil { Image(systemName: "video.fill").foregroundColor(Color.gold400) }
            }
        }
        .padding(16)
        .background(Color.obsidian800)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold500.opacity(0.25), lineWidth: 1))
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
            Color.obsidian900.ignoresSafeArea()
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
                .foregroundColor(.gold400)
            VStack(spacing: 1) { content }
                .background(Color.obsidian800)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold500.opacity(0.25), lineWidth: 1))
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
                    .foregroundColor(.white).lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gold300.opacity(0.65)).lineLimit(1)
            }
            Spacer()
            if hasVideo { Image(systemName: "video.fill").foregroundColor(.gold400) }
            if hasNote  { Image(systemName: "text.alignleft").foregroundColor(.gold400) }
        }
        .padding(14)
        .background(Color.obsidian800)
    }
}

// MARK: - Profile Header View (Luxury Monogram & Golden Specular Design)

private struct ProfileHeaderView: View {
    let name: String
    let club: String
    let imagePath: String?
    var avatarURL: String? = nil
    let routineCount: Int
    let customFiguresCount: Int
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar with camera badge
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(name: name, imagePath: imagePath, avatarURL: avatarURL, size: 92)
                
                Circle()
                    .fill(Color.obsidian800)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.gold500.opacity(0.6), lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gold400)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                    .offset(x: 2, y: 2)
            }
            
            // Name & Club
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: Color.gold500.opacity(0.35), radius: 10)
                
                if !club.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Tanečný klub: \(club)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.gold300.opacity(0.75))
                } else {
                    Text("Klub zatiaľ nenastavený")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
            
            // Counter Pills
            HStack(spacing: 10) {
                ProfilePill(title: "\(routineCount) zostáv", icon: "figure.dance")
                ProfilePill(title: "\(customFiguresCount) figúr", icon: "book.closed.fill")
            }
            
            // Edit Profile Button
            Button(action: onEdit) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                    Text("Upraviť profil")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color.obsidian800)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gold500.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Profile Avatar View (Initial-based Monogram or Photo)

private struct ProfileAvatarView: View {
    let name: String
    let imagePath: String?
    var avatarURL: String? = nil
    let size: CGFloat
    
    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(separator: " ").prefix(2).compactMap(\.first)
        if !words.isEmpty {
            return String(words).uppercased()
        }
        return trimmed.prefix(1).uppercased().isEmpty ? "T" : String(trimmed.prefix(1)).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Inner base circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.obsidian800, Color.obsidian700],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Photo or Initials Monogram
            if let imagePath, !imagePath.isEmpty, let uiImage = MediaResolver.resolveImage(path: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        Text(initials)
                            .font(.system(size: size * 0.38, weight: .black, design: .serif))
                            .foregroundColor(.gold400)
                            .shadow(color: Color.gold500.opacity(0.4), radius: 6)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                // Luxury Initials Monogram
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .black, design: .serif))
                    .foregroundColor(.gold400)
                    .shadow(color: Color.gold500.opacity(0.45), radius: 8)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(
            // Ambient outer bloom behind the frame
            Circle()
                .fill(Color.gold500.opacity(0.28))
                .frame(width: size + 14, height: size + 14)
                .blur(radius: 10)
        )
        .overlay(
            // Crisp Golden Luxury Rim Frame on top of the photo
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.gold300, Color.gold500, Color.gold400, Color.gold300],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        )
        .overlay(
            // Inner specular rim for high-end jewelry-grade depth
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                .padding(1.2)
        )
        .shadow(color: Color.gold500.opacity(0.25), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Avatar Cropper & Positioning Sheet (Interactive Zoom & Pan)

private struct AvatarCropperSheet: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let cropSize: CGFloat = 260
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Pohybom a priblížením prispôsob fotku do rámu")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.gold300.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                    
                    Spacer()
                    
                    // Viewport Container
                    ZStack {
                        // Background base
                        Circle()
                            .fill(Color.obsidian800)
                            .frame(width: cropSize, height: cropSize)
                        
                        // User photo with pan and pinch zoom
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: cropSize, height: cropSize)
                            .clipShape(Circle())
                        
                        // Luxury Outer Frame Rim
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.gold300, Color.gold500, Color.gold400, Color.gold300],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.5
                            )
                            .frame(width: cropSize, height: cropSize)
                        
                        // Inner specular accent
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            .frame(width: cropSize - 4, height: cropSize - 4)
                    }
                    .frame(width: cropSize, height: cropSize)
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = max(0.5, min(scale * delta, 5.0))
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                    )
                    .shadow(color: Color.gold500.opacity(0.35), radius: 18)
                    
                    Spacer()
                    
                    // Controls: Zoom Slider & Reset button
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(Color.gold400.opacity(0.7))
                                .font(.system(size: 15))
                            
                            Slider(value: $scale, in: 0.6...4.0)
                                .tint(Color.gold400)
                            
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(Color.gold400)
                                .font(.system(size: 15))
                        }
                        .padding(.horizontal, 36)
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                                lastScale = 1.0
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Vycentrovať")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(Color.gold400)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gold500.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Upraviť fotku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.obsidian900, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { onCancel() }
                        .foregroundColor(Color.white.opacity(0.7))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Použiť") {
                        let cropped = renderCroppedImage()
                        onSave(cropped)
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.gold400)
                }
            }
        }
    }
    
    private func renderCroppedImage() -> UIImage {
        let targetSize: CGFloat = 512
        let ratio = targetSize / cropSize
        
        let imgW = originalImage.size.width
        let imgH = originalImage.size.height
        guard imgW > 0, imgH > 0 else { return originalImage }
        
        let aspect = imgW / imgH
        let baseW: CGFloat
        let baseH: CGFloat
        if aspect > 1.0 {
            baseH = cropSize
            baseW = cropSize * aspect
        } else {
            baseW = cropSize
            baseH = cropSize / aspect
        }
        
        let displayedW = baseW * scale
        let displayedH = baseH * scale
        let imgX = (cropSize - displayedW) / 2.0 + offset.width
        let imgY = (cropSize - displayedH) / 2.0 + offset.height
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSize, height: targetSize), format: format)
        return renderer.image { _ in
            let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
            circle.addClip()
            
            originalImage.draw(in: CGRect(
                x: imgX * ratio,
                y: imgY * ratio,
                width: displayedW * ratio,
                height: displayedH * ratio
            ))
        }
    }
}

private struct ProfilePill: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.obsidian800)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gold500.opacity(0.25), lineWidth: 1)
            )
    }
}

private struct RecentRoutineRow: View {
    let routine: Routine
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: routine.danceCategory.lowercased() == "standard" ? "drop.fill" : "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(routine.danceCategory.lowercased() == "standard" ? .standardBlue : .latinPink)
                .frame(width: 32, height: 32)
                .background(Color.gold500.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white).lineLimit(1)
                Text("\(routine.danceName) • \(routine.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gold300.opacity(0.65)).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gold400.opacity(0.4))
        }
        .padding(16)
        .background(Color.obsidian800)
    }
}

private struct EmptyProfileSectionView: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(Color.gold400.opacity(0.6))
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(Color.gold300.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .luxuryProfileCard(cornerRadius: 16)
    }
}

private struct SettingsPickerRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.gold400)
                .frame(width: 28, height: 28)
                .background(Color.gold500.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.obsidian800)
    }
}

private struct MaintenanceButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    private var tint: Color { isDestructive ? .latinRed : .white }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isDestructive ? .latinRed : .gold400)
                    .frame(width: 28, height: 28)
                    .background(isDestructive ? Color.latinRed.opacity(0.12) : Color.gold500.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isDestructive ? Color.latinRed.opacity(0.06) : Color.obsidian800)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View extensions & Luxury Card Modifier

private struct LuxuryProfileCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(Color.obsidian800)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.gold500.opacity(0.35),
                                Color.gold400.opacity(0.18),
                                Color.gold500.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 14, x: 0, y: 6)
    }
}

private extension View {
    func luxuryProfileCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(LuxuryProfileCardModifier(cornerRadius: cornerRadius))
    }
    
    func profileTextField() -> some View {
        self
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.obsidian800)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gold500.opacity(0.35), lineWidth: 1.5)
            )
    }
}

private extension Text {
    func sectionHeader() -> some View {
        self
            .font(.system(size: 15, weight: .bold, design: .serif))
            .foregroundColor(.gold400)
            .shadow(color: Color.gold500.opacity(0.35), radius: 6)
            .padding(.horizontal, 4)
    }
}

// MARK: - Stat Card View (Obsidian & Gold Specular Design)

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    var tintColor: Color = .gold400
    
    private var iconView: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(tintColor)
                .frame(width: 32, height: 32)
                .background(tintColor.opacity(0.15))
                .clipShape(Circle())
            Spacer()
        }
    }
    
    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.gold300.opacity(0.65))
                .lineLimit(1)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            iconView
            labelStack
        }
        .padding(16)
        .luxuryProfileCard(cornerRadius: 18)
    }
}
