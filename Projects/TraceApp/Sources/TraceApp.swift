import SwiftUI
import MainTab
import Onboard
import UIComponent
import Domain
import Infrastructure

/// Composition root + session gate. Owns the shared store and the current session.
///
/// Login-first: in HTTP-backend mode the app starts signed-out and shows Onboard
/// (Apple/Kakao) — there is no guest path. In the in-memory mock mode (no backend
/// configured) the gate is skipped so the app always runs for design/dev without infra.
@MainActor
final class SessionStore: ObservableObject {
  let store: any TraceStore
  let photoStore: any PhotoStore
  @Published private(set) var user: User?

  private let auth: HTTPAuthService?
  private let offlineStore: OfflineFirstTraceStore?

  init() {
    SocialAuthConfigurator.configure()  // init Kakao/Google SDKs (no-op without keys)
    if let client = BackendProvider.makeClient() {
      // Offline-first: claims queue locally and sync in the background (T2.8).
      let offline = OfflineFirstTraceStore(remote: HTTPTraceStore(client: client))
      store = offline
      offlineStore = offline
      photoStore = HTTPPhotoStore(client: client)  // real /photos upload
      auth = HTTPAuthService(client: client)
      user = nil  // login-first — a session arrives only after Apple/Kakao sign-in (T2.6)
      print("[TRACE] backend = HTTP API (\(BackendProvider.baseURLFromBundle() ?? "?")) — login required")
    } else {
      store = Demo.store()
      offlineStore = nil
      photoStore = LocalPhotoStore()  // in-memory mock upload
      auth = nil
      user = .demo  // mock/dev: no backend, no gate — straight into the app
      print("[TRACE] backend = in-memory mock (no TRACE_API_BASE_URL)")
    }
  }

  func signInApple() async throws { try await signIn { try await $0.signInApple() } }
  func signInKakao() async throws { try await signIn { try await $0.signInKakao() } }
  func signInGoogle() async throws { try await signIn { try await $0.signInGoogle() } }

  /// Runs a provider flow, promotes its result to the active session, and drains any
  /// moments queued offline on a previous run now that authed calls will succeed.
  private func signIn(_ flow: (HTTPAuthService) async throws -> User) async throws {
    guard let auth else { return }
    user = try await flow(auth)
    await offlineStore?.flush()
  }

  func signOut() async {
    try? await auth?.signOut()
    user = nil
  }
}

@main
struct TraceApp: App {
  @StateObject private var session = SessionStore()

  var body: some Scene {
    WindowGroup {
      Group {
        if let user = session.user {
          MainTabFeatureView(
            store: session.store,
            user: user,
            photoStore: session.photoStore,
            onSignOut: { Task { await session.signOut() } }
          )
        } else {
          OnboardFeatureView(
            onSignInApple: { try await session.signInApple() },
            onSignInKakao: { try await session.signInKakao() },
            onSignInGoogle: { try await session.signInGoogle() }
          )
        }
      }
      .onOpenURL { url in
        _ = SocialAuthConfigurator.handle(url: url)  // route Kakao/Google OAuth redirects
      }
    }
  }
}
