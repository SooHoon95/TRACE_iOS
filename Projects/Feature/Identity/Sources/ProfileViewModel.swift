import SwiftUI
import Domain

/// Real profile stats from the signed-in user's own moments (no more hardcoded numbers).
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var momentCount = 0
    @Published private(set) var placeCount = 0
    @Published private(set) var joinedCount = 0

    private let store: any TraceStore
    private let userID: UUID

    init(store: any TraceStore, userID: UUID) {
        self.store = store
        self.userID = userID
    }

    func load() async {
        let mine = (try? await store.mine(authorID: userID)) ?? []
        momentCount = mine.count
        placeCount = Set(mine.map(\.placeID)).count
        // 합류 = 공개 전시에 남긴 서로 다른 자리 수.
        joinedCount = Set(mine.filter { $0.visibility == .publicExhibit }.map(\.placeID)).count
    }
}
