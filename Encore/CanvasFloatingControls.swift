import SwiftUI
import AVKit

// MARK: - Liquid Glass Circle Button
public struct LiquidGlassCircleButton: View {
    public let icon: String
    public var badge: String? = nil
    public var isActive: Bool = false
    public var activeColor: Color = LuxuryTheme.gold400
    public var size: CGFloat = 46
    public var iconSize: CGFloat = 17
    public var isSpinning: Bool = false
    public let action: () -> Void
    
    public init(
        icon: String,
        badge: String? = nil,
        isActive: Bool = false,
        activeColor: Color = LuxuryTheme.gold400,
        size: CGFloat = 46,
        iconSize: CGFloat = 17,
        isSpinning: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.badge = badge
        self.isActive = isActive
        self.activeColor = activeColor
        self.size = size
        self.iconSize = iconSize
        self.isSpinning = isSpinning
        self.action = action
    }
    
    public var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            action()
        } label: {
            ZStack {
                // Background Liquid Glass Layers
                Circle()
                    .fill(
                        isActive
                        ? activeColor.opacity(0.25)
                        : LuxuryTheme.obsidian800.opacity(0.68)
                    )
                
                Circle()
                    .fill(.ultraThinMaterial)
                
                // Specular Glass Bevel & Glow Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isActive
                            ? [activeColor, activeColor.opacity(0.35)]
                            : [Color.white.opacity(0.35), LuxuryTheme.gold400.opacity(0.15), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isActive ? 1.5 : 1
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundColor(isActive ? activeColor : .white)
                    .rotationEffect(.degrees(isSpinning ? (icon.contains("counterclockwise") ? -360 : 360) : 0))
                    .animation(
                        isSpinning
                        ? .linear(duration: 0.75).repeatForever(autoreverses: false)
                        : .default,
                        value: isSpinning
                    )
                
                // Optional Badge
                if let badge = badge {
                    VStack {
                        HStack {
                            Spacer()
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(activeColor)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
            .shadow(color: isActive ? activeColor.opacity(0.25) : Color.clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liquid Glass AirPlay Picker Button
public struct AirPlayPickerButton: View {
    @ObservedObject private var airPlayManager = StudioAirPlayManager.shared
    public var size: CGFloat = 46
    
    public init(size: CGFloat = 46) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Liquid glass background
            Circle()
                .fill(
                    airPlayManager.isExternalScreenConnected
                    ? LuxuryTheme.gold500.opacity(0.28)
                    : LuxuryTheme.obsidian800.opacity(0.68)
                )
            
            Circle()
                .fill(.ultraThinMaterial)
            
            Circle()
                .stroke(
                    LinearGradient(
                        colors: airPlayManager.isExternalScreenConnected
                        ? [LuxuryTheme.gold400, LuxuryTheme.gold500.opacity(0.4)]
                        : [Color.white.opacity(0.35), LuxuryTheme.gold400.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: airPlayManager.isExternalScreenConnected ? 1.5 : 1
                )
            
            // Native AirPlay Route Picker overlaid seamlessly
            AirPlayRoutePickerRepresentable(
                tintColor: airPlayManager.isExternalScreenConnected ? UIColor(LuxuryTheme.gold400) : .white,
                activeTintColor: UIColor(LuxuryTheme.gold400)
            )
            .frame(width: size - 14, height: size - 14)
            .allowsHitTesting(true)
            
            if airPlayManager.isExternalScreenConnected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .offset(x: 14, y: -14)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        .shadow(color: airPlayManager.isExternalScreenConnected ? LuxuryTheme.gold500.opacity(0.35) : Color.clear, radius: 10)
    }
}

// MARK: - Realtime Status Pill
public struct RealtimeStatusPill: View {
    public var isConnected: Bool
    public var isSyncing: Bool = false
    public var onManualReconnect: (() -> Void)? = nil
    
    public init(isConnected: Bool, isSyncing: Bool = false, onManualReconnect: (() -> Void)? = nil) {
        self.isConnected = isConnected
        self.isSyncing = isSyncing
        self.onManualReconnect = onManualReconnect
    }
    
    public var body: some View {
        Button {
            onManualReconnect?()
        } label: {
            HStack(spacing: 7) {
                // Pulsing Status Dot
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.30))
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                }
                
                Text(statusText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .tracking(0.3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    Capsule()
                        .fill(LuxuryTheme.obsidian800.opacity(0.72))
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), statusColor.opacity(0.2), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.30), radius: 6, x: 0, y: 3)
            .shadow(color: isConnected ? Color.green.opacity(0.2) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
    
    private var statusColor: Color {
        if isSyncing {
            return LuxuryTheme.gold400
        } else if isConnected {
            return Color.green
        } else {
            return Color.orange
        }
    }
    
    private var statusText: String {
        if isSyncing {
            return "Synchronizujem zmeny..."
        } else if isConnected {
            return "Real time"
        } else {
            return "Real time offline"
        }
    }
}

// MARK: - Canvas Actions Menu Sheet
public struct CanvasActionsMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let routineName: String
    public let onAddFigure: () -> Void
    public let onDuelVideos: () -> Void
    public let onOpenInventory: () -> Void
    
    public init(
        routineName: String,
        onAddFigure: @escaping () -> Void,
        onDuelVideos: @escaping () -> Void,
        onOpenInventory: @escaping () -> Void
    ) {
        self.routineName = routineName
        self.onAddFigure = onAddFigure
        self.onDuelVideos = onDuelVideos
        self.onOpenInventory = onOpenInventory
    }
    
    public var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 20)
                
                VStack(spacing: 18) {
                    // Drag handle
                    Capsule()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    
                    // Header
                    VStack(spacing: 4) {
                        Text("AKCIE ZOSTAVY")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(LuxuryTheme.gold400)
                            .tracking(1.4)
                        
                        Text(routineName)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // 1. Pridať figúru
                        actionRow(
                            title: "Pridať figúru",
                            subtitle: "Vybrať figúru z knižnice a vložiť na parket",
                            icon: "plus.circle.fill",
                            iconColor: LuxuryTheme.gold400
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onAddFigure()
                            }
                        }
                        
                        // 2. Duel videí
                        actionRow(
                            title: "Duel videí",
                            subtitle: "Synchronizované porovnanie pokusu a vzoru (Idol)",
                            icon: "rectangle.split.2x1.fill",
                            iconColor: LuxuryTheme.latinCrimson
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDuelVideos()
                            }
                        }
                        
                        // 3. Inventár videí a fotiek
                        actionRow(
                            title: "Inventár videí a fotiek",
                            subtitle: "Mediálny trezor so záznamami k tejto zostave",
                            icon: "photo.stack.fill",
                            iconColor: LuxuryTheme.syncEmerald
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onOpenInventory()
                            }
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .presentationDetents([.fraction(0.48), .medium])
        .presentationDragIndicator(.hidden)
    }
    
    private func actionRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LuxuryTheme.obsidian800.opacity(0.85))
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
