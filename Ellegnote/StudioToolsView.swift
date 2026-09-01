import SwiftUI

// MARK: - Studio & Coach Tools Hub View
// S4-2: Separated from ProfileView to reduce cognitive overload and
// elevate specialized coach/studio tools into a dedicated, premium view.
struct StudioToolsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showFinalSimulator = false
    @State private var showMusicSpeedTrainer = false
    @State private var showSeminarSplitter = false
    @State private var showCompetitionOrganizer = false

    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header Banner
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TRÉNERSKÉ & SÚŤAŽNÉ ŠTÚDIO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.gold400)
                            .tracking(1.5)
                        
                        Text("Profesionálne Nástroje")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Špecializované moduly pre trénerov, súťažné páry a tanečné kempy.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // 1. Competition Final Simulator
                    StudioToolCard(
                        icon: "trophy.fill",
                        iconColor: Color.gold400,
                        title: "Súťažný simulátor finále",
                        subtitle: "5 tancov v plnom tempe s odpočítavaním a prestávkami medzi tancami pre nácvik kondície.",
                        badge: "5 tancov"
                    ) {
                        showFinalSimulator = true
                    }
                    .padding(.horizontal, 20)
                    
                    // 2. Competition Rounds Organizer
                    StudioToolCard(
                        icon: "number.square.fill",
                        iconColor: Color.themeAccent,
                        title: "Súťažný organizér kôl",
                        subtitle: "Zoznam štartovných čísel, heatov a kôl pre hladký priebeh súťažného dňa.",
                        badge: "Heaty & Čísla"
                    ) {
                        showCompetitionOrganizer = true
                    }
                    .padding(.horizontal, 20)
                    
                    // 3. Music Speed & Pitch Trainer
                    StudioToolCard(
                        icon: "music.note.list",
                        iconColor: LuxuryTheme.latinCrimson,
                        title: "Music Speed & Pitch Trainer",
                        subtitle: "Zmena tempa skladby od 70% do 130% bez zmeny tóniny (pitch preservation).",
                        badge: "70% – 130%"
                    ) {
                        showMusicSpeedTrainer = true
                    }
                    .padding(.horizontal, 20)
                    
                    // 4. Workshop & Seminar Splitter
                    StudioToolCard(
                        icon: "scissors",
                        iconColor: LuxuryTheme.syncEmerald,
                        title: "Camp & Seminar Splitter",
                        subtitle: "Inteligentný strihač celých lekcií na jednotlivé figúry s automatickým pomenovaním.",
                        badge: "Workshopy"
                    ) {
                        showSeminarSplitter = true
                    }
                    .padding(.horizontal, 20)
                    
                    // 5. AirPlay & Studio TV Hub
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "tv.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.gold400)
                                .frame(width: 32, height: 32)
                                .background(LuxuryTheme.gold500.opacity(0.12))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Studio AirPlay & TV Mód")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text(StudioAirPlayManager.shared.isExternalScreenConnected ? "Pripojené k TV obrazovke" : "Zrkadlenie na televízor v sále")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.60))
                            }
                            
                            Spacer()
                            
                            AirPlayRoutePickerRepresentable(tintColor: UIColor(Color.gold400))
                                .frame(width: 36, height: 36)
                        }
                        .padding(16)
                        .background(LuxuryTheme.obsidian800.opacity(0.75))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gold400.opacity(0.20), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Trénerské Štúdio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LuxuryTheme.obsidian900, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showFinalSimulator) {
            CompetitionFinalSimulatorView()
        }
        .sheet(isPresented: $showMusicSpeedTrainer) {
            MusicSpeedTrainerSheet()
        }
        .sheet(isPresented: $showSeminarSplitter) {
            SeminarSplitterView()
        }
        .sheet(isPresented: $showCompetitionOrganizer) {
            CompetitionOrganizerView()
        }
    }
}

// MARK: - Reusable Studio Tool Card
private struct StudioToolCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(badge)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(iconColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(iconColor.opacity(0.14))
                            .clipShape(Capsule())
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.60))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.30))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color.obsidian800.opacity(0.75))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.gold400.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
