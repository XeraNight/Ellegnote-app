import SwiftUI
import AVFoundation
import Combine

// MARK: - MusicSpeedTrainerSheet
struct MusicSpeedTrainerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var audioTrainer = MusicSpeedTrainerEngine()
    @State private var showDocumentPicker = false
    
    // Quick Dance BPM Presets
    let dancePresets = [
        ("Waltz", 29),
        ("Tango", 32),
        ("Slowfox", 29),
        ("Quickstep", 51),
        ("Samba", 51),
        ("Cha-Cha", 31),
        ("Rumba", 26),
        ("Jive", 43)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 1. Audio Track Display Card
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 28))
                                .foregroundColor(.themeAccent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(audioTrainer.currentTrackTitle)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.themeDark)
                                    .lineLimit(1)
                                
                                Text(audioTrainer.isPlaying ? "Prehráva sa (Time-Pitch Engine)" : "Pozastavené")
                                    .font(.system(size: 12))
                                    .foregroundColor(.themeTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button("Zmeniť skladbu") {
                                showDocumentPicker = true
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeAccent)
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // 2. Dynamic BPM & Rate Gauge
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("RÝCHLOSŤ")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            Text("\(Int(audioTrainer.playbackRate * 100)) %")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.latinRed)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                        
                        VStack(spacing: 4) {
                            Text("UPRAVENÉ TEMPO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            Text(String(format: "%.1f MPM", audioTrainer.baseMPM * Double(audioTrainer.playbackRate)))
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(.themeAccent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                    }
                    .padding(.horizontal, 16)
                    
                    // 3. Rate Slider Deck (70% - 130%)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("POSUVNÍK RÝCHLOSTI (BEZ ZMENY TÓNINY)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            Spacer()
                            Button("Reset (100%)") {
                                audioTrainer.setRate(1.0)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.themeAccent)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(audioTrainer.playbackRate) },
                                set: { audioTrainer.setRate(Float($0)) }
                            ),
                            in: 0.70...1.30,
                            step: 0.01
                        )
                        .tint(.latinRed)
                        
                        HStack {
                            Text("70% (Spomalenie)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            Spacer()
                            Text("100% (Normál)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.themeDark)
                            Spacer()
                            Text("130% (Zrýchlenie)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                    .padding(18)
                    .background(Color.themeCard)
                    .neubrutalistCard(cornerRadius: 16, shadowOffset: 2)
                    .padding(.horizontal, 16)
                    
                    // 4. Quick Dance MPM Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RÝCHLE TANEČNÉ MPM")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.themeTextSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(dancePresets, id: \.0) { name, mpm in
                                    Button {
                                        audioTrainer.baseMPM = Double(mpm)
                                    } label: {
                                        Text("\(name) (\(mpm))")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(audioTrainer.baseMPM == Double(mpm) ? Color.themeAccent : Color.white)
                                            .foregroundColor(audioTrainer.baseMPM == Double(mpm) ? .white : .themeDark)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // 5. Main Play / Pause Button
                    Button(action: audioTrainer.togglePlayPause) {
                        HStack(spacing: 12) {
                            Image(systemName: audioTrainer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text(audioTrainer.isPlaying ? "Pozastaviť prehrávanie" : "Spustiť tréningovú hudbu")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.neubrutalist(accentColor: Color.themeAccent, cornerRadius: 18))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Music Speed Trainer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hotovo") { dismiss() }
                        .foregroundColor(.themeDark)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                AudioDocumentPicker { url in
                    audioTrainer.loadTrack(url: url)
                }
            }
        }
        .onDisappear {
            audioTrainer.stop()
        }
    }
}

// MARK: - Music Speed Trainer Engine (AVAudioEngine + AVAudioUnitTimePitch)
final class MusicSpeedTrainerEngine: ObservableObject, @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    
    @Published var isPlaying: Bool = false
    @Published var playbackRate: Float = 1.0
    @Published var currentTrackTitle: String = "Tréningový tanečný takt"
    @Published var baseMPM: Double = 29.0
    
    private var audioFile: AVAudioFile?
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(timePitch)
        
        // Connect playerNode -> timePitch -> mainMixerNode
        audioEngine.connect(playerNode, to: timePitch, format: nil)
        audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: nil)
        
        timePitch.pitch = 0.0 // Zero pitch shift guaranteed
        timePitch.rate = 1.0
        
        try? audioEngine.start()
    }
    
    func setRate(_ rate: Float) {
        playbackRate = max(0.5, min(rate, 2.0))
        timePitch.rate = playbackRate
    }
    
    func loadTrack(url: URL) {
        do {
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            self.currentTrackTitle = url.deletingPathExtension().lastPathComponent
            
            playerNode.stop()
            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            playerNode.pause()
            isPlaying = false
        } else {
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
            playerNode.play()
            isPlaying = true
        }
    }
    
    func stop() {
        playerNode.stop()
        audioEngine.stop()
        isPlaying = false
    }
}

// MARK: - Audio Document Picker
struct AudioDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let first = urls.first {
                onPick(first)
            }
        }
    }
}
