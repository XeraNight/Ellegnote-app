import SwiftUI

extension Color {
    // MARK: - Ellegance.sk Official Palette
    static let obsidian900 = Color(red: 5/255, green: 5/255, blue: 5/255)             // #050505 Canvas Base
    static let obsidian800 = Color(red: 10/255, green: 10/255, blue: 10/255)         // #0A0A0A Sub-canvas
    static let obsidian700 = Color(red: 20/255, green: 20/255, blue: 24/255)         // #141418 Smoked Glass Card
    static let gold300     = Color(red: 249/255, green: 241/255, blue: 204/255)       // #F9F1CC Light Champagne
    static let gold400     = Color(red: 255/255, green: 224/255, blue: 136/255)       // #FFE088 Bevel Specular
    static let gold500     = Color(red: 212/255, green: 175/255, blue: 55/255)        // #D4AF37 Core Gold
    
    // MARK: - Theme Aliases (Dark Obsidian Luxury Default)
    static let themeBg = Color(red: 5/255, green: 5/255, blue: 5/255)                 // #050505 Pure Obsidian
    static let themeCard = Color(red: 18/255, green: 18/255, blue: 22/255)           // #121216 Smoked Glass Card
    static let themeDark = Color(white: 0.96)                                         // #F5F5F5 Crisp Luminous White (Primary Text)
    static let themeAccent = Color(red: 212/255, green: 175/255, blue: 55/255)       // #D4AF37 Champagne Gold
    static let themeBorder = Color(red: 255/255, green: 224/255, blue: 136/255).opacity(0.20) // Gold 400 Bevel
    static let themeTextSecondary = Color.white.opacity(0.60)                          // Muted Secondary Text
    static let themeBgCard = Color(red: 18/255, green: 18/255, blue: 22/255)
    
    // MARK: - Discipline & Status Vibrance
    static let standardBlue = Color(red: 59/255, green: 130/255, blue: 246/255)      // #3B82F6 Vibrant Royal Blue
    static let latinPink = Color(red: 244/255, green: 63/255, blue: 94/255)          // #F43F5E Latin Rose
    static let latinRed = Color(red: 225/255, green: 29/255, blue: 72/255)            // #E11D48 Latin Crimson / REC
    static let latinCrimson = Color(red: 225/255, green: 29/255, blue: 72/255)        // #E11D48 Latin Crimson / REC
    static let amberGold = Color(red: 212/255, green: 175/255, blue: 55/255)          // #D4AF37 Core Gold
    static let syncEmerald = Color(red: 16/255, green: 185/255, blue: 129/255)        // #10B981 Sync Emerald
    
    // Classic Aliases
    static let obsidianBlack = Color(red: 5/255, green: 5/255, blue: 5/255)
    static let champagneGold = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let silkIvory = Color(red: 251/255, green: 249/255, blue: 245/255)
}
