import SwiftUI

// MARK: - Dance Category Selection Sheet
struct DanceCategorySelectionSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Výber tanečnej kategórie")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Vyberte štýl tanca pre založenie novej choreografie:")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 14) {
                            NavigationLink(destination: DanceCategoryView(category: "Standard")) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.standardBlue.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.standardBlue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ŠTANDARDNÉ TANCE")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.white)
                                        Text("Waltz, Tango, Valčík, Slowfox, Quickstep")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.white.opacity(0.3))
                                }
                                .padding(18)
                                .background(Color.themeCard)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.standardBlue.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: DanceCategoryView(category: "Latin")) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.latinPink.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.latinPink)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("LATINSKOAMERICKÉ TANCE")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundColor(.white)
                                        Text("Samba, Cha-Cha, Rumba, Paso Doble, Jive")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.white.opacity(0.3))
                                }
                                .padding(18)
                                .background(Color.themeCard)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.latinPink.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { isPresented = false }
                        .foregroundColor(Color.gold400)
                }
            }
        }
    }
}
