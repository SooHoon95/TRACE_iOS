import SwiftUI
import MainTab
import UIComponent
import Domain

/// Composition root — owns the single shared store + session and injects them into the app shell.
/// Phase 2 swaps `Demo.store()` for the Supabase-backed store and the real AuthService session.
@MainActor
final class AppContainer {
  let store: any TraceStore = Demo.store()
  let user: User = .demo
}

@main
struct TraceApp: App {
  private let container = AppContainer()

  var body: some Scene {
    WindowGroup {
      MainTabFeatureView(store: container.store, user: container.user)
    }
  }
}
