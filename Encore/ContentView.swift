import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import OSLog
import AVFoundation

// MARK: - Capture Mode Enum
enum CaptureInputMode: String, CaseIterable, Identifiable {
    case text = "Text"
    case voice = "Hlas"
    case camera = "Kamera"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .text: return "square.and.pencil"
        case .voice: return "waveform"
        case .camera: return "video.fill"
        }
    }
}

// MARK: - Main Creative Workspace Home Screen
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // SwiftData Queries
    @Query(sort: \Dance.name) private var dances: [Dance]
    @Query(sort: \Routine.updatedAt, order: .reverse, animation: .easeInOut) private var routines: [Routine]
    @Query(filter: #Predicate<InstantNote> { $0.importedAt == nil },
           sort: \InstantNote.createdAt, order: .reverse) private var inboxNotes: [InstantNote]
    @Query(sort: \FigureLibraryItem.name) private var allFigures: [FigureLibraryItem]
    
    // Central Capture Area State
    @State private var activeCaptureMode: CaptureInputMode = .text
    @State private var noteDraftText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @State private var selectedNoteTags: [String] = []
    @State private var selectedDance: String? = nil
    @State private var savedCounter: Int = 0
    @State private var sweepTrigger: Int = 0
    @State private var showNotesInbox: Bool = false
    @State private var noteToEdit: InstantNote? = nil
    @Namespace private var modeNamespace
    @State private var showSavedFeedback: Bool = false
    
    // Voice Capture State
    
    // Camera Capture State
    @State private var showCameraModal: Bool = false
    @State private var capturedVideoPath: String? = nil
    
    // Interactive Logo Command Menu & Radial Hub State
    @State private var isRadialHubOpen: Bool = false
    @State private var showLogoCommandPalette: Bool = false
    @State private var commandSearchQuery: String = ""
    
    // Quick Actions & Navigation Modals
    @State private var showNewRoutineCategorySheet: Bool = false
    @State private var showDanceMirrorModal: Bool = false
    @State private var showCompetitionOrganizerSheet: Bool = false
    @State private var showMusicSpeedTrainerSheet: Bool = false
    @State private var showCompareModeSheet: Bool = false
    @State private var showGlobalLibrarySheet: Bool = false
    @State private var showAllRoutinesSheet: Bool = false
    @State private var selectedRoutineForNavigation: Routine? = nil
    
    // QR Code Share & Import State
    @State private var showQRScanner: Bool = false
    @State private var scanErrorMessage: String? = nil
    @State private var showScanError: Bool = false
    @State private var showScanSuccess: Bool = false
    @State private var scannedRoutineName: String = ""
    @State private var showManualCodeSheet: Bool = false
    @State private var manualCodeInput: String = ""
    
    // Compare Mode Slot States
    @State private var compareSlotAPath: String? = nil
    @State private var compareSlotBPath: String? = nil
    
    /// Pinned notes first, then newest.
    private var sortedInbox: [InstantNote] {
        inboxNotes.sorted { ($0.isPinned ? 1 : 0, $0.createdAt) > ($1.isPinned ? 1 : 0, $1.createdAt) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Obsidian Canvas with Ambient Blooms
                EllegancePageBackground()
                
                // Invisible Dismiss Backdrop when Radial Hub is Open (No darkening as requested)
                if isRadialHubOpen {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                isRadialHubOpen = false
                            }
                        }
                        .zIndex(20)
                }
                
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    let isCompact = screenWidth < 380
                    let logoSize: CGFloat = isCompact ? 78 : 92
                    let workspaceHeight = max(geo.size.height * 0.30, 220)
                    let safeTop = max(geo.safeAreaInsets.top, 44)
                    let horizontalMargin = screenWidth * 0.10 // 10% od oboch strán obrazovky
                    
                    ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            // ── 1. Top Minimal Header & Interactive Radial Hub ──
                            workspaceTopHeader(logoSize: logoSize)
                                .padding(.top, safeTop - 24)
                                .zIndex(isRadialHubOpen ? 100 : 1)
                                // Fade out while it scrolls under the status bar instead of being cut off.
                                .scrollTransition(.animated(.easeOut(duration: 0.15))) { content, phase in
                                    content.opacity(phase.isIdentity ? 1 : 0)
                                }
                            
                            // ── 2. Central Workspace (The White Box Area: Text / Voice / Video) ──
                            centralCaptureContent
                                .id("capture")
                                .frame(height: workspaceHeight)
                                .padding(.horizontal, 4)
                                .zIndex(isRadialHubOpen ? 0 : 2)
                            
                            // ── 3. Centered Mode Switcher (The 3 Centered Lines below Workspace) ──
                            modeSwitcherBar
                                .padding(.top, 4)
                            
                            // ── 4. Notes inbox ──
                            NotesInboxStrip(
                                notes: sortedInbox,
                                onOpenAll: { showNotesInbox = true },
                                onOpenNote: { noteToEdit = $0 }
                            )
                            .padding(.top, 6)
                            
                            // ── 5. Recently Edited Routine Card & Figure Content ──
                            recentlyEditedRoutineCard
                                .padding(.top, 6)
                            
                            // Bottom spacing for comfortable typing & dock
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(.horizontal, horizontalMargin)
                        .frame(maxWidth: .infinity)
                        // Tapping anywhere outside the field closes the keyboard.
                        .background {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { isTextEditorFocused = false }
                        }
                    }
                    .scrollDisabled(isRadialHubOpen)
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        UserProfileStore.shared.refreshForActiveUser()
                        await AuthManager.shared.checkCurrentSession()
                        if let cloudRoutines = await SupabaseSyncManager.shared.fetchAllRoutines() {
                            await MainActor.run {
                                let descriptor = FetchDescriptor<Routine>()
                                let localRoutines = (try? modelContext.fetch(descriptor)) ?? []
                                let localMap = Dictionary(uniqueKeysWithValues: localRoutines.map { ($0.id, $0) })
                                for cr in cloudRoutines {
                                    if let existing = localMap[cr.id] {
                                        if cr.updated_at > existing.updatedAt {
                                            existing.name = cr.name
                                            existing.danceName = cr.dance_name
                                            existing.danceCategory = cr.dance_category
                                            existing.updatedAt = cr.updated_at
                                            existing.lastModifiedBy = cr.last_modified_by
                                        }
                                    } else {
                                        let newRoutine = Routine(
                                            id: cr.id,
                                            name: cr.name,
                                            danceName: cr.dance_name,
                                            danceCategory: cr.dance_category,
                                            createdAt: cr.created_at,
                                            updatedAt: cr.updated_at,
                                            lastModifiedBy: cr.last_modified_by
                                        )
                                        modelContext.insert(newRoutine)
                                    }
                                }
                                try? modelContext.save()
                            }
                        }
                    }
                    // While typing, the header scrolls up so the field sits at the top.
                    .onChange(of: isTextEditorFocused) { _, focused in
                        guard focused else { return }
                        sweepTrigger += 1
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            proxy.scrollTo("capture", anchor: .top)
                        }
                    }
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "sk"))
            .toolbar(.hidden, for: .navigationBar)
            .sensoryFeedback(.success, trigger: savedCounter)
            .sensoryFeedback(.selection, trigger: activeCaptureMode)
            // ── Navigation Destinations ──────────────────────────────────
            .navigationDestination(item: $selectedRoutineForNavigation) { routine in
                RoutineCanvasView(routine: routine)
            }
            // ── Sheets & Modals ──────────────────────────────────────────
            .sheet(isPresented: $showLogoCommandPalette) {
                LogoCommandPaletteView(
                    isPresented: $showLogoCommandPalette,
                    onSelectNewRoutine: { showNewRoutineCategorySheet = true },
                    onSelectCompare: { showCompareModeSheet = true },
                    onSelectLibrary: { showGlobalLibrarySheet = true },
                    onSelectCanvas: { showAllRoutinesSheet = true },
                    onSelectCamera: { showCameraModal = true },
                    onSelectScanQR: { showQRScanner = true },
                    onSelectRoutine: { routine in
                        selectedRoutineForNavigation = routine
                    },
                    routines: routines,
                    allFigures: allFigures
                )
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotesInbox) {
                NotesInboxSheet()
            }
            .sheet(item: $noteToEdit) { note in
                NoteDetailSheet(note: note)
            }
            .sheet(isPresented: $showNewRoutineCategorySheet) {
                NavigationStack {
                    DanceCategorySelectionSheet(isPresented: $showNewRoutineCategorySheet)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showCompareModeSheet) {
                NavigationStack {
                    CompareHubView(
                        pathA: $compareSlotAPath,
                        pathB: $compareSlotBPath,
                        isPresented: $showCompareModeSheet
                    )
                }
            }
            .sheet(isPresented: $showGlobalLibrarySheet) {
                GlobalLibraryView()
            }
            .sheet(isPresented: $showAllRoutinesSheet) {
                AllRoutinesSheetView(
                    routines: routines,
                    onSelectRoutine: { routine in
                        showAllRoutinesSheet = false
                        selectedRoutineForNavigation = routine
                    },
                    onNewRoutine: {
                        showAllRoutinesSheet = false
                        showNewRoutineCategorySheet = true
                    }
                )
            }
            .fullScreenCover(isPresented: $showCameraModal) {
                DanceCameraView { localPath in
                    capturedVideoPath = localPath
                    saveCapturedVideoNote(videoPath: localPath)
                    showCameraModal = false
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showDanceMirrorModal) {
                DanceMirrorView()
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showCompetitionOrganizerSheet) {
                CompetitionOrganizerView()
            }
            .sheet(isPresented: $showMusicSpeedTrainerSheet) {
                MusicSpeedTrainerSheet()
            }
            .qrScanner(isPresented: $showQRScanner, onScan: handleScannedCode)
            .sheet(isPresented: $showManualCodeSheet) {
                manualCodeImportSheet
            }
            .alert("Chyba skenovania", isPresented: $showScanError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(scanErrorMessage ?? "Neznáma chyba")
            })
            .alert("Zostava naimportovaná", isPresented: $showScanSuccess, actions: {
                Button("Skvelé", role: .cancel) {}
            }, message: {
                Text("Zostava \"\(scannedRoutineName)\" bola úspešne naimportovaná.")
            })
        }
    }
    
    // MARK: - 1. Top Minimal Header with Centered Pure Gold Logo & Interactive Radial Hub
    private func workspaceTopHeader(logoSize: CGFloat) -> some View {
        ZStack {
            // ── Interactive Encore Radial Hub (Logo + Drag-to-Select Satellite Buttons) ──
            EncoreRadialHubView(
                isOpen: $isRadialHubOpen,
                logoSize: logoSize,
                onSelectAction: { action in
                    handleRadialAction(action)
                },
                onTogglePaletteFallback: {
                    showLogoCommandPalette = true
                }
            )
        }
        .frame(maxWidth: .infinity)
        // Open height must equal the hub's own frame (EncoreRadialHubView) so nothing overflows
        // onto the text field below; closed, the header stays slim.
        .frame(height: isRadialHubOpen ? max(logoSize + 185, 300) : logoSize + 36)
        .overlay(alignment: .topTrailing) {
            // Right QR Scanner & Actions Menu (Single Apple 3D Liquid Glass Lens)
            Menu {
                Button(action: { showQRScanner = true }) {
                    Label("Skenovať QR kód", systemImage: "qrcode.viewfinder")
                }
                Button(action: {
                    if let str = UIPasteboard.general.string, !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        handleScannedCode(str)
                    } else {
                        showError("Schránka je prázdna alebo neobsahuje platný kód.")
                    }
                }) {
                    Label("Vložiť kód zo schránky", systemImage: "doc.on.clipboard")
                }
                Button(action: { showManualCodeSheet = true }) {
                    Label("Zadať kód manuálne", systemImage: "keyboard")
                }
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.trailing, 2)
            .opacity(isRadialHubOpen ? 0.0 : 1.0)
            .animation(.easeOut(duration: 0.18), value: isRadialHubOpen)
        }
    }
    
    // MARK: - Radial Action Dispatcher
    private func handleRadialAction(_ action: RadialHubAction) {
        switch action {
        case .newRoutine:
            showNewRoutineCategorySheet = true
        case .mirror:
            showDanceMirrorModal = true
            AnalyticsManager.shared.mirrorOpened(source: "radial_hub")
        case .organizer:
            showCompetitionOrganizerSheet = true
        case .speedTrainer:
            showMusicSpeedTrainerSheet = true
        }
    }
    
    // MARK: - 2. Central Capture Content (The White Box Area)
    private var centralCaptureContent: some View {
        ZStack {
            switch activeCaptureMode {
            case .text:
                textCaptureView
                    .transition(.opacity)
            case .voice:
                VoiceCaptureView { insertNote(text: $0) }
                    .transition(.opacity)
            case .camera:
                cameraCaptureView
                    .transition(.opacity)
            }
            
            if showSavedFeedback {
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Uložené")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color.syncEmerald)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale))
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 3. Centered Mode Switcher (The 3 Centered Lines below Workspace)
    private var modeSwitcherBar: some View {
        HStack(spacing: 12) {
            ForEach(CaptureInputMode.allCases) { mode in
                let isSelected = activeCaptureMode == mode
                Button {
                    HapticFeedback.light()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        activeCaptureMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.60))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        ZStack {
                            Capsule().fill(Color.white.opacity(0.04))
                            if isSelected {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .matchedGeometryEffect(id: "modeSelection", in: modeNamespace)
                            }
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected
                                ? LinearGradient(
                                    colors: [Color.white.opacity(0.45), Color.gold400.opacity(0.40), Color.gold500.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.pressable)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - 4. Recently Edited Routine Card (Naposledy editovaná zostava a jej obsah)
    @ViewBuilder
    private var recentlyEditedRoutineCard: some View {
        if let recentRoutine = routines.first {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("NAPOSLEDY UPRAVOVANÉ")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(Color.gold400)
                        .tracking(1.4)
                    
                    Spacer()
                    
                    Text(recentRoutine.updatedAt, format: .relative(presentation: .named))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.40))
                }
                
                Button {
                    HapticFeedback.medium()
                    selectedRoutineForNavigation = recentRoutine
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            // Icon / Category badge
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.gold500.opacity(0.35), Color.gold400.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gold400.opacity(0.4), lineWidth: 1)
                                    )
                                
                                Image(systemName: recentRoutine.danceCategory == "Latin" ? "flame.fill" : "drop.fill")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color.gold300)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(recentRoutine.name)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text(recentRoutine.danceName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.gold400)
                                    
                                    Text("•")
                                        .foregroundColor(Color.white.opacity(0.3))
                                    
                                    Text("\(recentRoutine.canvasNodes.count) figúr")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.gold400.opacity(0.7))
                        }
                        
                        // Floor-direction map of the routine
                        if recentRoutine.canvasNodes.count > 1 {
                            let ordered = recentRoutine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
                            RoutinePathThumbnail(points: ordered.map { CGPoint(x: $0.x, y: $0.y) })
                                .frame(height: 72)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .id(recentRoutine.id)
                        }
                        
                        // Figures preview pills (if there are figures in the routine)
                        if !recentRoutine.canvasNodes.isEmpty {
                            let sortedNodes = recentRoutine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(sortedNodes.prefix(4).enumerated()), id: \.element.id) { index, node in
                                        HStack(spacing: 4) {
                                            Text("\(index + 1).")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color.gold400.opacity(0.8))
                                            Text(node.figureName)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.white.opacity(0.85))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                        )
                                    }
                                    
                                    if sortedNodes.count > 4 {
                                        Text("+\(sortedNodes.count - 4)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color.gold400)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.gold500.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(red: 16/255, green: 16/255, blue: 22/255).opacity(0.85))
                            
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.gold400.opacity(0.35), Color.white.opacity(0.08), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.pressable)
            }
        }
    }
    
    // MARK: - Capture Mode: Text Input (Invisible Surface with Only Helper Text)
    private var textCaptureView: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            ZStack(alignment: .topLeading) {
                if noteDraftText.isEmpty {
                    Text("Zadaj myšlienku, figúru, technickú pripomienku alebo postreh z tréningu...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $noteDraftText)
                    .focused($isTextEditorFocused)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextEditorFocused = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { FieldEdgeSweep(trigger: sweepTrigger) }
            
            noteContextChips
            
            // Floating Save Button (Appears as soon as user types)
            if !noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Button("Vymazať") {
                        noteDraftText = ""
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                    
                    Spacer()
                    
                    Button {
                        saveTextNote()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Uložiť poznámku")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color.obsidian900)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.pressable)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    // MARK: - Dance & tag chips for the note being written
    private var noteContextChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dances) { dance in
                    noteChip(dance.name, isOn: selectedDance == dance.name, accent: true) {
                        selectedDance = (selectedDance == dance.name) ? nil : dance.name
                    }
                }
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 16)
                ForEach(NoteTags.quick, id: \.self) { tag in
                    noteChip(tag, isOn: selectedNoteTags.contains(tag), accent: false) {
                        if let i = selectedNoteTags.firstIndex(of: tag) {
                            selectedNoteTags.remove(at: i)
                        } else {
                            selectedNoteTags.append(tag)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: selectedNoteTags)
        .sensoryFeedback(.selection, trigger: selectedDance)
    }
    
    private func noteChip(_ title: String, isOn: Bool, accent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .foregroundColor(isOn ? Color.obsidian900 : (accent ? Color.white.opacity(0.85) : Color.gold300))
                .background(
                    isOn ? Color.gold400 : (accent ? Color.white.opacity(0.07) : Color.gold500.opacity(0.12)),
                    in: Capsule()
                )
                .scaleEffect(isOn ? 1.05 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isOn)
        }
        .buttonStyle(.pressable)
    }
    
    // MARK: - Capture Mode: Instant Camera Launch & Video
    private var cameraCaptureView: some View {
        VStack(spacing: 14) {
            if let videoPath = capturedVideoPath,
               let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                
                VStack(spacing: 12) {
                    LoopingVideoPlayer(videoURL: videoURL, rate: 1.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gold400.opacity(0.35), lineWidth: 1.2)
                        )
                    
                    HStack(spacing: 12) {
                        Button {
                            showCameraModal = true
                        } label: {
                            Label("Natočiť znova", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.pressable)
                        
                        Button {
                            MediaStorageManager.removeFile(named: videoPath)
                            capturedVideoPath = nil
                        } label: {
                            Label("Vymazať", systemImage: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.latinCrimson)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.latinCrimson.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.pressable)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.gold500.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(Color.gold400.opacity(0.4), lineWidth: 2)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "video.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color.gold400)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Spustiť tanečnú kameru")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Nahrávanie tréningu so spomaleným záberom a mriežkou")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.50))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Button {
                        HapticFeedback.medium()
                        showCameraModal = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "record.circle")
                                .font(.system(size: 16, weight: .bold))
                            Text("Otvoriť kameru")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color.obsidian900)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.pressable)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Helper Actions
    private func saveTextNote() {
        let trimmed = noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        insertNote(text: trimmed)
        noteDraftText = ""
        isTextEditorFocused = false
    }
    
    private func saveCapturedVideoNote(videoPath: String) {
        modelContext.insert(InstantNote(text: "Tréningové video", videoPath: videoPath, danceName: selectedDance))
        try? modelContext.save()
        savedCounter += 1
        triggerSavedFeedback()
    }
    
    /// One place that creates a note from the current capture context (dance + tags).
    private func insertNote(text: String) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            modelContext.insert(InstantNote(text: text, tags: selectedNoteTags, danceName: selectedDance))
        }
        try? modelContext.save()
        selectedNoteTags = []
        savedCounter += 1
        triggerSavedFeedback()
    }
    
    private func triggerSavedFeedback() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSavedFeedback = false
            }
        }
    }
    
    private func handleScannedCode(_ rawCode: String) {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            showError("Neplatné dáta kódového kľúča.")
            return
        }
        
        do {
            let payload = try JSONDecoder().decode(QRSharePayload.self, from: data)
            guard payload.nodes.count <= 200 else {
                showError("QR kód obsahuje príliš veľa figúr (max. 200).")
                return
            }
            guard payload.n.count <= 120, payload.d.count <= 80 else {
                showError("QR kód obsahuje neplatné dáta.")
                return
            }
            
            let routineId = payload.id.flatMap(UUID.init(uuidString:)) ?? UUID()
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
            
            for rawNode in payload.nodes {
                let nodeId = rawNode.id.flatMap(UUID.init(uuidString:)) ?? UUID()
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
            SupabaseSyncManager.shared.syncRoutineOnBackground(targetRoutine)
            
            scannedRoutineName = payload.n
            showScanSuccess = true
        } catch {
            showError("Nepodarilo sa naimportovať zostavu.")
        }
    }
    
    private func showError(_ message: String) {
        scanErrorMessage = message
        showScanError = true
    }
    
    private var manualCodeImportSheet: some View {
        NavigationStack {
            ZStack {
                Color.obsidian800.ignoresSafeArea()
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
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        let codeToProcess = manualCodeInput
                        manualCodeInput = ""
                        showManualCodeSheet = false
                        handleScannedCode(codeToProcess)
                    }) {
                        Text("Naimportovať zostavu")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.neubrutalist(accentColor: Color.gold500))
                    .padding(.horizontal, 24)
                    .disabled(manualCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zrušiť") { showManualCodeSheet = false }
                            .foregroundColor(.gold400)
                    }
                }
            }
        }
    }
}

// MARK: - Interactive Logo Command Palette Sheet
struct LogoCommandPaletteView: View {
    @Binding var isPresented: Bool
    let onSelectNewRoutine: () -> Void
    let onSelectCompare: () -> Void
    let onSelectLibrary: () -> Void
    let onSelectCanvas: () -> Void
    let onSelectCamera: () -> Void
    let onSelectScanQR: () -> Void
    let onSelectRoutine: (Routine) -> Void
    
    let routines: [Routine]
    let allFigures: [FigureLibraryItem]
    
    @State private var searchQuery: String = ""
    
    var filteredRoutines: [Routine] {
        if searchQuery.isEmpty { return routines }
        return routines.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.danceName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var filteredFigures: [FigureLibraryItem] {
        if searchQuery.isEmpty { return [] }
        return allFigures.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.danceName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidian900.ignoresSafeArea()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 20)
                    
                    VStack(spacing: 16) {
                        
                        // Search Header Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.gold400)
                            
                            TextField("Hľadať akcie, zostavy alebo figúry...", text: $searchQuery)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            
                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.white.opacity(0.4))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.themeCard)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gold400.opacity(0.30), lineWidth: 1)
                        )
                        .padding(.horizontal, autoSidePadding)
                        .padding(.top, 16)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                
                                // Primary Commands Grid
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("HLAVNÉ PRÍKAZY")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Color.white.opacity(0.4))
                                        .tracking(1.2)
                                    
                                    VStack(spacing: 8) {
                                        commandRow(icon: "plus.circle.fill", title: "Nová choreografia", subtitle: "Založiť zostavu na plátne", color: Color.gold500) {
                                            isPresented = false
                                            onSelectNewRoutine()
                                        }
                                        
                                        commandRow(icon: "arrow.left.and.right.square.fill", title: "⚔️ Porovnať tanec", subtitle: "Idol vs. Moje video s analýzou", color: Color.standardBlue) {
                                            isPresented = false
                                            onSelectCompare()
                                        }
                                        
                                        commandRow(icon: "square.grid.2x2.fill", title: "Tanečný Canvas", subtitle: "Zobraziť všetky zostavy", color: Color.latinPink) {
                                            isPresented = false
                                            onSelectCanvas()
                                        }
                                        
                                        commandRow(icon: "books.vertical.fill", title: "Knižnica a Figúry", subtitle: "Register krokov a techniky", color: Color.syncEmerald) {
                                            isPresented = false
                                            onSelectLibrary()
                                        }
                                        
                                        commandRow(icon: "video.fill", title: "Kamera & Spomalené zábery", subtitle: "Natočiť nový tréningový záznam", color: Color.gold400) {
                                            isPresented = false
                                            onSelectCamera()
                                        }
                                        
                                        commandRow(icon: "qrcode.viewfinder", title: "Skenovať QR kód", subtitle: "Naimportovať zostavu od partnera", color: Color.white.opacity(0.7)) {
                                            isPresented = false
                                            onSelectScanQR()
                                        }
                                    }
                                }
                                
                                // Matching Routines
                                if !filteredRoutines.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("ZODPOVEDAJÚCE ZOSTAVY (\(filteredRoutines.count))")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .tracking(1.2)
                                        
                                        ForEach(filteredRoutines.prefix(5)) { routine in
                                            Button {
                                                isPresented = false
                                                onSelectRoutine(routine)
                                            } label: {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(routine.name)
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.white)
                                                        Text("\(routine.danceName) • \(routine.canvasNodes.count) figúr")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(Color.white.opacity(0.5))
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(Color.gold400)
                                                }
                                                .padding(12)
                                                .background(Color.themeCard.opacity(0.7))
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                
                                // Matching Figures from Library (if searching)
                                if !filteredFigures.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("NÁJDENÉ FIGÚRY V KNIŽNICI (\(filteredFigures.count))")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .tracking(1.2)
                                        
                                        ForEach(filteredFigures.prefix(6)) { fig in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(fig.name)
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.white)
                                                    Text("\(fig.danceName) • \(fig.rhythm)")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(Color.gold400)
                                                }
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(Color.themeCard.opacity(0.5))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, autoSidePadding)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Command Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { isPresented = false }
                        .foregroundColor(Color.gold400)
                }
            }
        }
    }
    
    private func commandRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(12)
            .background(Color.themeCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dance Category Selection Sheet
struct DanceCategorySelectionSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Výber tanečnej kategórie")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Vyberte štýl tanca pre založenie novej choreografie:")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 14) {
                            NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.standardBlue.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.standardBlue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ŠTANDARDNÉ TANCE")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.white)
                                        Text("Waltz, Tango, Valčík, Slowfox, Quickstep")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.white.opacity(0.3))
                                }
                                .padding(18)
                                .background(Color.themeCard)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.standardBlue.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: DanceCategoryView(category: "Latin")) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.latinPink.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.latinPink)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("LATINSKOAMERICKÉ TANCE")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.white)
                                        Text("Samba, Cha-Cha, Rumba, Paso Doble, Jive")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.white.opacity(0.3))
                                }
                                .padding(18)
                                .background(Color.themeCard)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.latinPink.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { isPresented = false }
                        .foregroundColor(Color.gold400)
                }
            }
        }
    }
}

// MARK: - Compare Hub View (Reference vs My Performance)
struct CompareHubView: View {
    @Binding var pathA: String?
    @Binding var pathB: String?
    @Binding var isPresented: Bool
    
    @Query(sort: \VideoMediaEntry.createdAt, order: .reverse) private var allVideos: [VideoMediaEntry]
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var allNotes: [InstantNote]
    @Query(sort: \Dance.name) private var allDances: [Dance]
    
    @State private var showDirectComparison: Bool = false
    @State private var activeSlotForPicker: Int? = nil // 1 for A, 2 for B
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header description
                        VStack(spacing: 6) {
                            Text("⚔️ Dual Porovnávač")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            Text("Porovnanie referenčného vzoru (Idol) s vašim vlastným tancom so synchronizovaným posunom času a zrkadlením.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        // Slots Selection (A vs B)
                        HStack(spacing: 12) {
                            // Slot A (My Take)
                            compareSlotCard(
                                slotNumber: 1,
                                title: "MOJE VIDEO (A)",
                                path: pathA,
                                roleName: "Vlastný pokus",
                                accentColor: Color.latinCrimson,
                                onSelect: { activeSlotForPicker = 1 },
                                onClear: { pathA = nil }
                            )
                            
                            // Slot B (Reference Idol)
                            compareSlotCard(
                                slotNumber: 2,
                                title: "VZOR / IDOL (B)",
                                path: pathB,
                                roleName: "Referencia",
                                accentColor: Color.syncEmerald,
                                onSelect: { activeSlotForPicker = 2 },
                                onClear: { pathB = nil }
                            )
                        }
                        
                        // Launch Dual Player Button
                        Button {
                            showDirectComparison = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("Spustiť porovnávanie")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.gold500.opacity(0.35), radius: 10)
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { isPresented = false }
                        .foregroundColor(Color.gold400)
                }
            }
            .fullScreenCover(isPresented: $showDirectComparison) {
                DualVideoComparisonView(
                    pathA: $pathA,
                    pathB: $pathB,
                    titleA: "Moje video (A)",
                    titleB: "Vzor / Idol (B)"
                )
            }
            .sheet(isPresented: Binding(
                get: { activeSlotForPicker != nil },
                set: { if !$0 { activeSlotForPicker = nil } }
            )) {
                if let slot = activeSlotForPicker {
                    UniversalMediaPickerSheet(
                        slotTitle: slot == 1 ? "Moje video / fotka (A)" : "Vzor / Idol (B)",
                        currentPath: slot == 1 ? pathA : pathB,
                        onSelectMedia: { path in
                            if slot == 1 {
                                pathA = path
                            } else {
                                pathB = path
                            }
                            activeSlotForPicker = nil
                        },
                        onClearMedia: {
                            if slot == 1 {
                                pathA = nil
                            } else {
                                pathB = nil
                            }
                            activeSlotForPicker = nil
                        }
                    )
                }
            }
        }
    }
    
    private func compareSlotCard(slotNumber: Int, title: String, path: String?, roleName: String, accentColor: Color, onSelect: @escaping () -> Void, onClear: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(accentColor)
            
            if let path = path {
                if MediaResolver.isImagePath(path: path), let img = MediaResolver.resolveImage(path: path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else if let url = MediaResolver.resolveVideoURL(path: path) {
                    LoopingVideoPlayer(videoURL: url, rate: 1.0)
                        .frame(height: 120)
                        .cornerRadius(12)
                } else {
                    MediaThumbnailView(path: path, placeholderIcon: "photo", cornerRadius: 12)
                        .frame(height: 120)
                }
                
                HStack(spacing: 8) {
                    Button(action: onSelect) {
                        Text("Zmeniť")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.gold400)
                    }
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Button(action: onClear) {
                        Text("Odobrať")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.latinCrimson)
                    }
                }
            } else {
                Button(action: onSelect) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                        
                        Text("Zvoliť video / foto")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(roleName)
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.themeCard.opacity(0.7))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .luxurySmokedCard(cornerRadius: 16, accentColor: accentColor)
    }
}


// MARK: - All Routines Sheet View
struct AllRoutinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let routines: [Routine]
    let onSelectRoutine: (Routine) -> Void
    let onNewRoutine: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("VŠETKY ZOSTAVY (\(routines.count))")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(Color.white.opacity(0.45))
                                    .tracking(1.2)
                                Spacer()
                                Button("Nová zostava") {
                                    onNewRoutine()
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.gold400)
                            }
                            .padding(.top, 16)
                            
                            ForEach(routines) { routine in
                                Button {
                                    onSelectRoutine(routine)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: routine.danceCategory.lowercased() == "standard" ? "drop.fill" : "flame.fill")
                                                        .font(.system(size: 8, weight: .bold))
                                                    Text(routine.danceCategory.uppercased())
                                                        .font(.system(size: 9, weight: .black))
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    routine.danceCategory.lowercased() == "standard"
                                                    ? Color.standardBlue.opacity(0.25)
                                                    : Color.latinPink.opacity(0.25)
                                                )
                                                .foregroundColor(
                                                    routine.danceCategory.lowercased() == "standard"
                                                    ? Color.standardBlue
                                                    : Color.latinPink
                                                )
                                                .cornerRadius(4)
                                                
                                                Text(routine.danceName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Color.gold300)
                                            }
                                            
                                            Text(routine.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.on.square.dashed")
                                                .font(.system(size: 10))
                                            Text("\(routine.canvasNodes.count) figúr")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(Color.gold400)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gold500.opacity(0.1))
                                        .cornerRadius(6)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .luxurySmokedCard(cornerRadius: 14, accentColor: Color.gold400)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, autoSidePadding)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Tanečné zostavy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { dismiss() }
                        .foregroundColor(Color.gold400)
                }
            }
        }
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
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 22)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: category.lowercased() == "standard" ? "drop.fill" : "flame.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(category.lowercased() == "standard" ? .standardBlue : .latinPink)
                            Text(category == "Standard" ? "Štandardné tance" : "Latinsko-americké tance")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(filteredDances) { dance in
                                NavigationLink(destination: DanceDetailView(dance: dance)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(dance.name)
                                                .font(.system(size: 18, weight: .bold, design: .serif))
                                                .foregroundColor(.white)
                                            Text(dance.tempo)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.gold400)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color.white.opacity(0.3))
                                    }
                                    .padding(20)
                                    .luxurySmokedCard(cornerRadius: 18, accentColor: Color.gold400)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 40)
                }
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
                        if let videoPath = dance.videoPath,
                           let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                            LoopingVideoPlayer(videoURL: videoURL, rate: 1.0)
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
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Názov tanca")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    TextField("Názov", text: $nameText)
                                        .padding()
                                        .background(Color.themeCard)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tempo")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    TextField("Tempo (napr. 28t/m)", text: $tempoText)
                                        .padding()
                                        .background(Color.themeCard)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Image section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ilustračná fotografia tanca")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
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
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Video section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Všeobecné tréningové video")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                if let videoPath = dance.videoPath,
                                   let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                                    VStack(spacing: 12) {
                                        LoopingVideoPlayer(videoURL: videoURL, rate: playbackRate)
                                            .frame(height: 200)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        HStack(spacing: 12) {
                                            Text("Rýchlosť:")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.white.opacity(0.6))
                                            
                                            ForEach([0.5, 0.75, 1.0, 1.5], id: \.self) { speed in
                                                Button(action: { playbackRate = Float(speed) }) {
                                                    Text(String(format: "%.2fx", speed))
                                                        .font(.system(size: 11, weight: .black))
                                                        .foregroundColor(playbackRate == Float(speed) ? .black : .white)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(playbackRate == Float(speed) ? Color.gold400 : Color.themeCard)
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(playbackRate == Float(speed) ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
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
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Text description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popis tanca / Charakteristika")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $infoText)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.themeCard)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, autoSidePadding)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Upraviť \(dance.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.7))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Uložiť") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.gold400)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        UIApplication.shared.endEditing()
                    }
                    .foregroundColor(Color.gold400)
                }
            }
            .onAppear {
                nameText = dance.name
                tempoText = dance.tempo
                infoText = dance.info
            }
            .fullScreenCover(isPresented: $showCamera) {
                DanceCameraView { localPath in
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

// MARK: - Xcode Canvas Preview (Safe Static Container for Instant Live Preview)
#Preview("ContentView - Workspace") {
    ContentView()
        .previewWithSampleData()
}
