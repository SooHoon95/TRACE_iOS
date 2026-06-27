import SwiftUI
import Domain

/// Bridges TraceCore (Domain) enums to TRACE design-system colors / labels / glyphs,
/// and defines the UIComponent-local `Companion` enum used by CompanionTag / MomentCard.

// MARK: - VibeTag (Domain) → v2 vibe presentation

public extension VibeTag {
    /// Soft per-vibe color from v2 tokens/colors.css (--vibe-*).
    /// Domain spelling `scenic`/`foodie` maps to v2 `scenery`/`food`.
    var color: Color {
        switch self {
        case .calm:      return TraceColor.vibeCalm      // 차분
        case .lively:    return TraceColor.vibeLively    // 활기
        case .scenic:    return TraceColor.vibeScenery   // 풍경
        case .foodie:    return TraceColor.vibeFood      // 맛집
        case .adventure: return TraceColor.vibeAdventure // 모험
        case .hidden:    return TraceColor.vibeHidden    // 숨은곳
        }
    }

    /// Korean display label (TRACE fixed 6).
    var label: String {
        switch self {
        case .calm:      return "차분"
        case .lively:    return "활기"
        case .scenic:    return "풍경"
        case .foodie:    return "맛집"
        case .adventure: return "모험"
        case .hidden:    return "숨은곳"
        }
    }
}

// MARK: - Companion (Domain) → v2 chip presentation

/// `Companion` now lives in Domain (so a `Moment` is serializable). UIComponent adds only
/// its presentation here, from components/core/CompanionTag.jsx.
public extension Companion {
    /// Korean display label.
    var label: String {
        switch self {
        case .partner: return "연인"
        case .family:  return "가족"
        case .friends: return "친구"
        case .solo:    return "혼자"
        }
    }

    /// Coral glyph shown in the chip.
    var glyph: String {
        switch self {
        case .partner: return "♥"
        case .family:  return "⌂"
        case .friends: return "✦"
        case .solo:    return "●"
        }
    }
}

// MARK: - Warmth (Domain) → ExcavationMeter levels

public extension Warmth {
    /// Korean excavation label (v2 ExcavationMeter.jsx).
    var excavationLabel: String {
        switch self {
        case .cold: return "차가움"
        case .cool: return "선선함"
        case .warm: return "따뜻함"
        case .hot:  return "뜨거움"
        }
    }

    /// Short hint shown beside the label.
    var excavationHint: String {
        switch self {
        case .cold: return "아직 멀어요"
        case .cool: return "근처예요"
        case .warm: return "가까워요"
        case .hot:  return "바로 여기!"
        }
    }

    /// Heat color for the meter (from ExcavationMeter.jsx LEVELS).
    var excavationColor: Color {
        switch self {
        case .cold: return TraceColor.vibeCalm            // --vibe-calm
        case .cool: return Color(hex: 0x9DBFA8)           // bespoke cool green
        case .warm: return TraceColor.coral300            // --coral-300
        case .hot:  return TraceColor.coral500            // --coral-500
        }
    }

    /// Ordered 4-step index (cold=0 … hot=3), for filling the segment bar.
    var stepIndex: Int { rawValue }
}

// MARK: - RarityTier (Domain) → color (unused in v2, kept harmless)

public extension RarityTier {
    /// Legacy rarity tier color. Not used by any v2 component; retained so the bridge
    /// stays complete and Domain.RarityTier remains presentable if ever needed.
    var color: Color {
        switch self {
        case .common:    return Color(hex: 0xC2B5A4)
        case .uncommon:  return Color(hex: 0x7E9B6B)
        case .rare:      return TraceColor.coral600
        case .legendary: return Color(hex: 0xE0A93B)
        }
    }
}
