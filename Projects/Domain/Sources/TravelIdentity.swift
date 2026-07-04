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

// MARK: - Highlight (Task 2 shape; populated in Task 3)

/// Why a moment was surfaced as a highlight.
public enum HighlightReason: Equatable, Sendable {
    case representative   // 대표: exemplifies the dominant (vibe, companion) pair
    case rare             // 희귀: the pair the traveler almost never leaves
}

/// A surfaced moment plus the reason it stands out.
public struct Highlight: Equatable, Sendable {
    public let moment: Moment
    public let reason: HighlightReason

    public init(moment: Moment, reason: HighlightReason) {
        self.moment = moment
        self.reason = reason
    }
}

// MARK: - TravelIdentityModel

/// How much data backs the card, gating the headline + hint copy (D4).
public enum IdentityDataLevel: Equatable, Sendable {
    case empty   // 0 moments
    case low     // < lowDataThreshold total, or < lowDataThreshold with a vibe
    case full
}

/// The whole card in one value type — the output of the pure `compute`.
public struct TravelIdentityModel: Equatable, Sendable {
    public let headline: String             // 칭호 (D1)
    public let dataLevel: IdentityDataLevel
    public let distribution: TraitDistribution
    public let highlights: [Highlight]      // 0–2 (D2, populated in Task 3)
    public let lowDataHint: String?         // set for .empty / .low

    public init(headline: String,
                dataLevel: IdentityDataLevel,
                distribution: TraitDistribution,
                highlights: [Highlight],
                lowDataHint: String?) {
        self.headline = headline
        self.dataLevel = dataLevel
        self.distribution = distribution
        self.highlights = highlights
        self.lowDataHint = lowDataHint
    }
}

// MARK: - Headline table + compute (the pure function)

public extension TravelIdentity {

    /// Copy shown when the card can't yet form a distinct identity.
    static let lowDataHintText = "순간을 더 남기면 정체성이 뚜렷해져요."
    static let genericHeadline = "아직 정체성을 그리는 중"

    /// 동행 prefix (D1). Combined with a vibe noun into the headline.
    private static let companionPrefix: [Companion: String] = [
        .partner: "둘이 걷는",
        .family:  "함께하는",
        .friends: "우르르 몰려다니는",
        .solo:    "혼자 떠나는"
    ]

    /// 무드 noun (D1). The headline's core identity word.
    private static let vibeNoun: [VibeTag: String] = [
        .calm:      "고요 수집가",
        .lively:    "활기 메이커",
        .scenic:    "풍경 사냥꾼",
        .foodie:    "맛집 탐험가",
        .adventure: "모험가",
        .hidden:    "숨은 곳 발굴러"
    ]

    /// Deterministic headline from a (dominant vibe, dominant companion) pair (D1).
    /// - both present → "\(prefix) \(noun)" e.g. solo+scenic → "혼자 떠나는 풍경 사냥꾼"
    /// - vibe only    → the noun alone e.g. "풍경 사냥꾼"
    /// - companion only → "\(prefix) 여행자" e.g. "혼자 떠나는 여행자"
    /// - neither      → the generic placeholder
    static func headline(vibe: VibeTag?, companion: Companion?) -> String {
        switch (vibe, companion) {
        case let (v?, c?):
            return "\(companionPrefix[c]!) \(vibeNoun[v]!)"
        case let (v?, nil):
            return vibeNoun[v]!
        case let (nil, c?):
            return "\(companionPrefix[c]!) 여행자"
        case (nil, nil):
            return genericHeadline
        }
    }

    /// THE pure function: `[Moment] -> TravelIdentityModel`. No I/O, no clock, no locale —
    /// same input (in any order) yields the same card. Highlights are wired in Task 3.
    static func compute(_ moments: [Moment]) -> TravelIdentityModel {
        let dist = distribution(moments)
        let vibeBearing = dist.vibeCounts.values.reduce(0, +)

        let level: IdentityDataLevel
        if dist.total == 0 {
            level = .empty
        } else if dist.total < lowDataThreshold || vibeBearing < lowDataThreshold {
            level = .low
        } else {
            level = .full
        }

        let headline = headline(vibe: dist.dominantVibe, companion: dist.dominantCompanion)
        let hint = level == .full ? nil : lowDataHintText

        return TravelIdentityModel(headline: headline,
                                   dataLevel: level,
                                   distribution: dist,
                                   highlights: selectHighlights(moments, distribution: dist),
                                   lowDataHint: hint)
    }

    /// 대표/희귀 highlight selection (D2), fully deterministic from `[Moment]` alone.
    ///
    /// Candidates must have a **fully-defined** `(vibe, companion)` pair.
    /// - 대표 (representative): a moment of the dominant `(vibe, companion)` pair; if the dominant
    ///   axes never co-occur, the most-frequent pair (tie-break by enum order) — newest wins,
    ///   then smallest `id.uuidString`.
    /// - 희귀 (rare): a moment of the lowest-frequency pair — oldest wins, then smallest `id.uuidString`.
    /// - If 대표 and 희귀 resolve to the same moment (tiny sets), only 대표 is kept.
    static func selectHighlights(_ moments: [Moment], distribution: TraitDistribution) -> [Highlight] {
        struct Pair: Hashable { let vibe: VibeTag; let companion: Companion }

        let candidates: [(moment: Moment, pair: Pair)] = moments.compactMap { m in
            guard let v = m.vibe, let c = m.companion else { return nil }
            return (m, Pair(vibe: v, companion: c))
        }
        guard !candidates.isEmpty else { return [] }

        var pairCount: [Pair: Int] = [:]
        for c in candidates { pairCount[c.pair, default: 0] += 1 }

        // Newest-first (tie: smallest uuid) for 대표; oldest-first (tie: smallest uuid) for 희귀.
        func newest(_ pool: [Moment]) -> Moment {
            pool.sorted { a, b in
                a.createdAt != b.createdAt ? a.createdAt > b.createdAt : a.id.uuidString < b.id.uuidString
            }.first!
        }
        func oldest(_ pool: [Moment]) -> Moment {
            pool.sorted { a, b in
                a.createdAt != b.createdAt ? a.createdAt < b.createdAt : a.id.uuidString < b.id.uuidString
            }.first!
        }

        // 대표 pool: dominant pair if any moment has it, else the most-frequent pair.
        let dominantPair: Pair? = {
            guard let v = distribution.dominantVibe, let c = distribution.dominantCompanion else { return nil }
            return Pair(vibe: v, companion: c)
        }()
        let repPool: [Moment]
        if let dp = dominantPair, pairCount[dp] != nil {
            repPool = candidates.filter { $0.pair == dp }.map(\.moment)
        } else {
            let maxCount = pairCount.values.max()!
            let topPair = pairCount.filter { $0.value == maxCount }.keys.min { l, r in
                (VibeTag.allCases.firstIndex(of: l.vibe)!, Companion.allCases.firstIndex(of: l.companion)!)
                    < (VibeTag.allCases.firstIndex(of: r.vibe)!, Companion.allCases.firstIndex(of: r.companion)!)
            }!
            repPool = candidates.filter { $0.pair == topPair }.map(\.moment)
        }
        let representative = newest(repPool)

        // 희귀 pool: every candidate whose pair is at the minimum frequency.
        let minCount = pairCount.values.min()!
        let rarePool = candidates.filter { pairCount[$0.pair] == minCount }.map(\.moment)
        let rare = oldest(rarePool)

        var result = [Highlight(moment: representative, reason: .representative)]
        if rare.id != representative.id {
            result.append(Highlight(moment: rare, reason: .rare))
        }
        return result
    }
}
