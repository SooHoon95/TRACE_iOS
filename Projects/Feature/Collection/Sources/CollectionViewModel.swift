import SwiftUI
import Domain

/// Loads the signed-in user's own moments (public + 나만) for 도감, newest-first.
@MainActor
public final class CollectionViewModel: ObservableObject {
    @Published public private(set) var moments: [Moment] = []
    /// Resolved photo URLs per moment (via `PhotoStore.url`), for the grid images.
    @Published public private(set) var photoURLs: [UUID: URL] = [:]
    @Published public private(set) var placeCount: Int = 0
    @Published public private(set) var isLoading = false
    @Published public var errorMessage: String?
    /// True only after a successful load with no moments (vs. not-yet-loaded).
    @Published public private(set) var didLoad = false

    private let store: any TraceStore
    private let photoStore: any PhotoStore
    private let userID: UUID

    public init(store: any TraceStore,
                userID: UUID,
                photoStore: any PhotoStore = LocalPhotoStore()) {
        self.store = store
        self.userID = userID
        self.photoStore = photoStore
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let mine = try await store.mine(authorID: userID)
            moments = mine
            placeCount = Set(mine.map(\.placeID)).count
            errorMessage = nil
            didLoad = true
            var urls = photoURLs
            for moment in mine where urls[moment.id] == nil {
                urls[moment.id] = await photoStore.url(for: moment.photoRef)
            }
            photoURLs = urls
        } catch {
            errorMessage = "도감을 불러오지 못했어요"
        }
    }
}
