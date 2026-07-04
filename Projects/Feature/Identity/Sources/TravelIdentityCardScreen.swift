import SwiftUI
import UIKit
import UIComponent
import Domain

/// The sheet presented from the profile's "여행 정체성 카드 보기" button. Hosts the live card,
/// a close affordance, and the image-share button. Loads on appear; re-fetches `mine` every
/// entry so the card reflects newly-left moments.
struct TravelIdentityCardScreen: View {
    let user: User
    @StateObject private var vm: TravelIdentityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareItem?

    init(user: User, store: any TraceStore) {
        self.user = user
        _vm = StateObject(wrappedValue: TravelIdentityViewModel(store: store, userID: user.id))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let model = vm.model {
                        VStack(spacing: 18) {
                            TravelIdentityCardView(model: model,
                                                   name: user.nickname,
                                                   placeName: vm.dominantPlaceName)
                            if model.dataLevel != .empty {
                                TraceButton("카드 공유", variant: .primary, size: .lg) {
                                    share(model)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
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
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.image])
        }
    }

    /// Render the current card to a `UIImage` and hand it to the system share sheet.
    @MainActor
    private func share(_ model: TravelIdentityModel) {
        let card = TravelIdentityCardView(model: model,
                                          name: user.nickname,
                                          placeName: vm.dominantPlaceName)
        if let image = card.traceSnapshot() {
            shareItem = ShareItem(image: image)
        }
    }
}

/// Wraps the rendered card image so `.sheet(item:)` can present it.
private struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Minimal bridge to the system share sheet (`UIActivityViewController`).
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
