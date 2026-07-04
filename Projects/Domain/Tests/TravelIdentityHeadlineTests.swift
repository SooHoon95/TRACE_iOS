import XCTest
@testable import Domain

/// Task 2 — headline table + `compute`. Exact-string assertions use synthetic, test-owned
/// fixtures; the ONE `Demo.seed()`-coupled assertion is scoped to the tie-break rule only.
final class TravelIdentityHeadlineTests: XCTestCase {

    private let coord = Coordinate(latitude: 33.45, longitude: 126.56)
    private let place = UUID()
    private let author = UUID()

    private func moment(_ vibe: VibeTag?, _ companion: Companion?,
                        at date: Date = Date(timeIntervalSince1970: 1_000)) -> Moment {
        Moment(placeID: place, authorID: author, photoRef: "t",
               companion: companion, vibe: vibe, coordinate: coord, createdAt: date)
    }

    // MARK: headline table (D1)

    func testHeadlineBothAxes() {
        XCTAssertEqual(TravelIdentity.headline(vibe: .scenic, companion: .solo), "혼자 떠나는 풍경 사냥꾼")
        XCTAssertEqual(TravelIdentity.headline(vibe: .foodie, companion: .partner), "둘이 걷는 맛집 탐험가")
    }

    /// Every (vibe, companion) combination must resolve to a non-empty headline.
    func testHeadlineTotalOverAllCombinations() {
        for v in VibeTag.allCases {
            for c in Companion.allCases {
                XCTAssertFalse(TravelIdentity.headline(vibe: v, companion: c).isEmpty)
            }
        }
    }

    func testHeadlineSingleAxisFallbacks() {
        XCTAssertEqual(TravelIdentity.headline(vibe: .scenic, companion: nil), "풍경 사냥꾼")
        XCTAssertEqual(TravelIdentity.headline(vibe: nil, companion: .solo), "혼자 떠나는 여행자")
    }

    func testHeadlineGenericFallback() {
        XCTAssertEqual(TravelIdentity.headline(vibe: nil, companion: nil), TravelIdentity.genericHeadline)
        XCTAssertEqual(TravelIdentity.headline(vibe: nil, companion: nil), "아직 정체성을 그리는 중")
    }

    // MARK: compute — data levels

    func testComputeEmpty() {
        let m = TravelIdentity.compute([])
        XCTAssertEqual(m.dataLevel, .empty)
        XCTAssertEqual(m.headline, TravelIdentity.genericHeadline)
        XCTAssertTrue(m.highlights.isEmpty)
        XCTAssertNotNil(m.lowDataHint)
        XCTAssertEqual(m.distribution.total, 0)
    }

    func testComputeLowBelowThreshold() {
        let m = TravelIdentity.compute([moment(.scenic, .solo), moment(.scenic, .partner)])
        XCTAssertEqual(m.dataLevel, .low)          // total 2 < 3
        XCTAssertNotNil(m.lowDataHint)
    }

    /// Synthetic 3-moment fixture (scenic/partner, scenic/solo, calm/nil) — owned by this test,
    /// NOT Demo. scenic dominates (2 vs 1); partner & solo tie at 1 → partner wins by enum order.
    func testComputeFullAndExactHeadlineOnSyntheticFixture() {
        let ms = [moment(.scenic, .partner), moment(.scenic, .solo), moment(.calm, nil)]
        let m = TravelIdentity.compute(ms)
        XCTAssertEqual(m.dataLevel, .full)         // total 3, vibeBearing 3
        XCTAssertEqual(m.headline, "둘이 걷는 풍경 사냥꾼")
        XCTAssertNil(m.lowDataHint)
    }

    /// Determinism: shuffled input yields an identical model.
    func testComputeIsDeterministicUnderShuffle() {
        let ms = [moment(.scenic, .partner), moment(.scenic, .solo), moment(.calm, nil),
                  moment(.foodie, .friends)]
        XCTAssertEqual(TravelIdentity.compute(ms), TravelIdentity.compute(ms.shuffled()))
    }

    /// The ONE seed-coupled assertion, scoped to the tie-break rule so a seed edit fails readably.
    /// Demo `mine` = (scenic,partner),(scenic,solo),(calm,nil): partner precedes solo in
    /// Companion.allCases, nil excluded → dominantCompanion == .partner. Pinned to Demo.seed().
    func testDemoMineTieBreakPinned() {
        let mine = Demo.seed().moments.filter { $0.authorID == User.demo.id }
        let dist = TravelIdentity.distribution(mine)
        XCTAssertEqual(dist.dominantVibe, .scenic)
        XCTAssertEqual(dist.dominantCompanion, .partner) // partner precedes solo; nil excluded
    }
}
