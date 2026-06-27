import XCTest
@testable import Domain

/// E2E core-loop proof at the logic level (T1.6): a moment left at a place reflects in
/// 전시(exhibition), 도감(mine), and 홈(feed) from the SAME shared store. Backs the Phase-1 AC
/// ("＋로 남긴 순간이 전시·도감·홈에 반영"), which the UI surfaces via the injected shared store.
final class CoreLoopTests: XCTestCase {

    func testClaimReflectsAcrossSurfaces() async throws {
        let store = InMemoryTraceStore(seed: Demo.seed())
        let me = User.demo.id
        let here = Demo.seongsan.coordinate

        let beforeMine = try await store.mine(authorID: me).count
        let beforeExhibition = try await store.exhibition(placeID: Demo.seongsan.id).moments.count

        // claim: resolve the place (snaps to the seeded 성산일출봉) + leave a public moment
        let place = try await store.resolveOrCreate(at: here,
                                                    snapRadiusMeters: defaultSnapRadiusMeters,
                                                    suggestedName: "성산일출봉")
        XCTAssertEqual(place.id, Demo.seongsan.id, "should snap to the existing place")
        let moment = Moment(placeID: place.id, authorID: me, photoRef: "p.jpg",
                            coordinate: here, visibility: .publicExhibit)
        try await store.leave(moment)

        // reflects in 도감 (mine) — newest-first
        let mine = try await store.mine(authorID: me)
        XCTAssertEqual(mine.count, beforeMine + 1)
        XCTAssertEqual(mine.first?.id, moment.id)

        // reflects in 전시 (exhibition) — newest-first
        let ex = try await store.exhibition(placeID: place.id)
        XCTAssertEqual(ex.moments.count, beforeExhibition + 1)
        XCTAssertEqual(ex.moments.first?.id, moment.id)

        // reflects in 홈 (feed)
        let feed = try await store.feed(near: nil)
        XCTAssertTrue(feed.contains { $0.id == moment.id })
    }

    func testPrivateClaimStaysOutOfPublicSurfaces() async throws {
        let store = InMemoryTraceStore(seed: .empty)
        let me = User.demo.id
        let place = try await store.resolveOrCreate(at: Demo.seongsan.coordinate,
                                                    snapRadiusMeters: 20, suggestedName: nil)
        try await store.leave(Moment(placeID: place.id, authorID: me, photoRef: "p.jpg",
                                     coordinate: place.coordinate, visibility: .privateOnly))
        // the author sees it in 도감, but it never enters public 전시/홈
        let mine = try await store.mine(authorID: me)
        let exhibition = try await store.exhibition(placeID: place.id)
        let feed = try await store.feed(near: nil)
        XCTAssertEqual(mine.count, 1)
        XCTAssertTrue(exhibition.isEmpty)
        XCTAssertTrue(feed.isEmpty)
    }
}
