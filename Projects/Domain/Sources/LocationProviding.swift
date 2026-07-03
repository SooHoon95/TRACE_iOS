import Foundation

/// Supplies the device's current coordinate for location-based claiming (the ＋ flow).
public protocol LocationProviding {
    func current() async throws -> Coordinate
}

/// Default / mock provider — a fixed coordinate so design and dev run without CoreLocation.
public struct FixedLocationProvider: LocationProviding {
    private let coordinate: Coordinate

    public init(_ coordinate: Coordinate = Demo.seongsan.coordinate) {
        self.coordinate = coordinate
    }

    public func current() async throws -> Coordinate { coordinate }
}
