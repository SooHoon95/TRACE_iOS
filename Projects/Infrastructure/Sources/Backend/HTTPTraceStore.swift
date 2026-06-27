import Foundation
import Domain

/// `TraceStore` backed by the TRACE HTTP API. Browsing endpoints are public;
/// resolve/leave/mine/report/hide require the session JWT (set after auth).
public struct HTTPTraceStore: TraceStore {
    private let client: TraceAPIClient

    public init(client: TraceAPIClient) {
        self.client = client
    }

    // MARK: PlaceRepository

    public func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place] {
        let dtos: [PlaceDTO] = try await client.get(
            "places/nearby",
            query: [
                .init(name: "lat", value: String(c.latitude)),
                .init(name: "lng", value: String(c.longitude)),
                .init(name: "radius_m", value: String(radiusMeters)),
            ]
        )
        return dtos.map(\.place)
    }

    public func resolveOrCreate(at c: Coordinate,
                                snapRadiusMeters: Double,
                                suggestedName: String?) async throws -> Place {
        let dto: PlaceDTO = try await client.post(
            "places/resolve",
            body: ResolveBody(latitude: c.latitude, longitude: c.longitude,
                              radiusM: snapRadiusMeters, name: suggestedName),
            authed: true
        )
        return dto.place
    }

    public func place(id: UUID) async throws -> Place {
        do {
            let dto: PlaceDTO = try await client.get("places/\(id.uuidString.lowercased())")
            return dto.place
        } catch let error as APIError where error.status == 404 {
            throw PlaceError.notFound
        }
    }

    // MARK: MomentRepository

    public func leave(_ moment: Moment) async throws {
        let _: MomentDTO = try await client.post(
            "moments",
            body: MomentCreateBody(
                placeId: moment.placeID.uuidString.lowercased(),
                photoRef: moment.photoRef,
                latitude: moment.coordinate.latitude,
                longitude: moment.coordinate.longitude,
                caption: moment.caption,
                companion: moment.companion?.rawValue,
                vibe: moment.vibe?.rawValue,
                visibility: moment.visibility.rawValue
            ),
            authed: true
        )
    }

    public func exhibition(placeID: UUID) async throws -> Exhibition {
        let pid = placeID.uuidString.lowercased()
        async let placeDTO: PlaceDTO = client.get("places/\(pid)")
        async let momentDTOs: [MomentDTO] = client.get("places/\(pid)/moments", authed: true)
        let place = try await placeDTO.place
        let moments = try await momentDTOs.map(\.moment)
        return Exhibition(place: place, moments: moments)
    }

    public func mine(authorID: UUID) async throws -> [Moment] {
        let dtos: [MomentDTO] = try await client.get("me/moments", authed: true)
        return dtos.map(\.moment)
    }

    public func feed(near c: Coordinate?) async throws -> [Moment] {
        var query: [URLQueryItem] = []
        if let c {
            query = [
                .init(name: "lat", value: String(c.latitude)),
                .init(name: "lng", value: String(c.longitude)),
            ]
        }
        let dtos: [MomentDTO] = try await client.get("moments/feed", query: query)
        return dtos.map(\.moment)
    }

    public func report(momentID: UUID, by userID: UUID) async throws {
        try await client.postVoid(
            "moments/\(momentID.uuidString.lowercased())/report",
            body: ReportBody(reason: nil), authed: true
        )
    }

    public func hide(momentID: UUID, by userID: UUID) async throws {
        try await client.postVoid(
            "moments/\(momentID.uuidString.lowercased())/hide",
            body: EmptyBody(), authed: true
        )
    }
}
