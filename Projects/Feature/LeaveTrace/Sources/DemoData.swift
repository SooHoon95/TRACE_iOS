import Foundation
import Domain

/// Phase-1 demo seed so the claim loop is alive without cloud or a device.
/// Replaced by real Supabase data in Phase 2.
public enum DemoData {
    public static let place = Place(
        ref: .poi(providerID: "mock", name: "성산일출봉"),
        coordinate: Coordinate(latitude: 33.4580, longitude: 126.9426),
        displayName: "성산일출봉"
    )

    public static func seed() -> TraceSeed {
        let pid = place.id
        let base = Date(timeIntervalSince1970: 1_718_000_000)
        func moment(_ caption: String?, _ companion: Companion?, _ vibe: VibeTag?, _ offset: TimeInterval) -> Moment {
            Moment(
                placeID: pid,
                authorID: UUID(),                 // each seed moment = a different "other" person
                photoRef: "seed-\(Int(offset))",
                caption: caption,
                companion: companion,
                vibe: vibe,
                coordinate: place.coordinate,
                createdAt: base.addingTimeInterval(offset),
                visibility: .publicExhibit,
                syncState: .synced
            )
        }
        let moments = [
            moment("해 뜨기 전 그 보랏빛 하늘", .partner, .scenic, 400),
            moment("정상까지 숨 헐떡였지만", .friends, .adventure, 300),
            moment(nil, nil, .calm, 200),
            moment("바람 미쳤다 진짜", .solo, .lively, 100)
        ]
        return TraceSeed(places: [place], moments: moments)
    }
}
