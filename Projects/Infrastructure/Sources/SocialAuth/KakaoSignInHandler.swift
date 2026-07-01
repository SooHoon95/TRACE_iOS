import Foundation

import KakaoSDKAuth

/// Routes Kakao's OAuth redirect back into the Kakao SDK. Mirrors Mercury's `KakaoSignInHandler`.
public final class KakaoSignInHandler: @preconcurrency DeeplinkHandlable {
    public init() {}

    @MainActor
    public func handle(url: URL) -> Bool {
        AuthController.handleOpenUrl(url: url)
    }
}
