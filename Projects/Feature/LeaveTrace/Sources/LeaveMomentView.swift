import SwiftUI
import Domain
import UIComponent

/// 순간 남기기 (claim modal) — hosts the photo-first `CaptureComposer`. On submit it
/// runs the core claim action; the FOMO line ("여기 N명이 남겼어") comes from the place's
/// current contributor count.
public struct LeaveMomentView: View {
    @ObservedObject var vm: ClaimViewModel

    public init(vm: ClaimViewModel) {
        self.vm = vm
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CaptureComposer(
                    place: vm.placeDisplayName,
                    contributorCount: vm.contributorCount
                ) { draft in
                    await vm.claim(draft)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .alert(
            "남기지 못했어요",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            ),
            actions: { Button("확인", role: .cancel) { vm.errorMessage = nil } },
            message: { Text(vm.errorMessage ?? "") }
        )
    }
}
