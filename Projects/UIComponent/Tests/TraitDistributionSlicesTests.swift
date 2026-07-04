import XCTest
import SwiftUI
@testable import UIComponent

/// Task 4 — the pure count→percent mapping behind `TraitDistributionBar`.
/// This is the new deterministic logic (A1): percentages must sum to exactly 100 with a
/// pinned remainder tie-break (I2).
final class TraitDistributionSlicesTests: XCTestCase {

    private func pcts(_ counts: [String: Int], _ order: [String]) -> [Int] {
        distributionSlices(counts, order: order, label: { $0 }, color: { _ in .red }).map(\.pct)
    }

    private func labels(_ counts: [String: Int], _ order: [String]) -> [String] {
        distributionSlices(counts, order: order, label: { $0 }, color: { _ in .red }).map(\.label)
    }

    /// Three-way tie: equal remainders → the +1 goes to the first key in `order` (34/33/33).
    func testThreeWayTieBreaksByOrder() {
        let p = pcts(["a": 1, "b": 1, "c": 1], ["a", "b", "c"])
        XCTAssertEqual(p, [34, 33, 33])
        XCTAssertEqual(p.reduce(0, +), 100)
    }

    /// Unequal remainders: largest remainder (not order) wins — [5,3,1] → 56/33/11.
    func testUnequalRemaindersFollowRemainder() {
        let p = pcts(["a": 5, "b": 3, "c": 1], ["a", "b", "c"])
        XCTAssertEqual(p, [56, 33, 11])
        XCTAssertEqual(p.reduce(0, +), 100)
    }

    /// Six equal slices → 17/17/17/17/16/16, still summing to 100.
    func testSixWayEqual() {
        let p = pcts(["a": 1, "b": 1, "c": 1, "d": 1, "e": 1, "f": 1],
                     ["a", "b", "c", "d", "e", "f"])
        XCTAssertEqual(p, [17, 17, 17, 17, 16, 16])
        XCTAssertEqual(p.reduce(0, +), 100)
    }

    /// Zero-count keys are omitted; order among the rest is preserved; still sums to 100.
    func testZeroCountsOmitted() {
        let counts = ["a": 2, "b": 0, "c": 1]
        XCTAssertEqual(labels(counts, ["a", "b", "c"]), ["a", "c"])
        XCTAssertEqual(pcts(counts, ["a", "b", "c"]).reduce(0, +), 100)
    }

    /// Slices are emitted in `order`, not dictionary order.
    func testOrderIsRespected() {
        XCTAssertEqual(labels(["a": 1, "b": 1, "c": 1], ["c", "b", "a"]), ["c", "b", "a"])
    }

    func testEmptyInput() {
        XCTAssertTrue(distributionSlices([String: Int](), order: [], label: { $0 }, color: { _ in .red }).isEmpty)
        // All-zero counts also yield nothing.
        XCTAssertTrue(pcts(["a": 0, "b": 0], ["a", "b"]).isEmpty)
    }

    /// Single non-zero key → 100%.
    func testSingleKey() {
        XCTAssertEqual(pcts(["a": 7], ["a"]), [100])
    }
}
