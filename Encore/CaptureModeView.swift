import SwiftUI
import SwiftData
import UIKit
import AVKit
import AVFoundation

struct CaptureModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    @State private var showCamera = false
    @State private var showMirror = false
    @State private var triggerMirrorAnim = false
    @State private var capturedVideoPath: String?
    
    @StateObject private var speechManager = SpeechRecognizerHelper()
    @State private var dictatedNote = ""
    @State private var baseNoteText = ""
    
    init(isPresented: Binding<Bool>, preselectedRoutine: Routine? = nil) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    let autoSidePadding = max(screenWidth * 0.08, 22)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            
                            HStack(spacing: 8) {
                                Image(systemName: "tray.and.arrow.down.fill")
                                    .foregroundColor(LuxuryTheme.gold400)
                                Text("RÝCHLA POZNÁMKA DO SCHRÁNKY")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundColor(LuxuryTheme.gold400)
                                    .tracking(1.4)
                            }
                            .padding(.top, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.12))
                            
                            // Quick Video Capture Area with live play/pause controls
                            VStack(spacing: 12) {
                                if let videoPath = capturedVideoPath,
                                   let videoURL = resolveVideoURL(path: videoPath) {
                                    
                                    VStack(spacing: 10) {
                                        CapturedVideoPreview(videoURL: videoURL)
                                            .frame(height: 200)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(LuxuryTheme.gold400.opacity(0.35), lineWidth: 1)
                                            )
                                        
                                        HStack(spacing: 12) {
                                            Button(action: { presentCamera() }) {
                                                Label("Natočiť znova", systemImage: "arrow.triangle.2.circlepath")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .buttonStyle(.neubrutalistSecondary(cornerRadius: 10))
                                            
                                            Button(action: {
                                                MediaStorageManager.removeFile(named: videoPath)
                                                capturedVideoPath = nil
                                            }) {
                                                Label("Vymazať", systemImage: "trash")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .buttonStyle(.neubrutalistSecondary(textColor: LuxuryTheme.latinCrimson, cornerRadius: 10))
                                        }
                                    }
                                    
                                } else {
                                    Button(action: { presentCamera() }) {
                                        VStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(LuxuryTheme.gold500.opacity(0.12))
                                                    .frame(width: 90, height: 90)
                                                
                                                Circle()
                                                    .stroke(LuxuryTheme.gold400.opacity(0.6), lineWidth: 2.5)
                                                    .frame(width: 78, height: 78)
                                                
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(LuxuryTheme.gold400)
                                            }
                                            
                                            Text("Natočiť tréningové video")
                                                .font(.system(size: 14, weight: .bold, design: .serif))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 170)
                                        .background(
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(LuxuryTheme.obsidian800.opacity(0.75))
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(.ultraThinMaterial)
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Quick Dance Mirror Button (Čisté Tanečné Zrkadlo s animovanou ikonou bez pozadia)
                            Button(action: {
                                triggerMirrorAnim = true
                                HapticFeedback.light()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    showMirror = true
                                    triggerMirrorAnim = false
                                }
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(LuxuryTheme.gold500.opacity(0.15))
                                            .frame(width: 42, height: 42)
                                        AnimatedMirrorIconView(size: 28, triggerExternal: triggerMirrorAnim)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Čisté Tanečné Zrkadlo")
                                            .font(.system(size: 14, weight: .bold, design: .serif))
                                            .foregroundColor(.white)
                                        Text("Čistá predná kamera bez rušivých prvkov")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.60))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(LuxuryTheme.obsidian800.opacity(0.75))
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovered in
                                if isHovered {
                                    triggerMirrorAnim = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        triggerMirrorAnim = false
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.12))
                            
                            // Voice Note Dictation section
                            VStack(spacing: 12) {
                                if speechManager.isRecording {
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(LuxuryTheme.latinCrimson)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                
                                Button(action: toggleVoiceRecording) {
                                    HStack(spacing: 10) {
                                        Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 16, weight: .bold))
                                        Text(speechManager.isRecording ? "Zastaviť prepis" : "Hovoriť do poznámky")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(speechManager.isRecording ? .white : LuxuryTheme.obsidian900)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        speechManager.isRecording
                                        ? AnyView(Capsule().fill(LuxuryTheme.latinCrimson))
                                        : AnyView(LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .leading, endPoint: .trailing).clipShape(Capsule()))
                                    )
                                    .shadow(color: (speechManager.isRecording ? LuxuryTheme.latinCrimson : LuxuryTheme.gold500).opacity(0.35), radius: 8, y: 3)
                                }
                                .buttonStyle(.plain)
                                
                                AppleTypewriterTextView(
                                    text: $dictatedNote,
                                    isRecording: speechManager.isRecording,
                                    placeholder: "Hovorte... text sa bude postupne vpisovať"
                                )
                                .onChange(of: speechManager.transcript) { _, newValue in
                                    if !newValue.isEmpty {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            if baseNoteText.isEmpty {
                                                dictatedNote = newValue
                                            } else {
                                                dictatedNote = baseNoteText + " " + newValue
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Save Button
                            Button(action: saveCapturedMedia) {
                                Text("Uložiť do schránky")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(canSave ? LuxuryTheme.obsidian900 : Color.white.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        canSave
                                        ? AnyView(LinearGradient(colors: [LuxuryTheme.gold400, LuxuryTheme.gold500], startPoint: .leading, endPoint: .trailing).clipShape(Capsule()))
                                        : AnyView(Capsule().fill(Color.white.opacity(0.08)))
                                    )
                                    .shadow(color: canSave ? LuxuryTheme.gold500.opacity(0.35) : Color.clear, radius: 10, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canSave)
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal, autoSidePadding)
                        .frame(width: screenWidth)
                    }
                }
            }
            .navigationTitle("Nahrávanie Záznamu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zatvoriť") { dismiss() }
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
            .fullScreenCover(isPresented: $showCamera) {
                DanceCameraView { localPath in
                    capturedVideoPath = localPath
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showMirror) {
                DanceMirrorView()
                    .ignoresSafeArea()
            }
            .onChange(of: showCamera) { _, isShowing in
                if isShowing && speechManager.isRecording {
                    speechManager.stopTranscribing()
                }
            }
            .onAppear {
                speechManager.requestPermissions()
            }
        }
    }
    
    private var canSave: Bool {
        return capturedVideoPath != nil || !dictatedNote.isEmpty
    }
    
    private func presentCamera() {
        showCamera = true
    }
    
    private func toggleVoiceRecording() {
        if speechManager.isRecording {
            // Capture transcript BEFORE stopTranscribing cancels the recognition task
            let captured = speechManager.stopTranscribing()
            if !captured.isEmpty {
                if baseNoteText.isEmpty {
                    dictatedNote = captured
                } else {
                    dictatedNote = baseNoteText + " " + captured
                }
            }
        } else {
            speechManager.transcript = ""
            baseNoteText = dictatedNote
            speechManager.startTranscribing()
        }
    }
    
    private func saveCapturedMedia() {
        let note = InstantNote(
            text: dictatedNote,
            videoPath: capturedVideoPath
        )
        modelContext.insert(note)
        try? modelContext.save()
        
        capturedVideoPath = nil
        dictatedNote = ""
        isPresented = false
    }
    
    private func resolveVideoURL(path: String) -> URL? {
        return MediaResolver.resolveVideoURL(path: path)
    }
}

private struct CapturedVideoPreview: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: videoURL)
                }
            }
            .onDisappear {
                player?.pause()
            }
            .onChange(of: videoURL) { _, newURL in
                player?.pause()
                player = AVPlayer(url: newURL)
            }
    }
}
