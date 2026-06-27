import Foundation
import Domain

/// Durable outbox for offline-first claiming: moments that fail to upload (offline / server
/// hiccup) are persisted here as JSON and re-sent on the next launch or connectivity. An actor
/// so the (Sendable) store can enqueue/drain it from any task.
public actor MomentOutbox {
    private let url: URL
    private var pending: [Moment]

    public init(directory: URL? = nil, filename: String = "trace_outbox.json") {
        let dir = directory
            ?? (try? FileManager.default.url(for: .applicationSupportDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        url = dir.appendingPathComponent(filename)
        pending = Self.load(from: url)
    }

    public var count: Int { pending.count }

    public func all() -> [Moment] { pending }

    public func enqueue(_ moment: Moment) {
        pending.append(moment)
        persist()
    }

    public func remove(id: UUID) {
        pending.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func load(from url: URL) -> [Moment] {
        guard let data = try? Data(contentsOf: url),
              let moments = try? JSONDecoder().decode([Moment].self, from: data)
        else { return [] }
        return moments
    }
}
