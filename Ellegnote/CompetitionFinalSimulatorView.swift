import SwiftUI
import AudioToolbox
import SwiftData

// MARK: - Final Discipline Enum
enum FinalDiscipline: String, CaseIterable, Identifiable {
    case standard = "Štandard (STT)"
    case latin = "Latina (LAT)"
    case tenDance = "10 Tancov"
    
    var id: String { rawValue }
    
    var dances: [String] {
        switch self {
        case .standard:
            return ["Waltz", "Tango", "Viedenský valčík", "Slowfox", "Quickstep"]
        case .latin:
            return ["Samba", "Cha-Cha", "Rumba", "Paso Doble", "Jive"]
        case .tenDance:
            return ["Waltz", "Tango", "Viedenský valčík", "Slowfox", "Quickstep", "Samba", "Cha-Cha", "Rumba", "Paso Doble", "Jive"]
        }
    }
}

// MARK: - Final Phase Enum
enum FinalPhase {
    case setup
    case dancing
    case resting
    case finished
}

// MARK: - CompetitionFinalSimulatorView
struct CompetitionFinalSimulatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var routines: [Routine]
    
    @State private var selectedDiscipline: FinalDiscipline = .standard
    @State private var danceDurationSeconds: Int = 90 // 1:30 min
    @State private var restDurationSeconds: Int = 30  // 0:30 min
    
    // State
    @State private var phase: FinalPhase = .setup
    @State private var currentDanceIndex: Int = 0
    @State private var timeRemaining: Int = 90
    @State private var timer: Timer? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                switch phase {
                case .setup:
                    setupView
                case .dancing, .resting:
                    activeSimulationView
                case .finished:
                    finalResultsView
                }
            }
            .navigationTitle("Súťažný Simulátor Finále")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(phase == .setup ? "Zavrieť" : "Ukončiť") {
                        stopSimulator()
                        dismiss()
                    }
                    .foregroundColor(.themeDark)
                }
            }
        }
        .onDisappear {
            stopSimulator()
        }
    }
    
    // MARK: - 1. Setup View
    private var setupView: some View {
        VStack(spacing: 24) {
            // Header Info Card
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.amberGold)
                
                Text("Simulátor Finálového Kola")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.themeDark)
                
                Text("Tréning kondície a mentálnej pripravenosti na 5 tancov po sebe s 30s pauzou")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Discipline Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("DISCIPLÍNA")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.themeTextSecondary)
                
                Picker("Disciplína", selection: $selectedDiscipline) {
                    ForEach(FinalDiscipline.allCases) { disc in
                        Text(disc.rawValue).tag(disc)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 16)
            
            // List of Dances in this Final
            VStack(alignment: .leading, spacing: 8) {
                Text("PORADIE TANCOV VO FINÁLE (\(selectedDiscipline.dances.count))")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.themeTextSecondary)
                
                VStack(spacing: 6) {
                    ForEach(Array(selectedDiscipline.dances.enumerated()), id: \.offset) { idx, dance in
                        HStack {
                            Text("\(idx + 1).")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.themeAccent)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(dance)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeDark)
                            
                            Spacer()
                            
                            // Check if matching routine exists
                            if let _ = routines.first(where: { $0.danceName.localizedCaseInsensitiveContains(dance) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Zostava pripravená")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("Vlastný tanec")
                                    .font(.system(size: 11))
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Start Simulation Button
            Button(action: startFinal) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .black))
                    Text("Štart Finále (\(selectedDiscipline.dances.first ?? ""))")
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
    
    // MARK: - 2. Active Simulation View (Dancing or Resting)
    private var activeSimulationView: some View {
        let currentDanceName = selectedDiscipline.dances[currentDanceIndex]
        let currentRoutine = routines.first(where: { $0.danceName.localizedCaseInsensitiveContains(currentDanceName) })
        let total = phase == .dancing ? danceDurationSeconds : restDurationSeconds
        let progress = Double(total - timeRemaining) / Double(total)
        
        return VStack(spacing: 20) {
            // Phase Banner
            HStack {
                Text("TANEC \(currentDanceIndex + 1) / \(selectedDiscipline.dances.count)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .cornerRadius(12)
                
                Spacer()
                
                Text(phase == .dancing ? "🔥 NA PARKETE" : "💨 PAUZA NA VÝDYCH")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(phase == .dancing ? .latinRed : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Big Dance Title
            VStack(spacing: 4) {
                Text(currentDanceName.uppercased())
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.themeDark)
                
                if phase == .resting && currentDanceIndex + 1 < selectedDiscipline.dances.count {
                    Text("Pripravte sa na: \(selectedDiscipline.dances[currentDanceIndex + 1])")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            
            // Big Circular Countdown Gauge
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 14)
                    .frame(width: 220, height: 220)
                    .neubrutalistCard(cornerRadius: 110, shadowOffset: 2)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        phase == .dancing ? Color.latinRed : Color.green,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)
                
                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 52, weight: .black, design: .monospaced))
                        .foregroundColor(.themeDark)
                    
                    Text(phase == .dancing ? "Tancujte zostavu!" : "Vydýchať & Napiť sa")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .padding(.vertical, 12)
            
            // Choreography Figures Preview Card
            if let routine = currentRoutine, !routine.canvasNodes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ZOSTAVA: \(routine.name)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.themeTextSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })) { node in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(node.orderIndex). \(node.figureName)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.themeDark)
                                    if !node.rhythm.isEmpty {
                                        Text(node.rhythm)
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundColor(.themeAccent)
                                    }
                                }
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.themeBorder, lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Skip Dance / Next Button
            Button(action: advancePhase) {
                HStack(spacing: 8) {
                    Text("Preskočiť na ďalší krok")
                    Image(systemName: "forward.fill")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeDark)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.themeBorder, lineWidth: 1.5))
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - 3. Final Results View
    private var finalResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "medal.fill")
                .font(.system(size: 64))
                .foregroundColor(.amberGold)
            
            VStack(spacing: 8) {
                Text("FINÁLE DOKONČENÉ!")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.themeDark)
                
                Text("Úspešne ste odtancovali všetkých \(selectedDiscipline.dances.count) tancov v plnom súťažnom tempe.")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Stats card
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("CELKOVÝ ČAS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.themeTextSecondary)
                    let totalSec = (danceDurationSeconds + restDurationSeconds) * selectedDiscipline.dances.count
                    Text(formatTime(totalSec))
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.themeDark)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .neubrutalistCard(cornerRadius: 14, shadowOffset: 2)
                
                VStack(spacing: 4) {
                    Text("ODTANCIVANÝCH")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.themeTextSecondary)
                    Text("\(selectedDiscipline.dances.count) tancov")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .neubrutalistCard(cornerRadius: 14, shadowOffset: 2)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button("Ukončiť tréning") {
                dismiss()
            }
            .buttonStyle(.neubrutalist(accentColor: Color.themeAccent, cornerRadius: 18))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Simulation Logic & Timers
    private func startFinal() {
        currentDanceIndex = 0
        phase = .dancing
        timeRemaining = danceDurationSeconds
        playGongSound()
        
        let dance = selectedDiscipline.dances[0]
        let currentRoutine = routines.first(where: { $0.danceName.localizedCaseInsensitiveContains(dance) })
        let firstFig = currentRoutine?.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex }).first?.figureName ?? "Základný nášľap"
        
        DanceLiveActivityManager.shared.startLiveActivity(
            discipline: selectedDiscipline.rawValue,
            routineName: currentRoutine?.name ?? "Súťažné Finále",
            firstDance: dance,
            totalDances: selectedDiscipline.dances.count,
            durationSeconds: danceDurationSeconds,
            firstFigure: firstFig
        )
        
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 1 {
                timeRemaining -= 1
                if timeRemaining == 10 {
                    AudioServicesPlaySystemSound(1057) // 10s warning
                }
                
                // Update Dynamic Island on every tick (or 5s interval)
                if timeRemaining % 2 == 0 {
                    updateLiveActivityState()
                }
            } else {
                advancePhase()
            }
        }
    }
    
    private func advancePhase() {
        if phase == .dancing {
            playGongSound()
            if currentDanceIndex + 1 < selectedDiscipline.dances.count {
                phase = .resting
                timeRemaining = restDurationSeconds
                updateLiveActivityState()
            } else {
                timer?.invalidate()
                timer = nil
                phase = .finished
                DanceLiveActivityManager.shared.endLiveActivity()
                playFanfareSound()
            }
        } else if phase == .resting {
            playGongSound()
            currentDanceIndex += 1
            phase = .dancing
            timeRemaining = danceDurationSeconds
            updateLiveActivityState()
        }
    }
    
    private func updateLiveActivityState() {
        let dance = selectedDiscipline.dances[currentDanceIndex]
        let currentRoutine = routines.first(where: { $0.danceName.localizedCaseInsensitiveContains(dance) })
        let firstFig = currentRoutine?.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex }).first?.figureName ?? "Základný nášľap"
        
        DanceLiveActivityManager.shared.updateLiveActivity(
            danceName: dance,
            danceIndex: currentDanceIndex,
            totalDances: selectedDiscipline.dances.count,
            timeRemaining: timeRemaining,
            isResting: phase == .resting,
            currentFigure: firstFig
        )
    }
    
    private func stopSimulator() {
        timer?.invalidate()
        timer = nil
        DanceLiveActivityManager.shared.endLiveActivity()
    }
    
    private func playGongSound() {
        AudioServicesPlaySystemSound(1005) // Round Gong / Bell
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
    
    private func playFanfareSound() {
        AudioServicesPlaySystemSound(1025) // Fanfare / Success
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
