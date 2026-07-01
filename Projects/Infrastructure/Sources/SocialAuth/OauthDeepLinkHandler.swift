import Foundation

/// Dispatches an inbound OAuth redirect URL to the first handler that consumes it.
/// Mirrors Mercury's `OauthDeepLinkHandler`. Route the app's `.onOpenURL` here.
public final class OauthDeepLinkHandler {
    public static let shared = OauthDeepLinkHandler(handlers: [
        GoogleSignInHandler(),
        KakaoSignInHandler()
    ])

    private let handlers: [DeeplinkHandlable]

    private init(handlers: [DeeplinkHandlable]) {
        self.handlers = handlers
    }

    @MainActor
    public func handle(url: URL) {
        for handler in handlers where handler.handle(url: url) {
            return
        }
        print("Handler not found : \(url)")
    }
}
