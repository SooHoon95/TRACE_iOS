import SwiftUI
import Domain

/// Loads the signed-in user's own moments (public + 나만) for 도감, newest-first.
@MainActor
public final class CollectionViewModel: ObservableObject {
    @Published public private(set) var moments: [Moment] = []
    @Published public private(set) var placeCount: Int = 0

    private let store: InMemoryTraceStore
    private let userID: UUID

    public init(store: InMemoryTraceStore, userID: UUID) {
        self.store = store
        self.userID = userID
    }

    public func load() async {
        moments = (try? await store.mine(authorID: userID)) ?? []
        placeCount = Set(moments.map(\.placeID)).count
    }
}

/// Phase-1 demo: the current user's own moments across two 제주 places (one is 나만).
public enum CollectionDemo {
    public static let user = User(nickname: "여행자", authProvider: .apple)

    public static func store() -> InMemoryTraceStore {
        let seongsan = Place(ref: .poi(providerID: "mock", name: "성산일출봉"),
                             coordinate: Coordinate(latitude: 33.4580, longitude: 126.9426),
                             displayName: "성산일출봉")
        let woljeong = Place(ref: .poi(providerID: "mock", name: "월정리 해변"),
                             coordinate: Coordinate(latitude: 33.5563, longitude: 126.7955),
                             displayName: "월정리 해변")
        let base = Date(timeIntervalSince1970: 1_718_000_000)

        func m(_ place: Place, _ caption: String?, _ companion: Companion?, _ vibe: VibeTag?,
               _ visibility: MomentVisibility, _ offset: TimeInterval) -> Moment {
            Moment(placeID: place.id, authorID: user.id, photoRef: "mine-\(Int(offset))",
                   caption: caption, companion: companion, vibe: vibe,
                   coordinate: place.coordinate, createdAt: base.addingTimeInterval(offset),
                   visibility: visibility, syncState: .synced)
        }

        let moments = [
            m(seongsan, "해 뜨기 전 그 보랏빛 하늘", .partner, .scenic, .publicExhibit, 600),
            m(seongsan, "정상까지 기어이 올라왔다", .friends, .adventure, .publicExhibit, 500),
            m(woljeong, "이 바다 색 실화냐", .solo, .scenic, .publicExhibit, 400),
            m(woljeong, "혼자만 보고 싶은 노을", nil, .calm, .privateOnly, 300),
            m(woljeong, nil, .family, .lively, .publicExhibit, 200)
        ]
        return InMemoryTraceStore(seed: TraceSeed(places: [seongsan, woljeong], moments: moments))
    }
}
