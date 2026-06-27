import SwiftUI
import Combine
import Domain
import Router

/// Maps the 나-tab's routes to their screens. Conforms to the ported `ViewFactory`.
/// Holds the session `user` so 프로필/설정 know member vs guest.
struct IdentityViewFactory: ViewFactory {
    let user: User

    @ViewBuilder
    func makeView(_ route: TraceRoute,
                  navigationStream: PassthroughSubject<NavigationEvent<TraceRoute>, Never>) -> some View {
        switch route {
        case .profile:
            ProfileView(user: user, nav: navigationStream)
        case .settings:
            SettingsView(user: user, nav: navigationStream)
        default:
            EmptyView()
        }
    }
}
