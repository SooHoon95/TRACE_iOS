import SwiftUI
import UIComponent
import Domain

public struct OnboardFeatureView: View {
  private let onGuestStart: () -> Void
  private let onLogin: () -> Void

  public init(
    onGuestStart: @escaping () -> Void = {},
    onLogin: @escaping () -> Void = {}
  ) {
    self.onGuestStart = onGuestStart
    self.onLogin = onLogin
  }

  public var body: some View {
    ZStack {
      TraceColor.paper50.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {

        // MARK: — Hero
        VStack(alignment: .leading, spacing: TraceSpace.s2) {
          Text("TRACE")
            .traceType(.displayXL)
            .foregroundStyle(TraceColor.textPrimary)

          Text("이 자리에 순간을 남기고,\n누군가의 흔적을 발견하세요.")
            .traceType(.bodyLG)
            .foregroundStyle(TraceColor.textSecondary)
            .lineSpacing(4)
        }
        .padding(.top, TraceSpace.s10)

        Spacer()

        // MARK: — Value Props
        VStack(alignment: .leading, spacing: TraceSpace.s6) {
          ValuePropRow(
            symbol: "mappin.and.ellipse",
            title: "이 자리에 순간을 남겨요",
            subtitle: "사진 한 장으로 지금 여기를 마킹."
          )
          ValuePropRow(
            symbol: "figure.walk",
            title: "남의 흔적을 발견해요",
            subtitle: "같은 자리에 쌓인 다른 사람들의 순간."
          )
          ValuePropRow(
            symbol: "books.vertical",
            title: "도감에 모아요",
            subtitle: "내가 남긴 자리들이 컬렉션이 돼요."
          )
        }

        Spacer()

        // MARK: — Bottom CTAs
        VStack(spacing: TraceSpace.s3) {
          // Permissions note
          Text("위치와 카메라 권한은 지금 이 자리를 인증하고 사진을 남기는 데만 써요.")
            .traceType(.bodySM)
            .foregroundStyle(TraceColor.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

          TraceButton("게스트로 시작", variant: .primary, size: .lg) {
            onGuestStart()
          }

          TraceButton("로그인", variant: .ghost, size: .lg) {
            onLogin()
          }
        }
        .padding(.bottom, TraceSpace.s10)
      }
      .padding(.horizontal, TraceSpace.s6)
    }
  }
}

// MARK: — Value Prop Row

private struct ValuePropRow: View {
  let symbol: String
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: TraceSpace.s4) {
      ZStack {
        RoundedRectangle(cornerRadius: TraceRadius.sm, style: .continuous)
          .fill(TraceColor.coralWash)
          .frame(width: 44, height: 44)
        Image(systemName: symbol)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(TraceColor.accent)
      }

      VStack(alignment: .leading, spacing: TraceSpace.s1) {
        Text(title)
          .traceType(.bodyLG)
          .foregroundStyle(TraceColor.textPrimary)
        Text(subtitle)
          .traceType(.bodyMD)
          .foregroundStyle(TraceColor.textSecondary)
      }
    }
  }
}
