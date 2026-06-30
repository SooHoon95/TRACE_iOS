import XCTest
import Domain
import UIComponent
@testable import LeaveTrace

/// Records what gets uploaded and hands back a fixed remote ref, so we can assert the
/// claim flow uploads the picked bytes and attaches the *returned* ref (not a synthetic one).
final class SpyPhotoStore: PhotoStore, @unchecked Sendable {
    let returnedRef: String
    private(set) var uploadedData: Data?
    private(set) var uploadCount = 0

    init(returnedRef: String) { self.returnedRef = returnedRef }

    func upload(_ data: Data, key: String) async throws -> String {
        uploadedData = data
        uploadCount += 1
        return returnedRef
    }

    func url(for ref: String) async -> URL? { nil }
}

final class LeaveTraceTests: XCTestCase {

    @MainActor
    func testClaimUploadsPhotoBytesAndAttachesReturnedRef() async {
        let store = Demo.store()
        let photos = SpyPhotoStore(returnedRef: "remote/abc-123.jpg")
        let vm = ClaimViewModel(store: store, user: .demo, photoStore: photos, place: Demo.seongsan)

        let bytes = Data([0xFF, 0xD8, 0xFF, 0x01, 0x02])
        let draft = CaptureComposer.Draft(
            caption: "첫 순간", companion: nil, vibe: nil,
            visibility: .publicExhibit, photoData: bytes
        )

        await vm.claim(draft)

        XCTAssertNil(vm.errorMessage, "claim should succeed")
        XCTAssertEqual(photos.uploadCount, 1, "exactly one upload")
        XCTAssertEqual(photos.uploadedData, bytes, "the picked bytes are uploaded verbatim")

        let refs = vm.exhibition?.moments.map(\.photoRef) ?? []
        XCTAssertTrue(refs.contains("remote/abc-123.jpg"),
                      "the left moment carries the storage ref returned by upload, got \(refs)")
    }

    @MainActor
    func testClaimWithoutPhotoBytesSkipsUpload() async {
        let store = Demo.store()
        let photos = SpyPhotoStore(returnedRef: "remote/should-not-be-used.jpg")
        let vm = ClaimViewModel(store: store, user: .demo, photoStore: photos, place: Demo.seongsan)

        // Catalog/preview path: no bytes → no upload, falls back to a synthetic ref.
        let draft = CaptureComposer.Draft(
            caption: nil, companion: nil, vibe: nil,
            visibility: .publicExhibit, photoData: nil
        )

        await vm.claim(draft)

        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(photos.uploadCount, 0, "no bytes → no upload")
    }
}
