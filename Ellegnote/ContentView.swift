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
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var recentNotes: [InstantNote]
    @Query(sort: \FigureLibraryItem.name) private var allFigures: [FigureLibraryItem]
    
    // Central Capture Area State
    @State private var activeCaptureMode: CaptureInputMode = .text
    @State private var noteDraftText: String = ""
    @State private var selectedNoteTag: String? = nil
    @State private var showSavedFeedback: Bool = false
    
    // Voice Capture State
    @StateObject private var speechManager = SpeechRecognizerHelper()
    @State private var baseVoiceTranscript: String = ""
    
    // Camera Capture State
    @State private var showCameraModal: Bool = false
    @State private var capturedVideoPath: String? = nil
    
    // Interactive Logo Command Menu State
    @State private var showLogoCommandPalette: Bool = false
    @State private var commandSearchQuery: String = ""
    
    // Quick Actions & Navigation Modals
    @State private var showNewRoutineCategorySheet: Bool = false
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
    
    // Quick Suggestion Tags for Notes
    private let quickNoteTags = ["#Držanie", "#Rytmus", "#Waltz", "#Rumba", "#Sway", "#Rotácia", "#Nášľap"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Obsidian Canvas with Ambient Blooms
                EllegancePageBackground()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // ── 1. Top Minimal Header & Interactive Logo ─────────────
                        workspaceTopHeader
                            .padding(.horizontal, 22)
                            .padding(.top, 14)
                        
                        // ── 2. Central Capture Surface (Primary Interaction) ─────
                        centralCaptureWorkspace
                            .padding(.horizontal, 18)
                        
                        // ── 3. Quick Actions Row ─────────────────────────────────
                        quickActionsSection
                            .padding(.horizontal, 18)
                        
                        // ── 4. Most Recent Edit Preview Card ─────────────────────
                        mostRecentEditSection
                            .padding(.horizontal, 18)
                        
                        // Bottom spacing for comfortable scrolling above dock
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
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
    
    // MARK: - 1. Top Minimal Header with Interactive Sculptural Logo
    private var workspaceTopHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            // Interactive Logo Button (triggers Floating Command Palette)
            Button {
                HapticFeedback.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showLogoCommandPalette = true
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gold500.opacity(0.20), Color.gold400.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.gold400.opacity(0.45), Color.white.opacity(0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image("EllegnoteLogo")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .shadow(color: Color.gold500.opacity(0.35), radius: 6)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("ELLEGNOTE")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(1.4)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.gold400.opacity(0.70))
                        }
                        
                        Text("Pripravený na tréning")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.gold300.opacity(0.80))
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Secondary Top Utilities: QR Scanner / Code entry
            HStack(spacing: 8) {
                Button {
                    HapticFeedback.light()
                    showQRScanner = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.gold400)
                    }
                }
                .buttonStyle(.plain)
                
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
                        Label("Vložiť zo schránky", systemImage: "doc.on.clipboard")
                    }
                    Button(action: { showManualCodeSheet = true }) {
                        Label("Zadať kód ručne", systemImage: "keyboard")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    // MARK: - 2. Central Capture Surface (Liquid Glass Workspace)
    private var centralCaptureWorkspace: some View {
        VStack(spacing: 0) {
            
            // Mode Switcher Bar (Text | Hlas | Kamera)
            HStack(spacing: 6) {
                ForEach(CaptureInputMode.allCases) { mode in
                    let isSelected = activeCaptureMode == mode
                    Button {
                        HapticFeedback.light()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            activeCaptureMode = mode
                            if mode != .voice && speechManager.isRecording {
                                speechManager.stopTranscribing()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? LuxuryTheme.obsidian900 : Color.white.opacity(0.65))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            isSelected
                            ? LinearGradient(colors: [Color.gold400, Color.gold500], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                if showSavedFeedback {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Uložené")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color.syncEmerald)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Mode Content Container
            ZStack {
                switch activeCaptureMode {
                case .text:
                    textCaptureView
                        .transition(.opacity)
                case .voice:
                    voiceCaptureView
                        .transition(.opacity)
                case .camera:
                    cameraCaptureView
                        .transition(.opacity)
                }
            }
            .padding(16)
        }
        .background(
            ZStack {
                Color(red: 16/255, green: 16/255, blue: 20/255).opacity(0.75)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color.gold400.opacity(0.35), Color.white.opacity(0.10), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
    }
    
    // MARK: - Capture Mode: Text Input (Lined Creative Surface)
    private var textCaptureView: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            ZStack(alignment: .topLeading) {
                // Subtle Lined Paper Visual Guide
                VStack(spacing: 24) {
                    ForEach(0..<4, id: \.self) { _ in
                        Divider()
                            .background(Color.white.opacity(0.04))
                    }
                }
                .padding(.top, 28)
                .allowsHitTesting(false)
                
                if noteDraftText.isEmpty {
                    Text("Zadaj myšlienku, figúru, technickú pripomienku alebo postreh z tréningu...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $noteDraftText)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(minHeight: 90)
            }
            
            // Quick Tag Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickNoteTags, id: \.self) { tag in
                        Button {
                            HapticFeedback.light()
                            if !noteDraftText.contains(tag) {
                                noteDraftText += (noteDraftText.isEmpty ? "" : " ") + tag
                            }
                        } label: {
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.gold300.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gold500.opacity(0.10))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gold400.opacity(0.20), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Action Bottom Bar
            HStack {
                if !noteDraftText.isEmpty {
                    Button("Vymazať") {
                        noteDraftText = ""
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Button {
                    saveTextNote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Uložiť poznámku")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.3) : Color.obsidian900)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
                .disabled(noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Capture Mode: Voice Recording & Waveform
    private var voiceCaptureView: some View {
        VStack(spacing: 16) {
            
            // Audio Waveform Visualization
            HStack(spacing: 4) {
                ForEach(0..<18, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            speechManager.isRecording
                            ? LinearGradient(colors: [Color.latinCrimson, Color.gold400], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(
                            width: 5,
                            height: speechManager.isRecording
                            ? CGFloat.random(in: 12...50)
                            : 8
                        )
                        .animation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true), value: speechManager.isRecording)
                }
            }
            .frame(height: 55)
            .padding(.vertical, 4)
            
            // Live Transcription Display
            if !speechManager.transcript.isEmpty || !noteDraftText.isEmpty {
                Text(speechManager.transcript.isEmpty ? noteDraftText : speechManager.transcript)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .lineLimit(3)
            } else {
                Text(speechManager.isRecording ? "Hovorte zreteľne o choreografii alebo technike..." : "Stlačte mikrofón a začnite diktovať")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.40))
            }
            
            // Record / Stop Control
            HStack(spacing: 16) {
                Button {
                    toggleVoiceRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(speechManager.isRecording ? Color.latinCrimson.opacity(0.20) : Color.gold500.opacity(0.15))
                            .frame(width: 68, height: 68)
                        
                        Circle()
                            .fill(speechManager.isRecording ? Color.latinCrimson : Color.gold500)
                            .frame(width: 54, height: 54)
                            .shadow(color: (speechManager.isRecording ? Color.latinCrimson : Color.gold500).opacity(0.4), radius: 10)
                        
                        Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(speechManager.isRecording ? .white : Color.obsidian900)
                    }
                }
                .buttonStyle(.plain)
                
                if !noteDraftText.isEmpty || !speechManager.transcript.isEmpty {
                    Button {
                        saveVoiceNote()
                    } label: {
                        Text("Uložiť prepis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Capture Mode: Instant Camera Launch & Video
    private var cameraCaptureView: some View {
        VStack(spacing: 14) {
            if let videoPath = capturedVideoPath,
               let videoURL = MediaResolver.resolveVideoURL(path: videoPath) {
                
                VStack(spacing: 10) {
                    LoopingVideoPlayer(videoURL: videoURL, rate: 1.0)
                        .frame(height: 160)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gold400.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack(spacing: 12) {
                        Button {
                            showCameraModal = true
                        } label: {
                            Label("Natočiť znova", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            MediaStorageManager.removeFile(named: videoPath)
                            capturedVideoPath = nil
                        } label: {
                            Label("Vymazať", systemImage: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.latinCrimson)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.latinCrimson.opacity(0.12))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button {
                    HapticFeedback.medium()
                    showCameraModal = true
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.gold500.opacity(0.12))
                                .frame(width: 64, height: 64)
                            
                            Circle()
                                .stroke(Color.gold400.opacity(0.4), lineWidth: 2)
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: "video.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.gold400)
                        }
                        
                        VStack(spacing: 3) {
                            Text("Spustiť tanečnú kameru")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Nahrávanie tréningu so spomaleným záberom a mriežkou")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.50))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 3. Quick Actions Section (Secondary Workspace Triggers)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RÝCHLE AKCIE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color.white.opacity(0.45))
                    .tracking(1.2)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                
                // 1. New Routine
                Button {
                    HapticFeedback.light()
                    showNewRoutineCategorySheet = true
                } label: {
                    QuickActionTile(
                        icon: "plus.circle.fill",
                        title: "Nová zostava",
                        subtitle: "Vytvoriť choreografiu",
                        accentColor: Color.gold500
                    )
                }
                .buttonStyle(.plain)
                
                // 2. Compare Mode
                Button {
                    HapticFeedback.light()
                    showCompareModeSheet = true
                } label: {
                    QuickActionTile(
                        icon: "arrow.left.and.right.square.fill",
                        title: "Porovnať",
                        subtitle: "Vzor vs. Môj tanec",
                        accentColor: Color.standardBlue
                    )
                }
                .buttonStyle(.plain)
                
                // 3. Library
                Button {
                    HapticFeedback.light()
                    showGlobalLibrarySheet = true
                } label: {
                    QuickActionTile(
                        icon: "books.vertical.fill",
                        title: "Knižnica",
                        subtitle: "Figúry, videá, poznámky",
                        accentColor: Color.syncEmerald
                    )
                }
                .buttonStyle(.plain)
                
                // 4. Canvas (All Routines)
                Button {
                    HapticFeedback.light()
                    showAllRoutinesSheet = true
                } label: {
                    QuickActionTile(
                        icon: "square.grid.2x2.fill",
                        title: "Canvas",
                        subtitle: "\(routines.count) zostáv na plátne",
                        accentColor: Color.latinPink
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 4. Most Recent Edit Section (Direct Canvas Continuation)
    private var mostRecentEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NAPOSLEDY UPRAVOVANÉ")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color.white.opacity(0.45))
                    .tracking(1.2)
                
                Spacer()
                
                if !routines.isEmpty {
                    Button("Zobraziť všetky") {
                        showAllRoutinesSheet = true
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.gold400)
                }
            }
            .padding(.horizontal, 4)
            
            if let latestRoutine = routines.first {
                NavigationLink(destination: RoutineCanvasView(routine: latestRoutine)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(latestRoutine.danceCategory.uppercased())
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            latestRoutine.danceCategory.lowercased() == "standard"
                                            ? Color.standardBlue.opacity(0.25)
                                            : Color.latinPink.opacity(0.25)
                                        )
                                        .foregroundColor(
                                            latestRoutine.danceCategory.lowercased() == "standard"
                                            ? Color.standardBlue
                                            : Color.latinPink
                                        )
                                        .cornerRadius(6)
                                    
                                    Text("•")
                                        .foregroundColor(Color.white.opacity(0.25))
                                    
                                    Text(latestRoutine.danceName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.gold300)
                                }
                                
                                Text(latestRoutine.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "square.on.square.dashed")
                                    .font(.system(size: 11))
                                Text("\(latestRoutine.canvasNodes.count) figúr")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Color.gold400)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gold500.opacity(0.12))
                            .cornerRadius(8)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.08))
                        
                        HStack {
                            Text("Pokračovať v úpravách na plátne")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.gold400)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Text(timeAgo(latestRoutine.updatedAt))
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.40))
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.gold400)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        ZStack {
                            Color.themeCard
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    )
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.gold400.opacity(0.25), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 28))
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text("Zatiaľ nemáte vytvorenú žiadnu zostavu")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Button {
                        showNewRoutineCategorySheet = true
                    } label: {
                        Text("Vytvoriť prvú choreografiu")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.themeCard.opacity(0.6))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Helper Actions
    private func saveTextNote() {
        let trimmed = noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newNote = InstantNote(text: trimmed)
        modelContext.insert(newNote)
        try? modelContext.save()
        
        HapticFeedback.medium()
        noteDraftText = ""
        triggerSavedFeedback()
    }
    
    private func saveVoiceNote() {
        let transcript = speechManager.transcript.isEmpty ? noteDraftText : speechManager.transcript
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        speechManager.stopTranscribing()
        let newNote = InstantNote(text: trimmed)
        modelContext.insert(newNote)
        try? modelContext.save()
        
        HapticFeedback.medium()
        noteDraftText = ""
        speechManager.transcript = ""
        triggerSavedFeedback()
    }
    
    private func saveCapturedVideoNote(videoPath: String) {
        let newNote = InstantNote(text: "Tréningové video", videoPath: videoPath)
        modelContext.insert(newNote)
        try? modelContext.save()
        triggerSavedFeedback()
    }
    
    private func toggleVoiceRecording() {
        if speechManager.isRecording {
            let captured = speechManager.stopTranscribing()
            if !captured.isEmpty {
                noteDraftText = captured
            }
        } else {
            speechManager.transcript = ""
            speechManager.startTranscribing()
        }
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
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "sk")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var manualCodeImportSheet: some View {
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
                            .foregroundColor(.themeDark)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Tile Subview
private struct QuickActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Color.themeCard
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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
                    .padding(.horizontal, 20)
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
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
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
            
            VStack(spacing: 20) {
                Text("Výber tanečnej kategórie")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Vyberte štýl tanca pre založenie novej choreografie:")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 14) {
                    NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.standardBlue.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "star.fill")
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
                .padding(.horizontal, 20)
                
                Spacer()
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
                        .padding(.horizontal, 24)
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
                .padding(.horizontal, 16)
                
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
                .padding(.horizontal, 16)
                
                Spacer()
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
                    VideoSlotPickerSheet(
                        slotTitle: slot == 1 ? "Moje video (A)" : "Vzor / Idol (B)",
                        onSelectVideo: { path in
                            if slot == 1 {
                                pathA = path
                            } else {
                                pathB = path
                            }
                            activeSlotForPicker = nil
                        },
                        allVideos: allVideos,
                        allNotes: allNotes,
                        allDances: allDances
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
            
            if let path = path, let url = MediaResolver.resolveVideoURL(path: path) {
                LoopingVideoPlayer(videoURL: url, rate: 1.0)
                    .frame(height: 120)
                    .cornerRadius(12)
                
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
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                        
                        Text("Zvoliť video")
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
        .background(Color.themeCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Video Slot Picker Sheet
struct VideoSlotPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let slotTitle: String
    let onSelectVideo: (String) -> Void
    
    let allVideos: [VideoMediaEntry]
    let allNotes: [InstantNote]
    let allDances: [Dance]
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraModal: Bool = false
    
    var availableVideoPaths: [(title: String, path: String, role: String)] {
        var items: [(String, String, String)] = []
        for v in allVideos {
            items.append((v.title.isEmpty ? "Video záznam" : v.title, v.filePath, v.role.displayName))
        }
        for n in allNotes where n.videoPath != nil {
            if let p = n.videoPath {
                items.append((n.text.isEmpty ? "Rýchla poznámka" : n.text, p, "Poznámka"))
            }
        }
        for d in allDances where d.videoPath != nil {
            if let p = d.videoPath {
                items.append(("Vzor pre \(d.name)", p, "Vzor tanca"))
            }
        }
        return items
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Top Quick Actions (Record or Photos)
                        HStack(spacing: 12) {
                            Button {
                                showCameraModal = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "video.badge.plus.fill")
                                        .font(.system(size: 14))
                                    Text("Natočiť kamerou")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(Color.obsidian900)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 14))
                                    Text("Vybrať z galérie")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Video Vault List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ULOŽENÉ VIDEÁ V APLIKÁCII (\(availableVideoPaths.count))")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.white.opacity(0.45))
                                .tracking(1.2)
                                .padding(.horizontal, 20)
                            
                            if availableVideoPaths.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "video.slash")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.white.opacity(0.3))
                                    Text("Nemáte žiadne uložené videá")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                ForEach(availableVideoPaths, id: \.path) { item in
                                    Button {
                                        onSelectVideo(item.path)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.gold500.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(Color.gold400)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.title)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text(item.role)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color.gold300.opacity(0.8))
                                            }
                                            
                                            Spacer()
                                            
                                            Text("Vybrať")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.gold400)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.gold500.opacity(0.12))
                                                .cornerRadius(6)
                                        }
                                        .padding(12)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vybrať pre \(slotTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundColor(Color.gold400)
                }
            }
            .fullScreenCover(isPresented: $showCameraModal) {
                DanceCameraView { localPath in
                    onSelectVideo(localPath)
                    dismiss()
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let filename = try? MediaStorageManager.store(data: data, prefix: "vault_vid", fileExtension: "mp4") {
                            await MainActor.run {
                                onSelectVideo(filename)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
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
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        ForEach(routines) { routine in
                            Button {
                                onSelectRoutine(routine)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(routine.danceCategory.uppercased())
                                                .font(.system(size: 9, weight: .black))
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
                                .background(Color.themeCard)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
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
            EllegancePageBackground()
            
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
                .toolbarColorScheme(.dark, for: .navigationBar)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
