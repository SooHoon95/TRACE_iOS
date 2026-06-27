import XCTest
@testable import Domain

final class HuntStateMachineTests: XCTestCase {
    func testStartsApproaching() {
        XCTAssertEqual(HuntStateMachine().state, .approaching)
    }

    func testFarKeepsApproaching_NearUnlocksReveal() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(50))
        XCTAssertEqual(m.state, .approaching)
        m.handle(.distanceUpdated(10))
        XCTAssertEqual(m.state, .revealable)
    }

    func testMovingAwayRelocksReveal() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(10))
        XCTAssertEqual(m.state, .revealable)
        m.handle(.distanceUpdated(80))
        XCTAssertEqual(m.state, .approaching)
    }

    func testRevealTapIgnoredWhenNotRevealable() {
        var m = HuntStateMachine()
        m.handle(.revealTapped)
        XCTAssertEqual(m.state, .approaching)
    }

    func testHappyPathToTraceLeft() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(8))
        m.handle(.revealTapped)
        XCTAssertEqual(m.state, .revealed)
        m.handle(.captured)
        XCTAssertEqual(m.state, .captured)
        m.handle(.traceLeft)
        XCTAssertEqual(m.state, .traceLeft)
    }
}
