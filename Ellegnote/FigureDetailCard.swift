import SwiftUI
import AVKit
import Speech
import SwiftData
import Combine


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
    
    // Auto-save and Cloud Indicator state
    @State private var autoSaveTask: Task<Void, Never>? = nil
    @State private var isAutoSaved = false
    
    // Voice note state
    @StateObject private var speechManager = SpeechRecognizerHelper()
    @State private var isListening = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Video loop section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Video ukážka")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                            
                            if let videoPath = node.videoPath,
                               let _ = resolveVideoURL(path: videoPath) {
                                
                                VStack(spacing: 12) {
                                    if let player = player {
                                        VideoPlayer(player: player)
                                            .frame(height: 220)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.themeDark, lineWidth: 2)
                                            )
                                    }
                                    
                                    // Playback Speed Controls
                                    HStack(spacing: 12) {
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
                        .padding(.horizontal, 20)
                        
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
                                        .stroke(Color.themeDark, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 20)
                        
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
                                node.videoPath = videoPath
                                try? modelContext.save()
                                
                                // Background Sync Video & Routine
                                if let routine = node.routine {
                                    Task.detached(priority: .background) {
                                        await SupabaseSyncManager.shared.uploadFileAsync(localFileName: videoPath)
                                        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 16)
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
            .fullScreenCover(isPresented: $showCamera) {
                VideoRecorderView { localPath in
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
                            SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                        }
                    }
                    
                    // Broadcast update
                    realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func saveChanges() {
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
            player = nil
            
            // Broadcast update
            realtimeManager?.broadcastNodeUpdated(node: node, senderName: userName)
        }
    }
    
    private func setupPlayer(for path: String?) {
        guard let path = path, let url = resolveVideoURL(path: path),
              (url.isFileURL ? MediaStorageManager.fileExists(path) : true) else {
            player = nil
            return
        }
        let ap = AVPlayer(url: url)
        // Looping via notification
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: ap.currentItem,
            queue: .main
        ) { _ in
            ap.seek(to: .zero)
            ap.play()
            ap.rate = playbackRate
        }
        player = ap
        ap.play()
        ap.rate = playbackRate
    }
    
    private func resolveVideoURL(path: String) -> URL? {
        return MediaResolver.resolveVideoURL(path: path)
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
        
        // Configure AVAudioSession for playback (unmutes audio in Silent Mode)
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
        try? audioSession.setActive(true)
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let player = AVQueuePlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        self.queuePlayer = player
        
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        player.play()
        player.rate = rate
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
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine, let request = request else { return }
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        isRecording = true
        transcript = ""
        
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
        return capturedTranscript
    }
}

// MARK: - Simple camera view representable
// MARK: - Full-Screen Camera with Frosted Cream Bottom Overlay

/// Kamera na celú obrazovku. Ovládacie prvky plávajú ako frosted creamy panel dolu,
/// priehľadný X button hore. Žiadny čierny obdĺžnik — kamera vypĺňa celý screen.
struct VideoRecorderView: UIViewControllerRepresentable {
    var onRecordComplete: (String) -> Void

    func makeUIViewController(context: Context) -> CameraWrapperViewController {
        let vc = CameraWrapperViewController()
        vc.onRecordComplete = onRecordComplete
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraWrapperViewController, context: Context) {}
    func makeCoordinator() -> Void {}
}

// MARK: - CameraWrapperViewController

final class CameraWrapperViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var onRecordComplete: ((String) -> Void)?
    
    private let cream = UIColor(red: 0.961, green: 0.929, blue: 0.847, alpha: 1.0)
    private let espresso = UIColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
    
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var activeInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.ellegnote.videoRecorder.session", qos: .userInitiated)
    
    private var isRecording = false
    private var recordBtn: UIButton!
    private var timerLabel: UILabel!
    private var recordingTimer: Timer?
    private var elapsedSeconds = 0
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildOverlay()
        checkPermissionsAndSetup()
    }

    // MARK: - Permission gate
    // Production apps ALWAYS check permissions before touching AVCaptureSession.
    // Without this, the session silently fails when the user hasn't explicitly
    // granted camera access yet (first launch after install).
    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.showCameraSetupError("Prístup ku kamere bol odmietnutý.\nPovoľ ho v Nastavenia → Ellegnote.")
                    }
                }
            }
        case .denied, .restricted:
            showCameraSetupError("Prístup ku kamere je zakázaný.\nPovoľ ho v Nastavenia → Ellegnote.")
        @unknown default:
            setupCaptureSession()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Setup AVCaptureSession
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            // Step 1: Configure AVAudioSession BEFORE adding audio input.
            // Default category .soloAmbient is incompatible with capture → err=-19224.
            do {
                let as_ = AVAudioSession.sharedInstance()
                try as_.setCategory(.playAndRecord, mode: .videoRecording,
                                    options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
                try as_.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("[Camera] AVAudioSession: \(error.localizedDescription)")
                // Non-fatal — video records without audio
            }

            // Step 2: Build capture session
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .hd1280x720

            // Video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.showCameraSetupError("Kamera nie je dostupná.") }
                return
            }
            session.addInput(videoInput)

            // Audio input — optional, failure is non-fatal
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }

            // Movie output
            let output = AVCaptureMovieFileOutput()
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.showCameraSetupError("Výstup nie je dostupný.") }
                return
            }
            session.addOutput(output)
            session.commitConfiguration()

            // Step 3: Attach to UI on main thread, then start
            DispatchQueue.main.async {
                self.captureSession = session
                self.movieOutput   = output
                self.activeInput   = videoInput

                // Preview layer — use current bounds (layout is complete at this point)
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.frame = self.view.bounds
                preview.videoGravity = .resizeAspectFill
                self.view.layer.insertSublayer(preview, at: 0)
                self.previewLayer = preview

                // Enable record button
                self.recordBtn.isEnabled = true
                self.recordBtn.alpha = 1.0

                // Start running on background queue
                self.sessionQueue.async { session.startRunning() }
            }
        }
    }
    
    private func showCameraSetupError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    // MARK: - Floating Overlays
    private func buildOverlay() {
        let bottomH: CGFloat = 160
        
        // Bottom: liquid glass creamy bar floating over camera
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        
        let creamTint = UIView()
        creamTint.backgroundColor = cream.withAlphaComponent(0.42)
        creamTint.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(creamTint)
        
        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.65)
        separator.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.heightAnchor.constraint(equalToConstant: bottomH),
            
            creamTint.topAnchor.constraint(equalTo: blur.topAnchor),
            creamTint.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            creamTint.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            creamTint.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            
            separator.topAnchor.constraint(equalTo: blur.topAnchor),
            separator.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.5)
        ])
        
        // Record button
        recordBtn = UIButton(type: .custom)
        recordBtn.translatesAutoresizingMaskIntoConstraints = false
        recordBtn.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        blur.contentView.addSubview(recordBtn)
        NSLayoutConstraint.activate([
            recordBtn.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            recordBtn.topAnchor.constraint(equalTo: blur.topAnchor, constant: 22),
            recordBtn.widthAnchor.constraint(equalToConstant: 76),
            recordBtn.heightAnchor.constraint(equalToConstant: 76)
        ])
        recordBtn.isEnabled = false
        recordBtn.alpha = 0.45
        drawRecordButton(recording: false)
        
        // Flip camera — right side
        let flipBtn = makeIconButton(systemName: "camera.rotate.fill", size: 24, weight: .medium)
        flipBtn.tintColor = espresso
        flipBtn.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        blur.contentView.addSubview(flipBtn)
        NSLayoutConstraint.activate([
            flipBtn.centerYAnchor.constraint(equalTo: recordBtn.centerYAnchor),
            flipBtn.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -32),
            flipBtn.widthAnchor.constraint(equalToConstant: 48),
            flipBtn.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // Close button (Top Left)
        let closeBtn = makeIconButton(systemName: "xmark.circle.fill", size: 26, weight: .bold)
        closeBtn.tintColor = .white
        closeBtn.layer.shadowColor = UIColor.black.cgColor
        closeBtn.layer.shadowRadius = 4
        closeBtn.layer.shadowOpacity = 0.5
        closeBtn.layer.shadowOffset = .zero
        closeBtn.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
        view.addSubview(closeBtn)
        NSLayoutConstraint.activate([
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Timer (Top Center)
        timerLabel = UILabel()
        timerLabel.text = ""
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        timerLabel.textColor = .white
        timerLabel.layer.shadowColor = UIColor.black.cgColor
        timerLabel.layer.shadowRadius = 4
        timerLabel.layer.shadowOpacity = 0.8
        timerLabel.layer.shadowOffset = .zero
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: closeBtn.centerYAnchor)
        ])
    }
    
    private func makeIconButton(systemName: String, size: CGFloat, weight: UIImage.SymbolWeight) -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: cfg), for: .normal)
        return btn
    }
    
    private func drawRecordButton(recording: Bool) {
        recordBtn.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let size: CGFloat = 76
        
        // Outer ring — cream fill with espresso border
        let ring = CALayer()
        ring.frame = CGRect(x: 0, y: 0, width: size, height: size)
        ring.cornerRadius = size / 2
        ring.borderWidth = 3.5
        ring.borderColor = espresso.cgColor
        ring.backgroundColor = cream.withAlphaComponent(0.85).cgColor
        recordBtn.layer.addSublayer(ring)
        
        // Inner shape — circle when idle, rounded square when recording
        let innerSize: CGFloat = recording ? 30 : 58
        let pad = (size - innerSize) / 2
        let inner = CALayer()
        inner.frame = CGRect(x: pad, y: pad, width: innerSize, height: innerSize)
        inner.cornerRadius = recording ? 8 : innerSize / 2
        inner.backgroundColor = UIColor.systemRed.cgColor
        recordBtn.layer.addSublayer(inner)
    }
    
    // MARK: - Actions
    @objc private func toggleRecording() {
        guard let movieOutput = movieOutput else { return }
        
        if isRecording {
            isRecording = false
            stopTimer()
            drawRecordButton(recording: false)
            sessionQueue.async {
                movieOutput.stopRecording()
            }
        } else {
            let outputDirectory = NSTemporaryDirectory()
            let outputURL = URL(fileURLWithPath: outputDirectory).appendingPathComponent("\(UUID().uuidString).mp4")
            isRecording = true
            startTimer()
            drawRecordButton(recording: true)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            sessionQueue.async {
                movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            }
        }
    }
    
    @objc private func flipCamera() {
        guard let session = captureSession, !isRecording else { return }
        
        recordBtn.isEnabled = false
        sessionQueue.async { [weak self] in
            guard let self, let currentInput = self.activeInput else {
                DispatchQueue.main.async {
                    self?.recordBtn.isEnabled = true
                }
                return
            }
            
            session.beginConfiguration()
            session.removeInput(currentInput)
            
            let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                session.addInput(currentInput)
                session.commitConfiguration()
                DispatchQueue.main.async {
                    self.recordBtn.isEnabled = true
                }
                return
            }
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                DispatchQueue.main.async {
                    self.activeInput = newInput
                    self.recordBtn.isEnabled = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                session.addInput(currentInput)
                DispatchQueue.main.async {
                    self.recordBtn.isEnabled = true
                }
            }
            session.commitConfiguration()
        }
    }
    
    @objc private func dismissCamera() {
        if isRecording {
            movieOutput?.stopRecording()
            isRecording = false
            stopTimer()
        }
        dismiss(animated: true)
    }
    
    // MARK: - Timer
    private func startTimer() {
        elapsedSeconds = 0
        updateTimerLabel()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
            self?.updateTimerLabel()
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        timerLabel?.text = ""
        elapsedSeconds = 0
    }
    
    private func updateTimerLabel() {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        timerLabel?.text = String(format: "● %02d:%02d", m, s)
        timerLabel?.textColor = isRecording ? .systemRed : .white
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        stopTimer()

        // An error here can be non-fatal (e.g. max duration reached) — check if
        // there's usable data in the file before deciding to discard.
        let recordingSucceeded: Bool
        if let error = error as NSError? {
            let isPartialData = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            recordingSucceeded = isPartialData
            if !isPartialData {
                print("[Camera] Recording error (no data): \(error.localizedDescription)")
            }
        } else {
            recordingSucceeded = true
        }

        guard recordingSucceeded else {
            DispatchQueue.main.async { self.dismiss(animated: true) }
            return
        }

        Task.detached(priority: .userInitiated) {
            do {
                let filename = try MediaStorageManager.moveIntoDocuments(
                    from: outputFileURL, fileExtension: "mp4"
                )
                await MainActor.run { [weak self] in
                    self?.onRecordComplete?(filename)
                    self?.dismiss(animated: true)
                }
            } catch {
                print("[Camera] Failed to save recording: \(error)")
                await MainActor.run { [weak self] in self?.dismiss(animated: true) }
            }
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
