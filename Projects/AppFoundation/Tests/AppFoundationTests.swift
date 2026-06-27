import XCTest
@testable import AppFoundation

final class AppFoundationTests: XCTestCase {
  func testPlaceholder() {
    XCTAssertEqual(0.toKoreanCurrency(), "0원")
  }
}
