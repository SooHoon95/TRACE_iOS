import Foundation

/// Hybrid place identity: either snapped to a real POI, or an anonymous / user-named
/// coordinate spot when no POI is nearby.
public enum PlaceRef: Equatable, Codable, Sendable {
    case poi(providerID: String, name: String)
    case coordinate(name: String?)
}

/// A real-world place that aggregates the moments left there (its exhibition).
///
/// Evolves the treasure-model `Spot`: same coordinate-anchored shape, plus hybrid
/// identity and denormalized counts so lists render without re-aggregating.
public struct Place: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var ref: PlaceRef
    public let coordinate: Coordinate
    /// Resolved display name (POI name, user-given name, or "이름 없는 자리").
    public var displayName: String
    /// = public exhibition size (denormalized).
    public var momentCount: Int
    public var contributorCount: Int
    public var coverPhotoRef: String?

    public init(id: UUID = UUID(),
                ref: PlaceRef,
                coordinate: Coordinate,
                displayName: String,
                momentCount: Int = 0,
                contributorCount: Int = 0,
                coverPhotoRef: String? = nil) {
        self.id = id
        self.ref = ref
        self.coordinate = coordinate
        self.displayName = displayName
        self.momentCount = momentCount
        self.contributorCount = contributorCount
        self.coverPhotoRef = coverPhotoRef
    }

    /// Name shown when a fresh coordinate spot has no name yet.
    public static let unnamed = "이름 없는 자리"
}
