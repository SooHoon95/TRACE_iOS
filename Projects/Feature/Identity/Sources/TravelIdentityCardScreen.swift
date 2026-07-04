import SwiftUI
import UIComponent
import Domain

/// The sheet presented from the profile's "여행 정체성 카드 보기" button. Hosts the live card,
/// a close affordance, and (Task 6) the image-share button. Loads on appear; re-fetches `mine`
/// every entry so the card reflects newly-left moments.
struct TravelIdentityCardScreen: View {
    let user: User
    @StateObject private var vm: TravelIdentityViewModel
    @Environment(\.dismiss) private var dismiss

    init(user: User, store: any TraceStore) {
        self.user = user
        _vm = StateObject(wrappedValue: TravelIdentityViewModel(store: store, userID: user.id))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let model = vm.model {
                        TravelIdentityCardView(model: model,
                                               name: user.nickname,
                                               placeName: vm.dominantPlaceName)
                            .padding(.vertical, 28)
                    } else {
                        TraceLoadingView()
                            .padding(.top, 100)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(TraceColor.paper50.ignoresSafeArea())
            .navigationTitle("여행 정체성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(TraceColor.textPrimary)
                }
            }
        }
        .task { await vm.load() }
    }
}
