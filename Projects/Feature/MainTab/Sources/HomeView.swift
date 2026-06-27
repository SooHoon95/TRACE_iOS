import SwiftUI
import UIComponent
import Domain
import LeaveTrace

/// Loads the home feed (recent public moments + nearby places) from the shared store.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var recent: [Moment] = []
    @Published private(set) var nearby: [Place] = []
    @Published private(set) var isLoading = false

    private let store: any TraceStore
    init(store: any TraceStore) { self.store = store }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        recent = (try? await store.feed(near: nil)) ?? []
        nearby = (try? await store.nearby(Demo.seongsan.coordinate, radiusMeters: 1_000_000)) ?? []
    }

    func placeName(for moment: Moment) -> String {
        nearby.first { $0.id == moment.placeID }?.displayName ?? "어딘가"
    }
}

/// 🏠 홈 (활동·주변) — 인사 + 🔥방금 남들이 남긴 순간 + 📍내 주변 남길 자리 + ✨둘러볼 전시.
struct HomeView: View {
    @StateObject private var vm: HomeViewModel
    private let store: any TraceStore
    private let user: User
    @State private var claimingPlace: Place?

    init(store: any TraceStore, user: User) {
        self.store = store
        self.user = user
        _vm = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                greeting
                activitySection
                nearbySection
                exhibitionSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .task { await vm.load() }
        .sheet(item: $claimingPlace) { place in
            ClaimSheet(store: store, user: user, place: place)
        }
    }

    private var greeting: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘은 어디에 남길까?")
                    .traceType(.displayLG).fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textPrimary)
                Text("이 자리에 네 순간을 남겨봐")
                    .traceType(.bodyMD).foregroundStyle(TraceColor.textMuted)
            }
            Spacer()
            Avatar(name: user.nickname, size: .md)
        }
    }

    @ViewBuilder private var activitySection: some View {
        SectionHeader(title: "🔥 방금 남들이 남긴 순간")
        if vm.recent.isEmpty {
            emptyHint("아직 조용하네 — 네가 첫 순간을 남겨봐")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.recent) { moment in
                        ActivityFeedItem(placeName: vm.placeName(for: moment),
                                         vibe: moment.vibe,
                                         companion: moment.companion,
                                         timeAgo: Self.timeAgo(moment.createdAt))
                    }
                }
            }
        }
    }

    @ViewBuilder private var nearbySection: some View {
        SectionHeader(title: "📍 내 주변 남길 자리")
        VStack(spacing: 10) {
            ForEach(vm.nearby) { place in
                PlacePromptCard(placeName: place.displayName, distance: "근처",
                                onClaim: { claimingPlace = place })
            }
        }
    }

    @ViewBuilder private var exhibitionSection: some View {
        SectionHeader(title: "✨ 둘러볼 전시")
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(vm.nearby) { place in
                    ExhibitionTile(place: place.displayName,
                                   contributors: place.contributorCount,
                                   hasTop12: false)
                }
            }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .traceType(.bodyMD).foregroundStyle(TraceColor.textMuted)
            .frame(maxWidth: .infinity).padding(.vertical, 30)
    }

    private static func timeAgo(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date(timeIntervalSince1970: 1_718_001_000))
    }
}

/// The ＋ flow presented from a home "너도 남겨" tap, against the shared store.
private struct ClaimSheet: View {
    let store: any TraceStore
    let user: User
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LeaveTraceFeatureView(store: store, user: user, place: place)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Text("닫기").traceType(.bodyMD).fontWeight(.bold)
                                .foregroundStyle(TraceColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(TraceColor.paper50)
                }
        }
    }
}
