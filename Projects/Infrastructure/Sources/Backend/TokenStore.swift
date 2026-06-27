import Foundation
import KeychainAccess

/// Holds the session JWT. In-memory cache backed by the Keychain so it survives relaunch.
/// An actor so the (Sendable) API client can read it from any task safely.
public actor TokenStore {
    private let keychain: Keychain
    private var cached: String?

    public init(service: String = "com.efreedom.trace.auth") {
        keychain = Keychain(service: service)
    }

    public func token() -> String? {
        if let cached { return cached }
        cached = try? keychain.getString("jwt")
        return cached
    }

    public func set(_ token: String?) {
        cached = token
        if let token {
            try? keychain.set(token, key: "jwt")
        } else {
            try? keychain.remove("jwt")
        }
    }
}
