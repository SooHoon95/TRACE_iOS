import Foundation

/// Whether a moment joins the place's public exhibition or stays visible only to its author.
/// Named `MomentVisibility` (not `Visibility`) to avoid colliding with `SwiftUI.Visibility`
/// in any screen that imports both SwiftUI and Domain.
public enum MomentVisibility: String, Codable, Sendable {
    case publicExhibit   // joins the place's "모두의 순간" (default)
    case privateOnly     // "나만" — never enters any public surface
}

/// Local-only sync lifecycle for offline-first claiming. Not persisted server-side.
public enum SyncState: String, Codable, Sendable {
    case pendingUpload, uploading, synced, failed
}

/// A single photo-moment left at a place.
///
/// Evolves the treasure-model `Trace`: the photo is the only required field;
/// caption / companion / vibe / visibility are all optional (low-friction claim).
/// `collectCount` (treasure mechanic) is dropped.
public struct Moment: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let placeID: UUID
    public let authorID: UUID
    /// Storage key for the photo (required) — resolved to a URL via `PhotoStore`.
    public let photoRef: String
    public var caption: String?
    public var companion: Companion?
    public var vibe: VibeTag?
    /// GPS at capture time (field-authenticity).
    public let coordinate: Coordinate
    public let createdAt: Date
    public var visibility: MomentVisibility
    public var syncState: SyncState

    public init(id: UUID = UUID(),
                placeID: UUID,
                authorID: UUID,
                photoRef: String,
                caption: String? = nil,
                companion: Companion? = nil,
                vibe: VibeTag? = nil,
                coordinate: Coordinate,
                createdAt: Date = Date(),
                visibility: MomentVisibility = .publicExhibit,
                syncState: SyncState = .pendingUpload) {
        self.id = id
        self.placeID = placeID
        self.authorID = authorID
        self.photoRef = photoRef
        self.caption = caption
        self.companion = companion
        self.vibe = vibe
        self.coordinate = coordinate
        self.createdAt = createdAt
        self.visibility = visibility
        self.syncState = syncState
    }

    public var isPublic: Bool { visibility == .publicExhibit }
}
