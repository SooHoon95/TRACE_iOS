import Foundation

import GoogleSignIn
import KakaoSDKCommon

/// Initializes the social-login SDKs from bundle keys (Info.plist ← Sensitive.xcconfig):
/// `KAKAO_NATIVE_APP_KEY` and `GIDClientID`. Each init is a no-op when its key is absent,
/// so the app still launches unconfigured (e.g. mock mode). Call `configure()` at launch;
/// route the app's `.onOpenURL` through `OauthDeepLinkHandler.shared`.
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
}
