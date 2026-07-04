import SwiftUI
import UIKit

public extension View {
    /// Renders the view to a `UIImage` via `ImageRenderer` at a **fixed** scale (default 3).
    ///
    /// The scale is a constant — not `UIScreen.main.scale` — so the shared image is deterministic
    /// and device-independent (matching the card's fixed 320pt render width), and avoids the
    /// iOS-16+ `UIScreen.main` deprecation.
    @MainActor
    func traceSnapshot(scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.uiImage
    }
}
