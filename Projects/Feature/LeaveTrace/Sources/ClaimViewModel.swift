import SwiftUI
import Domain
import UIComponent

/// Drives the claim loop for one place: load its exhibition, leave a moment, refresh.
/// Depends only on the `TraceStore` protocol — the concrete store (mock now, Supabase later) is injected.
@MainActor
public final class ClaimViewModel: ObservableObject {
    @Published public private(set) var exhibition: Exhibition?
    @Published public var isComposing = false
    /// Set briefly after a successful claim to drive the "합류" feedback.
    @Published public var justJoinedAt: Date?
    @Published public private(set) var isLoading = false
    /// Non-nil when a load or claim fails — drives the error view / banner.
    @Published public var errorMessage: String?

    private let store: any TraceStore
    private let user: User
    private let placeCoordinate: Coordinate
    private let placeName: String
    private var placeID: UUID

    public init(store: any TraceStore, user: User, place: Place) {
        self.store = store
        self.user = user
        self.placeID = place.id
        self.placeCoordinate = place.coordinate
        self.placeName = place.displayName
    }

    public var placeDisplayName: String { exhibition?.place.displayName ?? placeName }
    public var contributorCount: Int { exhibition?.contributorCount ?? 0 }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            exhibition = try await store.exhibition(placeID: placeID)
            errorMessage = nil
        } catch {
            errorMessage = "전시를 불러오지 못했어요"
        }
    }

    /// The core action: resolve the place (hybrid snap) and leave the moment, then refresh.
    /// On failure the moment is NOT counted as joined — `errorMessage` is set instead.
    public func claim(_ draft: CaptureComposer.Draft) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let place = try await store.resolveOrCreate(
                at: placeCoordinate,
                snapRadiusMeters: defaultSnapRadiusMeters,
                suggestedName: placeName
            )
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
            try await store.leave(moment)
            exhibition = try await store.exhibition(placeID: placeID)
            isComposing = false
            justJoinedAt = Date()        // only after a confirmed write
            errorMessage = nil
        } catch {
            errorMessage = "남기지 못했어요. 다시 시도해줘"
        }
    }

    /// Report a moment (safety). Removes it from public surfaces and refreshes.
    public func report(_ momentID: UUID) async {
        do {
            try await store.report(momentID: momentID, by: user.id)
            await load()
        } catch {
            errorMessage = "신고하지 못했어요"
        }
    }

    /// Hide a moment from view. Removes it from public surfaces and refreshes.
    public func hide(_ momentID: UUID) async {
        do {
            try await store.hide(momentID: momentID, by: user.id)
            await load()
        } catch {
            errorMessage = "숨기지 못했어요"
        }
    }
}
