import Foundation

import GoogleSignIn

/// Routes Google's OAuth redirect back into GoogleSignIn. Mirrors Mercury's `GoogleSignInHandler`.
public final class GoogleSignInHandler: DeeplinkHandlable {
    public init() {}

    public func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
