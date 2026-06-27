import Foundation
import Domain
import Supabase

/// Postgres-backed store (places + moments) via Supabase PostgREST + RLS.
/// Conforms to `TraceStore` so it drops into the same `any TraceStore` injection as the mock.
public final class SupabaseTraceStore: TraceStore {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - PlaceRepository

    public func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place] {
        let rows: [PlaceRow] = try await client.from("places").select().execute().value
        return rows
            .map { ($0.toDomain(), GeoMath.distanceMeters(from: c, to: $0.toDomain().coordinate)) }
            .filter { $0.1 <= radiusMeters }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    public func resolveOrCreate(at c: Coordinate, snapRadiusMeters: Double,
                                suggestedName: String?) async throws -> Place {
        let params = ResolveOrCreateParams(p_lat: c.latitude, p_lng: c.longitude,
                                           p_radius_m: snapRadiusMeters, p_name: suggestedName)
        let rows: [PlaceRow] = try await client.rpc("resolve_or_create_place", params: params)
            .execute().value
        guard let row = rows.first else { throw PlaceError.notFound }
        return row.toDomain()
    }

    public func place(id: UUID) async throws -> Place {
        let rows: [PlaceRow] = try await client.from("places")
            .select().eq("id", value: id.uuidString).limit(1).execute().value
        guard let row = rows.first else { throw PlaceError.notFound }
        return row.toDomain()
    }

    // MARK: - MomentRepository

    public func leave(_ moment: Moment) async throws {
        try await client.from("moments").insert(MomentInsert(moment)).execute()
    }

    public func exhibition(placeID: UUID) async throws -> Exhibition {
        let place = try await place(id: placeID)
        let rows: [MomentRow] = try await client.from("moments")
            .select()
            .eq("place_id", value: placeID.uuidString)
            .eq("visibility", value: MomentVisibility.publicExhibit.rawValue)
            .order("created_at", ascending: false)
            .execute().value
        return Exhibition(place: place, moments: rows.map { $0.toDomain() })
    }

    public func mine(authorID: UUID) async throws -> [Moment] {
        let rows: [MomentRow] = try await client.from("moments")
            .select()
            .eq("author_id", value: authorID.uuidString)
            .order("created_at", ascending: false)
            .execute().value
        return rows.map { $0.toDomain() }
    }

    public func feed(near c: Coordinate?) async throws -> [Moment] {
        let rows: [MomentRow] = try await client.from("moments")
            .select()
            .eq("visibility", value: MomentVisibility.publicExhibit.rawValue)
            .order("created_at", ascending: false)
            .limit(50)
            .execute().value
        let moments = rows.map { $0.toDomain() }
        guard let c else { return moments }
        return moments.sorted {
            GeoMath.distanceMeters(from: c, to: $0.coordinate)
                < GeoMath.distanceMeters(from: c, to: $1.coordinate)
        }
    }

    // MARK: - moderation (T2.11 — server-side review queue + per-viewer hide)

    public func report(momentID: UUID, by userID: UUID) async throws {
        // T2.11: insert into a moderation/reports table for review. No-op until that lands.
    }

    public func hide(momentID: UUID, by userID: UUID) async throws {
        // T2.11: per-viewer hidden list. No-op until that lands.
    }
}
