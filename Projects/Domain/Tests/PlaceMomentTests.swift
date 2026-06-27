import XCTest
@testable import Domain

/// v2.1 claiming-model tests. Additive — does not touch the 19 treasure-model tests.
final class PlaceMomentTests: XCTestCase {
    let here = Coordinate(latitude: 33.4500, longitude: 126.5600)
    let near = Coordinate(latitude: 33.4501, longitude: 126.5600)   // ~11m (within 20m snap)
    let far  = Coordinate(latitude: 33.4510, longitude: 126.5600)   // ~111m (new place)

    private func moment(at c: Coordinate, place: UUID, author: UUID = UUID(),
                        visibility: MomentVisibility = .publicExhibit,
                        createdAt: Date = Date()) -> Moment {
        Moment(placeID: place, authorID: author, photoRef: "p.jpg",
               coordinate: c, createdAt: createdAt, visibility: visibility)
    }

    // MARK: hybrid snap (resolveOrCreate)

    func testNearbyClaimSnapsToSamePlace() async throws {
        let store = InMemoryTraceStore()
        let p1 = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let p2 = try await store.resolveOrCreate(at: near, snapRadiusMeters: 20, suggestedName: nil)
        XCTAssertEqual(p1.id, p2.id)
    }

    func testFarClaimCreatesNewPlace() async throws {
        let store = InMemoryTraceStore()
        let p1 = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let p2 = try await store.resolveOrCreate(at: far, snapRadiusMeters: 20, suggestedName: nil)
        XCTAssertNotEqual(p1.id, p2.id)
    }

    func testSuggestedNameMakesPoiRef() async throws {
        let store = InMemoryTraceStore()
        let p = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: "성산일출봉")
        XCTAssertEqual(p.displayName, "성산일출봉")
        if case .poi = p.ref {} else { XCTFail("expected .poi ref") }
    }

    func testUnnamedSpotWhenNoSuggestion() async throws {
        let store = InMemoryTraceStore()
        let p = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        XCTAssertEqual(p.displayName, Place.unnamed)
        if case .coordinate = p.ref {} else { XCTFail("expected .coordinate ref") }
    }

    // MARK: exhibition (newest-first, public-only, counts)

    func testExhibitionIsNewestFirst() async throws {
        let store = InMemoryTraceStore()
        let place = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let older = moment(at: here, place: place.id, createdAt: Date(timeIntervalSince1970: 100))
        let newer = moment(at: here, place: place.id, createdAt: Date(timeIntervalSince1970: 200))
        try await store.leave(older)
        try await store.leave(newer)
        let ex = try await store.exhibition(placeID: place.id)
        XCTAssertEqual(ex.moments.first?.id, newer.id)
        XCTAssertEqual(ex.moments.count, 2)
    }

    func testPrivateMomentNeverEntersExhibition() async throws {
        let store = InMemoryTraceStore()
        let place = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let mine = UUID()
        try await store.leave(moment(at: here, place: place.id, author: mine, visibility: .privateOnly))
        let ex = try await store.exhibition(placeID: place.id)
        XCTAssertTrue(ex.isEmpty)
        // ...but the author still sees it in their own 도감.
        let own = try await store.mine(authorID: mine)
        XCTAssertEqual(own.count, 1)
    }

    func testContributorCountIsDistinctAuthors() async throws {
        let store = InMemoryTraceStore()
        let place = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let a = UUID()
        try await store.leave(moment(at: here, place: place.id, author: a))
        try await store.leave(moment(at: here, place: place.id, author: a))   // same author twice
        try await store.leave(moment(at: here, place: place.id, author: UUID()))
        let ex = try await store.exhibition(placeID: place.id)
        XCTAssertEqual(ex.moments.count, 3)
        XCTAssertEqual(ex.contributorCount, 2)
    }

    // MARK: safety — report/hide actually remove from public surfaces

    func testReportRemovesFromExhibitionButKeepsInOwn() async throws {
        let store = InMemoryTraceStore()
        let place = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        let author = UUID()
        let m = moment(at: here, place: place.id, author: author)
        try await store.leave(m)
        try await store.report(momentID: m.id, by: UUID())
        let ex = try await store.exhibition(placeID: place.id)
        XCTAssertTrue(ex.isEmpty)
        let own = try await store.mine(authorID: author)
        XCTAssertEqual(own.count, 1)
    }

    func testFeedExcludesPrivateAndSuppressed() async throws {
        let store = InMemoryTraceStore()
        let place = try await store.resolveOrCreate(at: here, snapRadiusMeters: 20, suggestedName: nil)
        try await store.leave(moment(at: here, place: place.id))                       // public
        try await store.leave(moment(at: here, place: place.id, visibility: .privateOnly))
        let hidden = moment(at: here, place: place.id)
        try await store.leave(hidden)
        try await store.hide(momentID: hidden.id, by: UUID())
        let feed = try await store.feed(near: nil)
        XCTAssertEqual(feed.count, 1)
    }
}
