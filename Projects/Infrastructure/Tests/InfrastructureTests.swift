import XCTest
import Domain
@testable import Infrastructure

final class InfrastructureTests: XCTestCase {
  func testPlaceholder() {
    XCTAssertTrue(true)
  }
}

final class MomentOutboxTests: XCTestCase {

  /// A claim made offline is queued (and the user's `leave` still succeeds); a later flush
  /// while online drains it to the remote exactly once.
  func testOfflineClaimQueuesThenSyncsWhenOnline() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let outbox = MomentOutbox(directory: tmp)
    let remote = FakeRemote()
    let store = OfflineFirstTraceStore(remote: remote, outbox: outbox)

    let moment = Moment(placeID: UUID(), authorID: UUID(), photoRef: "p.jpg",
                        coordinate: Coordinate(latitude: 33.45, longitude: 126.94))

    // Offline: leave does NOT throw, the moment is queued, the remote receives nothing.
    await remote.setOnline(false)
    try await store.leave(moment)
    let queuedWhileOffline = await outbox.count
    let deliveredWhileOffline = await remote.deliveredCount
    XCTAssertEqual(queuedWhileOffline, 1)
    XCTAssertEqual(deliveredWhileOffline, 0)

    // Online: flush drains the queue to the remote, exactly once.
    await remote.setOnline(true)
    let sent = await store.flush()
    let queuedAfter = await outbox.count
    let deliveredAfter = await remote.deliveredCount
    XCTAssertEqual(sent, 1)
    XCTAssertEqual(queuedAfter, 0)
    XCTAssertEqual(deliveredAfter, 1)
  }

  /// The outbox persists across instances (survives relaunch).
  func testOutboxPersistsAcrossInstances() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let moment = Moment(placeID: UUID(), authorID: UUID(), photoRef: "p.jpg",
                        coordinate: Coordinate(latitude: 1, longitude: 2))
    let first = MomentOutbox(directory: tmp)
    await first.enqueue(moment)

    let reopened = MomentOutbox(directory: tmp)
    let restored = await reopened.count
    XCTAssertEqual(restored, 1)
  }
}

/// Minimal in-memory `TraceStore` that simulates offline (URLError) vs online for `leave`.
private actor FakeRemote: TraceStore {
  private var online = true
  private(set) var deliveredCount = 0

  func setOnline(_ value: Bool) { online = value }

  func leave(_ moment: Moment) async throws {
    if !online { throw URLError(.notConnectedToInternet) }
    deliveredCount += 1
  }

  func nearby(_ c: Coordinate, radiusMeters: Double) async throws -> [Place] { [] }
  func resolveOrCreate(at c: Coordinate, snapRadiusMeters: Double,
                       suggestedName: String?) async throws -> Place {
    Place(ref: .coordinate(name: nil), coordinate: c, displayName: "x")
  }
  func place(id: UUID) async throws -> Place { throw PlaceError.notFound }
  func exhibition(placeID: UUID) async throws -> Exhibition {
    Exhibition(place: Place(ref: .coordinate(name: nil),
                            coordinate: Coordinate(latitude: 0, longitude: 0),
                            displayName: "x"),
               moments: [])
  }
  func mine(authorID: UUID) async throws -> [Moment] { [] }
  func feed(near c: Coordinate?) async throws -> [Moment] { [] }
  func report(momentID: UUID, by userID: UUID) async throws {}
  func hide(momentID: UUID, by userID: UUID) async throws {}
}
