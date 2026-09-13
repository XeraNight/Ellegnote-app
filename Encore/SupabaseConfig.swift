import Foundation
import Supabase

// MARK: - Supabase Configuration
// Reads from Info.plist with robust fallback constants so the app never crashes or halts in Xcode.
nonisolated struct SupabaseConfig: Sendable {

    private static let fallbackURLString = "https://iukblwlttvrcdclmlyxu.supabase.co"
    private static let fallbackAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1a2Jsd2x0dHZyY2RjbG1seXh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyMTc5MjYsImV4cCI6MjA5OTc5MzkyNn0.Xq8BKQliVLT7rS2xHn8n_I84tD_rwPSz15AdHp1hcNo"

    // MARK: - URL & Key
    nonisolated static let url: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !raw.isEmpty,
           !raw.contains("$("),
           let parsed = URL(string: raw) {
            return parsed
        }
        return URL(string: fallbackURLString)!
    }()

    nonisolated static let anonKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !key.isEmpty,
           !key.contains("$(") {
            return key
        }
        return fallbackAnonKey
    }()

    // MARK: - Shared Singleton Client
    // Single SupabaseClient instance shared across the entire app.
    nonisolated static let client: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}
