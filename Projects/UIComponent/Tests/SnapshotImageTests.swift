import XCTest
import SwiftUI
@testable import UIComponent
import Domain

/// Task 6 — the identity card renders to a non-empty UIImage (share-sheet input).
@MainActor
final class SnapshotImageTests: XCTestCase {

    func testCardRendersToImage() {
        let coord = Coordinate(latitude: 33.45, longitude: 126.56)
        let place = UUID()
        func m(_ v: VibeTag?, _ c: Companion?) -> Moment {
            Moment(placeID: place, authorID: UUID(), photoRef: "p",
                   companion: c, vibe: v, coordinate: coord)
        }
        let model = TravelIdentity.compute([m(.scenic, .partner), m(.scenic, .solo), m(.calm, .family)])
        let card = TravelIdentityCardView(model: model, name: "지민", placeName: "월정리 해변")

        let image = card.traceSnapshot(scale: 2)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
        XCTAssertGreaterThan(image?.size.height ?? 0, 0)
    }
}
