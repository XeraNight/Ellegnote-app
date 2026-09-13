import SwiftUI
import SwiftData

// MARK: - Competition Round Model
struct CompetitionRoundItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var heatNumber: Int
    var isQualified: Bool
    var marksCount: Int? = nil
    var notes: String = ""
}

// MARK: - CompetitionOrganizerView
struct CompetitionOrganizerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("competitionBibNumber") private var bibNumber: String = "142"
    @AppStorage("competitionCategoryName") private var categoryName: String = "Dospelí - Štandard (A/S)"
    @AppStorage("competitionEventName") private var eventName: String = "Grand Prix Bratislava"
    
    @State private var rounds: [CompetitionRoundItem] = [
        CompetitionRoundItem(name: "1. Kolo (Rozstrely)", heatNumber: 2, isQualified: true, marksCount: 25, notes: "Všetky tance postup"),
        CompetitionRoundItem(name: "Semifinále", heatNumber: 1, isQualified: true, marksCount: 23, notes: "Dobrý priestor na Slowfox"),
        CompetitionRoundItem(name: "FINÁLE (6 Párov)", heatNumber: 1, isQualified: false, notes: "Tancovať na maximum!")
    ]
    
    @State private var newRoundName: String = ""
    @State private var venueFloorNotes: String = "Parket je rýchly, v rohu pri rozhodcoch 3 a 5 je mierne šmykľavý. Pozor na rám vo Viedenskom valčíku."
    @State private var showAddRoundSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Starting Bib Number & Couple Header Card
                        VStack(spacing: 12) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(eventName.uppercased())
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.themeTextSecondary)
                                    Text(categoryName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.themeDark)
                                }
                                
                                Spacer()
                                
                                // Big Bib Badge
                                VStack(spacing: 2) {
                                    Text("ŠTARTOVNÉ ČÍSLO")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("#\(bibNumber)")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundColor(.amberGold)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.amberGold, lineWidth: 1.5))
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // 2. Rounds & Heats Progression List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("POSTUP V SÚŤAŽI (KOLÁ & ROZSTRELY)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.themeTextSecondary)
                                Spacer()
                                Button("+ Pridať kolo") {
                                    showAddRoundSheet = true
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.themeAccent)
                            }
                            
                            ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(index + 1).")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.themeAccent)
                                        
                                        Text(round.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.themeDark)
                                        
                                        Spacer()
                                        
                                        // Heat Number Badge
                                        Text("Rozstrel \(round.heatNumber)")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(.themeDark)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.amberGold.opacity(0.2))
                                            .cornerRadius(8)
                                        
                                        // Qualification status toggle
                                        Button {
                                            rounds[index].isQualified.toggle()
                                            let gen = UIImpactFeedbackGenerator(style: .medium)
                                            gen.impactOccurred()
                                        } label: {
                                            Image(systemName: round.isQualified ? "checkmark.seal.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(round.isQualified ? .green : .themeBorder)
                                        }
                                    }
                                    
                                    if !round.notes.isEmpty {
                                        Text(round.notes)
                                            .font(.system(size: 12))
                                            .foregroundColor(.themeTextSecondary)
                                            .padding(.leading, 20)
                                    }
                                }
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(round.isQualified ? Color.green.opacity(0.5) : Color.themeBorder, lineWidth: 1.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 3. Venue & Floor Tactical Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TAKTICKÉ POZNÁMKY K PARKETU & ROZHODCOM")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.themeTextSecondary)
                            
                            TextEditor(text: $venueFloorNotes)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(10)
                                .background(Color.white)
                                .foregroundColor(.themeDark)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 1.5))
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Súťažný Organizér Kôl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hotovo") { dismiss() }
                        .foregroundColor(.themeDark)
                }
            }
            .sheet(isPresented: $showAddRoundSheet) {
                NavigationStack {
                    ZStack {
                        Color.themeBg.ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            TextField("Názov kola (napr. 2. Kolo)", text: $newRoundName)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder, lineWidth: 1))
                            
                            Button("Pridať kolo") {
                                if !newRoundName.isEmpty {
                                    rounds.append(CompetitionRoundItem(name: newRoundName, heatNumber: 1, isQualified: false))
                                    newRoundName = ""
                                    showAddRoundSheet = false
                                }
                            }
                            .buttonStyle(.neubrutalist(accentColor: Color.themeAccent, cornerRadius: 12))
                            .disabled(newRoundName.isEmpty)
                            
                            Spacer()
                        }
                        .padding(20)
                    }
                    .navigationTitle("Nové súťažné kolo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Zrušiť") { showAddRoundSheet = false }
                        }
                    }
                }
            }
        }
    }
}
