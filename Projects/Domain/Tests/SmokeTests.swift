import XCTest
@testable import Domain

final class SmokeTests: XCTestCase {
    func testVersionExists() {
        XCTAssertEqual(TraceCore.version, "0.1.0")
    }
}
