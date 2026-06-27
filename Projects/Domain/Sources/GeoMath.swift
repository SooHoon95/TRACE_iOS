import Foundation

/// Pure geo helpers for the v2.1 place/snap path.
///
/// Deliberately separate from `WarmthCalculator` (the vestigial treasure-hunt proximity
/// engine) so the claiming path never wires in hunt logic. Same haversine formula, so the
/// 20m snap behavior matches the original repository.
public enum GeoMath {
    /// Great-circle distance in meters between two coordinates (haversine, R = 6_371_000m).
    public static func distanceMeters(from: Coordinate, to: Coordinate) -> Double {
        let r = 6_371_000.0
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
              + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

/// Default snap radius for joining an existing place (meters). Tunable product constant.
public let defaultSnapRadiusMeters: Double = 20
