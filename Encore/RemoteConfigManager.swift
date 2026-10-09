import Foundation
import SwiftUI
import Combine
import OSLog
import Supabase

// MARK: - Remote Config Payload
/// One row of `public.app_config` (migration 20261009_app_config.sql), readable by everyone.
struct RemoteConfigPayload: Codable {
    let min_version: String?
    let maintenance_mode: Bool?
    let maintenance_message: String?
    let app_store_url: String?
}

// MARK: - Remote Config & Emergency Precautions Manager
/// Force update and maintenance notice, set in Supabase → Table Editor → `app_config`.
@MainActor
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    private let cacheKey = "encore_remote_config_cache"

    @Published var isMaintenanceMode: Bool = false
    @Published var maintenanceMessage: String = "Prebieha plánovaná údržba. Tvoje tréningy v telefóne fungujú bez obmedzení."
    @Published var needsForceUpdate: Bool = false
    @Published var appStoreURL: URL? = nil
    /// Launch and every return to the foreground both ask; once every 15 minutes is enough.
    private var lastSyncAttempt: Date?
    private let minimumSyncInterval: TimeInterval = 15 * 60

    private init() {
        loadCachedConfig()
    }

    // MARK: - Fetch Config on App Launch or Scene Foreground
    func syncConfig() async {
        if let lastSyncAttempt, Date().timeIntervalSince(lastSyncAttempt) < minimumSyncInterval { return }
        lastSyncAttempt = Date()

        do {
            let data = try await SupabaseConfig.client
                .from("app_config")
                .select("min_version, maintenance_mode, maintenance_message, app_store_url")
                .single()
                .execute()
                .data
            let decoded = try JSONDecoder().decode(RemoteConfigPayload.self, from: data)
            applyConfig(decoded)

            // Cache successful payload
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            Logger.general.notice("RemoteConfig sync failed, using cache or defaults: \(error.localizedDescription, privacy: .public)")
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
