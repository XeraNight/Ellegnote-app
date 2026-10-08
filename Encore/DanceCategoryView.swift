import SwiftUI
import SwiftData

// MARK: - Dance Category View
struct DanceCategoryView: View {
    let category: String
    @Query(sort: \Dance.name) private var allDances: [Dance]
    
    var filteredDances: [Dance] {
        allDances.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 22)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: category.lowercased() == "standard" ? "drop.fill" : "flame.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(category.lowercased() == "standard" ? .standardBlue : .latinPink)
                            Text(category == "Standard" ? "Štandardné tance" : "Latinsko-americké tance")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(filteredDances) { dance in
                                NavigationLink(destination: DanceDetailView(dance: dance)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(dance.name)
                                                .font(.system(size: 18, weight: .bold, design: .serif))
                                                .foregroundColor(.white)
                                            Text(dance.tempo)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.gold400)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color.white.opacity(0.3))
                                    }
                                    .padding(20)
                                    .luxurySmokedCard(cornerRadius: 18, accentColor: Color.gold400)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
