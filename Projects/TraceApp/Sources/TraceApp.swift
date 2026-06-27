import SwiftUI
import MainTab
import UIComponent
import Domain
import Infrastructure

/// Composition root — owns the single shared store + session and injects them into the app shell.
/// Uses the HTTP backend when `TRACE_API_BASE_URL` is configured (XCConfigs/Sensitive.xcconfig →
/// Info.plist), otherwise falls back to the in-memory mock so the app always runs.
@MainActor
final class AppContainer {
  let store: any TraceStore
  let user: User
  private let auth: HTTPAuthService?

  init() {
    if let client = BackendProvider.makeClient() {
      // Offline-first: claims queue locally and sync in the background (T2.8).
      let offline = OfflineFirstTraceStore(remote: HTTPTraceStore(client: client))
      store = offline
      let auth = HTTPAuthService(client: client)
      self.auth = auth
      // Account-free claiming until the login UI (T2.6) lands: fetch an anonymous
      // session token in the background so authed calls (resolve/leave) succeed,
      // then drain any moments queued offline on a previous run.
      Task {
        try? await auth.bootstrapGuest()
        await offline.flush()
      }
      print("[TRACE] backend = HTTP API (\(BackendProvider.baseURLFromBundle() ?? "?"))")
    } else {
      store = Demo.store()
      auth = nil
      print("[TRACE] backend = in-memory mock (no TRACE_API_BASE_URL)")
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
