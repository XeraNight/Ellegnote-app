import SwiftUI
import UIKit

// MARK: - Neubrutalist Card Modifier
struct NeubrutalistCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var fillColor: Color
    var strokeWidth: CGFloat
    var shadowOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(fillColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.themeDark, lineWidth: strokeWidth)
            )
            .shadow(color: Color.themeDark.opacity(0.85), radius: 0, x: shadowOffset, y: shadowOffset)
    }
}

// MARK: - Neubrutalist Button Style
struct NeubrutalistButtonStyle: ButtonStyle {
    var fillColor: Color
    var textColor: Color = .white
    var cornerRadius: CGFloat = 12
    var strokeWidth: CGFloat = 2
    var shadowOffset: CGFloat = 3
    var isToggled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed || isToggled
        let currentShadowOffset = isToggled ? 0 : shadowOffset
        let currentTranslate = isToggled ? shadowOffset : 0
        
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(fillColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.themeDark, lineWidth: strokeWidth)
            )
            .shadow(color: isPressed ? Color.clear : Color.themeDark.opacity(0.85), radius: 0, x: currentShadowOffset, y: currentShadowOffset)
            .offset(x: isPressed ? shadowOffset : currentTranslate, y: isPressed ? shadowOffset : currentTranslate)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Creative Cream Tactile Button Style (Warm Cream & Terracotta Aesthetic)
struct CreativeCreamButtonStyle: ButtonStyle {
    var fillColor: Color = .themeAccent
    var textColor: Color = .white
    var cornerRadius: CGFloat = 20
    var hasHaptic: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .serif))
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(
                ZStack {
                    // Base fill gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [fillColor, fillColor.opacity(0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle inner light border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.themeDark.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .foregroundColor(textColor)
            .shadow(color: Color.themeDark.opacity(isPressed ? 0.2 : 0.9), radius: 0, x: isPressed ? 1 : 3, y: isPressed ? 1 : 4)
            .offset(x: isPressed ? 2 : 0, y: isPressed ? 3 : 0)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
            .onChange(of: isPressed) { _, newValue in
                if newValue && hasHaptic {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
    }
}

// MARK: - Creative Pill Action Button Style (Floating Cream & Gold Pill)
struct CreativePillButtonStyle: ButtonStyle {
    var accentColor: Color = .themeAccent
    var isGold: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let bgGradient = isGold
            ? LinearGradient(colors: [Color.amberGold, Color.amberGold.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [accentColor, accentColor.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
        
        configuration.label
            .font(.system(size: 14, weight: .black, design: .serif))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(bgGradient)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.themeDark, lineWidth: 2)
            )
            .shadow(color: Color.themeDark.opacity(isPressed ? 0.15 : 0.85), radius: 0, x: isPressed ? 1 : 3, y: isPressed ? 1 : 4)
            .offset(x: isPressed ? 2 : 0, y: isPressed ? 3 : 0)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
            .onChange(of: isPressed) { _, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// MARK: - Extensions for View & ButtonStyle
extension View {
    func neubrutalistCard(
        cornerRadius: CGFloat = 16,
        fillColor: Color = .themeCard,
        strokeWidth: CGFloat = 2,
        shadowOffset: CGFloat = 3
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
    static func neubrutalist(accentColor: Color, cornerRadius: CGFloat = 12) -> NeubrutalistButtonStyle {
        NeubrutalistButtonStyle(fillColor: accentColor, textColor: .white, cornerRadius: cornerRadius)
    }
    
    static func neubrutalistSecondary(fillColor: Color = .themeCard, textColor: Color = .themeDark, cornerRadius: CGFloat = 12) -> NeubrutalistButtonStyle {
        NeubrutalistButtonStyle(fillColor: fillColor, textColor: textColor, cornerRadius: cornerRadius)
    }
    
    static func neubrutalistToggle(isActive: Bool, activeColor: Color, cornerRadius: CGFloat = 12) -> NeubrutalistButtonStyle {
        if isActive {
            return NeubrutalistButtonStyle(fillColor: activeColor, textColor: .white, cornerRadius: cornerRadius, isToggled: true)
        } else {
            return NeubrutalistButtonStyle(fillColor: .themeCard, textColor: .themeDark, cornerRadius: cornerRadius, isToggled: false)
        }
    }
}

extension ButtonStyle where Self == CreativeCreamButtonStyle {
    static func creativeCream(accentColor: Color = .themeAccent, textColor: Color = .white, cornerRadius: CGFloat = 18) -> CreativeCreamButtonStyle {
        CreativeCreamButtonStyle(fillColor: accentColor, textColor: textColor, cornerRadius: cornerRadius)
    }
}

extension ButtonStyle where Self == CreativePillButtonStyle {
    static func creativePill(accentColor: Color = .themeAccent, isGold: Bool = false) -> CreativePillButtonStyle {
        CreativePillButtonStyle(accentColor: accentColor, isGold: isGold)
    }
}
