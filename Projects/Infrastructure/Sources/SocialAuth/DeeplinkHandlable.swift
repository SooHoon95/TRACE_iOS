import Foundation

/// Something that can consume an inbound OAuth redirect URL, returning `true` when it owns it.
/// Mirrors Mercury's `DeeplinkHandlable`.
public protocol DeeplinkHandlable {
    func handle(url: URL) -> Bool
}
