import SwiftUI
import UIComponent
import Domain

/// Entry point for the LeaveTrace feature — the claim loop demoed end-to-end against the
/// in-memory store: 장소 전시 (newest-first grid) → "너도 남겨" → 순간 남기기 → 합류 → grid refreshes.
public struct LeaveTraceFeatureView: View {
    @StateObject private var vm: ClaimViewModel

    public init(store: any TraceStore = Demo.store(),
                user: User = .demo,
                photoStore: any PhotoStore = LocalPhotoStore(),
                place: Place = Demo.seongsan) {
        _vm = StateObject(wrappedValue: ClaimViewModel(store: store, user: user, photoStore: photoStore, place: place))
    }

    public var body: some View {
        PlaceExhibitionView(vm: vm)
    }
}
