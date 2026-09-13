import SwiftUI
import AVFoundation
import PhotosUI
import SwiftData

// MARK: - Seminar Split Clip Model
struct SeminarClipItem: Identifiable {
    let id = UUID()
    let title: String
    let startTime: Double
    let endTime: Double
    let fileURL: URL
    let dateCreated = Date()
    
    var durationString: String {
        let diff = max(0, endTime - startTime)
        let m = Int(diff) / 60
        let s = Int(diff) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - SeminarSplitterView
struct SeminarSplitterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]
    
    // Video Source
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var seminarVideoURL: URL? = nil
    @State private var player: AVPlayer? = nil
    
    // Playback state
    @State private var totalDuration: Double = 0.0
    @State private var currentTime: Double = 0.0
    @State private var isPlaying: Bool = false
    @State private var timeObserverToken: Any?
    
    // Splitting marks
    @State private var clipStartTime: Double = 0.0
    @State private var clipEndTime: Double = 30.0
    @State private var figureNameInput: String = "Nová figúra zo seminára"
    @State private var selectedRoutine: Routine? = nil
    
    // Extracted clips in this session
    @State private var extractedClips: [SeminarClipItem] = []
    @State private var isExportingClip: Bool = false
    @State private var exportSuccessMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Video Player or Import Prompt
                        if let _ = seminarVideoURL, let player = player {
                            VStack(spacing: 8) {
                                ZStack {
                                    VideoTrimPlayerRepresentable(player: player)
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(16)
                                        .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
                                    
                                    Button(action: togglePlay) {
                                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                                
                                // Scrubbing Slider & Time
                                VStack(spacing: 4) {
                                    Slider(value: Binding(
                                        get: { currentTime },
                                        set: { newTime in
                                            currentTime = newTime
                                            seek(to: newTime)
                                        }
                                    ), in: 0...max(totalDuration, 0.1))
                                    .tint(.themeAccent)
                                    
                                    HStack {
                                        Text(formatTime(currentTime))
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        Spacer()
                                        Text(formatTime(totalDuration))
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(.themeTextSecondary)
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                            .padding(.horizontal, 16)
                        } else {
                            // Upload / Import Card
                            PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
                                VStack(spacing: 12) {
                                    Image(systemName: "film.stack.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.themeAccent)
                                    
                                    Text("Nahrať video seminára z kempu")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.themeDark)
                                    
                                    Text("Podporuje dlhé 30 – 60 minútové nahrávky z workshopov")
                                        .font(.system(size: 12))
                                        .foregroundColor(.themeTextSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(36)
                                .background(Color.white)
                                .neubrutalistCard(cornerRadius: 18, shadowOffset: 3)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // 2. Mark In & Mark Out Deck
                        if seminarVideoURL != nil {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("OZNAČIŤ FIGÚRU V SEMINÁRI")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.themeTextSecondary)
                                
                                HStack(spacing: 12) {
                                    // Set Start Time Button
                                    Button {
                                        clipStartTime = currentTime
                                        let gen = UIImpactFeedbackGenerator(style: .medium)
                                        gen.impactOccurred()
                                    } label: {
                                        VStack(spacing: 4) {
                                            HStack(spacing: 4) {
                                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                                Text("ZAČIATOK")
                                                    .font(.system(size: 11, weight: .black))
                                            }
                                            Text(formatTime(clipStartTime))
                                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Set End Time Button
                                    Button {
                                        clipEndTime = max(clipStartTime + 1.0, currentTime)
                                        let gen = UIImpactFeedbackGenerator(style: .medium)
                                        gen.impactOccurred()
                                    } label: {
                                        VStack(spacing: 4) {
                                            HStack(spacing: 4) {
                                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                                Text("KONIEC")
                                                    .font(.system(size: 11, weight: .black))
                                            }
                                            Text(formatTime(clipEndTime))
                                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 2))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Figure Name TextField
                                TextField("Názov vystrihnutej figúry...", text: $figureNameInput)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 1.5))
                                
                                // Target Routine Picker
                                if !routines.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("PRIRADIŤ K ZOSTAVE (VOLITEĽNÉ)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.themeTextSecondary)
                                        
                                        Picker("Zostava", selection: $selectedRoutine) {
                                            Text("Nepriradzovať").tag(Routine?.none)
                                            ForEach(routines) { r in
                                                Text("\(r.name) (\(r.danceName))").tag(Routine?.some(r))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .padding(8)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                }
                                
                                // Cut & Save Action Button
                                Button(action: extractAndSaveClip) {
                                    HStack(spacing: 8) {
                                        if isExportingClip {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "scissors")
                                                .font(.system(size: 16, weight: .black))
                                            Text("Vystrihnúť figúru do inventára")
                                                .font(.system(size: 15, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.neubrutalist(accentColor: Color.latinRed, cornerRadius: 14))
                                .disabled(isExportingClip || clipEndTime <= clipStartTime)
                            }
                            .padding(16)
                            .background(Color.themeCard)
                            .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                            .padding(.horizontal, 16)
                        }
                        
                        // 3. Extracted Clips List
                        if !extractedClips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("VYSTRIHNUTÉ FIGÚRY ZO SEMINÁRA (\(extractedClips.count))")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.themeTextSecondary)
                                
                                ForEach(extractedClips) { clip in
                                    HStack {
                                        Image(systemName: "play.rectangle.fill")
                                            .foregroundColor(.themeAccent)
                                            .font(.system(size: 20))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(clip.title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.themeDark)
                                            Text("Trvanie: \(clip.durationString)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.themeTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Camp & Seminar Splitter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hotovo") { dismiss() }
                        .foregroundColor(.themeDark)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoImport(newItem)
            }
        }
    }
    
    // MARK: - Playback Helpers
    private func togglePlay() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }
    
    private func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - Import Video from Photo Library
    private func handlePhotoImport(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
                await MainActor.run {
                    self.seminarVideoURL = movie.url
                    setupPlayer(for: movie.url)
                }
            }
        }
    }
    
    private func setupPlayer(for url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        self.player = p
        
        Task {
            if let dur = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(dur)
                await MainActor.run {
                    self.totalDuration = seconds
                    self.clipStartTime = 0.0
                    self.clipEndTime = min(seconds, 30.0)
                }
            }
        }
        
        timeObserverToken = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            self.currentTime = CMTimeGetSeconds(time)
        }
    }
    
    // MARK: - Extract Clip
    private func extractAndSaveClip() {
        guard let sourceURL = seminarVideoURL else { return }
        isExportingClip = true
        
        let asset = AVURLAsset(url: sourceURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("clip_\(UUID().uuidString).mp4")
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        let startCM = CMTime(seconds: clipStartTime, preferredTimescale: 600)
        let durationCM = CMTime(seconds: max(0.2, clipEndTime - clipStartTime), preferredTimescale: 600)
        exportSession?.timeRange = CMTimeRange(start: startCM, duration: durationCM)
        
        guard let session = exportSession else {
            isExportingClip = false
            return
        }
        
        Task {
            if #available(iOS 18.0, *) {
                do {
                    try await session.export(to: outputURL, as: .mp4)
                } catch {
                    print("Seminar clip export failed: \(error)")
                }
            } else {
                await withCheckedContinuation { continuation in
                    session.exportAsynchronously {
                        continuation.resume()
                    }
                }
            }
            
            await MainActor.run {
                self.isExportingClip = false
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    do {
                        let filename = try MediaStorageManager.moveIntoDocuments(from: outputURL, fileExtension: "mp4")
                        let clip = SeminarClipItem(
                            title: self.figureNameInput,
                            startTime: self.clipStartTime,
                            endTime: self.clipEndTime,
                            fileURL: outputURL
                        )
                        self.extractedClips.append(clip)
                        
                        // If assigned to a routine, add to Media Vault
                        if let routine = self.selectedRoutine {
                            let entry = VideoMediaEntry(
                                filePath: filename,
                                title: self.figureNameInput,
                                role: .coach
                            )
                            entry.routine = routine
                            self.modelContext.insert(entry)
                            try? self.modelContext.save()
                        }
                        
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                        
                        // Advance start time to current end time for next clip
                        self.clipStartTime = self.clipEndTime
                        self.clipEndTime = min(self.totalDuration, self.clipStartTime + 30.0)
                        self.figureNameInput = "Ďalšia figúra zo seminára"
                    } catch {
                        print("Failed to save clip: \(error)")
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
