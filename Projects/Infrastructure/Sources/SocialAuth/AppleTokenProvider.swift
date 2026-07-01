import UIKit
import AuthenticationServices

/// Apple native login → **identity token** (id_token JWT), via the delegate-based
/// ASAuthorization flow. The backend verifies it against Apple's JWKS (`verify_apple`).
public final class AppleTokenProvider: OAuthTokenProvider {
    private var delegate: AppleAuthDelegate?

    public init() {}

    public func token() async throws -> String {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            Task { @MainActor in
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]

                let delegate = AppleAuthDelegate(continuation: continuation)
                self?.delegate = delegate

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
            }
        }
    }
}

/// Bridges the continuation across ASAuthorization's delegate callbacks. Held by the
/// provider for the flow's lifetime so it isn't deallocated mid-request.
private final class AppleAuthDelegate: NSObject,
                                       ASAuthorizationControllerDelegate,
                                       ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<String, Error>
    private let userCancelCode = 1001

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            continuation.resume(throwing: AuthError.noProviderToken)
            return
        }
        continuation.resume(returning: tokenString)
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
