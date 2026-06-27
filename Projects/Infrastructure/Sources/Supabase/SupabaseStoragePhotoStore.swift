import Foundation
import Domain
import Supabase

/// Photos in a Supabase Storage bucket (public read for the PoC). Swappable for R2 later
/// behind the same `PhotoStore` protocol — only this file changes.
public final class SupabaseStoragePhotoStore: PhotoStore {
    private let client: SupabaseClient
    private let bucket: String

    public init(client: SupabaseClient, bucket: String = "moment-photos") {
        self.client = client
        self.bucket = bucket
    }

    @discardableResult
    public func upload(_ data: Data, key: String) async throws -> String {
        // Caller (capture) compresses to JPEG; we just store under the moment's key.
        try await client.storage.from(bucket).upload(
            key, data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        return key
    }

    public func url(for ref: String) async -> URL? {
        try? client.storage.from(bucket).getPublicURL(path: ref)
    }
}
