import SwiftUI

// MARK: - All Routines Sheet View
struct AllRoutinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let routines: [Routine]
    let onSelectRoutine: (Routine) -> Void
    let onNewRoutine: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("VŠETKY ZOSTAVY (\(routines.count))")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(Color.white.opacity(0.45))
                                    .tracking(1.2)
                                Spacer()
                                Button("Nová zostava") {
                                    onNewRoutine()
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.gold400)
                            }
                            .padding(.top, 16)
                            
                            ForEach(routines) { routine in
                                Button {
                                    onSelectRoutine(routine)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: routine.danceCategory.lowercased() == "standard" ? "drop.fill" : "flame.fill")
                                                        .font(.system(size: 8, weight: .bold))
                                                    Text(routine.danceCategory.uppercased())
                                                        .font(.system(size: 9, weight: .black))
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    routine.danceCategory.lowercased() == "standard"
                                                    ? Color.standardBlue.opacity(0.25)
                                                    : Color.latinPink.opacity(0.25)
                                                )
                                                .foregroundColor(
                                                    routine.danceCategory.lowercased() == "standard"
                                                    ? Color.standardBlue
                                                    : Color.latinPink
                                                )
                                                .cornerRadius(4)
                                                
                                                Text(routine.danceName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Color.gold300)
                                            }
                                            
                                            Text(routine.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.on.square.dashed")
                                                .font(.system(size: 10))
                                            Text("\(routine.canvasNodes.count) figúr")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(Color.gold400)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gold500.opacity(0.1))
                                        .cornerRadius(6)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .luxurySmokedCard(cornerRadius: 14, accentColor: Color.gold400)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, autoSidePadding)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Tanečné zostavy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { dismiss() }
                        .foregroundColor(Color.gold400)
                }
            }
        }
    }
}
