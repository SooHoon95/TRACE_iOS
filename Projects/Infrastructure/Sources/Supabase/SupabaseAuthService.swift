import Foundation
import Domain
import Supabase

/// Supabase-backed auth. Apple/Kakao token exchange is wired by the login UI (T2.6),
/// which obtains the provider ID token and calls `signIn(idToken:provider:)`.
/// (`Domain.User` is qualified throughout to avoid clashing with Supabase's own `User`.)
@MainActor
public final class SupabaseAuthService: AuthService {
    private let client: SupabaseClient
    public private(set) var current: Domain.User?

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func signInApple() async throws -> Domain.User {
        // The ASAuthorization flow (UI) provides the Apple ID token; exchange happens in T2.6.
        throw AuthError.providerFlowRequired
    }

    public func signInKakao() async throws -> Domain.User {
        throw AuthError.providerFlowRequired   // Kakao token exchange — fast-follow (T2.6)
    }

    /// Exchange a provider ID token (Apple/Kakao) for a Supabase session. Called by the login UI.
    public func signIn(idToken: String,
                       provider: OpenIDConnectCredentials.Provider) async throws -> Domain.User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: provider, idToken: idToken)
        )
        let user = Domain.User(id: session.user.id, nickname: "여행자",
                               authProvider: provider == .apple ? .apple : .kakao)
        current = user
        return user
    }

    public func continueAsGuest() -> Domain.User {
        let guest = Domain.User(nickname: "게스트", authProvider: .guest)
        current = guest
        Task { try? await client.auth.signInAnonymously() }   // requires anonymous sign-ins enabled
        return guest
    }

    public func signOut() async throws {
        try await client.auth.signOut()
        current = nil
    }
}

public enum AuthError: Error, Sendable {
    case providerFlowRequired
}
