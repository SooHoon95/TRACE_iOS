import Foundation

/// Abstracts photo storage so the backend is swappable: a local mock now,
/// Cloudflare R2 (presigned PUT, zero-egress URL reads) in Phase 2.
public protocol PhotoStore: Sendable {
    /// Store image data under `key`; returns the ref written to `Moment.photoRef`.
    @discardableResult
    func upload(_ data: Data, key: String) async throws -> String

    /// A retrievable URL for a stored ref (remote R2 URL in production; local in the mock).
    func url(for ref: String) async -> URL?
}
