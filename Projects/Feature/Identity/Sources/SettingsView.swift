import SwiftUI
import Combine
import UIComponent
import Domain
import Router

/// S14 · 설정 — 계정·백업·공개·안전. Guest variant swaps 백업·공개 for a 가입 유도 카드.
/// Ported 1:1 from the claude.ai/design `TRACE 나·설정` board. Back goes through the coordinator.
public struct SettingsView: View {
    let user: User
    let nav: PassthroughSubject<NavigationEvent<TraceRoute>, Never>
    let onSignOut: () -> Void
    @State private var publicRange = 0   // 0 = 전시 공개, 1 = 나만

    public init(user: User,
                nav: PassthroughSubject<NavigationEvent<TraceRoute>, Never>,
                onSignOut: @escaping () -> Void = {}) {
        self.user = user
        self.nav = nav
        self.onSignOut = onSignOut
    }

    private var isGuest: Bool { user.isGuest }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if isGuest { guestBody } else { memberBody }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { nav.send(.pop) } label: {
                Text("‹").font(.system(size: 26)).foregroundStyle(TraceColor.textSecondary)
            }
            Text("설정").traceType(.displaySM).fontWeight(.heavy)
                .foregroundStyle(TraceColor.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 10)
    }

    // MARK: member

    @ViewBuilder private var memberBody: some View {
        section("계정") {
            row("닉네임", trailing: { disclosure(user.nickname) }, divider: true)
            row("로그인", trailing: {
                Text(user.authProvider == .kakao ? "Kakao" : "Apple")
                    .traceType(.bodyMD).fontWeight(.semibold).foregroundStyle(TraceColor.textSecondary)
            }, divider: true)
            actionRow("로그아웃") { onSignOut() }
        }
        section("백업") {
            row("클라우드 백업", trailing: {
                HStack(spacing: 6) {
                    Circle().fill(TraceColor.coral500).frame(width: 7, height: 7)
                    Text("켜짐 · 자동").traceType(.bodyMD).fontWeight(.bold)
                        .foregroundStyle(TraceColor.accentStrong)
                }
            }, divider: true)
            row("마지막 백업", trailing: {
                Text("방금").traceType(.bodyMD).foregroundStyle(TraceColor.textMuted)
            })
        }
        publicRangeSection
        section("안전") {
            row("차단·신고 내역", trailing: { chevron }, divider: true)
            row("이용약관", trailing: { chevron }, divider: true)
            row("개인정보 처리방침", trailing: { chevron })
        }
    }

    private var publicRangeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("공개")
            VStack(alignment: .leading, spacing: 12) {
                Text("새 순간 기본 공개범위")
                    .traceType(.bodyMD).fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textPrimary)
                HStack(spacing: 4) {
                    segment("전시 공개", index: 0)
                    segment("나만", index: 1)
                }
                .padding(4)
                .background(TraceColor.paper100, in: Capsule())
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TraceColor.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1))
            .padding(.top, 9)
        }
    }

    private func segment(_ title: String, index: Int) -> some View {
        let on = publicRange == index
        return Text(title)
            .traceType(.bodyMD).fontWeight(.bold)
            .foregroundStyle(on ? TraceColor.paper0 : TraceColor.textSecondary)
            .frame(maxWidth: .infinity).frame(height: 36)
            .background(on ? TraceColor.accent : .clear, in: Capsule())
            .contentShape(Capsule())
            .onTapGesture { publicRange = index }
    }

    // MARK: guest

    @ViewBuilder private var guestBody: some View {
        section("계정") {
            row("상태", trailing: {
                Text("게스트로 둘러보는 중").traceType(.bodyMD).fontWeight(.bold)
                    .foregroundStyle(TraceColor.textMuted)
            })
        }
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("가입하면 더 많은 걸 할 수 있어요")
                    .traceType(.bodyLG).fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textPrimary)
                Text("가입하면 백업과 도감을 쓸 수 있어요. 게스트는 전시 구경만 가능해요.")
                    .traceType(.bodyMD)
                    .foregroundStyle(TraceColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TraceButton("가입하기", variant: .primary, size: .lg) {}
        }
        .padding(20)
        .background(TraceColor.coralWash)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
            .strokeBorder(TraceColor.accentSoft, lineWidth: 1))
        section("안전") {
            row("이용약관", trailing: { chevron }, divider: true)
            row("개인정보 처리방침", trailing: { chevron })
        }
        actionRowBare("둘러보기 종료") { onSignOut() }
    }

    // MARK: building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel(title)
            VStack(spacing: 0) { content() }
                .background(TraceColor.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
                    .strokeBorder(TraceColor.hairline, lineWidth: 1))
                .padding(.top, 9)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .traceType(.bodyXS).fontWeight(.bold)
            .tracking(0.1 * 12)
            .foregroundStyle(TraceColor.textMuted)
            .padding(.leading, 4)
    }

    private func row<Trailing: View>(_ title: String,
                                     @ViewBuilder trailing: () -> Trailing,
                                     divider: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).traceType(.bodyMD).fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textPrimary)
                Spacer()
                trailing()
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
            if divider { Rectangle().fill(TraceColor.hairline).frame(height: 1) }
        }
    }

    private func disclosure(_ value: String) -> some View {
        HStack(spacing: 8) {
            Text(value).traceType(.bodyMD).foregroundStyle(TraceColor.textMuted)
            Text("›").font(.system(size: 18)).foregroundStyle(TraceColor.textFaint)
        }
    }

    private var chevron: some View {
        Text("›").font(.system(size: 18)).foregroundStyle(TraceColor.textFaint)
    }

    private func actionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).traceType(.bodyMD).fontWeight(.bold)
                    .foregroundStyle(TraceColor.accentStrong)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func actionRowBare(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).traceType(.bodyMD).fontWeight(.bold)
                    .foregroundStyle(TraceColor.accentStrong)
                Spacer()
            }
            .padding(.horizontal, 4).padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
