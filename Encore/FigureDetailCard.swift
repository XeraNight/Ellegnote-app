import SwiftUI
import AVKit
import Speech
import SwiftData
import Combine
import UniformTypeIdentifiers


struct FigureDetailCard: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var node: CanvasNode
    
    var realtimeManager: CanvasRealtimeManager? = nil
    @AppStorage("profileName") private var userName = "Tanečník"
    
    @State private var playbackRate: Float = 1.0
    @State private var notesText = ""
    @State private var showCamera = false
    @State private var player: AVPlayer? = nil
    @State private var playerObserverToken: (any NSObjectProtocol)? = nil
    @State private var showFigureVideoVault = false
    @State private var showDuelComparison = false

    // Auto-save and Cloud Indicator state
    @State private var autoSaveTask: Task<Void, Never>? = nil
    @State private var isAutoSaved = false
    
    // Voice note state
    @StateObject private var speechManager = SpeechRecognizerHelper()
    @State private var isListening = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 22)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Video loop and Vault section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Tréningové & Referenčné Videá")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Button {
                                    showFigureVideoVault = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "film.stack")
                                        Text("Inventár (\(node.mediaVault.count))")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.themeAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.themeAccent.opacity(0.12))
                                    .cornerRadius(6)
                                }
                            }
                            
                            if let videoPath = node.videoPath,
                               let _ = resolveVideoURL(path: videoPath) {
                                
                                VStack(spacing: 12) {
                                    if let player = player {
                                        VideoPlayer(player: player)
                                            .frame(height: 220)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.gold400.opacity(0.25), lineWidth: 1)
                                            )
                                    }
                                    
                                    // Playback Speed Controls & Actions
                                    HStack(spacing: 8) {
                                        Text("Rýchlosť:")
                                            .font(.system(size: 12, weight: .bold, design: .serif))
                                            .foregroundColor(.themeDark)
                                        
                                        ForEach([0.5, 0.75, 1.0, 1.5], id: \.self) { speed in
                                            Button(action: { playbackRate = Float(speed) }) {
                                                Text(String(format: "%.2fx", speed))
                                                    .font(.system(size: 11, weight: .black))
                                                    .foregroundColor(playbackRate == Float(speed) ? .white : .themeDark)
                                            }
                                            .buttonStyle(playbackRate == Float(speed)
                                                ? .neubrutalist(accentColor: Color.themeAccent, cornerRadius: 8)
                                                : .neubrutalistSecondary(cornerRadius: 8)
                                            )
                                        }
                                        
                                        Spacer()
                                        
                                        // Duel button if target exists or multiple videos exist
                                        if node.activeTargetVideoPath != nil || node.mediaVault.count > 1 {
                                            Button {
                                                showDuelComparison = true
                                            } label: {
                                                Image(systemName: "rectangle.split.2x1.fill")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                                    .background(Color.themeAccent)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        
                                        // Delete Video Option
                                        Button(action: deleteVideo) {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.latinRed)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            } else {
                                // No Video Placeholder
                                Button(action: { showCamera = true }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "video.badge.plus.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.themeAccent)
                                        Text("Nahrať tréningové video")
                                            .font(.system(size: 14, weight: .bold, design: .serif))
                                            .foregroundColor(.themeDark)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Mastery Star Rating & Coach Evaluation (Funkcia 19)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Úroveň zvládnutia figúry")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                Spacer()
                                Text(ratingLabel(node.masteryRating))
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(ratingColor(node.masteryRating))
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        node.masteryRating = star
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.impactOccurred()
                                    } label: {
                                        Image(systemName: star <= node.masteryRating ? "star.fill" : "star")
                                            .font(.system(size: 22))
                                            .foregroundColor(star <= node.masteryRating ? .amberGold : Color.themeBorder)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.themeCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.25), lineWidth: 1))
                        }
                        
                        // Text notes section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Moje poznámky k figúre")
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
                                        .stroke(Color.gold400.opacity(0.25), lineWidth: 1)
                                )
                        }
                        
                        // Trainer voice dictation section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Hlasová poznámka trénera")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                Spacer()
                                if speechManager.isRecording {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .opacity(isListening ? 0.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isListening)
                                        .onAppear { isListening = true }
                                        .onDisappear { isListening = false }
                                }
                            }
                            
                            Button(action: toggleVoiceRecording) {
                                  HStack(spacing: 8) {
                                      Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                          .font(.system(size: 20))
                                      Text(speechManager.isRecording ? "Zastaviť nahrávanie" : "Diktovať (Hlasový vstup)")
                                          .font(.system(size: 14, weight: .bold))
                                  }
                                  .foregroundColor(speechManager.isRecording ? .white : .themeDark)
                                  .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(speechManager.isRecording
                                ? .neubrutalist(accentColor: Color.red, cornerRadius: 12)
                                : .neubrutalistSecondary(cornerRadius: 12)
                            )
                            
                            if !speechManager.transcript.isEmpty {
                                Text("Prepísaný text:")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundColor(.themeDark)
                                
                                Text("\"\(speechManager.transcript)\"")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.themeDark)
                                    .italic()
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .neubrutalistCard(cornerRadius: 10, shadowOffset: 2)
                                
                                Button("Použiť prepis") {
                                    if !notesText.isEmpty {
                                        notesText += "\n" + speechManager.transcript
                                    } else {
                                        notesText = speechManager.transcript
                                    }
                                    speechManager.transcript = ""
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeAccent)
                            }
                        }
                        
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
                                node.videoPath = videoPath
                                try? modelContext.save()
                                
                                // Background Sync Video & Routine
                                if let routine = node.routine {
                                    Task.detached(priority: .background) {
                                        await SupabaseSyncManager.shared.uploadFileAsync(localFileName: videoPath)
                                        await SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                                    }
                                }
                            }
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(node.figureName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.themeDark)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 6) {
                        if isAutoSaved {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.cloud.fill")
                                    .foregroundColor(.themeAccent)
                                Text("Uložené")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.themeDark)
                            }
                            .transition(.opacity)
                        }
                        
                        Button("Hotovo") {
                            saveChanges()
                            dismiss()
                        }
                        .foregroundColor(.themeAccent)
                        .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .onAppear {
                notesText = node.notes
                speechManager.requestPermissions()
                setupPlayer(for: node.videoPath)
            }
            .onChange(of: node.videoPath) { _, newValue in
                setupPlayer(for: newValue)
            }
            .onChange(of: notesText) { _, newText in
                autoSaveTask?.cancel()
                autoSaveTask = Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard !Task.isCancelled else { return }
                    
                    node.notes = newText
                    try? node.modelContext?.save()
                    realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
                    
                    if let routine = node.routine {
                        routine.updatedAt = Date()
                        routine.lastModifiedBy = userName
                        try? routine.modelContext?.save()
                        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                    }
                    await MainActor.run {
                        withAnimation { isAutoSaved = true }
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation { isAutoSaved = false }
                    }
                }
            }
            .onChange(of: playbackRate) { _, newRate in
                player?.rate = newRate
            }
            .onChange(of: showCamera) { _, isShowing in
                if isShowing {
                    if let token = playerObserverToken {
                        NotificationCenter.default.removeObserver(token)
                        playerObserverToken = nil
                    }
                    player?.pause()
                    player = nil
                    if speechManager.isRecording {
                        speechManager.stopTranscribing()
                    }
                } else {
                    setupPlayer(for: node.videoPath)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                DanceCameraView(ghostVideoPath: node.activeTargetVideoPath) { localPath in
                    node.videoPath = localPath
                    try? node.modelContext?.save()
                    showCamera = false
                    
                    // Background Sync Video & Routine
                    if let routine = node.routine {
                        routine.updatedAt = Date()
                        routine.lastModifiedBy = userName
                        try? routine.modelContext?.save()
                        
                        Task.detached(priority: .background) {
                            await SupabaseSyncManager.shared.uploadFileAsync(localFileName: localPath)
                            await SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                        }
                    }
                    
                    // Broadcast update
                    realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showFigureVideoVault) {
                VideoVaultView(
                    node: node,
                    activeSlotAPath: $node.videoPath,
                    activeSlotBPath: $node.activeTargetVideoPath
                )
            }
            .sheet(isPresented: $showDuelComparison) {
                DualVideoComparisonView(
                    pathA: $node.videoPath,
                    pathB: $node.activeTargetVideoPath,
                    titleA: "\(node.figureName) (Moje)",
                    titleB: "\(node.figureName) (Vzor)"
                )
            }
        }
    }
    
    private func saveChanges() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
        
        guard node.notes != notesText else { return }
        node.notes = notesText
        try? node.modelContext?.save()
        
        // Background Sync Routine
        if let routine = node.routine {
            routine.updatedAt = Date()
            routine.lastModifiedBy = userName
            try? routine.modelContext?.save()
            SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        }
        
        // Broadcast update
        realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
    }
    
    private func deleteVideo() {
        if let videoPath = node.videoPath {
            MediaStorageManager.removeFile(named: videoPath)
            node.videoPath = nil
            try? node.modelContext?.save()
            
            // Background Sync Routine
            if let routine = node.routine {
                routine.updatedAt = Date()
                routine.lastModifiedBy = userName
                try? routine.modelContext?.save()
                SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
            }
            // Cleanup observer a player pred vymazaním
            if let token = playerObserverToken {
                NotificationCenter.default.removeObserver(token)
                playerObserverToken = nil
            }
            player = nil
            Task { await AudioSessionCoordinator.shared.deactivate(.player) }
            
            // Broadcast update
            realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
        }
    }
    
    private func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "🔴 Potrebuje tréning"
        case 2: return "🟠 Začiatočná fáza"
        case 3: return "🟡 Dobre zvládnuté"
        case 4: return "🔵 Pokročilá technika"
        case 5: return "🟢 Súťažná istota"
        default: return "🟡 Dobre zvládnuté"
        }
    }
    
    private func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1: return .red
        case 2: return .orange
        case 3: return .amberGold
        case 4: return .blue
        case 5: return .green
        default: return .amberGold
        }
    }
    
    private func setupPlayer(for path: String?) {

        // ✅ OPRAVA 1: Vždy odober starý observer pred novou inštanciou.
        // Pôvodný kód ukladal token do nicoho → removeObserver nešlo nikdy zavolať.
        if let token = playerObserverToken {
            NotificationCenter.default.removeObserver(token)
            playerObserverToken = nil
        }
        player?.pause()
        player = nil

        guard let path = path,
              let url = resolveVideoURL(path: path),
              (url.isFileURL ? MediaStorageManager.fileExists(path) : true) else {
            return
        }

        let ap = AVPlayer(url: url)

        // ✅ OPRAVA 2: Token uložený → observer sa dá neskôr odstrániť.
        // ✅ OPRAVA 3: [weak ap] → žiadny retain cycle (pôvodný kód držal ap silno).
        let token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: ap.currentItem,
            queue: .main
        ) { [weak ap] _ in
            ap?.seek(to: .zero)
            ap?.play()
        }
        playerObserverToken = token
        player = ap

        // ✅ OPRAVA 4: Prehrávač ide cez koordinátora — koniec konfliktu so speech session.
        Task { @MainActor in
            try? await AudioSessionCoordinator.shared.activate(.player)
            ap.play()
            ap.rate = playbackRate
        }
    }
    
    private func resolveVideoURL(path: String) -> URL? {
        return MediaResolver.resolveVideoURL(path: path)
    }
    
    private func toggleVoiceRecording() {
        if speechManager.isRecording {
            // Capture transcript BEFORE stopTranscribing clears the task
            let captured = speechManager.stopTranscribing()
            if !captured.isEmpty {
                speechManager.transcript = captured
            }
        } else {
            speechManager.transcript = ""
            speechManager.startTranscribing()
        }
    }
}

// MARK: - Looping Player view helpers
class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    init(url: URL, rate: Float) {
        super.init(frame: .zero)

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        self.queuePlayer = player

        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        // ✅ Audio session cez koordinátora — nie priamo, aby nenarazil do kamery.
        Task {
            try? await AudioSessionCoordinator.shared.activate(.player)
            player.play()
            player.rate = rate
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    func setRate(_ rate: Float) {
        queuePlayer?.rate = rate
    }
    
    func stop() {
        queuePlayer?.pause()
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer = nil
        Task {
            await AudioSessionCoordinator.shared.deactivate(.player)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoURL: URL
    let rate: Float
    
    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView(url: videoURL, rate: rate)
        return view
    }
    
    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.setRate(rate)
    }
    
    static func dismantleUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.stop()
    }
}

// MARK: - Speech Recognition Manager
@MainActor
class SpeechRecognizerHelper: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var audioLevel: CGFloat = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init() {
        if let slovak = SFSpeechRecognizer(locale: Locale(identifier: "sk-SK")) {
            self.recognizer = slovak
        } else {
            self.recognizer = SFSpeechRecognizer() // Fallback to system locale
        }
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        Task {
            if #available(iOS 17.0, *) {
                _ = await AVAudioApplication.requestRecordPermission()
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            }
        }
    }
    
    func startTranscribing() {
        guard let recognizer = recognizer, recognizer.isAvailable else { return }

        // ✅ Audio session cez koordinátora — aktivujeme .speech PRED štartom audioEngine.
        // Koordinátor nastaví .record/.measurement a bezpečne odovzdá session od .player.
        Task {
            do {
                try await AudioSessionCoordinator.shared.activate(.speech)
            } catch {
                print("[Speech] AudioSessionCoordinator activate failed: \(error)")
                return
            }

            audioEngine = AVAudioEngine()
            request = SFSpeechAudioBufferRecognitionRequest()

            guard let audioEngine = audioEngine, let request = request else { return }
            request.shouldReportPartialResults = true
            request.contextualStrings = [
                "Waltz", "Valčík", "Tango", "Slowfox", "Quickstep", "Samba", "Cha-Cha", "Čača", "Rumba", "Paso Doble", "Jive",
                "Chassé", "Rondé", "Fleckerl", "Contra Check", "Whisk", "Feather Step", "Hover Corte", "Telemark", "Impetus",
                "Natural Spin Turn", "Reverse Pivot", "Botafogo", "Volta", "Samba Rolls", "New York", "Spot Turn", "Alemana",
                "Rumba Walks", "Sliding Doors", "Opening Out", "Promenade", "Appell", "Huit", "Chasse Cape", "Link", "Whip",
                "Fallaway", "Toe Heel", "MPM", "BPM", "Sway", "Rise & Fall", "CBMP", "CBM", "Pohyb", "Držanie", "Rám", "Nášľap",
                "Chodidlo", "Rotácia", "Panva", "Partnerka", "Partner", "Tréner", "Rytmus", "Akcent", "Zdvih", "Klesanie"
            ]

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                request.append(buffer)
                
                // Native Apple AVFoundation Audio Metering (RMS / Decibel Calculation)
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frames = Int(buffer.frameLength)
                guard frames > 0 else { return }
                
                var sum: Float = 0
                for i in 0..<frames {
                    let sample = channelData[i]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(frames))
                let avgPower = 20 * log10(max(rms, 0.0001))
                let normalized = CGFloat(max(0.0, min(1.0, (avgPower + 45) / 45)))
                
                Task { @MainActor in
                    self?.audioLevel = normalized
                }
            }

            audioEngine.prepare()
            try? audioEngine.start()

            isRecording = true
            transcript = ""
            audioLevel = 0.0

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }

                let text = result?.bestTranscription.formattedString ?? ""
                let isDone = error != nil || result?.isFinal == true

                DispatchQueue.main.async {
                    self.transcript = text
                    if isDone {
                        self.stopTranscribing()
                    }
                }
            }
        }
    }
    
    /// Stops transcribing and returns the best transcript captured so far.
    /// We capture transcript BEFORE cancelling the task to avoid race condition
    /// where async main-queue callback would arrive after task is nil.
    @discardableResult
    func stopTranscribing() -> String {
        let capturedTranscript = transcript
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()

        audioEngine = nil
        request = nil
        task = nil
        isRecording = false
        audioLevel = 0.0

        Task {
            await AudioSessionCoordinator.shared.deactivate(.speech)
        }

        return capturedTranscript
    }
}

// MARK: - Native Video Camera Recorder (Apple Standard)
struct VideoRecorderView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onRecordComplete: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.mediaTypes = [UTType.movie.identifier]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeHigh
            picker.cameraDevice = .rear
            picker.allowsEditing = false
            if UIImagePickerController.isFlashAvailable(for: .rear) {
                picker.cameraFlashMode = .off
            }
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoRecorderView

        init(_ parent: VideoRecorderView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                do {
                    let filename = try MediaStorageManager.moveIntoDocuments(from: videoURL, fileExtension: "mp4")
                    parent.onRecordComplete(filename)
                } catch {
                    print("[Camera] Failed to move recorded video: \(error)")
                    parent.dismiss()
                }
            } else {
                parent.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
struct InstantNotesInboxSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var instantNotes: [InstantNote]
    
    let onImportText: (String) -> Void
    let onImportVideo: (String) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Label {
                        Text("Schránka instantných poznámok (\(instantNotes.count))")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                    } icon: {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .foregroundColor(.themeAccent)
                    }
                    .foregroundColor(.themeDark)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeDark)
                }
                .padding()
                .neubrutalistCard(cornerRadius: 12, shadowOffset: 3)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if instantNotes.isEmpty {
                    VStack(spacing: 8) {
                        Text("Schránka je prázdna")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .neubrutalistCard(cornerRadius: 12, shadowOffset: 0)
                } else {
                    VStack(spacing: 12) {
                        ForEach(instantNotes) { note in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.themeDark.opacity(0.5))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        modelContext.delete(note)
                                        try? modelContext.save()
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                if !note.text.isEmpty {
                                    Text(note.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(.themeDark)
                                        .padding(8)
                                        .background(Color.themeBg)
                                        .cornerRadius(8)
                                }
                                
                                if note.videoPath != nil {
                                    HStack {
                                        Image(systemName: "video.fill")
                                            .foregroundColor(.themeAccent)
                                            .font(.system(size: 12))
                                        Text("Obsahuje tréningové video")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.themeDark.opacity(0.7))
                                    }
                                    .padding(.vertical, 2)
                                }
                                
                                HStack(spacing: 8) {
                                    if !note.text.isEmpty {
                                        Button(action: {
                                            onImportText(note.text)
                                            // Consume block if it doesn't contain video, or delete note
                                            if note.videoPath == nil {
                                                modelContext.delete(note)
                                                try? modelContext.save()
                                            } else {
                                                note.text = ""
                                                try? modelContext.save()
                                            }
                                        }) {
                                            Label("Vložiť text", systemImage: "text.quote")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.themeAccent)
                                        }
                                        .buttonStyle(.neubrutalistSecondary(cornerRadius: 8))
                                    }
                                    
                                    if let videoPath = note.videoPath {
                                        Button(action: {
                                            onImportVideo(videoPath)
                                            // Consume video or delete note
                                            if note.text.isEmpty {
                                                modelContext.delete(note)
                                                try? modelContext.save()
                                            } else {
                                                note.videoPath = nil
                                                try? modelContext.save()
                                            }
                                        }) {
                                            Label("Použiť video", systemImage: "video.badge.plus")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.themeAccent)
                                        }
                                        .buttonStyle(.neubrutalistSecondary(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding()
                            .neubrutalistCard(cornerRadius: 12, shadowOffset: 3)
                        }
                    }
                }
            }
        }
    }
}
