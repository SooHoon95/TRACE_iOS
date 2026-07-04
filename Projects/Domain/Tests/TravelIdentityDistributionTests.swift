import XCTest
@testable import Domain

/// Task 1 — TraitDistribution + TimeBand. All fixtures are hand-built in-test (never `Demo.seed()`).
final class TravelIdentityDistributionTests: XCTestCase {

    private let coord = Coordinate(latitude: 33.45, longitude: 126.56)
    private let place = UUID()
    private let author = UUID()

    private func moment(vibe: VibeTag?, companion: Companion?,
                        placeID: UUID? = nil, at date: Date = Date(timeIntervalSince1970: 0)) -> Moment {
        Moment(placeID: placeID ?? place, authorID: author, photoRef: "t",
               companion: companion, vibe: vibe, coordinate: coord, createdAt: date)
    }

    func testEmptyDistribution() {
        let d = TravelIdentity.distribution([])
        XCTAssertEqual(d.total, 0)
        XCTAssertTrue(d.vibeCounts.isEmpty)
        XCTAssertTrue(d.companionCounts.isEmpty)
        XCTAssertTrue(d.timeBandCounts.isEmpty)
        XCTAssertTrue(d.regionCounts.isEmpty)
        XCTAssertNil(d.dominantVibe)
        XCTAssertNil(d.dominantCompanion)
        XCTAssertNil(d.dominantTimeBand)
        XCTAssertNil(d.dominantRegion)
    }

    /// nil vibe/companion are excluded from their counts but still count in total, timeBand, region.
    func testNilTraitsExcludedFromCountsButNotTotal() {
        let d = TravelIdentity.distribution([moment(vibe: nil, companion: nil)])
        XCTAssertEqual(d.total, 1)
        XCTAssertTrue(d.vibeCounts.isEmpty)
        XCTAssertTrue(d.companionCounts.isEmpty)
        XCTAssertEqual(d.regionCounts[place], 1)
        XCTAssertEqual(d.timeBandCounts.values.reduce(0, +), 1)
        XCTAssertNil(d.dominantVibe)
        XCTAssertNil(d.dominantCompanion)
    }

    /// Mode tie-break is by enum declaration order: calm (index 0) beats scenic (index 2) on a 1–1 tie.
    func testDominantTieBreakByEnumOrder() {
        let d = TravelIdentity.distribution([
            moment(vibe: .scenic, companion: .solo),
            moment(vibe: .calm, companion: .partner)
        ])
        XCTAssertEqual(d.dominantVibe, .calm)        // calm precedes scenic in VibeTag.allCases
        XCTAssertEqual(d.dominantCompanion, .partner) // partner precedes solo in Companion.allCases
    }

    func testDominantVibeClearWinner() {
        let d = TravelIdentity.distribution([
            moment(vibe: .scenic, companion: nil),
            moment(vibe: .scenic, companion: nil),
            moment(vibe: .calm, companion: nil)
        ])
        XCTAssertEqual(d.dominantVibe, .scenic)
    }

    func testDominantRegionMostFrequented() {
        let p1 = UUID(), p2 = UUID()
        let d = TravelIdentity.distribution([
            moment(vibe: nil, companion: nil, placeID: p1),
            moment(vibe: nil, companion: nil, placeID: p2),
            moment(vibe: nil, companion: nil, placeID: p2)
        ])
        XCTAssertEqual(d.dominantRegion, p2)
        XCTAssertEqual(d.regionCounts[p2], 2)
        XCTAssertEqual(d.regionCounts[p1], 1)
    }

    func testTimeBandBoundaries() {
        XCTAssertEqual(TimeBand.band(forHour: 0), .dawn)
        XCTAssertEqual(TimeBand.band(forHour: 5), .dawn)
        XCTAssertEqual(TimeBand.band(forHour: 6), .morning)
        XCTAssertEqual(TimeBand.band(forHour: 10), .morning)
        XCTAssertEqual(TimeBand.band(forHour: 11), .day)
        XCTAssertEqual(TimeBand.band(forHour: 16), .day)
        XCTAssertEqual(TimeBand.band(forHour: 17), .evening)
        XCTAssertEqual(TimeBand.band(forHour: 20), .evening)
        XCTAssertEqual(TimeBand.band(forHour: 21), .night)
        XCTAssertEqual(TimeBand.band(forHour: 23), .night)
    }

    /// Determinism across timezone: epoch 0 is 00:00 UTC but 09:00 in Seoul → `.morning`, not `.dawn`.
    /// Asserting `.morning` proves the fixed Asia/Seoul calendar is used, not UTC or device tz.
    func testTimeBandUsesSeoulTimezone() {
        let d = TravelIdentity.distribution([moment(vibe: .calm, companion: .solo,
                                                    at: Date(timeIntervalSince1970: 0))])
        XCTAssertEqual(d.timeBandCounts[.morning], 1)
        XCTAssertNil(d.timeBandCounts[.dawn])
        XCTAssertEqual(d.dominantTimeBand, .morning)
    }

    /// Order-independence: shuffling the input never changes the distribution.
    func testDistributionIsOrderIndependent() {
        let ms = [
            moment(vibe: .scenic, companion: .partner),
            moment(vibe: .calm, companion: .solo),
            moment(vibe: .scenic, companion: nil)
        ]
        XCTAssertEqual(TravelIdentity.distribution(ms), TravelIdentity.distribution(ms.reversed()))
    }
}
