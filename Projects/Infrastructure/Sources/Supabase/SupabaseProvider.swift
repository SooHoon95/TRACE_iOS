import Foundation
import Supabase

/// Builds the shared `SupabaseClient` from local config (SUPABASE_URL / SUPABASE_ANON_KEY,
/// injected via XCConfigs/Sensitive.xcconfig → Info.plist). Returns nil when unconfigured,
/// so the app falls back to the in-memory mock store.
public enum SupabaseProvider {
    public static func makeClient(url: String?, anonKey: String?) -> SupabaseClient? {
        guard let url, let anonKey,
              !url.isEmpty, !anonKey.isEmpty,
              let supabaseURL = URL(string: url) else { return nil }
        return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }

    /// Reads the two config values from the main bundle's Info.plist.
    public static func configFromBundle() -> (url: String?, anonKey: String?) {
        let info = Bundle.main.infoDictionary
        return (info?["SUPABASE_URL"] as? String, info?["SUPABASE_ANON_KEY"] as? String)
    }
}
