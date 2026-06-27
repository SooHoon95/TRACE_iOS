import Foundation
import KeychainAccess

/// Secure key-value storage backed by the iOS Keychain (via KeychainAccess).
/// Phase 2 uses this to persist the auth session token across launches.
/// Validates the external-SPM dependency layer end-to-end.
public struct SecureStore: Sendable {
    private let keychain: Keychain

    public init(service: String = "com.efreedom.trace") {
        self.keychain = Keychain(service: service)
    }

    public func set(_ value: String, for key: String) throws {
        try keychain.set(value, key: key)
    }

    public func string(for key: String) throws -> String? {
        try keychain.get(key)
    }

    public func remove(_ key: String) throws {
        try keychain.remove(key)
    }
}
