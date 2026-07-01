import Foundation
import Domain

public enum AuthError: Error, Sendable {
    case providerFlowRequired
    case noProviderToken
    case presentationFailed
    case cancelled
}

/// `AuthService` backed by the TRACE API. The native Apple/Kakao flows run in the
/// login UI (T2.6), which obtains the provider token and calls `signIn(provider:token:)`.
/// On success the JWT is stored in the shared `TokenStore`, so the `HTTPTraceStore`
/// built from the same client immediately makes authenticated calls.
@MainActor
public final class HTTPAuthService: AuthService {
    private let client: TraceAPIClient
    private let apple: OAuthTokenProvider
    private let kakao: OAuthTokenProvider
    private let google: OAuthTokenProvider
    public private(set) var current: User?

    public init(client: TraceAPIClient,
                apple: OAuthTokenProvider = AppleTokenProvider(),
                kakao: OAuthTokenProvider = KakaoTokenProvider(),
                google: OAuthTokenProvider = GoogleTokenProvider()) {
        self.client = client
        self.apple = apple
        self.kakao = kakao
        self.google = google
    }

    /// Run the native Apple flow, then exchange the id_token for a session.
    public func signInApple() async throws -> User {
        let token = try await apple.token()
        return try await signIn(provider: .apple, token: token)
    }

    /// Run the native Kakao flow, then exchange the access token for a session.
    public func signInKakao() async throws -> User {
        let token = try await kakao.token()
        return try await signIn(provider: .kakao, token: token)
    }

    /// Run the native Google flow, then exchange the id_token for a session.
    public func signInGoogle() async throws -> User {
        let token = try await google.token()
        return try await signIn(provider: .google, token: token)
    }

    /// Exchange a verified provider token (Apple id_token / Kakao access token) for a session.
    @discardableResult
    public func signIn(provider: AuthProvider, token: String) async throws -> User {
        let resp: AuthResponseDTO = try await client.post(
            "auth/oauth",
            body: OAuthBody(provider: provider.rawValue, token: token,
                            nickname: current?.nickname),
            authed: false
        )
        await client.tokens.set(resp.accessToken)
        let user = resp.user.user
        current = user
        return user
    }

    public func continueAsGuest() -> User {
        // Optimistic local identity; the real anonymous session is fetched in the background.
        let guest = User(nickname: "게스트", authProvider: .guest)
        current = guest
        Task { [weak self] in try? await self?.bootstrapGuest() }
        return guest
    }

    /// Establish (or refresh) an anonymous session and store its JWT.
    @discardableResult
    public func bootstrapGuest() async throws -> User {
        let resp: AuthResponseDTO = try await client.post(
            "auth/guest",
            body: GuestBody(nickname: current?.nickname),
            authed: false
        )
        await client.tokens.set(resp.accessToken)
        let user = resp.user.user
        current = user
        return user
    }

    public func signOut() async throws {
        await client.tokens.set(nil)
        current = nil
    }
}
