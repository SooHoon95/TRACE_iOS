import SwiftUI
import UIComponent
import Domain

/// Pre-auth entry. Login-first: the only way in is Apple or Kakao — no guest path.
/// The actual provider exchange is injected; defaults throw `notConfigured` so the
/// screen degrades gracefully until the real Apple cert / Kakao key land (T2.6).
public struct OnboardFeatureView: View {
  public typealias SignInAction = () async throws -> Void

  private let onSignInApple: SignInAction
  private let onSignInKakao: SignInAction
  private let onSignInGoogle: SignInAction

  @State private var isSigningIn = false
  @State private var errorMessage: String?

  public init(
    onSignInApple: @escaping SignInAction = { throw OnboardError.notConfigured },
    onSignInKakao: @escaping SignInAction = { throw OnboardError.notConfigured },
    onSignInGoogle: @escaping SignInAction = { throw OnboardError.notConfigured }
  ) {
    self.onSignInApple = onSignInApple
    self.onSignInKakao = onSignInKakao
    self.onSignInGoogle = onSignInGoogle
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

        // MARK: — Login (Apple / Kakao only — no guest)
        VStack(spacing: TraceSpace.s3) {
          if let errorMessage {
            Text(errorMessage)
              .traceType(.bodySM)
              .foregroundStyle(TraceColor.accentStrong)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
          }

          // TODO(T2.6): swap for the official SignInWithAppleButton once the Apple
          // entitlement/cert is provisioned; styled button keeps dev buildable today.
          ProviderButton(
            title: "Apple로 계속하기",
            symbol: "apple.logo",
            background: .black,
            foreground: .white
          ) { signIn(onSignInApple) }

          ProviderButton(
            title: "카카오로 계속하기",
            symbol: "message.fill",
            background: Self.kakaoYellow,
            foreground: .black
          ) { signIn(onSignInKakao) }

          ProviderButton(
            title: "Google로 계속하기",
            background: TraceColor.paper0,
            foreground: TraceColor.textPrimary,
            border: TraceColor.hairline
          ) { signIn(onSignInGoogle) }

          Text("계속하면 서비스 약관과 개인정보 처리방침에 동의하는 것으로 간주돼요.")
            .traceType(.bodySM)
            .foregroundStyle(TraceColor.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, TraceSpace.s1)
        }
        .disabled(isSigningIn)
        .padding(.bottom, TraceSpace.s10)
      }
      .padding(.horizontal, TraceSpace.s6)

      if isSigningIn {
        Color.black.opacity(0.08).ignoresSafeArea()
        ProgressView()
          .controlSize(.large)
          .tint(TraceColor.accent)
      }
    }
  }

  // Kakao brand color (#FEE500) — not part of the app palette, scoped to this screen.
  private static let kakaoYellow = Color(red: 254 / 255, green: 229 / 255, blue: 0)

  private func signIn(_ action: @escaping SignInAction) {
    Task { @MainActor in
      isSigningIn = true
      errorMessage = nil
      do {
        try await action()
      } catch {
        errorMessage = "로그인 연동은 곧 지원돼요. 조금만 기다려 주세요."
      }
      isSigningIn = false
    }
  }
}

/// Errors surfaced by the onboarding sign-in flow.
public enum OnboardError: Error {
  /// No real provider wired yet (default injected action).
  case notConfigured
}

// MARK: — Provider login button

/// Brand-styled full-width login button (Apple / Kakao). Mirrors TraceButton's
/// press feel via the shared `TracePressStyle`, but carries provider brand colors.
private struct ProviderButton: View {
  let title: String
  var symbol: String? = nil
  let background: Color
  let foreground: Color
  var border: Color = .clear
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: TraceSpace.s2) {
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
        }
        Text(title)
          .font(TraceType.bodyLG.font.weight(TraceWeight.semibold))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 15)
      .padding(.horizontal, 26)
      .foregroundStyle(foreground)
      .background(background, in: RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
          .strokeBorder(border, lineWidth: 1)
      )
    }
    .buttonStyle(TracePressStyle())
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
