import Foundation

/// Builds the API client from `TRACE_API_BASE_URL` (Info.plist ← Sensitive.xcconfig).
/// Returns nil when unconfigured, so the app falls back to the in-memory mock store.
public enum BackendProvider {
    public static func makeClient(tokens: TokenStore = TokenStore()) -> TraceAPIClient? {
        // Requires a real scheme AND host — an unconfigured xcconfig leaves "://" or "https://",
        // which fails this guard and falls back to the mock.
        guard let raw = baseURLFromBundle(),
              let url = URL(string: raw),
              let scheme = url.scheme, !scheme.isEmpty,
              let host = url.host, !host.isEmpty else { return nil }
        return TraceAPIClient(baseURL: url, tokens: tokens)
    }

    public static func baseURLFromBundle() -> String? {
        (Bundle.main.infoDictionary?["TRACE_API_BASE_URL"] as? String)?
            .trimmingCharacters(in: .whitespaces)
    }
}
