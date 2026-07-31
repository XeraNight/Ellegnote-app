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
                Color.themeBg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    HStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .foregroundColor(.themeAccent)
                        Text("RÝCHLA POZNÁMKA DO SCHRÁNKY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.themeDark)
                            .tracking(1)
                    }
                    .padding(.top, 16)
                    
                    Divider()
                        .background(Color.themeBorder)
                        .padding(.horizontal, 20)
                    
                    // Quick Video Capture Area with live play/pause controls
                    VStack(spacing: 12) {
                        if let videoPath = capturedVideoPath,
                           let videoURL = resolveVideoURL(path: videoPath) {
                            
                            VStack(spacing: 10) {
                                VideoPlayer(player: AVPlayer(url: videoURL))
                                    .frame(height: 200)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.themeDark, lineWidth: 2)
                                    )
                                
                                HStack(spacing: 12) {
                                    Button(action: { showCamera = true }) {
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
                                    .buttonStyle(.neubrutalistSecondary(textColor: .latinRed, cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                        } else {
                            Button(action: { showCamera = true }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.themeAccent.opacity(0.08))
                                            .frame(width: 100, height: 100)
                                        
                                        Circle()
                                            .stroke(Color.themeAccent, lineWidth: 4)
                                            .frame(width: 86, height: 86)
                                        
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.themeAccent)
                                    }
                                    
                                    Text("Natočiť tréningové video")
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .foregroundColor(.themeDark)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                            }
                            .buttonStyle(.neubrutalistSecondary(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Divider()
                        .background(Color.themeBorder)
                        .padding(.horizontal, 20)
                    
                    // Voice Note Dictation section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hlasová poznámka trénera")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(.themeDark)
                            Spacer()
                            if speechManager.isRecording {
                                Circle()
                                    .fill(Color.latinRed)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: toggleVoiceRecording) {
                            HStack(spacing: 10) {
                                Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 18))
                                Text(speechManager.isRecording ? "Zastaviť prepis" : "Hovoriť do poznámky")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(speechManager.isRecording ? .white : .themeDark)
                        }
                        .buttonStyle(speechManager.isRecording
                            ? .neubrutalist(accentColor: Color.latinRed, cornerRadius: 24)
                            : .neubrutalistSecondary(cornerRadius: 24)
                        )
                        
                        AppleTypewriterTextView(
                            text: $dictatedNote,
                            isRecording: speechManager.isRecording,
                            placeholder: "Hovorte... text sa bude postupne vpisovať"
                        )
                        .padding(.horizontal, 20)
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
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveCapturedMedia) {
                        Text("Uložiť do schránky")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.neubrutalist(accentColor: canSave ? Color.themeAccent : Color.gray.opacity(0.6)))
                    .disabled(!canSave)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Nahrávanie Záznamu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
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
                VideoRecorderView { localPath in
                    capturedVideoPath = localPath
                }
                .ignoresSafeArea()
            }
            .onAppear {
                speechManager.requestPermissions()
            }
        }
    }
    
    private var canSave: Bool {
        return capturedVideoPath != nil || !dictatedNote.isEmpty
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
