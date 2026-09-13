import SwiftUI
import UIKit

// MARK: - Smoked Liquid Glass Card Modifier (Ellegance.sk Style)
struct NeubrutalistCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var fillColor: Color = .themeCard
    var strokeWidth: CGFloat = 1.0
    var shadowOffset: CGFloat = 6.0
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    fillColor.opacity(0.85)
                    // Glass blur
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.gold400.opacity(0.35),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: strokeWidth
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: shadowOffset)
    }
}

// MARK: - Luxury Primary / Action Button Style
struct NeubrutalistButtonStyle: ButtonStyle {
    var fillColor: Color
    var textColor: Color = .white
    var cornerRadius: CGFloat = 16
    var strokeWidth: CGFloat = 1.0
    var shadowOffset: CGFloat = 4
    var isToggled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed || isToggled
        let isGold = fillColor == .themeAccent || fillColor == .amberGold || fillColor == .gold500 || isToggled
        
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                isGold
                ? LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.obsidian700, Color.obsidian800], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(isGold ? Color.obsidian900 : (textColor == .white ? Color.gold500 : textColor))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isGold ? Color.white.opacity(0.40) : Color.gold400.opacity(0.25), lineWidth: strokeWidth)
            )
            .shadow(color: isGold ? Color.gold500.opacity(isPressed ? 0.10 : 0.25) : Color.black.opacity(0.35), radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 1 : 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPressed)
            .onChange(of: isPressed) { _, newValue in
                if newValue {
                    HapticFeedback.medium()
                }
            }
    }
}

// MARK: - Luxury Tactile CTA Button Style
struct CreativeCreamButtonStyle: ButtonStyle {
    var fillColor: Color = .obsidian700
    var textColor: Color = .gold500
    var cornerRadius: CGFloat = 16
    var hasHaptic: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(
                LinearGradient(
                    colors: [Color.gold500, Color.gold400],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(Color.obsidian900)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: Color.gold500.opacity(isPressed ? 0.10 : 0.30), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 5)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
            .onChange(of: isPressed) { _, newValue in
                if newValue && hasHaptic {
                    HapticFeedback.medium()
                }
            }
    }
}

// MARK: - Luxury Pill Action Button Style (Floating Smoked Glass Capsule)
struct CreativePillButtonStyle: ButtonStyle {
    var accentColor: Color = .themeAccent
    var isGold: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let bgGradient = isGold
            ? LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [accentColor, accentColor.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
        
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(isGold ? Color.obsidian900 : .white)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(bgGradient)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: isGold ? Color.gold500.opacity(0.25) : Color.black.opacity(0.30), radius: isPressed ? 3 : 8, x: 0, y: isPressed ? 1 : 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
            .onChange(of: isPressed) { _, newValue in
                if newValue {
                    HapticFeedback.light()
                }
            }
    }
}

// MARK: - Extensions for View & ButtonStyle
extension View {
    func neubrutalistCard(
        cornerRadius: CGFloat = 20,
        fillColor: Color = .themeCard,
        strokeWidth: CGFloat = 1.0,
        shadowOffset: CGFloat = 6.0
    ) -> some View {
        self.modifier(NeubrutalistCardModifier(
            cornerRadius: cornerRadius,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
            shadowOffset: shadowOffset
        ))
    }
}

extension ButtonStyle where Self == NeubrutalistButtonStyle {
    static func neubrutalist(accentColor: Color = .gold500, cornerRadius: CGFloat = 16) -> NeubrutalistButtonStyle {
        NeubrutalistButtonStyle(fillColor: accentColor, textColor: .white, cornerRadius: cornerRadius)
    }
    
    static func neubrutalistSecondary(fillColor: Color = .obsidian700, textColor: Color = .gold500, cornerRadius: CGFloat = 14) -> NeubrutalistButtonStyle {
        NeubrutalistButtonStyle(fillColor: fillColor, textColor: textColor, cornerRadius: cornerRadius)
    }
    
    static func neubrutalistToggle(isActive: Bool, activeColor: Color = .gold500, cornerRadius: CGFloat = 14) -> NeubrutalistButtonStyle {
        if isActive {
            return NeubrutalistButtonStyle(fillColor: activeColor, textColor: Color.obsidian900, cornerRadius: cornerRadius, isToggled: true)
        } else {
            return NeubrutalistButtonStyle(fillColor: .obsidian700, textColor: Color.white.opacity(0.8), cornerRadius: cornerRadius, isToggled: false)
        }
    }
}

extension ButtonStyle where Self == CreativeCreamButtonStyle {
    static func creativeCream(accentColor: Color = .obsidian700, textColor: Color = .gold500, cornerRadius: CGFloat = 16) -> CreativeCreamButtonStyle {
        CreativeCreamButtonStyle(fillColor: accentColor, textColor: textColor, cornerRadius: cornerRadius)
    }
}

extension ButtonStyle where Self == CreativePillButtonStyle {
    static func creativePill(accentColor: Color = .themeAccent, isGold: Bool = false) -> CreativePillButtonStyle {
        CreativePillButtonStyle(accentColor: accentColor, isGold: isGold)
    }
}
