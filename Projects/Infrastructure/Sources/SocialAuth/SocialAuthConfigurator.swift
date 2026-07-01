import Foundation

import GoogleSignIn
import KakaoSDKCommon
import KakaoSDKAuth

/// Initializes the social-login SDKs and routes their OAuth redirect URLs.
///
/// Keys come from the app bundle (Info.plist ← Sensitive.xcconfig): `KAKAO_NATIVE_APP_KEY`
/// and `GIDClientID`. Each provider is a no-op when its key is absent, so the app still
/// launches unconfigured (e.g. mock mode). Call `configure()` at launch and route
/// `.onOpenURL` through `handle(url:)`.
public enum SocialAuthConfigurator {

    public static func configure() {
        if let kakaoKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String,
           !kakaoKey.isEmpty {
            KakaoSDK.initSDK(appKey: kakaoKey)
        }
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    /// Route an inbound OAuth redirect URL to whichever SDK owns it. Returns true if handled.
    @MainActor
    public static func handle(url: URL) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
}
