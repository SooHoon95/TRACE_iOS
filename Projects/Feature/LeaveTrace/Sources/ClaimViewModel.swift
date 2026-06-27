import SwiftUI
import Domain
import UIComponent

/// Drives the claim loop for one place: load its exhibition, leave a moment, refresh.
/// Depends only on Domain protocols; the concrete `InMemoryTraceStore` is injected.
@MainActor
public final class ClaimViewModel: ObservableObject {
    @Published public private(set) var exhibition: Exhibition?
    @Published public var isComposing = false
    /// Set briefly after a successful claim to drive the "합류" feedback.
    @Published public var justJoinedAt: Date?

    private let store: InMemoryTraceStore
    private let user: User
    private let placeCoordinate: Coordinate
    private let placeName: String
    private var placeID: UUID

    public init(store: InMemoryTraceStore, user: User, place: Place) {
        self.store = store
        self.user = user
        self.placeID = place.id
        self.placeCoordinate = place.coordinate
        self.placeName = place.displayName
    }

    public var placeDisplayName: String { exhibition?.place.displayName ?? placeName }
    public var contributorCount: Int { exhibition?.contributorCount ?? 0 }

    public func load() async {
        exhibition = try? await store.exhibition(placeID: placeID)
    }

    /// The core action: resolve the place (hybrid snap) and leave the moment, then refresh.
    public func claim(_ draft: CaptureComposer.Draft) async {
        guard let place = try? await store.resolveOrCreate(
            at: placeCoordinate,
            snapRadiusMeters: defaultSnapRadiusMeters,
            suggestedName: placeName
        ) else { return }
        placeID = place.id

        let moment = Moment(
            placeID: place.id,
            authorID: user.id,
            photoRef: "user-\(UUID().uuidString).jpg",
            caption: draft.caption,
            companion: draft.companion,
            vibe: draft.vibe,
            coordinate: placeCoordinate,
            visibility: draft.visibility
        )
        try? await store.leave(moment)
        await load()
        isComposing = false
        justJoinedAt = Date()
    }
}
