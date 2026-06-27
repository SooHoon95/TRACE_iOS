import Foundation

/// Shared Phase-1 demo data (single source). One seeded store is injected at the app root and
/// shared across tabs, so a moment left via ＋ shows up in 도감/전시 when you navigate there.
/// Replaced by real Supabase data in Phase 2.
public enum Demo {
    public static let seongsan = Place(
        ref: .poi(providerID: "mock", name: "성산일출봉"),
        coordinate: Coordinate(latitude: 33.4580, longitude: 126.9426),
        displayName: "성산일출봉"
    )
    public static let woljeong = Place(
        ref: .poi(providerID: "mock", name: "월정리 해변"),
        coordinate: Coordinate(latitude: 33.5563, longitude: 126.7955),
        displayName: "월정리 해변"
    )

    public static func seed() -> TraceSeed {
        let base = Date(timeIntervalSince1970: 1_718_000_000)
        let me = User.demo.id
        let (a, b, c) = (UUID(), UUID(), UUID())

        func m(_ place: Place, _ author: UUID, _ caption: String?, _ companion: Companion?,
               _ vibe: VibeTag?, _ visibility: MomentVisibility, _ offset: TimeInterval) -> Moment {
            Moment(placeID: place.id, authorID: author, photoRef: "seed-\(Int(offset))",
                   caption: caption, companion: companion, vibe: vibe,
                   coordinate: place.coordinate, createdAt: base.addingTimeInterval(offset),
                   visibility: visibility, syncState: .synced)
        }

        let moments = [
            // mine — shows in 도감
            m(seongsan, me, "해 뜨기 전 그 보랏빛 하늘", .partner, .scenic, .publicExhibit, 600),
            m(woljeong, me, "이 바다 색 실화냐", .solo, .scenic, .publicExhibit, 500),
            m(woljeong, me, "혼자만 보고 싶은 노을", nil, .calm, .privateOnly, 450),
            // others — shows in 전시 / 홈
            m(seongsan, a, "정상까지 기어이 올라왔다", .friends, .adventure, .publicExhibit, 400),
            m(seongsan, b, nil, .family, .lively, .publicExhibit, 300),
            m(seongsan, c, "바람 미쳤다 진짜", .solo, .lively, .publicExhibit, 200),
            m(woljeong, a, "여기 카페 노을맛집", .friends, .foodie, .publicExhibit, 250)
        ]
        return TraceSeed(places: [seongsan, woljeong], moments: moments)
    }

    /// A fresh seeded in-memory store. The app creates ONE and shares it; SampleApps each get their own.
    public static func store() -> InMemoryTraceStore { InMemoryTraceStore(seed: seed()) }
}

public extension User {
    /// Signed-in demo user (stable id). Phase 2 replaces with the real AuthService session.
    static let demo = User(nickname: "지민", authProvider: .apple)
}
