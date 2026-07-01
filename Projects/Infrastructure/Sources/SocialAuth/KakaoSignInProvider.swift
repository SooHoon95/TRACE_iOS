import Foundation

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

/// Kakao native login → OAuth **access token** (KakaoTalk app when available, else account web).
/// Mirrors Mercury's `KakaoSignInProvider`.
public final class KakaoSignInProvider: OauthSignInable {
    public init() {}

    private func kakaoTalkLogin(continuation: CheckedContinuation<OauthSignInToken, any Error>) {
        UserApi.shared.loginWithKakaoTalk { oauthToken, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let token = oauthToken?.accessToken else {
                continuation.resume(throwing: AuthError.noProviderToken)
                return
            }
            continuation.resume(returning: token)
        }
    }

    private func kakaoAccountLogin(continuation: CheckedContinuation<OauthSignInToken, any Error>) {
        UserApi.shared.loginWithKakaoAccount { oauthToken, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let token = oauthToken?.accessToken else {
                continuation.resume(throwing: AuthError.noProviderToken)
                return
            }
            continuation.resume(returning: token)
        }
    }

    @MainActor
    public func signIn() async throws -> OauthSignInToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.isKakaoTalkLoginAvailable()
                ? kakaoTalkLogin(continuation: continuation)
                : kakaoAccountLogin(continuation: continuation)
        }
    }
}
