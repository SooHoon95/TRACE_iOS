import Foundation

/// A read projection over a place's public moments (newest-first).
/// Built by `MomentRepository.exhibition(placeID:)`; never stored.
public struct Exhibition: Equatable, Sendable {
    public let place: Place
    /// Newest-first, public + not-suppressed only.
    public let moments: [Moment]

    public init(place: Place, moments: [Moment]) {
        self.place = place
        self.moments = moments
    }

    /// Distinct contributors — the "여기 N명이 남겼어" number.
    public var contributorCount: Int { Set(moments.map(\.authorID)).count }
    public var cover: String? { moments.first?.photoRef }
    public var isEmpty: Bool { moments.isEmpty }
}
