import SwiftUI
import Domain

/// Drives the 여행 정체성 카드 screen. Reads the SAME `store.mine(authorID:)` the profile already
/// uses (one data path, [[holistic-connected-changes]]), computes the card via the pure Domain
/// function, and resolves the dominant place's human name once — on the async load path — since
/// `store.place(id:)` is an async actor call a pure View can't make (C1).
@MainActor
final class TravelIdentityViewModel: ObservableObject {
    @Published private(set) var model: TravelIdentityModel?      // nil = loading
    @Published private(set) var dominantPlaceName: String?       // resolved during load()

    private let store: any TraceStore
    private let userID: UUID

    init(store: any TraceStore, userID: UUID) {
        self.store = store
        self.userID = userID
    }

    func load() async {
        let mine = (try? await store.mine(authorID: userID)) ?? []
        let computed = TravelIdentity.compute(mine)

        // Resolve the dominant place NAME (UI-only) before publishing the model, so the card
        // never flashes a missing name. Domain stays name-free (only `dominantRegion: UUID?`).
        if let region = computed.distribution.dominantRegion {
            dominantPlaceName = try? await store.place(id: region).displayName
        } else {
            dominantPlaceName = nil
        }
        model = computed
    }
}
