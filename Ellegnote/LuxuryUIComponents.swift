import SwiftUI
import AudioToolbox

// MARK: - Luxury Design System Tokens (Ellegance.sk DNA)
public struct LuxuryTheme {
    public static let obsidian900 = Color(red: 5/255, green: 5/255, blue: 5/255)       // #050505
    public static let obsidian800 = Color(red: 10/255, green: 10/255, blue: 10/255)   // #0A0A0A
    public static let obsidian700 = Color(red: 20/255, green: 20/255, blue: 24/255)   // #141418
    public static let gold500     = Color(red: 212/255, green: 175/255, blue: 55/255)  // #D4AF37 Core Gold
    public static let gold400     = Color(red: 255/255, green: 224/255, blue: 136/255) // #FFE088 Bevel
    public static let gold300     = Color(red: 249/255, green: 241/255, blue: 204/255) // #F9F1CC
    
    // Discipline Colors
    public static let latinCrimson  = Color(red: 225/255, green: 29/255, blue: 72/255)   // #E11D48
    public static let standardBlue  = Color(red: 30/255, green: 64/255, blue: 175/255)   // #1E40AF
    public static let syncEmerald   = Color(red: 16/255, green: 185/255, blue: 129/255)  // #10B981
}

// MARK: - 0. Ellegance Ambient Page Background (Direct from Ellegance Website)
public struct EllegancePageBackground: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Base Obsidian Canvas
            LuxuryTheme.obsidian900.ignoresSafeArea()
            
            // Ambient Gold Light Bloom (Top-Left)
            Circle()
                .fill(LuxuryTheme.gold500.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -120, y: -250)
            
            // Ambient Slate Bloom (Bottom-Right)
            Circle()
                .fill(Color(red: 30/255, green: 30/255, blue: 45/255).opacity(0.20))
                .frame(width: 500, height: 500)
                .blur(radius: 140)
                .offset(x: 140, y: 300)
            
            // Soft Radial Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.65)],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
        // S3-2: Render entire ZStack into a single Metal texture.
        // Eliminates per-frame Gaussian blur GPU recalculation (blur:120, blur:140).
        // Safe here because this background is purely decorative and never animates.
        .drawingGroup()
    }
}

// MARK: - 1. Luxury Primary Button (Ellegance Gold CTA)
public struct LuxuryPrimaryButton: View {
    public let title: String
    public var icon: String? = nil
    public var isGoldVariant: Bool = true
    public let action: () -> Void
    
    public init(title: String, icon: String? = nil, isGoldVariant: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isGoldVariant = isGoldVariant
        self.action = action
    }
    
    public var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(isGoldVariant ? LuxuryTheme.obsidian900 : LuxuryTheme.gold500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                isGoldVariant
                ? LinearGradient(colors: [LuxuryTheme.gold500, LuxuryTheme.gold400], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian800], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isGoldVariant ? Color.white.opacity(0.40) : LuxuryTheme.gold400.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: isGoldVariant ? LuxuryTheme.gold500.opacity(0.25) : Color.black.opacity(0.4), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 2. Luxury Secondary Smoked Glass Button
public struct LuxurySecondaryButton: View {
    public let title: String
    public var icon: String? = nil
    public let action: () -> Void
    
    public init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                ZStack {
                    LuxuryTheme.obsidian700.opacity(0.85)
                    Rectangle().fill(.ultraThinMaterial)
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.20), Color.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.30), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3. Luxury Discipline Pill Filter
public struct LuxuryPillFilter: View {
    public let title: String
    public var icon: String? = nil
    public var isSelected: Bool = false
    public var accentColor: Color = LuxuryTheme.gold500
    public let action: () -> Void
    
    public init(title: String, icon: String? = nil, isSelected: Bool = false, accentColor: Color = LuxuryTheme.gold500, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }
    
    public var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(isSelected ? LuxuryTheme.obsidian900 : Color.white.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? LinearGradient(colors: [accentColor, LuxuryTheme.gold400], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [LuxuryTheme.obsidian700, LuxuryTheme.obsidian800], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.30) : Color.clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - 4. Luxury Smoked Liquid Glass Figure Card
public struct LuxuryFigureCardView: View {
    public let stepNumber: Int
    public let figureName: String
    public let danceName: String
    public let timing: String
    public let direction: String
    public let descriptionText: String
    public let footworkMan: String
    public let footworkLady: String
    public var coachNoteCount: Int = 1
    public var hasVideo: Bool = true
    
    @State private var masteryRating: Int = 4
    @State private var isExpanded: Bool = false
    
    public init(
        stepNumber: Int = 3,
        figureName: String = "Natural Spin Turn",
        danceName: String = "Waltz",
        timing: String = "1 2 3",
        direction: String = "↗ LOD",
        descriptionText: String = "Pravá noha vpred s plynulým znížením, prechod na špičku a rotácia 3/8 vpravo do záveru.",
        footworkMan: String = "TH - T - TH",
        footworkLady: String = "HT - T - TH",
        coachNoteCount: Int = 1,
        hasVideo: Bool = true
    ) {
        self.stepNumber = stepNumber
        self.figureName = figureName
        self.danceName = danceName
        self.timing = timing
        self.direction = direction
        self.descriptionText = descriptionText
        self.footworkMan = footworkMan
        self.footworkLady = footworkLady
        self.coachNoteCount = coachNoteCount
        self.hasVideo = hasVideo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Meta Bar: Discipline & Step # (Left) + Timing & Direction (Right)
            HStack {
                HStack(spacing: 6) {
                    Text(danceName.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(LuxuryTheme.gold500)
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text(String(format: "#%02d", stepNumber))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                
                Spacer()
                
                // Timing Badge & Direction
                HStack(spacing: 6) {
                    Text(timing)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(LuxuryTheme.gold400)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LuxuryTheme.gold500.opacity(0.18))
                        .cornerRadius(6)
                    
                    Text(direction)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
            }
            
            // Figure Name & Mastery Rating Stars
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(figureName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(descriptionText)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.7))
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                // Interactive 5-Star Mastery Bar
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            HapticFeedback.light()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                masteryRating = star
                            }
                        } label: {
                            Image(systemName: star <= masteryRating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(star <= masteryRating ? LuxuryTheme.gold400 : Color.white.opacity(0.2))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            
            // Technical Footwork Chips
            HStack(spacing: 8) {
                techChip(title: "Pán", value: footworkMan, icon: "figure.walk")
                techChip(title: "Dáma", value: footworkLady, icon: "figure.stand")
                
                if coachNoteCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 9))
                        Text("\(coachNoteCount)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(LuxuryTheme.standardBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LuxuryTheme.standardBlue.opacity(0.20))
                    .cornerRadius(8)
                }
            }
            
            // Video Preview Strip if available
            if hasVideo {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(LuxuryTheme.gold500)
                            .font(.system(size: 15))
                        Text("Tréningový záznam (00:14)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Prehrať ➔")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold400)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
        .padding(18)
        .background(
            ZStack {
                LuxuryTheme.obsidian700.opacity(0.75)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            LuxuryTheme.gold400.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 6)
    }
    
    private func techChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(Color.white.opacity(0.5))
            Text("\(title):")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }
}

// MARK: - 5. Showcase Playground View
public struct LuxuryDesignSystemShowcaseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDiscipline: String = "Všetky"
    
    let disciplines = ["Všetky", "💃 Latinské", "👔 Štandard", "⭐ Obľúbené"]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ELLEGNOTE DESIGN SYSTEM")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(LuxuryTheme.gold500)
                                .kerning(1.0)
                            Text("Ellegance Dark Liquid Glass")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 1. Tanečné Filtre
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(disciplines, id: \.self) { disc in
                                    LuxuryPillFilter(
                                        title: disc,
                                        isSelected: selectedDiscipline == disc,
                                        accentColor: disc.contains("Latin") ? LuxuryTheme.latinCrimson : LuxuryTheme.gold500
                                    ) {
                                        selectedDiscipline = disc
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 2. Ukážka Kariet Figúr
                        VStack(alignment: .leading, spacing: 14) {
                            Text("KARTY FIGÚR (FIGURE CARDS)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                LuxuryFigureCardView(
                                    stepNumber: 1,
                                    figureName: "Natural Spin Turn",
                                    danceName: "Waltz",
                                    timing: "1 2 3",
                                    direction: "↗ LOD",
                                    descriptionText: "Pravá noha vpred s plynulým znížením, prechod na špičku a rotácia 3/8 vpravo.",
                                    footworkMan: "TH - T - TH",
                                    footworkLady: "HT - T - TH",
                                    coachNoteCount: 2,
                                    hasVideo: true
                                )
                                
                                LuxuryFigureCardView(
                                    stepNumber: 2,
                                    figureName: "Open Hip Twist",
                                    danceName: "Cha-Cha",
                                    timing: "2 3 4&1",
                                    direction: "→ Stenou",
                                    descriptionText: "Prudké zastavenie pohybu na dobe 2, rotácia bedier a vyvedenie partnerky do vejára.",
                                    footworkMan: "B - B - B - B",
                                    footworkLady: "B - B - B - B",
                                    coachNoteCount: 0,
                                    hasVideo: true
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 3. Tlačidlá (Buttons)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TLAČIDLÁ (BUTTONS)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                LuxuryPrimaryButton(title: "Spustiť Tréningové Finále", icon: "play.fill", isGoldVariant: true) {}
                                
                                LuxuryPrimaryButton(title: "Uložiť Novú Figúru", icon: "sparkles", isGoldVariant: false) {}
                                
                                HStack(spacing: 10) {
                                    LuxurySecondaryButton(title: "Zdieľať QR", icon: "qrcode") {}
                                    LuxurySecondaryButton(title: "Exportovať PDF", icon: "doc.text") {}
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") {
                        dismiss()
                    }
                    .foregroundColor(LuxuryTheme.gold500)
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
}

// MARK: - Native SwiftUI Animated Download Loop Icon
public struct DownloadingLoopIconView: View {
    public var size: CGFloat = 24
    public var strokeColor: Color = LuxuryTheme.gold500
    public var isAnimating: Bool = true
    
    @State private var rotation: Double = 0
    @State private var arrowOffset: CGFloat = 0

    public init(size: CGFloat = 24, strokeColor: Color = LuxuryTheme.gold500, isAnimating: Bool = true) {
        self.size = size
        self.strokeColor = strokeColor
        self.isAnimating = isAnimating
    }

    public var body: some View {
        ZStack {
            // Left Arc
            Circle()
                .trim(from: 0.25, to: 0.75)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size * 0.75, height: size * 0.75)

            // Rotating dashed right arc
            Circle()
                .trim(from: 0.75, to: 1.25)
                .stroke(strokeColor.opacity(0.65), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
                .frame(width: size * 0.75, height: size * 0.75)
                .rotationEffect(.degrees(rotation))

            // Arrow Down (Center)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(strokeColor)
                    .frame(width: 2, height: size * 0.32)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: size * 0.30, weight: .bold))
                    .foregroundColor(strokeColor)
                    .offset(y: -1 + arrowOffset)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if isAnimating {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    arrowOffset = 1.5
                }
            }
        }
    }
}
