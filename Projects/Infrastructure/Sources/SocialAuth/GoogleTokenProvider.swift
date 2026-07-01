import UIKit

import GoogleSignIn

/// Google native login → **id_token** (JWT) via GoogleSignIn-iOS. The backend verifies it
/// against Google's JWKS (`verify_google`), checking the `aud` = configured client id.
public struct GoogleTokenProvider: OAuthTokenProvider {
    public init() {}

    @MainActor
    public func token() async throws -> String {
        guard let presenter = Self.presenter() else { throw AuthError.presentationFailed }
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.noProviderToken)
                    return
                }
                continuation.resume(returning: idToken)
            }
        }
    }

    private static func presenter() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.rootViewController
    }
}
