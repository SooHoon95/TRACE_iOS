import SwiftUI
import Domain

/// Loads the signed-in user's own moments (public + 나만) for 도감, newest-first.
@MainActor
public final class CollectionViewModel: ObservableObject {
    @Published public private(set) var moments: [Moment] = []
    @Published public private(set) var placeCount: Int = 0

    private let store: any TraceStore
    private let userID: UUID

    public init(store: any TraceStore, userID: UUID) {
        self.store = store
        self.userID = userID
    }

    public func load() async {
        moments = (try? await store.mine(authorID: userID)) ?? []
        placeCount = Set(moments.map(\.placeID)).count
    }
}
