import Foundation
import SwiftUI
import Combine

// MARK: - App Feature Enum
enum AppFeature: String, CaseIterable {
    case canvasRealtime       = "canvas_realtime"
    case cloudSync            = "cloud_sync"
    case postureAnalysis      = "posture_analysis"
    case ghostOverlay         = "ghost_overlay"
    case dualVideoComparison  = "dual_video_comparison"
    case musicSpeedTrainer    = "music_speed_trainer"
    case danceMetronome       = "dance_metronome"
    case inAppFeedback        = "in_app_feedback"
}

// MARK: - Remote Config Payload
struct RemoteConfigPayload: Codable {
    let min_version: String?
    let current_version: String?
    let maintenance_mode: Bool?
    let maintenance_message: String?
    let features: [String: Bool]?
    let announcement: String?
    let app_store_url: String?
}

// MARK: - Remote Config & Emergency Precautions Manager
@MainActor
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()
    
    // Remote config endpoint on your Next.js backend
    private let configURL = URL(string: "https://encore-app.vercel.app/api/app-config")
    private let cacheKey = "encore_remote_config_cache"
    
    @Published var isMaintenanceMode: Bool = false
    @Published var maintenanceMessage: String = "Prebieha plánovaná údržba. Vaše lokálne tréningy fungujú bez obmedzení."
    @Published var announcement: String? = nil
    @Published var needsForceUpdate: Bool = false
    @Published var appStoreURL: URL? = nil
    @Published private var features: [String: Bool] = [:]
    
    private init() {
        loadCachedConfig()
    }
    
    // MARK: - Feature Flag Check (Kill-Switch)
    /// Checks if a feature is enabled. Defaults to true if remote config is unavailable.
    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        if let remoteValue = features[feature.rawValue] {
            return remoteValue
        }
        return true // Safe default
    }
    
    // MARK: - Fetch Config on App Launch or Scene Foreground
    func syncConfig() async {
        guard let url = configURL else { return }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 6.0
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            let decoded = try JSONDecoder().decode(RemoteConfigPayload.self, from: data)
            applyConfig(decoded)
            
            // Cache successful payload
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("RemoteConfig sync failed (using cache or defaults): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Apply Decoded Config
    private func applyConfig(_ payload: RemoteConfigPayload) {
        if let maintenance = payload.maintenance_mode {
            self.isMaintenanceMode = maintenance
        }
        if let message = payload.maintenance_message, !message.isEmpty {
            self.maintenanceMessage = message
        }
        self.announcement = payload.announcement
        if let features = payload.features {
            self.features = features
        }
        if let storeStr = payload.app_store_url, let storeURL = URL(string: storeStr) {
            self.appStoreURL = storeURL
        }
        
        // Version Check (Force Update)
        if let minVersion = payload.min_version {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            self.needsForceUpdate = isVersion(appVersion, olderThan: minVersion)
        }
    }
    
    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(RemoteConfigPayload.self, from: data) else {
            return
        }
        applyConfig(decoded)
    }
    
    private func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        v1.compare(v2, options: .numeric) == .orderedAscending
    }
}

// MARK: - Force Update Modal Overlay
struct ForceUpdateView: View {
    let appStoreURL: URL?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.amberGold.opacity(0.18))
                        .frame(width: 84, height: 84)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color.amberGold)
                }
                
                VStack(spacing: 10) {
                    Text("Dôležitá aktualizácia")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Pre bezproblémové používanie a stabilitu tvojich tréningov si prosím stiahni najnovšiu verziu Encore z App Store.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                if let url = appStoreURL {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16, weight: .bold))
                            Text("Aktualizovať cez App Store")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.amberGold)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 36)
                        .shadow(color: Color.amberGold.opacity(0.4), radius: 10, y: 4)
                    }
                }
            }
        }
    }
}

// MARK: - Maintenance Notice Modal Overlay
struct MaintenanceNoticeView: View {
    let message: String
    let onContinueOffline: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 84, height: 84)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(Color.amberGold)
                }
                
                VStack(spacing: 10) {
                    Text("Plánovaná údržba serverov")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                Button {
                    HapticFeedback.light()
                    onContinueOffline()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.horizontal.fill")
                        Text("Pokračovať v offline režime")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(white: 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .padding(.horizontal, 36)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
