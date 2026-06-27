import Foundation
import Domain

public enum AuthError: Error, Sendable {
    case providerFlowRequired
}

/// `AuthService` backed by the TRACE API. The native Apple/Kakao flows run in the
/// login UI (T2.6), which obtains the provider token and calls `signIn(provider:token:)`.
/// On success the JWT is stored in the shared `TokenStore`, so the `HTTPTraceStore`
/// built from the same client immediately makes authenticated calls.
@MainActor
public final class HTTPAuthService: AuthService {
    private let client: TraceAPIClient
    public private(set) var current: User?

    public init(client: TraceAPIClient) {
        self.client = client
    }

    public func signInApple() async throws -> User {
        throw AuthError.providerFlowRequired
    }

    public func signInKakao() async throws -> User {
        throw AuthError.providerFlowRequired
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
