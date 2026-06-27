import XCTest
@testable import Domain

final class RarityTests: XCTestCase {
    let r = Rarity()

    func testOwnershipPercentRounds() {
        XCTAssertEqual(r.ownershipPercent(owners: 3, population: 100), 3)
        XCTAssertEqual(r.ownershipPercent(owners: 1, population: 3), 33)
    }

    func testZeroPopulationIsSafe() {
        XCTAssertEqual(r.ownershipPercent(owners: 5, population: 0), 0)
    }

    func testTiers() {
        XCTAssertEqual(r.tier(owners: 1, population: 100), .legendary) // 1%
        XCTAssertEqual(r.tier(owners: 3, population: 100), .rare)      // 3%
        XCTAssertEqual(r.tier(owners: 20, population: 100), .uncommon) // 20%
        XCTAssertEqual(r.tier(owners: 60, population: 100), .common)   // 60%
    }
}
