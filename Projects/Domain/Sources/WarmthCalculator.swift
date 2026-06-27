import Foundation

public enum Warmth: Int, Equatable, Sendable {
    case cold, cool, warm, hot
}

public struct WarmthCalculator: Sendable {
    public static let revealRadiusMeters: Double = 15
    public init() {}

    public func distanceMeters(from: Coordinate, to: Coordinate) -> Double {
        let r = 6_371_000.0
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
              + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    public func warmth(distanceMeters d: Double) -> Warmth {
        switch d {
        case ..<15: return .hot
        case ..<100: return .warm
        case ..<500: return .cool
        default: return .cold
        }
    }

    public func canReveal(distanceMeters d: Double) -> Bool {
        d < Self.revealRadiusMeters
    }
}
