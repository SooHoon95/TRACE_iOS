import Foundation
import Domain

/// Wraps a remote `TraceStore` to make claiming offline-first. `leave` enqueues to a durable
/// outbox and uploads in the background; an offline/transient failure is swallowed so the user
/// still gets their "합류" confirmation, and the moment syncs on the next opportunity. Reads pass
/// through and opportunistically drain the outbox.
///
/// Only network/transient failures are queued — a permanent 4xx still throws so real errors surface.
public struct OfflineFirstTraceStore: TraceStore {
    private let remote: any TraceStore
    private let outbox: MomentOutbox

    public init(remote: any TraceStore, outbox: MomentOutbox = MomentOutbox()) {
        self.remote = remote
        self.outbox = outbox
    }

    /// Upload every queued moment; stop at the first still-failing one (still offline / server down).
    @discardableResult
    public func flush() async -> Int {
        var sent = 0
        for moment in await outbox.all() {
            do {
                try await remote.leave(moment)
                await outbox.remove(id: moment.id)
                sent += 1
            } catch is URLError {
                break  // still offline — keep the rest queued
            } catch let error as APIError where error.status >= 500 {
                break  // server hiccup — retry later
            } catch {
                // permanent failure (4xx / decoding) — drop so it can't wedge the queue forever
                await outbox.remove(id: moment.id)
            }
        }
        return sent
    }

    // MARK: MomentRepository (write)

    public func leave(_ moment: Moment) async throws {
        do {
            try await remote.leave(moment)
        } catch is URLError {
            await outbox.enqueue(moment)  // offline → optimistic success, sync later
        } catch let error as APIError where error.status >= 500 {
            await outbox.enqueue(moment)  // transient server error → queue
        }
        await flush()
    }

    // MARK: pass-throughs (reads opportunistically drain the outbox)

    public func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place] {
        Task { await flush() }
        return try await remote.nearby(c, radiusMeters: radiusMeters)
    }

    public func resolveOrCreate(at c: Coordinate,
                                snapRadiusMeters: Double,
                                suggestedName: String?) async throws -> Place {
        try await remote.resolveOrCreate(at: c, snapRadiusMeters: snapRadiusMeters,
                                         suggestedName: suggestedName)
    }

    public func place(id: UUID) async throws -> Place {
        try await remote.place(id: id)
    }

    public func exhibition(placeID: UUID) async throws -> Exhibition {
        Task { await flush() }
        return try await remote.exhibition(placeID: placeID)
    }

    public func mine(authorID: UUID) async throws -> [Moment] {
        try await remote.mine(authorID: authorID)
    }

    public func feed(near c: Coordinate?) async throws -> [Moment] {
        Task { await flush() }
        return try await remote.feed(near: c)
    }

    public func report(momentID: UUID, by userID: UUID) async throws {
        try await remote.report(momentID: momentID, by: userID)
    }

    public func hide(momentID: UUID, by userID: UUID) async throws {
        try await remote.hide(momentID: momentID, by: userID)
    }
}
