import SwiftUI

// MARK: - Dance Metronome & BPM Trainer View
// A dedicated, high-precision rhythm training tool for ballroom dancers and coaches.
public struct DanceMetronomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = DanceMetronomeEngine.shared
    
    @State private var selectedCategory: DanceCategoryTab = .all
    @State private var showBpmSlider: Bool = false
    
    private enum DanceCategoryTab: String, CaseIterable {
        case all = "Všetky"
        case standard = "Štandard"
        case latin = "Latina"
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ElleganceToolBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 1. Silent Mode & Studio Mixing Info Badge
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.amberGold)
                            Text("Bypass tichého režimu • Mixuje sa so štúdiovou hudbou")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.amberGold.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.amberGold.opacity(0.30), lineWidth: 1))
                        .padding(.top, 10)
                        
                        // 2. Large Interactive Rhythm Display
                        VStack(spacing: 12) {
                            Text(engine.selectedPreset != .off ? engine.selectedPreset.danceName.uppercased() : "VYBERTE TANEC")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color.amberGold)
                                .tracking(2.0)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(engine.effectiveBpm)")
                                    .font(.system(size: 78, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: engine.isPlaying && engine.isPulse ? Color.amberGold.opacity(0.5) : Color.clear, radius: 16)
                                
                                Text("BPM")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .scaleEffect(engine.isPlaying && engine.isPulse ? 1.04 : 1.0)
                            .animation(.spring(response: 0.12, dampingFraction: 0.6), value: engine.isPulse)
                            
                            if engine.effectiveMpm > 0 {
                                Text("\(engine.effectiveMpm) taktov za minútu (MPM) • \(engine.beatsPerMeasure) doby v takte")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.60))
                            }
                        }
                        .padding(.vertical, 12)
                        
                        // 3. Beat Visualizer (Pulsing Bar Capsules)
                        HStack(spacing: 14) {
                            ForEach(1...engine.beatsPerMeasure, id: \.self) { beat in
                                let isCurrent = (engine.isPlaying && engine.currentBeat == beat)
                                let isDownbeat = (beat == 1)
                                
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                isCurrent
                                                    ? (isDownbeat ? Color.amberGold : Color.white)
                                                    : Color.white.opacity(0.12)
                                            )
                                            .frame(maxWidth: 60)
                                            .frame(height: isCurrent ? 44 : 36)
                                            .shadow(
                                                color: isCurrent
                                                    ? (isDownbeat ? Color.amberGold.opacity(0.7) : Color.white.opacity(0.3))
                                                    : Color.clear,
                                                radius: 12
                                            )
                                        
                                        Text("\(beat)")
                                            .font(.system(size: isCurrent ? 18 : 14, weight: .black, design: .rounded))
                                            .foregroundColor(isCurrent ? .black : .white.opacity(0.6))
                                    }
                                    
                                    Text(isDownbeat ? "ŤAH" : "DOBA")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(isCurrent ? (isDownbeat ? Color.amberGold : .white) : .white.opacity(0.35))
                                }
                                .animation(.spring(response: 0.14, dampingFraction: 0.6), value: engine.currentBeat)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 4. Main Action Button (Play / Pause)
                        Button {
                            HapticFeedback.medium()
                            engine.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 20, weight: .bold))
                                Text(engine.isPlaying ? "ZASTAVIŤ METRONÓM" : "SPUSTIŤ RYTMUS")
                                    .font(.system(size: 15, weight: .black))
                                    .tracking(0.5)
                            }
                            .foregroundColor(engine.isPlaying ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                engine.isPlaying
                                    ? LinearGradient(colors: [Color.amberGold, Color.amberGold.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color(white: 0.2), Color(white: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(engine.isPlaying ? Color.amberGold : Color.white.opacity(0.20), lineWidth: 1)
                            )
                            .shadow(color: engine.isPlaying ? Color.amberGold.opacity(0.40) : Color.black.opacity(0.5), radius: 14, y: 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // 5. Fine Tempo Adjustments (-5, -1, +1, +5)
                        HStack(spacing: 10) {
                            tempoAdjustButton(title: "-5", delta: -5)
                            tempoAdjustButton(title: "-1", delta: -1)
                            
                            Button {
                                HapticFeedback.light()
                                engine.tempoMultiplier = 1.0
                                if engine.isPlaying {
                                    engine.start()
                                }
                            } label: {
                                Text("100%")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(engine.tempoMultiplier == 1.0 ? Color.amberGold : .white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                            }
                            
                            tempoAdjustButton(title: "+1", delta: 1)
                            tempoAdjustButton(title: "+5", delta: 5)
                        }
                        .padding(.horizontal, 20)
                        
                        // 6. Tempo Multiplier Quick Selector (80% to 115%)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TRÉNINGOVÁ RÝCHLOSŤ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 8) {
                                multiplierChip(label: "80%", value: 0.8)
                                multiplierChip(label: "90%", value: 0.9)
                                multiplierChip(label: "100%", value: 1.0)
                                multiplierChip(label: "105%", value: 1.05)
                                multiplierChip(label: "110%", value: 1.10)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 7. Dance Category Tabs & Presets
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("TANEČNÉ ŠTÝLY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                                
                                Spacer()
                                
                                Picker("", selection: $selectedCategory) {
                                    ForEach(DanceCategoryTab.allCases, id: \.self) { tab in
                                        Text(tab.rawValue).tag(tab)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                            }
                            .padding(.horizontal, 20)
                            
                            // Preset Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(filteredPresets) { preset in
                                    let isSelected = (engine.selectedPreset == preset)
                                    
                                    Button {
                                        HapticFeedback.light()
                                        engine.selectedPreset = preset
                                        engine.tempoMultiplier = 1.0
                                        if engine.isPlaying {
                                            engine.start(preset: preset)
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(preset.shortCode)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(isSelected ? Color.amberGold : .white)
                                                
                                                Text("\(Int(preset.bpm)) BPM (\(Int(preset.mpm)) MPM)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white.opacity(0.55))
                                            }
                                            
                                            Spacer()
                                            
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color.amberGold)
                                                    .font(.system(size: 16))
                                            }
                                        }
                                        .padding(14)
                                        .background(isSelected ? Color.amberGold.opacity(0.18) : Color.obsidian800.opacity(0.75))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Color.amberGold : Color.white.opacity(0.10), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 8. Toggles (Sound & Haptics)
                        VStack(spacing: 12) {
                            Toggle(isOn: $engine.isSoundEnabled) {
                                Label("Zvukový klik (Bypass Silent)", systemImage: "speaker.wave.2.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.amberGold)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $engine.isHapticEnabled) {
                                Label("Haptické pulzy v ruke", systemImage: "hand.tap.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.amberGold)
                        }
                        .padding(16)
                        .background(Color.obsidian800.opacity(0.75))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Tanečný Metronóm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LuxuryTheme.obsidian900, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hotovo") {
                        dismiss()
                    }
                    .foregroundColor(Color.amberGold)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredPresets: [DanceMetronomePreset] {
        DanceMetronomePreset.allCases.filter { preset in
            guard preset != .off && preset != .custom else { return false }
            switch selectedCategory {
            case .all:
                return true
            case .standard:
                return preset.category == "Standard"
            case .latin:
                return preset.category == "Latina"
            }
        }
    }
    
    // MARK: - Helper Views
    private func tempoAdjustButton(title: String, delta: Int) -> some View {
        Button {
            HapticFeedback.light()
            let newBpm = max(40, min(260, engine.effectiveBpm + delta))
            if engine.selectedPreset == .off || engine.selectedPreset == .custom {
                engine.selectedPreset = .custom
                engine.customBpm = newBpm
                engine.tempoMultiplier = 1.0
            } else {
                let baseBpm = engine.selectedPreset.bpm
                engine.tempoMultiplier = Double(newBpm) / baseBpm
            }
            if engine.isPlaying {
                engine.start()
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
        }
    }
    
    private func multiplierChip(label: String, value: Double) -> some View {
        let isSelected = abs(engine.tempoMultiplier - value) < 0.01
        
        return Button {
            HapticFeedback.light()
            engine.tempoMultiplier = value
            if engine.isPlaying {
                engine.start()
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .black : .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? Color.amberGold : Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.amberGold : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

// MARK: - Xcode Canvas Preview
#Preview("DanceMetronomeView") {
    DanceMetronomeView()
        .preferredColorScheme(.dark)
}
