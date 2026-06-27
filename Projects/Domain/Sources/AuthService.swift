import Foundation

/// Authentication + the current session. Main-actor isolated so the UI can read
/// `current` synchronously for routing. Concrete impls: `InMemoryAuthService`
/// (Phase 1) → Supabase Auth (Phase 2, Apple + Kakao token exchange).
@MainActor
public protocol AuthService: AnyObject {
    var current: User? { get }
    func signInApple() async throws -> User
    func signInKakao() async throws -> User
    func continueAsGuest() -> User
    func signOut() async throws
}
