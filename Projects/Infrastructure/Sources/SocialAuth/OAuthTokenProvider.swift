import Foundation

/// Runs a native provider sign-in and returns the token to exchange with the backend.
/// Kakao → OAuth access token; Google/Apple → id_token (JWT).
/// Mirrors Mercury's `OauthSignInable`; the concrete providers wrap each SDK.
public protocol OAuthTokenProvider {
    func token() async throws -> String
}
