import XCTest
@testable import Domain

/// Core value-type tests. (Treasure-model Trace/Spot tests removed in T1.0 legacy cleanup.)
final class ModelTests: XCTestCase {
    func testCoordinateCodableRoundTrip() throws {
        let c = Coordinate(latitude: 33.45, longitude: 126.56)
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(c, decoded)
    }
}
