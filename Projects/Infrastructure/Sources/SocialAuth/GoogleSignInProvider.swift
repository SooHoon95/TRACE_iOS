import UIKit

import GoogleSignIn

/// Google native login → **id_token** (JWT). Mirrors Mercury's `GoogleSignInProvider`.
public final class GoogleSignInProvider: OauthSignInable {
    public init() {}

    @MainActor
    public func signIn() async throws -> OauthSignInToken {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.rootViewController else {
            throw AuthError.presentationFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let token = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.noProviderToken)
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
}
