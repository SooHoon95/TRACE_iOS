import Foundation

public enum PlaceError: Error, Sendable {
    case notFound
}

/// Reads/writes for places (hybrid identity + exhibition aggregation).
/// Concrete impls: `InMemoryTraceStore` (Phase 1) → Supabase (Phase 2).
public protocol PlaceRepository: Sendable {
    /// Places whose coordinate is within `radiusMeters` of `c`, nearest-first.
    func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place]

    /// Join the nearest place within `snapRadiusMeters`, else create a new one.
    /// Atomic so concurrent first-claims at the same spot don't create duplicates
    /// (mock: serialized by the actor; production: a server-side transaction).
    func resolveOrCreate(at c: Coordinate,
                         snapRadiusMeters: Double,
                         suggestedName: String?) async throws -> Place

    func place(id: UUID) async throws -> Place
}
