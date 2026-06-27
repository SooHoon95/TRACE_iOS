import Foundation

public struct Spot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let coordinate: Coordinate
    public var traces: [Trace]
    public var heat: Int { traces.count }

    public init(id: UUID, coordinate: Coordinate, traces: [Trace]) {
        self.id = id; self.coordinate = coordinate; self.traces = traces
    }
}
