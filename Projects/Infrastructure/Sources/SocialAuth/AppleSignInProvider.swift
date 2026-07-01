import Foundation
import UIKit
import AuthenticationServices

/// Apple native login → **identity token** (id_token JWT), via the delegate-based
/// ASAuthorization flow. Mirrors Mercury's `AppleSignInProvider`.
public final class AppleSignInProvider: OauthSignInable {
    private var delegate: AppleSignInDelegate?

    public init() {}

    public func signIn() async throws -> OauthSignInToken {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            Task { @MainActor in
                let provider = ASAuthorizationAppleIDProvider()
                let request = provider.createRequest()
                request.requestedScopes = [.fullName, .email]

                let controller = ASAuthorizationController(authorizationRequests: [request])
                self?.delegate = AppleSignInDelegate(continuation: continuation)
                controller.delegate = self?.delegate
                controller.presentationContextProvider = self?.delegate
                controller.performRequests()
            }
        }
    }
}

private final class AppleSignInDelegate: NSObject,
                                         ASAuthorizationControllerDelegate,
                                         ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<OauthSignInToken, Error>
    private let userCancelCode = 1001

    init(continuation: CheckedContinuation<OauthSignInToken, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let identityToken = appleIDCredential.identityToken,
           let tokenString = String(data: identityToken, encoding: .utf8) {
            continuation.resume(returning: tokenString)
        } else {
            continuation.resume(throwing: AuthError.noProviderToken)
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        if (error as NSError).code == userCancelCode {
            continuation.resume(throwing: AuthError.cancelled)
        } else {
            continuation.resume(throwing: error)
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
            ?? ASPresentationAnchor()
    }
}
