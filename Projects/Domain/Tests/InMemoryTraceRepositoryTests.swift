import XCTest
@testable import Domain

final class InMemoryTraceRepositoryTests: XCTestCase {
    let here = Coordinate(latitude: 33.4500, longitude: 126.5600)

    func makeTrace(at c: Coordinate, creator: UUID = UUID()) -> Trace {
        Trace(id: UUID(), creatorID: creator, photoRef: "p.jpg", note: "",
              vibe: .calm, coordinate: c, createdAt: Date(timeIntervalSince1970: 0),
              collectCount: 0)
    }

    func testTwoNearbyTracesStackIntoOneSpot() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        // ~11m 떨어진 위치(스냅 반경 20m 이내) → 같은 스팟
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.4501, longitude: 126.5600)))
        XCTAssertEqual(repo.spots().count, 1)
        XCTAssertEqual(repo.spots().first?.heat, 2)
    }

    func testFarTraceMakesNewSpot() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        // ~111m 떨어진 위치 → 별도 스팟
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.4510, longitude: 126.5600)))
        XCTAssertEqual(repo.spots().count, 2)
    }

    func testNearbySpotsFiltersByDistance() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.5000, longitude: 126.5600)))
        let near = repo.nearbySpots(to: here, withinMeters: 100)
        XCTAssertEqual(near.count, 1)
    }

    func testCollectIncrementsCountAndRecordsOwnership() {
        let repo = InMemoryTraceRepository()
        let t = makeTrace(at: here)
        repo.leaveTrace(t)
        let user = UUID()
        repo.collect(traceID: t.id, by: user)
        XCTAssertEqual(repo.collected(by: user).count, 1)
        XCTAssertEqual(repo.spots().first?.traces.first?.collectCount, 1)
    }
}
