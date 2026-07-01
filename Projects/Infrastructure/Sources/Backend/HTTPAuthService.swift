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
    private let providerFactory: SignInProviderFactory
    public private(set) var current: User?

    public init(client: TraceAPIClient,
                providerFactory: SignInProviderFactory = SignInProviderFactory()) {
        self.client = client
        self.providerFactory = providerFactory
    }

    public func signInApple() async throws -> User { try await socialSignIn(.apple) }
    public func signInKakao() async throws -> User { try await socialSignIn(.kakao) }
    public func signInGoogle() async throws -> User { try await socialSignIn(.google) }

    /// Run the native provider flow (via the factory), then exchange its token for a session.
    private func socialSignIn(_ provider: OauthProvider) async throws -> User {
        let token = try await providerFactory.createProvider(provider: provider).signIn()
        return try await signIn(provider: provider.authProvider, token: token)
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
