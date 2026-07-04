import XCTest
@testable import Domain

/// Task 3 — 대표/희귀 highlight selection (D2). Hand-built fixtures with controlled createdAt/id.
final class TravelIdentityHighlightTests: XCTestCase {

    private let coord = Coordinate(latitude: 33.45, longitude: 126.56)
    private let place = UUID()
    private let author = UUID()

    private func moment(_ vibe: VibeTag?, _ companion: Companion?,
                        offset: TimeInterval, id: UUID = UUID()) -> Moment {
        Moment(id: id, placeID: place, authorID: author, photoRef: "t",
               companion: companion, vibe: vibe, coordinate: coord,
               createdAt: Date(timeIntervalSince1970: 1_000 + offset))
    }

    private func highlights(_ ms: [Moment]) -> [Highlight] {
        TravelIdentity.selectHighlights(ms, distribution: TravelIdentity.distribution(ms))
    }

    /// Representative = newest moment of the dominant pair; later createdAt wins.
    func testRepresentativeIsNewestOfDominantPair() {
        let older = moment(.scenic, .partner, offset: 10)
        let newer = moment(.scenic, .partner, offset: 20)
        let rareOne = moment(.foodie, .solo, offset: 5)
        let hs = highlights([older, newer, rareOne])
        let rep = hs.first { $0.reason == .representative }
        XCTAssertEqual(rep?.moment.id, newer.id)   // dominant pair (scenic,partner); newer wins
    }

    /// Equal createdAt within the representative pool → smaller uuidString wins.
    func testRepresentativeTieBreaksByUUID() {
        let idA = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let idB = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let a = moment(.scenic, .partner, offset: 10, id: idA)
        let b = moment(.scenic, .partner, offset: 10, id: idB)
        let filler = moment(.calm, .solo, offset: 1)
        let hs = highlights([b, a, filler])
        XCTAssertEqual(hs.first { $0.reason == .representative }?.moment.id, idA) // smaller uuid
    }

    /// Rare = lowest-frequency pair; ties within the rare pool → oldest createdAt.
    func testRareIsLowestFrequencyThenOldest() {
        // (scenic,partner) x3 dominant; (foodie,solo) x1 rare.
        let ms = [
            moment(.scenic, .partner, offset: 30),
            moment(.scenic, .partner, offset: 20),
            moment(.scenic, .partner, offset: 10),
            moment(.foodie, .solo, offset: 40)
        ]
        let rare = highlights(ms).first { $0.reason == .rare }
        XCTAssertEqual(rare?.moment.vibe, .foodie)
        XCTAssertEqual(rare?.moment.companion, .solo)
    }

    /// nil vibe or nil companion → excluded from highlight candidacy entirely.
    func testNilPairMomentsExcluded() {
        let defined = moment(.scenic, .partner, offset: 10)
        let nilVibe = moment(nil, .solo, offset: 20)
        let nilComp = moment(.calm, nil, offset: 30)
        let hs = highlights([defined, nilVibe, nilComp])
        // Only `defined` is a candidate → single representative highlight.
        XCTAssertEqual(hs.count, 1)
        XCTAssertEqual(hs.first?.moment.id, defined.id)
        XCTAssertEqual(hs.first?.reason, .representative)
    }

    /// Single defined-pair moment → representative only (rep == rare → dedupe to 1).
    func testSingleMomentYieldsOneHighlight() {
        let hs = highlights([moment(.scenic, .partner, offset: 10)])
        XCTAssertEqual(hs.count, 1)
        XCTAssertEqual(hs.first?.reason, .representative)
    }

    /// Empty / all-nil-pair input → no highlights.
    func testEmptyAndAllNilYieldNoHighlights() {
        XCTAssertTrue(highlights([]).isEmpty)
        XCTAssertTrue(highlights([moment(nil, nil, offset: 1), moment(nil, .solo, offset: 2)]).isEmpty)
    }

    /// Two distinct pairs → both a representative and a rare, distinct moments.
    func testRepresentativeAndRareAreDistinct() {
        let ms = [
            moment(.scenic, .partner, offset: 30),
            moment(.scenic, .partner, offset: 20),
            moment(.foodie, .solo, offset: 10)
        ]
        let hs = highlights(ms)
        XCTAssertEqual(hs.count, 2)
        let rep = hs.first { $0.reason == .representative }!
        let rare = hs.first { $0.reason == .rare }!
        XCTAssertNotEqual(rep.moment.id, rare.moment.id)
        XCTAssertEqual(rare.moment.vibe, .foodie)
    }

    /// Determinism under shuffle.
    func testHighlightsDeterministicUnderShuffle() {
        let ms = [
            moment(.scenic, .partner, offset: 30),
            moment(.scenic, .partner, offset: 20),
            moment(.foodie, .solo, offset: 10),
            moment(.calm, .family, offset: 5)
        ]
        XCTAssertEqual(highlights(ms), highlights(ms.shuffled()))
    }
}
