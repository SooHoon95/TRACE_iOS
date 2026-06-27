import Foundation

public final class InMemoryTraceRepository: TraceRepository {
    public let snapRadiusMeters: Double = 20
    private let calc = WarmthCalculator()
    private var store: [Spot] = []
    private var ownership: [UUID: Set<UUID>] = [:] // userID -> traceIDs

    public init(seed: [Trace] = []) {
        for t in seed { leaveTrace(t) }
    }

    public func spots() -> [Spot] { store }

    public func nearbySpots(to coordinate: Coordinate, withinMeters: Double) -> [Spot] {
        store.filter {
            calc.distanceMeters(from: coordinate, to: $0.coordinate) <= withinMeters
        }
    }

    public func leaveTrace(_ trace: Trace) {
        if let idx = store.firstIndex(where: {
            calc.distanceMeters(from: $0.coordinate, to: trace.coordinate) <= snapRadiusMeters
        }) {
            store[idx].traces.append(trace)
        } else {
            store.append(Spot(id: UUID(), coordinate: trace.coordinate, traces: [trace]))
        }
    }

    public func collect(traceID: UUID, by userID: UUID) {
        for s in store.indices {
            if let t = store[s].traces.firstIndex(where: { $0.id == traceID }) {
                store[s].traces[t].incrementCollect()
                ownership[userID, default: []].insert(traceID)
                return
            }
        }
    }

    public func collected(by userID: UUID) -> [Trace] {
        let ids = ownership[userID] ?? []
        return store.flatMap { $0.traces }.filter { ids.contains($0.id) }
    }
}
