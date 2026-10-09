import SwiftUI
import AVFoundation
import PhotosUI
import SwiftData
import OSLog

// MARK: - Seminar Split Clip Model
struct SeminarClipItem: Identifiable {
    let id = UUID()
    let title: String
    let startTime: Double
    let endTime: Double
    let fileURL: URL
    let filePath: String
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
      private var isCutDisabled: Bool {
        isExportingClip || clipEndTime <= clipStartTime
    }
    
    @ViewBuilder
    private var cutButtonBackground: some View {
        if isCutDisabled {
            LinearGradient(
                colors: [Color.obsidian700.opacity(0.85), Color.obsidian800.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.goldLinearGradient
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ElleganceToolBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let _ = seminarVideoURL, let player = player {
                            videoPlayerSection(player: player)
                        } else {
                            videoImportCard
                        }
                        
                        if seminarVideoURL != nil {
                            markDeckSection
                        }
                        
                        if !extractedClips.isEmpty {
                            extractedClipsSection
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
                        .foregroundColor(.gold400)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoImport(newItem)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func videoPlayerSection(player: AVPlayer) -> some View {
        VStack(spacing: 8) {
            ZStack {
                VideoTrimPlayerRepresentable(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)
                
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.gold400.opacity(0.9))
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
                .tint(Color.gold400)
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatTime(totalDuration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var videoImportCard: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
            ZStack {
                // Subtle Art Deco geometric concentric circles in background (4% opacity)
                Circle()
                    .strokeBorder(Color.gold400.opacity(0.06), lineWidth: 1)
                    .frame(width: 140, height: 140)
                Circle()
                    .strokeBorder(Color.gold400.opacity(0.04), lineWidth: 1)
                    .frame(width: 210, height: 210)
                
                VStack(spacing: 12) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color.gold400)
                    
                    Text("Nahrať video seminára z kempu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Podporuje dlhé 30 – 60 minútové nahrávky z workshopov")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
            .luxurySmokedCard(cornerRadius: 18, accentColor: Color.gold400)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var markDeckSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("OZNAČIŤ FIGÚRU V SEMINÁRI")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color.textSecondary)
            
            HStack(spacing: 12) {
                // Set Start Time Button
                Button {
                    clipStartTime = currentTime
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.syncEmerald).frame(width: 8, height: 8)
                            Text("ZAČIATOK")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.syncEmerald)
                        }
                        Text(formatTime(clipStartTime))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.obsidian900)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.syncEmerald.opacity(0.6), lineWidth: 1.5))
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
                            Circle().fill(Color.latinRed).frame(width: 8, height: 8)
                            Text("KONIEC")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.latinRed)
                        }
                        Text(formatTime(clipEndTime))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.obsidian900)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.latinRed.opacity(0.6), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            
            // Figure Name TextField
            TextField("Názov vystrihnutej figúry...", text: $figureNameInput)
                .padding(12)
                .foregroundColor(.white)
                .background(Color.obsidian900)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.20), lineWidth: 1))
            
            // Target Routine Picker
            if !routines.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRIRADIŤ K ZOSTAVE (VOLITEĽNÉ)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                    
                    Picker("Zostava", selection: $selectedRoutine) {
                        Text("Nepriradzovať").tag(Routine?.none)
                        ForEach(routines) { r in
                            Text("\(r.name) (\(r.danceName))").tag(Routine?.some(r))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .background(Color.obsidian900)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
            
            // Cut & Save Action Button
            Button(action: extractAndSaveClip) {
                HStack(spacing: 8) {
                    if isExportingClip {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "scissors")
                            .font(.system(size: 15, weight: .bold))
                        Text("Vystrihnúť figúru do inventára")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(isCutDisabled ? Color.white.opacity(0.35) : Color.obsidian900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(cutButtonBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCutDisabled ? Color.gold400.opacity(0.18) : Color.white.opacity(0.40), lineWidth: 1)
                )
                .shadow(color: isCutDisabled ? Color.clear : Color.gold500.opacity(0.35), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isCutDisabled)
        }
        .padding(16)
        .luxurySmokedCard(cornerRadius: 16, accentColor: Color.gold400)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var extractedClipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VYSTRIHNUTÉ FIGÚRY ZO SEMINÁRA (\(extractedClips.count))")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color.textSecondary)
            
            ForEach(extractedClips) { clip in
                HStack(spacing: 12) {
                    MediaThumbnailView(path: clip.filePath, cornerRadius: 8)
                        .frame(width: 54, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clip.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Trvanie: \(clip.durationString)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.syncEmerald)
                }
                .padding(12)
                .background(Color.obsidian800)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
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
                    Logger.camera.error("Seminar clip export failed: \(error.localizedDescription, privacy: .public)")
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
                            fileURL: outputURL,
                            filePath: filename
                        )
                        self.extractedClips.append(clip)
                        
                        // Always save to Media Vault
                        let entry = VideoMediaEntry(
                            filePath: filename,
                            title: self.figureNameInput,
                            role: .coach
                        )
                        if let routine = self.selectedRoutine {
                            entry.routine = routine
                        }
                        self.modelContext.insert(entry)
                        try? self.modelContext.save()
                        
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                        
                        // Advance start time to current end time for next clip
                        self.clipStartTime = self.clipEndTime
                        self.clipEndTime = min(self.totalDuration, self.clipStartTime + 30.0)
                        self.figureNameInput = "Ďalšia figúra zo seminára"
                    } catch {
                        Logger.camera.error("Saving seminar clip failed: \(error.localizedDescription, privacy: .public)")
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

// MARK: - Xcode Canvas Preview
#Preview("SeminarSplitterView") {
    SeminarSplitterView()
        .previewWithSampleData()
}
