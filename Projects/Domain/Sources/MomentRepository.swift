import Foundation

/// Reads/writes for moments (claiming, exhibition, 도감, feed) plus the safety minimum.
public protocol MomentRepository: Sendable {
    /// Leave a moment. Offline-first: insert locally now, upload in the background.
    func leave(_ moment: Moment) async throws

    /// The newest-first public exhibition for a place (suppressed moments excluded).
    func exhibition(placeID: UUID) async throws -> Exhibition

    /// A user's own moments (public + private), newest-first — the 도감.
    func mine(authorID: UUID) async throws -> [Moment]

    /// Recent public moments for the home activity feed; sorted by distance when `c` is given.
    func feed(near c: Coordinate?) async throws -> [Moment]

    /// Report a moment for review. Mock: soft-removes it from public surfaces immediately.
    func report(momentID: UUID, by userID: UUID) async throws

    /// Hide a moment from view. Mock: soft-removes it from public surfaces immediately.
    func hide(momentID: UUID, by userID: UUID) async throws
}
