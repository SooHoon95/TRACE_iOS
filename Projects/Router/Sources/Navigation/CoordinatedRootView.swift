import SwiftUI

/// Reusable host that wires a `NavigationCoordinator` + `ViewFactory` into a `NavigationStack`
/// with a full-screen cover. Encapsulates the glue Mercury duplicated per sample app, so every
/// tab/app root just supplies its coordinator, factory, and root route.
///
/// The caller owns the coordinator (`@StateObject` it), which lets a tab bar keep one coordinator
/// per tab while a parent owns an app-level one for full-screen flows (login/onboarding).
public struct CoordinatedRootView<Factory: ViewFactory>: View {
  @ObservedObject private var coordinator: NavigationCoordinator<Factory.ScreenRoute>
  private let factory: Factory
  private let root: Factory.ScreenRoute
  
  public init(coordinator: NavigationCoordinator<Factory.ScreenRoute>,
              factory: Factory,
              root: Factory.ScreenRoute) {
    self.coordinator = coordinator
    self.factory = factory
    self.root = root
  }
  
  public var body: some View {
    NavigationStack(path: $coordinator.rootStack) {
      factory.makeView(root, navigationStream: coordinator.eventSubject)
        .navigationDestination(for: Factory.ScreenRoute.self) { route in
          factory.makeView(route, navigationStream: coordinator.eventSubject)
        }
    }
    .fullScreenCover(isPresented: $coordinator.isFullScreenPresented) {
      if let route = coordinator.fullScreenRoute {
        NavigationStack(path: $coordinator.fullScreenStack) {
          factory.makeView(route, navigationStream: coordinator.eventSubject)
            .navigationDestination(for: Factory.ScreenRoute.self) { route in
              factory.makeView(route, navigationStream: coordinator.eventSubject)
            }
        }
      }
    }
    .environmentObject(coordinator)
  }
}
