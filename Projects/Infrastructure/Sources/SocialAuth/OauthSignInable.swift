import Foundation

import Domain

/// The token string a provider hands back after a successful native sign-in.
public typealias OauthSignInToken = String

/// A social provider the app can sign in with. Mirrors Mercury's `OauthProvider`.
public enum OauthProvider: String, CaseIterable, Sendable {
    case apple, kakao, google

    /// Domain identity used for the backend exchange (`/auth/oauth` provider field).
    public var authProvider: AuthProvider {
        switch self {
        case .apple:  return .apple
        case .kakao:  return .kakao
        case .google: return .google
        }
    }
}

/// Runs a native provider login and returns the token to exchange with the backend.
/// Kakao → OAuth access token; Google/Apple → id_token (JWT). Mirrors Mercury's `OauthSignInable`.
public protocol OauthSignInable {
    func signIn() async throws -> OauthSignInToken
}
