import Foundation
import Domain

// MARK: - Responses (snake_case JSON decoded via convertFromSnakeCase)

struct UserDTO: Decodable {
    let id: String
    let nickname: String
    let provider: String
    let email: String?

    var user: User {
        User(id: UUID(uuidString: id) ?? UUID(),
             nickname: nickname,
             authProvider: AuthProvider(rawValue: provider) ?? .guest)
    }
}

struct AuthResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let user: UserDTO
}

struct PlaceRefDTO: Decodable {
    let type: String
    let providerId: String?
    let name: String?

    var ref: PlaceRef {
        type == "poi"
            ? .poi(providerID: providerId ?? "", name: name ?? Place.unnamed)
            : .coordinate(name: name)
    }
}

struct PlaceDTO: Decodable {
    let id: String
    let ref: PlaceRefDTO
    let latitude: Double
    let longitude: Double
    let displayName: String
    let momentCount: Int
    let contributorCount: Int
    let coverPhotoRef: String?
    let coverPhotoUrl: String?
    let createdAt: Date

    var place: Place {
        Place(id: UUID(uuidString: id) ?? UUID(),
              ref: ref.ref,
              coordinate: Coordinate(latitude: latitude, longitude: longitude),
              displayName: displayName,
              momentCount: momentCount,
              contributorCount: contributorCount,
              coverPhotoRef: coverPhotoRef)
    }
}

struct MomentDTO: Decodable {
    let id: String
    let placeId: String
    let authorId: String
    let authorNickname: String
    let photoRef: String
    let photoUrl: String?
    let caption: String?
    let companion: String?
    let vibe: String?
    let latitude: Double
    let longitude: Double
    let visibility: String
    let createdAt: Date

    var moment: Moment {
        Moment(id: UUID(uuidString: id) ?? UUID(),
               placeID: UUID(uuidString: placeId) ?? UUID(),
               authorID: UUID(uuidString: authorId) ?? UUID(),
               photoRef: photoRef,
               caption: caption,
               companion: companion.flatMap(Companion.init(rawValue:)),
               vibe: vibe.flatMap(VibeTag.init(rawValue:)),
               coordinate: Coordinate(latitude: latitude, longitude: longitude),
               createdAt: createdAt,
               visibility: MomentVisibility(rawValue: visibility) ?? .publicExhibit,
               syncState: .synced)
    }
}

public struct PhotoDTO: Decodable {
    public let ref: String
    public let url: String?
}

// MARK: - Request bodies (encoded via convertToSnakeCase)

struct GuestBody: Encodable { let nickname: String? }
struct OAuthBody: Encodable { let provider: String; let token: String; let nickname: String? }
struct ResolveBody: Encodable {
    let latitude: Double
    let longitude: Double
    let radiusM: Double
    let name: String?
}
struct MomentCreateBody: Encodable {
    let placeId: String
    let photoRef: String
    let latitude: Double
    let longitude: Double
    let caption: String?
    let companion: String?
    let vibe: String?
    let visibility: String
}
struct ReportBody: Encodable { let reason: String? }
struct EmptyBody: Encodable {}
