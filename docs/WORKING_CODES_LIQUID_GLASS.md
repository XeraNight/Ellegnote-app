# 💎 Apple Liquid Glass Design System – Working Codes & Reusable Guide

Tento dokument slúži ako kompletná technická referencia a knižnica znovupoužiteľného kódu pre **Apple Liquid Glass (iOS 18 & visionOS)**.

---

## 🏛️ 1. Architektúra: „Think in Layers“ (Princíp vrstvenia)

Podľa oficiálnych smerníc Apple (WWDC & Apple HIG) sa pravý **Liquid Glass** nikdy neskladá z jednej plochej vrstvy. Tvorí ho 5 synchronizovaných fyzikálnych vrstiev:

```
┌────────────────────────────────────────────────────────┐
│  VRSTVA 5: 3D Beveled Specular Rim (Svetelná hrana)    │ ➔ 1.4pt gradient zachytávajúci svetlo
├────────────────────────────────────────────────────────┤
│  VRSTVA 4: Foreground Content (Ikona & Text)           │ ➔ Ostrá biela / kontrastná typografia
├────────────────────────────────────────────────────────┤
│  VRSTVA 3: Convex Glass Cushion Light (3D objem)       │ ➔ Jemný svetelný vankúš zhora-nadol
├────────────────────────────────────────────────────────┤
│  VRSTVA 2: Crystal Pass-Through Base                   │ ➔ .ultraThinMaterial (optický lom pozadia)
├────────────────────────────────────────────────────────┤
│  VRSTVA 1: Dual Ambient & Specular Drop Shadows        │ ➔ Priestorová hĺbka (čierny tieň + horný odlesk)
└────────────────────────────────────────────────────────┘
```

---

## 🧩 2. Znovupoužiteľné SwiftUI komponenty

### A. Kruhová Liquid Glass šošovka (Tlačidlo / Action Button)
Použitie: Samostatné kruhové akčné tlačidlá, nástroje v hlavičke (QR skener, menu, pero, nastavenia).

```swift
import SwiftUI

struct LiquidGlassLensButton<Content: View>: View {
    let size: CGFloat
    let action: () -> Void
    @ViewBuilder let label: () -> Content
    
    init(size: CGFloat = 40, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.size = size
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                // 1. Crystal Translucent Base
                Circle()
                    .fill(.ultraThinMaterial)
                
                // 2. Convex Volumetric Light Cushion
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 3. Foreground Icon/Content
                label()
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                // 4. 3D Beveled Specular Rim
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.90),
                                Color.white.opacity(0.40),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.60)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            // 5. Dual Shadows
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            .shadow(color: Color.white.opacity(0.12), radius: 3, x: 0, y: -1)
        }
        .buttonStyle(.plain)
    }
}
```

---

### B. Liquid Glass Kapsula / Dock (Floating Segmented Bar)
Použitie: Navigačné docky, prepínače režimov (Segmented Controls), plávajúce toolbary.

```swift
import SwiftUI

struct LiquidGlassDockPill<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(cornerRadius: CGFloat = 32, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                // 1. Pure Crystal UltraThinMaterial Pass-Through
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // 2. 3D Beveled Specular Outer Rim
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.35),
                                Color.clear,
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 8)
            .shadow(color: Color.white.opacity(0.15), radius: 4, x: 0, y: -1)
    }
}
```

---

### C. Univerzálny ViewModifier `.liquidGlass(...)`
Umožňuje aplikovať Liquid Glass efekt na **akýkoľvek SwiftUI tvar alebo prvok**:

```swift
import SwiftUI

struct LiquidGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    var specularStrength: Double = 1.0
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            // Base Material
            shape
                .fill(.ultraThinMaterial)
            
            // Volumetric Gradient
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            (tintColor ?? Color.white).opacity(0.35 * specularStrength),
                            Color.white.opacity(0.06),
                            (tintColor ?? Color.white).opacity(0.18 * specularStrength)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Content
            content
        }
        .clipShape(shape)
        .overlay(
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.90 * specularStrength),
                            Color.white.opacity(0.40 * specularStrength),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.60 * specularStrength)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.white.opacity(0.12 * specularStrength), radius: 3, x: 0, y: -1)
    }
}

extension View {
    func liquidGlass<S: Shape>(shape: S, specularStrength: Double = 1.0, tint: Color? = nil) -> some View {
        self.modifier(LiquidGlassModifier(shape: shape, specularStrength: specularStrength, tintColor: tint))
    }
}
```

---

## 🎨 3. Ako prispôsobovať Liquid Glass rôznym dizajnom

| Štýl / Scenár | Ako upraviť kód |
| :--- | :--- |
| **100% Pure Crystal (Apple Defaults)** | Ponechať čistý `.ultraThinMaterial` bez pridávania akéhokoľvek `Color.fill`. |
| **Haute Gold Edition** | Do specular hrany pridať jemný prechod: `Color.gold400.opacity(0.60) -> Color.white.opacity(0.30)`. |
| **Prismatic / Rainbow Dispersion** | Do vonkajšieho lemu vložiť `AngularGradient(colors: [.cyan, .blue, .white, .green, .yellow, .pink, .cyan])` v režime `.blendMode(.screen)`. |
| **Obsidian Dark Mode** | Pod `.ultraThinMaterial` pridať podkladovú vrstvu `Color.black.opacity(0.40)` pre hlbší nočný kontrast. |
| **Interaktívna fyzika prsta** | Pridať `DragGesture(minimumDistance: 0)` so `scaleEffect(x: 1.12, y: 0.94)` pri dotyku a plynulý `.spring(response: 0.32, dampingFraction: 0.74)` na návrat. |
