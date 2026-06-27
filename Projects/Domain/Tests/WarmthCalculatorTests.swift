import XCTest
@testable import Domain

final class WarmthCalculatorTests: XCTestCase {
    let calc = WarmthCalculator()

    func testWarmthBuckets() {
        XCTAssertEqual(calc.warmth(distanceMeters: 800), .cold)
        XCTAssertEqual(calc.warmth(distanceMeters: 300), .cool)
        XCTAssertEqual(calc.warmth(distanceMeters: 50), .warm)
        XCTAssertEqual(calc.warmth(distanceMeters: 5), .hot)
    }

    func testRevealGateAt15Meters() {
        XCTAssertFalse(calc.canReveal(distanceMeters: 15.0)) // 경계 미포함
        XCTAssertTrue(calc.canReveal(distanceMeters: 14.9))
    }

    func testHaversineKnownDistance() {
        // 약 111m 떨어진 두 점 (위도 0.001도 ≈ 111m)
        let a = Coordinate(latitude: 33.4500, longitude: 126.5600)
        let b = Coordinate(latitude: 33.4510, longitude: 126.5600)
        let d = calc.distanceMeters(from: a, to: b)
        XCTAssertEqual(d, 111, accuracy: 2)
    }
}
