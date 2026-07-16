import XCTest
import SwiftUI
@testable import UIComponent

/// X-A11Y — the distribution bar is purely visual, so VoiceOver needs a spoken summary.
/// `distributionAccessibilityLabel` is the pure, deterministic string the bar exposes.
final class DistributionAccessibilityTests: XCTestCase {

    private func slice(_ label: String, _ pct: Int) -> CompositionSlice {
        CompositionSlice(label: label, pct: pct, color: .gray)
    }

    /// Title + each slice as "라벨 N퍼센트", comma-joined in slice order.
    func testLabelJoinsTitleAndSlices() {
        let label = distributionAccessibilityLabel(
            title: "무드 분포",
            slices: [slice("풍경", 50), slice("고요", 30), slice("활기", 20)]
        )
        XCTAssertEqual(label, "무드 분포. 풍경 50퍼센트, 고요 30퍼센트, 활기 20퍼센트")
    }

    /// No slices (empty/low card) → just the title, never a dangling period+empty list.
    func testEmptySlicesFallBackToTitle() {
        XCTAssertEqual(distributionAccessibilityLabel(title: "시간대 분포", slices: []), "시간대 분포")
    }

    func testSingleSlice() {
        let label = distributionAccessibilityLabel(title: "무드 분포", slices: [slice("풍경", 100)])
        XCTAssertEqual(label, "무드 분포. 풍경 100퍼센트")
    }
}
