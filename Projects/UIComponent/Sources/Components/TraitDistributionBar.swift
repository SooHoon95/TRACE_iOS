import SwiftUI
import Domain

/// A generalized composition bar + wrapping legend over any trait distribution (vibe, time-band, …).
/// Reuses `CompositionSlice` as the render struct; the count→percent math is the pure, tested
/// `distributionSlices` below (not smuggled into the View).

// MARK: - Pure percentage mapping (unit-tested — Task 4)

/// Convert raw `counts` into integer-percent `CompositionSlice`s that **sum to exactly 100**.
///
/// - Slices are emitted in `order`; zero-count keys are omitted.
/// - Rounding is **largest-remainder**: floor every percent, then hand the leftover units
///   (100 − Σfloors) to the largest fractional remainders. **Ties in remainder are broken by
///   `order` position** (earlier keys receive the extra unit first) — so `[1,1,1]` → 34/33/33
///   deterministically, while unequal remainders (`[5,3,1]` → 56/33/11) follow the remainder.
public func distributionSlices<Key: Hashable>(
    _ counts: [Key: Int],
    order: [Key],
    label: (Key) -> String,
    color: (Key) -> Color
) -> [CompositionSlice] {
    let present = order.filter { (counts[$0] ?? 0) > 0 }
    let total = present.reduce(0) { $0 + (counts[$1] ?? 0) }
    guard total > 0 else { return [] }

    var floors = [Int](repeating: 0, count: present.count)
    var remainders = [Double](repeating: 0, count: present.count)
    for (i, key) in present.enumerated() {
        let exact = Double(counts[key]!) / Double(total) * 100.0
        floors[i] = Int(exact.rounded(.down))
        remainders[i] = exact - Double(floors[i])
    }

    // Rank indices by remainder desc, then by order position asc (earlier wins the tie).
    let ranked = present.indices.sorted { a, b in
        remainders[a] != remainders[b] ? remainders[a] > remainders[b] : a < b
    }
    var pcts = floors
    var leftover = 100 - floors.reduce(0, +)
    var r = 0
    while leftover > 0 {
        pcts[ranked[r % ranked.count]] += 1
        leftover -= 1
        r += 1
    }

    return present.enumerated().map { i, key in
        CompositionSlice(label: label(key), pct: pcts[i], color: color(key))
    }
}

// MARK: - TimeBand presentation bridge (Domain enum → label/color)

public extension TimeBand {
    var bandLabel: String {
        switch self {
        case .dawn:    return "새벽"
        case .morning: return "아침"
        case .day:     return "낮"
        case .evening: return "저녁"
        case .night:   return "밤"
        }
    }

    var bandColor: Color {
        switch self {
        case .dawn:    return TraceColor.vibeCalm
        case .morning: return TraceColor.vibeScenery
        case .day:     return TraceColor.coral300
        case .evening: return TraceColor.vibeAdventure
        case .night:   return TraceColor.vibeHidden
        }
    }
}

// MARK: - Bar view

/// Horizontal composition bar + wrapping legend. Sized for up to 6 slices at a fixed card width.
public struct TraitDistributionBar: View {
    private let slices: [CompositionSlice]

    public init(slices: [CompositionSlice]) {
        self.slices = slices
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(slices) { slice in
                        Rectangle()
                            .fill(slice.color)
                            .frame(width: max(0, geo.size.width * CGFloat(slice.pct) / 100))
                    }
                }
            }
            .frame(height: 12)
            .clipShape(Capsule())

            legend
        }
    }

    /// Two entries per row → up to 6 slices wrap into 3 rows at a 320pt card width (M1).
    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stride(from: 0, to: slices.count, by: 2)), id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row..<min(row + 2, slices.count), id: \.self) { i in
                        legendItem(slices[i])
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func legendItem(_ s: CompositionSlice) -> some View {
        HStack(spacing: 6) {
            Circle().fill(s.color).frame(width: 8, height: 8)
            Text("\(s.label) \(s.pct)%")
                .traceType(.bodyXS)
                .foregroundStyle(TraceColor.textOnDark)
        }
    }
}
