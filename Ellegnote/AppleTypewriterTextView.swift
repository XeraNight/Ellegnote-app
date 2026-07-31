import SwiftUI

// MARK: - Apple Intelligence Style Glowing Typewriter View
struct AppleTypewriterTextView: View {
    @Binding var text: String
    var isRecording: Bool
    var placeholder: String = "Hovorte... text sa bude postupne vpisovať"
    
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var waveAnimation: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Container with Apple Intelligence Glowing Border
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isRecording
                                ? LinearGradient(
                                    colors: [.themeAccent, .amberGold, .latinPink, .themeAccent],
                                    startPoint: UnitPoint(x: shimmerPhase + 1.0, y: 0),
                                    endPoint: UnitPoint(x: shimmerPhase + 1.5, y: 1)
                                )
                                : LinearGradient(colors: [Color.themeDark.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                            lineWidth: isRecording ? 2.5 : 1.5
                        )
                )
                .shadow(color: isRecording ? Color.themeAccent.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                if text.isEmpty && !isRecording {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(.themeDark.opacity(0.4))
                        .padding(12)
                } else {
                    // Typewriter Spoken Words Text Area
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.themeDark)
                        .padding(6)
                        .overlay(
                            // Shimmering Apple gradient light pass overlay
                            Group {
                                if isRecording {
                                    LinearGradient(
                                        colors: [.clear, Color.white.opacity(0.9), .clear],
                                        startPoint: UnitPoint(x: shimmerPhase, y: 0),
                                        endPoint: UnitPoint(x: shimmerPhase + 0.4, y: 0)
                                    )
                                    .mask(
                                        Text(text)
                                            .font(.system(size: 15, weight: .bold, design: .serif))
                                            .padding(6)
                                    )
                                    .allowsHitTesting(false)
                                }
                            }
                        )
                }
                
                // Active Dictation Sound Wave Indicator
                if isRecording {
                    HStack(spacing: 4) {
                        ForEach(0..<9, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.themeAccent, Color.amberGold],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 3, height: CGFloat([8, 14, 20, 12, 18, 22, 10, 16, 8][index]) * waveAnimation)
                        }
                        
                        Text("Rozpoznávam reč...")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.themeAccent)
                            .padding(.leading, 6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                            waveAnimation = 1.3
                        }
                    }
                }
            }
        }
        .frame(height: 120)
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                shimmerPhase = 2.0
            }
        }
    }
}
