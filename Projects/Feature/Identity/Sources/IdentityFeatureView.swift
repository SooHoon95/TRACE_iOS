import SwiftUI
import UIComponent
import Domain
import Router

/// 나 탭 진입점 — 프로필(S13) → 설정(S14)을 ported Coordinator 패턴으로 호스팅.
/// 설정 진입/뒤로가기가 `NavigationCoordinator`를 통해 흐른다.
public struct IdentityFeatureView: View {
  let user: User
  @StateObject private var coordinator = NavigationCoordinator<TraceRoute>()

  /// Default demo user (signed-in). Pass `User(..., authProvider: .guest)` to preview the guest 설정.
  public init(user: User = User(nickname: "지민", authProvider: .apple)) {
    self.user = user
  }

  public var body: some View {
    CoordinatedRootView(coordinator: coordinator,
                        factory: IdentityViewFactory(user: user),
                        root: .profile)
  }
}
