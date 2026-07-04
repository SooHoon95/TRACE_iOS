import SwiftUI
import Combine
import UIComponent
import Domain
import Router

/// S13 · 나 / 프로필 — Avatar + 통계 3칸 + TRACE WRAPPED(준비 중) + 설정 진입.
/// Ported 1:1 from the claude.ai/design `TRACE 나·설정` board. Navigation goes through the coordinator.
public struct ProfileView: View {
    let user: User
    let nav: PassthroughSubject<NavigationEvent<TraceRoute>, Never>
    @StateObject private var vm: ProfileViewModel

    public init(user: User,
                store: any TraceStore,
                nav: PassthroughSubject<NavigationEvent<TraceRoute>, Never>) {
        self.user = user
        self.nav = nav
        _vm = StateObject(wrappedValue: ProfileViewModel(store: store, userID: user.id))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileBlock
                statsRow.padding(.bottom, 22)
                wrappedCard.padding(.bottom, 14)
                TraceButton("여행 정체성 카드 보기", variant: .soft, size: .lg) {}
                settingsRow.padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await vm.load() }
    }

    private var profileBlock: some View {
        VStack(spacing: 12) {
            Avatar(name: user.nickname, size: .lg, ring: true)
            VStack(spacing: 5) {
                Text(user.nickname)
                    .traceType(.displaySM).fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textPrimary)
                Text("여행자 · \(Self.joinText(user.createdAt)) 합류")
                    .traceType(.bodySM).fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textMuted)
            }
        }
        .padding(.vertical, 24)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            stat(vm.momentCount, "순간")
            stat(vm.placeCount, "장소")
            stat(vm.joinedCount, "합류한 자리")
        }
    }

    private static func joinText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM"
        return f.string(from: date)
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .traceType(.displaySM).fontWeight(.heavy)
                .foregroundStyle(TraceColor.accentStrong)
            Text(label)
                .traceType(.bodySM).fontWeight(.semibold)
                .foregroundStyle(TraceColor.textMuted)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
            .strokeBorder(TraceColor.hairline, lineWidth: 1))
    }

    private var wrappedCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TRACE WRAPPED")
                    .traceType(.eyebrow)
                    .foregroundStyle(TraceColor.accentSoft)
                Spacer()
                Text("준비 중")
                    .traceType(.bodyXS).fontWeight(.bold)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
                    .padding(.vertical, 4).padding(.horizontal, 9)
                    .background(TraceColor.surfaceDarkCard, in: Capsule())
            }
            VStack(spacing: 10) {
                Text("⌖")
                    .font(.system(size: 24))
                    .foregroundStyle(TraceColor.accentSoft)
                    .frame(width: 52, height: 52)
                    .background(TraceColor.surfaceDarkCard, in: Circle())
                Text("너의 여행 정체성, 곧 만나요")
                    .traceType(.bodyLG).fontWeight(.bold)
                    .foregroundStyle(TraceColor.paper0)
                Text("순간이 쌓이면 너만의 칭호와\n발자취 카드가 열려요.")
                    .traceType(.bodySM)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }
            .padding(.top, 22).padding(.bottom, 8)
        }
        .padding(22)
        .background(
            LinearGradient(colors: [TraceColor.char700, TraceColor.char900],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous)
            .strokeBorder(TraceColor.surfaceDarkLine, lineWidth: 1))
    }

    private var settingsRow: some View {
        Button {
            nav.send(.push(.settings))
        } label: {
            HStack {
                Text("설정")
                    .traceType(.bodyLG).fontWeight(.bold)
                    .foregroundStyle(TraceColor.textPrimary)
                Spacer()
                Text("›").font(.system(size: 18)).foregroundStyle(TraceColor.textFaint)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(TraceColor.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
