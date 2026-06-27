import SwiftUI
import MainTab
import UIComponent
import Domain
import Infrastructure

/// Composition root — owns the single shared store + session and injects them into the app shell.
/// Uses the Supabase-backed store when SUPABASE_* config is present (XCConfigs/Sensitive.xcconfig),
/// otherwise falls back to the in-memory mock so the app always runs.
@MainActor
final class AppContainer {
  let store: any TraceStore
  let user: User

  init() {
    let config = SupabaseProvider.configFromBundle()
    if let client = SupabaseProvider.makeClient(url: config.url, anonKey: config.anonKey) {
      store = SupabaseTraceStore(client: client)
      print("[TRACE] backend = Supabase")
    } else {
      store = Demo.store()
      print("[TRACE] backend = in-memory mock (no SUPABASE config)")
    }
    // Real session arrives via AuthService after login (Phase 2 auth UI). Demo user for now.
    user = .demo
  }
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
