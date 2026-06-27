import Foundation
import Domain

/// `PhotoStore` backed by the API's `/photos` endpoints. Local backend serves from
/// `/photos/{ref}`; with OCI Object Storage the same ref resolves to its public URL
/// (the moment payload also carries `photo_url`), so only the backend config changes.
public struct HTTPPhotoStore: PhotoStore {
    private let client: TraceAPIClient

    public init(client: TraceAPIClient) {
        self.client = client
    }

    @discardableResult
    public func upload(_ data: Data, key: String) async throws -> String {
        let dto = try await client.uploadPhoto(data, filename: key)
        return dto.ref
    }

    public func url(for ref: String) async -> URL? {
        client.photoURL(for: ref)
    }
}
