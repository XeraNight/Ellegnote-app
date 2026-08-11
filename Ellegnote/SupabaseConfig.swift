// Supabase credentials — loaded from Secrets.xcconfig (never hardcoded)
// Secrets.xcconfig is in .gitignore and must be created manually on each machine.
// See Secrets.xcconfig.template for the required keys.
import Foundation

struct SupabaseConfig {
    static let url: URL? = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }()

    static let anonKey: String? = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else { return nil }
        return key
    }()
}
