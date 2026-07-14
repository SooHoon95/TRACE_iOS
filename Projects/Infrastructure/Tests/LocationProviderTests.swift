import XCTest
import CoreLocation
@testable import Infrastructure

/// Regression for the "dev login spins forever" bug: `LocationProvider.current()` awaited a
/// CoreLocation callback that, on a simulator with no location set, never arrives — so its
/// continuation never resumed and `HomeViewModel.load()` (which awaits it) hung with the
/// loading indicator stuck. `current()` must now ALWAYS resolve within its timeout.
@MainActor
final class LocationProviderTests: XCTestCase {

    /// With no deliverable location in the test environment, `current()` must resolve
    /// (throw) within the timeout window — never suspend indefinitely.
    func testCurrentResolvesInsteadOfHanging() async {
        let provider = LocationProvider(timeout: 0.5)
        let start = Date()
        do {
            _ = try await provider.current()   // may return a coordinate if the host has one
        } catch {
            // expected in a headless test: .unavailable via the timeout
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 3.0,
                          "current() did not resolve within the timeout — it hung on CoreLocation")
    }
}
