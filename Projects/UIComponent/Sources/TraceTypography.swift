import SwiftUI

/// TRACE typography tokens — from v2 tokens/typography.css.
/// Single family: Pretendard (full 한글). Hierarchy comes from weight + size only — no serif.
/// `display` uses Pretendard ExtraBold (weight 800); Fraunces is fully removed.
/// NOTE: Pretendard must be bundled + registered (`TraceFonts.registerAll`) for the exact look;
/// `.custom` falls back to the system font automatically until then.
public enum TraceFontFamily {
    public static let sans = "Pretendard"
}

/// Pretendard weights (400–800).
public enum TraceWeight {
    public static let regular   = Font.Weight.regular   // 400
    public static let medium    = Font.Weight.medium    // 500
    public static let semibold  = Font.Weight.semibold  // 600
    public static let bold      = Font.Weight.bold      // 700
    public static let extrabold = Font.Weight.heavy     // 800
}

/// Line-height multipliers from typography.css.
public enum TraceLeading {
    public static let tight: CGFloat  = 1.08
    public static let snug: CGFloat   = 1.25
    public static let normal: CGFloat = 1.5
}

public enum TraceType {
    case displayXL  // 52 · distance / hero counter
    case displayLG  // 30 · title / 칭호
    case displayMD  // 26 · screen title
    case displaySM  // 21 · stat / caption hero
    case bodyLG     // 17 · sheet heading
    case bodyMD     // 15 · body / inputs
    case bodySM     // 13 · labels
    case bodyXS     // 11.5 · captions / meta
    case eyebrow    // 11 · uppercase, wide tracking

    public var size: CGFloat {
        switch self {
        case .displayXL: return 52
        case .displayLG: return 30
        case .displayMD: return 26
        case .displaySM: return 21
        case .bodyLG:    return 17
        case .bodyMD:    return 15
        case .bodySM:    return 13
        case .bodyXS:    return 11.5
        case .eyebrow:   return 11
        }
    }

    /// All hierarchy is weight + size. Display = extrabold 800.
    public var weight: Font.Weight {
        switch self {
        case .displayXL, .displayLG, .displayMD, .displaySM:
            return TraceWeight.extrabold    // 800
        case .eyebrow, .bodyLG, .bodySM:
            return TraceWeight.semibold     // 600
        case .bodyXS:
            return TraceWeight.semibold     // 600
        case .bodyMD:
            return TraceWeight.medium       // 500
        }
    }

    /// Tracking in points (em × size). Display tightens slightly; eyebrow widens to 0.16em.
    public var tracking: CGFloat {
        switch self {
        case .displayXL, .displayLG, .displayMD, .displaySM:
            return -0.015 * size
        case .eyebrow:
            return 0.16 * size
        default:
            return 0
        }
    }

    public var font: Font {
        Font.custom(TraceFontFamily.sans, size: size).weight(weight)
    }
}

public extension View {
    /// Apply a TRACE type style (font + tracking).
    func traceType(_ style: TraceType) -> some View {
        self.font(style.font).tracking(style.tracking)
    }
}
