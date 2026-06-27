import Foundation

/// How a user signed in. Guests can browse but not claim (per the v2.1 flow).
public enum AuthProvider: String, Codable, Sendable {
    case apple, kakao, guest
}

/// The person leaving moments. Identity is the unit accounts/backup hang off of.
public struct User: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var nickname: String
    public let authProvider: AuthProvider
    public let createdAt: Date

    public init(id: UUID = UUID(),
                nickname: String,
                authProvider: AuthProvider,
                createdAt: Date = Date()) {
        self.id = id
        self.nickname = nickname
        self.authProvider = authProvider
        self.createdAt = createdAt
    }

    /// Guests get read-only browse; claiming / 도감 / backup require a real account.
    public var isGuest: Bool { authProvider == .guest }
}
