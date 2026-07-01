import Foundation

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

/// Kakao native login → OAuth **access token** (KakaoTalk app when installed, else the
/// account web flow). The backend verifies it via Kakao's `/v2/user/me`.
public struct KakaoTokenProvider: OAuthTokenProvider {
    public init() {}

    @MainActor
    public func token() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let accessToken = oauthToken?.accessToken else {
                    continuation.resume(throwing: AuthError.noProviderToken)
                    return
                }
                continuation.resume(returning: accessToken)
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
    }
}
