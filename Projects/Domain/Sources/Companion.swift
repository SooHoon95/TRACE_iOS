import Foundation

/// Who-you-were-with when a moment was left. Optional on a `Moment` (low-friction claim).
///
/// Lives in Domain (moved from UIComponent) so a `Moment` is fully server-serializable.
/// `CaseIterable` is kept so the composer can render a picker; UIComponent adds the
/// `label`/`glyph` presentation in `TraceVibeRarity.swift`.
public enum Companion: String, CaseIterable, Codable, Sendable {
    case partner, family, friends, solo
}
