import Foundation

/// 나의 여행 정체성 카드 — deterministic, client-side derivation over a user's own moments.
///
/// The whole surface is a **pure function** `[Moment] -> TravelIdentityModel` (see `compute`,
/// Task 2). This file (Task 1) establishes the raw distribution primitives it builds on.
///
/// Determinism is a hard invariant: no `Date()`, `UUID()`, `Locale.current`, `TimeZone.current`,
/// or `Calendar.current` anywhere in this file. Time bucketing uses a fixed
/// `Calendar(identifier: .gregorian)` + `TimeZone("Asia/Seoul")` so the same `[Moment]` always
/// yields the same card, regardless of device locale/timezone or input order.

// MARK: - TimeBand

/// Hour-of-day bucket a moment's `createdAt` falls into (computed in Seoul local time).
public enum TimeBand: String, CaseIterable, Codable, Sendable {
    case dawn      // 새벽 0–5
    case morning   // 아침 6–10
    case day       // 낮 11–16
    case evening   // 저녁 17–20
    case night     // 밤 21–23

    /// Maps a 0...23 hour to its band. Values outside 0...23 clamp into `.night`
    /// via the default arm (only reachable with malformed input).
    public static func band(forHour h: Int) -> TimeBand {
        switch h {
        case 0...5:   return .dawn
        case 6...10:  return .morning
        case 11...16: return .day
        case 17...20: return .evening
        default:      return .night   // 21...23
        }
    }
}

// MARK: - TraitDistribution

/// Raw per-trait counts over a set of moments, plus deterministic "dominant" (mode) accessors.
///
/// - `vibeCounts` / `companionCounts` exclude moments whose trait is `nil` (low-friction claim
///   leaves them optional), but every moment still contributes to `total`, `timeBandCounts`,
///   and `regionCounts`.
/// - `regionCounts` is keyed by `placeID` (D3): opaque, deterministic, no reverse-geocoding.
public struct TraitDistribution: Equatable, Sendable {
    public let vibeCounts: [VibeTag: Int]
    public let companionCounts: [Companion: Int]
    public let timeBandCounts: [TimeBand: Int]
    public let regionCounts: [UUID: Int]
    public let total: Int

    public init(vibeCounts: [VibeTag: Int],
                companionCounts: [Companion: Int],
                timeBandCounts: [TimeBand: Int],
                regionCounts: [UUID: Int],
                total: Int) {
        self.vibeCounts = vibeCounts
        self.companionCounts = companionCounts
        self.timeBandCounts = timeBandCounts
        self.regionCounts = regionCounts
        self.total = total
    }

    /// Mode of a `CaseIterable` trait, tie-broken by **declaration order** (earliest wins).
    /// Iterating `order` and replacing only on strictly-greater counts makes the first max win.
    private static func mode<K: Hashable>(_ counts: [K: Int], order: [K]) -> K? {
        var best: K?
        var bestCount = 0
        for key in order {
            let c = counts[key] ?? 0
            if c > bestCount {
                bestCount = c
                best = key
            }
        }
        return best
    }

    public var dominantVibe: VibeTag? { Self.mode(vibeCounts, order: VibeTag.allCases) }
    public var dominantCompanion: Companion? { Self.mode(companionCounts, order: Companion.allCases) }
    public var dominantTimeBand: TimeBand? { Self.mode(timeBandCounts, order: TimeBand.allCases) }

    /// Most-frequented `placeID`. Ties broken by smallest `uuidString` for total determinism
    /// (UUIDs have no natural declaration order).
    public var dominantRegion: UUID? {
        let maxCount = regionCounts.values.max() ?? 0
        guard maxCount > 0 else { return nil }
        return regionCounts
            .filter { $0.value == maxCount }
            .keys
            .min(by: { $0.uuidString < $1.uuidString })
    }
}

// MARK: - TravelIdentity (namespace + distribution)

public enum TravelIdentity {
    /// Below this many moments (total, or vibe-bearing) the card shows a low-data hint (D4).
    public static let lowDataThreshold = 3

    /// Fixed Gregorian/Seoul calendar — the sole source of hour-of-day bucketing, so time-bands
    /// never depend on the device's locale or timezone.
    static let seoulCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }()

    /// Pure tally of a moment set into a `TraitDistribution`. Order-independent.
    public static func distribution(_ moments: [Moment]) -> TraitDistribution {
        var vibe: [VibeTag: Int] = [:]
        var companion: [Companion: Int] = [:]
        var band: [TimeBand: Int] = [:]
        var region: [UUID: Int] = [:]

        for m in moments {
            if let v = m.vibe { vibe[v, default: 0] += 1 }
            if let c = m.companion { companion[c, default: 0] += 1 }
            let hour = seoulCalendar.component(.hour, from: m.createdAt)
            band[TimeBand.band(forHour: hour), default: 0] += 1
            region[m.placeID, default: 0] += 1
        }

        return TraitDistribution(vibeCounts: vibe,
                                 companionCounts: companion,
                                 timeBandCounts: band,
                                 regionCounts: region,
                                 total: moments.count)
    }
}
