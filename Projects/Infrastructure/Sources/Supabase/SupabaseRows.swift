import Foundation
import Domain

// Row DTOs matching the Postgres columns (snake_case), with converters to/from Domain.

struct PlaceRow: Decodable {
    let id: UUID
    let ref_type: String
    let ref_provider_id: String?
    let ref_name: String?
    let latitude: Double
    let longitude: Double
    let display_name: String

    func toDomain() -> Place {
        let ref: PlaceRef = (ref_type == "poi")
            ? .poi(providerID: ref_provider_id ?? "mock", name: ref_name ?? display_name)
            : .coordinate(name: ref_name)
        return Place(id: id, ref: ref,
                     coordinate: Coordinate(latitude: latitude, longitude: longitude),
                     displayName: display_name)
    }
}

struct MomentRow: Decodable {
    let id: UUID
    let place_id: UUID
    let author_id: UUID
    let photo_ref: String
    let caption: String?
    let companion: String?
    let vibe: String?
    let latitude: Double
    let longitude: Double
    let visibility: String
    let created_at: Date

    func toDomain() -> Moment {
        Moment(id: id,
               placeID: place_id,
               authorID: author_id,
               photoRef: photo_ref,
               caption: caption,
               companion: companion.flatMap(Companion.init(rawValue:)),
               vibe: vibe.flatMap(VibeTag.init(rawValue:)),
               coordinate: Coordinate(latitude: latitude, longitude: longitude),
               createdAt: created_at,
               visibility: MomentVisibility(rawValue: visibility) ?? .publicExhibit,
               syncState: .synced)
    }
}

/// Insert payload for a new moment (id/created_at default server-side).
struct MomentInsert: Encodable {
    let id: String
    let place_id: String
    let author_id: String
    let photo_ref: String
    let caption: String?
    let companion: String?
    let vibe: String?
    let latitude: Double
    let longitude: Double
    let visibility: String

    init(_ m: Moment) {
        id = m.id.uuidString
        place_id = m.placeID.uuidString
        author_id = m.authorID.uuidString
        photo_ref = m.photoRef
        caption = m.caption
        companion = m.companion?.rawValue
        vibe = m.vibe?.rawValue
        latitude = m.coordinate.latitude
        longitude = m.coordinate.longitude
        visibility = m.visibility.rawValue
    }
}

/// Params for the resolve_or_create_place RPC.
struct ResolveOrCreateParams: Encodable {
    let p_lat: Double
    let p_lng: Double
    let p_radius_m: Double
    let p_name: String?
}
