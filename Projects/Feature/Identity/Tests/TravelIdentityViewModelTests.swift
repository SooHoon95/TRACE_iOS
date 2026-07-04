import XCTest
@testable import Identity
import Domain

/// Task 5 — VM load, real-time re-fetch, and the C1/I1 async region-name resolution.
@MainActor
final class TravelIdentityViewModelTests: XCTestCase {

    private let coord = Coordinate(latitude: 33.45, longitude: 126.56)

    private func moment(_ v: VibeTag?, _ c: Companion?, placeID: UUID, author: UUID) -> Moment {
        Moment(placeID: placeID, authorID: author, photoRef: "p",
               companion: c, vibe: v, coordinate: coord)
    }

    private func store(_ moments: [Moment], places: [Place] = []) -> InMemoryTraceStore {
        InMemoryTraceStore(seed: TraceSeed(places: places, moments: moments))
    }

    func testLoadComputesFullModelWithExpectedHeadline() async {
        let author = UUID(), place = UUID()
        let s = store([
            moment(.scenic, .partner, placeID: place, author: author),
            moment(.scenic, .solo, placeID: place, author: author),
            moment(.calm, nil, placeID: place, author: author)
        ])
        let vm = TravelIdentityViewModel(store: s, userID: author)
        await vm.load()
        XCTAssertNotNil(vm.model)
        XCTAssertEqual(vm.model?.dataLevel, .full)
        XCTAssertEqual(vm.model?.headline, "둘이 걷는 풍경 사냥꾼") // scenic dominant; partner tie-break
    }

    /// Real-time: leaving a new moment then reloading increments the distribution total (AC).
    func testReloadReflectsNewlyLeftMoment() async {
        let author = UUID(), place = UUID()
        let s = store([
            moment(.scenic, .partner, placeID: place, author: author),
            moment(.scenic, .solo, placeID: place, author: author)
        ])
        let vm = TravelIdentityViewModel(store: s, userID: author)
        await vm.load()
        let before = vm.model?.distribution.total ?? 0
        try? await s.leave(moment(.calm, .family, placeID: place, author: author))
        await vm.load()
        XCTAssertEqual(vm.model?.distribution.total, before + 1)
    }

    /// I1: the dominant place's displayName is resolved (async) and surfaced on the VM.
    func testDominantPlaceNameResolved() async {
        let author = UUID()
        let seongsan = Place(ref: .poi(providerID: "mock", name: "성산일출봉"),
                             coordinate: coord, displayName: "성산일출봉")
        let s = store([
            moment(.scenic, .solo, placeID: seongsan.id, author: author),
            moment(.scenic, .partner, placeID: seongsan.id, author: author)
        ], places: [seongsan])
        let vm = TravelIdentityViewModel(store: s, userID: author)
        await vm.load()
        XCTAssertEqual(vm.dominantPlaceName, "성산일출봉")
    }

    /// I1: empty store → empty model, no place name.
    func testEmptyStoreYieldsEmptyModelAndNoPlaceName() async {
        let vm = TravelIdentityViewModel(store: store([]), userID: UUID())
        await vm.load()
        XCTAssertEqual(vm.model?.dataLevel, .empty)
        XCTAssertNil(vm.dominantPlaceName)
    }
}
