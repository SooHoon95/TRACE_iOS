import SwiftUI
import UIComponent
import Domain

/// Entry point for the LeaveTrace feature — the claim loop demoed end-to-end against the
/// in-memory store: 장소 전시 (newest-first grid) → "너도 남겨" → 순간 남기기 → 합류 → grid refreshes.
public struct LeaveTraceFeatureView: View {
    @StateObject private var vm: ClaimViewModel

    public init() {
        let store = InMemoryTraceStore(seed: DemoData.seed())
        let user = User(nickname: "여행자", authProvider: .apple)
        _vm = StateObject(wrappedValue: ClaimViewModel(store: store, user: user, place: DemoData.place))
    }

    public var body: some View {
        PlaceExhibitionView(vm: vm)
    }
}
