import XCTest
@testable import Domain

final class ModelTests: XCTestCase {
    func testTraceCollectCountIncrements() {
        var t = Trace(id: UUID(), creatorID: UUID(), photoRef: "p.jpg",
                      note: "야경 미쳤음", vibe: .scenic,
                      coordinate: Coordinate(latitude: 33.45, longitude: 126.56),
                      createdAt: Date(timeIntervalSince1970: 0), collectCount: 0)
        t.incrementCollect()
        t.incrementCollect()
        XCTAssertEqual(t.collectCount, 2)
    }

    func testSpotHeatEqualsTraceCount() {
        let c = Coordinate(latitude: 33.45, longitude: 126.56)
        let spot = Spot(id: UUID(), coordinate: c, traces: [
            sampleTrace(at: c), sampleTrace(at: c), sampleTrace(at: c)
        ])
        XCTAssertEqual(spot.heat, 3)
    }

    func testCoordinateCodableRoundTrip() throws {
        let c = Coordinate(latitude: 33.45, longitude: 126.56)
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(c, decoded)
    }

    private func sampleTrace(at c: Coordinate) -> Trace {
        Trace(id: UUID(), creatorID: UUID(), photoRef: "p.jpg", note: "",
              vibe: .calm, coordinate: c, createdAt: Date(timeIntervalSince1970: 0),
              collectCount: 0)
    }
}
