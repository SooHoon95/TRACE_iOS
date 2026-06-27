import Foundation

public protocol TraceRepository: AnyObject {
    func spots() -> [Spot]
    func nearbySpots(to coordinate: Coordinate, withinMeters: Double) -> [Spot]
    func leaveTrace(_ trace: Trace)
    func collect(traceID: UUID, by userID: UUID)
    func collected(by userID: UUID) -> [Trace]
}
