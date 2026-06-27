import Foundation

/// In-memory backing for Phase-1 development — no cloud, no device required.
///
/// Conforms to **both** place & moment repositories so a left moment immediately shows up
/// in its place's exhibition, feed, and 도감. Swapped for the Supabase impls in Phase 2.
/// An `actor` makes `resolveOrCreate` atomic (no duplicate-place races) for free.
public actor InMemoryTraceStore: PlaceRepository, MomentRepository {
    private var places: [Place]
    private var moments: [Moment]
    /// Soft-removed from public surfaces. Mock conflates report+hide; production splits them
    /// (report → review queue; hide → per-viewer). Author still sees their own in 도감.
    private var suppressed: Set<UUID> = []

    public init(seed: TraceSeed = .empty) {
        self.places = seed.places
        self.moments = seed.moments
    }

    // MARK: - PlaceRepository

    public func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place] {
        places
            .map { ($0, GeoMath.distanceMeters(from: c, to: $0.coordinate)) }
            .filter { $0.1 <= radiusMeters }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    public func resolveOrCreate(at c: Coordinate,
                                snapRadiusMeters: Double,
                                suggestedName: String?) async throws -> Place {
        // Snap to the NEAREST place within radius (not the first found) to curb dup spots.
        let nearest = places
            .map { ($0, GeoMath.distanceMeters(from: c, to: $0.coordinate)) }
            .filter { $0.1 <= snapRadiusMeters }
            .min { $0.1 < $1.1 }?.0
        if let nearest { return nearest }

        let ref: PlaceRef = suggestedName.map { .poi(providerID: "mock", name: $0) }
            ?? .coordinate(name: nil)
        let place = Place(ref: ref,
                          coordinate: c,
                          displayName: suggestedName ?? Place.unnamed)
        places.append(place)
        return place
    }

    public func place(id: UUID) async throws -> Place {
        guard let p = places.first(where: { $0.id == id }) else { throw PlaceError.notFound }
        return p
    }

    // MARK: - MomentRepository

    public func leave(_ moment: Moment) async throws {
        var m = moment
        m.syncState = .synced   // mock "uploads" instantly
        moments.append(m)
        recomputeAggregates(placeID: m.placeID)
    }

    public func exhibition(placeID: UUID) async throws -> Exhibition {
        let place = try await place(id: placeID)
        let visible = publicMoments
            .filter { $0.placeID == placeID }
            .sorted { $0.createdAt > $1.createdAt }
        return Exhibition(place: place, moments: visible)
    }

    public func mine(authorID: UUID) async throws -> [Moment] {
        moments
            .filter { $0.authorID == authorID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func feed(near c: Coordinate?) async throws -> [Moment] {
        var pool = publicMoments
        if let c {
            pool.sort {
                GeoMath.distanceMeters(from: c, to: $0.coordinate)
                    < GeoMath.distanceMeters(from: c, to: $1.coordinate)
            }
        } else {
            pool.sort { $0.createdAt > $1.createdAt }
        }
        return pool
    }

    public func report(momentID: UUID, by userID: UUID) async throws {
        suppress(momentID)
    }

    public func hide(momentID: UUID, by userID: UUID) async throws {
        suppress(momentID)
    }

    // MARK: - private

    private var publicMoments: [Moment] {
        moments.filter { $0.isPublic && !suppressed.contains($0.id) }
    }

    private func suppress(_ id: UUID) {
        suppressed.insert(id)
        if let m = moments.first(where: { $0.id == id }) {
            recomputeAggregates(placeID: m.placeID)
        }
    }

    private func recomputeAggregates(placeID: UUID) {
        guard let idx = places.firstIndex(where: { $0.id == placeID }) else { return }
        let pub = publicMoments
            .filter { $0.placeID == placeID }
            .sorted { $0.createdAt > $1.createdAt }
        places[idx].momentCount = pub.count
        places[idx].contributorCount = Set(pub.map(\.authorID)).count
        places[idx].coverPhotoRef = pub.first?.photoRef
    }
}

/// Seed data for the in-memory store (demo places + moments so screens look alive).
public struct TraceSeed: Sendable {
    public let places: [Place]
    public let moments: [Moment]

    public init(places: [Place], moments: [Moment]) {
        self.places = places
        self.moments = moments
    }

    public static let empty = TraceSeed(places: [], moments: [])
}

// MARK: - Mock auth (Phase 1)

/// Local fake auth: sign-in just mints a user; guest is read-only per the flow.
@MainActor
public final class InMemoryAuthService: AuthService {
    public private(set) var current: User?

    public init(current: User? = nil) {
        self.current = current
    }

    public func signInApple() async throws -> User {
        let u = User(nickname: "여행자", authProvider: .apple)
        current = u
        return u
    }

    public func signInKakao() async throws -> User {
        let u = User(nickname: "여행자", authProvider: .kakao)
        current = u
        return u
    }

    public func continueAsGuest() -> User {
        let u = User(nickname: "게스트", authProvider: .guest)
        current = u
        return u
    }

    public func signOut() async throws {
        current = nil
    }
}

// MARK: - Mock photo store (Phase 1)

/// Keeps uploaded data in memory and hands back a synthetic ref/URL. Phase-1 screens
/// render placeholder visuals, so this only needs to round-trip a key.
public actor LocalPhotoStore: PhotoStore {
    private var blobs: [String: Data] = [:]

    public init() {}

    @discardableResult
    public func upload(_ data: Data, key: String) async throws -> String {
        blobs[key] = data
        return key
    }

    public func url(for ref: String) async -> URL? {
        URL(string: "memory://photo/\(ref)")
    }
}
