import XCTest
import SwiftUI
@testable import UIComponent
import Domain

/// Task 7 — empty/low-data state verification. Asserts the model values that drive the screen
/// (placeholder headline, hint, share-hidden condition) and that both branches render.
@MainActor
final class IdentityCardStateTests: XCTestCase {

    private let coord = Coordinate(latitude: 33.45, longitude: 126.56)

    private func moment(_ v: VibeTag?, _ c: Companion?) -> Moment {
        Moment(placeID: UUID(), authorID: UUID(), photoRef: "p",
               companion: c, vibe: v, coordinate: coord)
    }

    /// Empty: placeholder headline + hint + no highlights; `dataLevel == .empty` is the exact
    /// condition the screen uses to hide the share button. Card renders without trapping.
    func testEmptyStateDrivesPlaceholderAndHidesShare() {
        let model = TravelIdentity.compute([])
        XCTAssertEqual(model.dataLevel, .empty)             // → share button hidden
        XCTAssertEqual(model.headline, TravelIdentity.genericHeadline)
        XCTAssertNotNil(model.lowDataHint)
        XCTAssertTrue(model.highlights.isEmpty)

        let image = TravelIdentityCardView(model: model, name: "지민").traceSnapshot(scale: 1)
        XCTAssertNotNil(image)
    }

    /// Low: below threshold → hint present, share still allowed (dataLevel != .empty). Renders.
    func testLowStateRendersWithHint() {
        let model = TravelIdentity.compute([moment(.scenic, .solo)])
        XCTAssertEqual(model.dataLevel, .low)
        XCTAssertNotNil(model.lowDataHint)
        XCTAssertNotEqual(model.dataLevel, .empty)          // share NOT hidden

        let image = TravelIdentityCardView(model: model, name: "지민", placeName: nil).traceSnapshot(scale: 1)
        XCTAssertNotNil(image)
    }

    /// Full: no hint; card with highlights renders.
    func testFullStateHasNoHint() {
        let model = TravelIdentity.compute([moment(.scenic, .partner), moment(.scenic, .solo),
                                            moment(.calm, .family)])
        XCTAssertEqual(model.dataLevel, .full)
        XCTAssertNil(model.lowDataHint)
        XCTAssertFalse(model.highlights.isEmpty)

        let image = TravelIdentityCardView(model: model, name: "지민", placeName: "월정리 해변").traceSnapshot(scale: 1)
        XCTAssertNotNil(image)
    }
}
