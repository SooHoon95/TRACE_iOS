import Foundation

/// Maps a provider to its native sign-in implementation. Mirrors Mercury's `SignInProviderFactory`.
public final class SignInProviderFactory {
    public init() {}

    public func createProvider(provider: OauthProvider) -> OauthSignInable {
        switch provider {
        case .apple:  return AppleSignInProvider()
        case .google: return GoogleSignInProvider()
        case .kakao:  return KakaoSignInProvider()
        }
    }
}
