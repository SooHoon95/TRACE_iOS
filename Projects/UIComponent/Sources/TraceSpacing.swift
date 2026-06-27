import SwiftUI

/// TRACE spacing / radius / shadow tokens — from v2 tokens/spacing.css. 4px base.
public enum TraceSpace {
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s10: CGFloat = 40
}

/// Soft radii, never sharp.
public enum TraceRadius {
    public static let sm: CGFloat = 12     // tags, small chips, sm buttons
    public static let md: CGFloat = 16     // buttons, inputs, inner cards
    public static let lg: CGFloat = 20     // moment cards
    public static let xl: CGFloat = 26     // exhibition tiles, meters
    public static let xxl: CGFloat = 28    // composer / identity card / timeline
    public static let pill: CGFloat = 999
    public static let phone: CGFloat = 44  // device frame
}

/// Warm terracotta-tinted shadows. CSS box-shadow has a spread term SwiftUI lacks,
/// so these are visual approximations (blur ≈ css_blur/2, y = css_offset). Where the
/// CSS token layers two shadows, we approximate with the larger, more visible layer.
public struct TraceShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color; self.radius = radius; self.x = x; self.y = y
    }

    // rgba(74,56,42) == 0x4A382A ; rgba(58,42,30) == 0x3A2A1E ; rgba(199,93,67) == 0xC75D43
    /// --shadow-sm: 0 1px 2 + 0 2px 6 rgba(74,56,42,.06/.05)
    public static let sm     = TraceShadow(color: Color(hex: 0x4A382A).opacity(0.06), radius: 3,  y: 2)
    /// --shadow-md: 0 4px 12 + 0 1px 3 rgba(74,56,42,.10/.06)
    public static let md     = TraceShadow(color: Color(hex: 0x4A382A).opacity(0.10), radius: 6,  y: 4)
    /// --shadow-lg: 0 14px 36 + 0 4px 10 rgba(58,42,30,.16/.08)
    public static let lg     = TraceShadow(color: Color(hex: 0x3A2A1E).opacity(0.16), radius: 18, y: 14)
    /// --shadow-coral: 0 8px 22 rgba(199,93,67,.28)
    public static let coral  = TraceShadow(color: Color(hex: 0xC75D43).opacity(0.28), radius: 11, y: 8)
    /// No shadow (for variant switches).
    public static let none   = TraceShadow(color: .clear, radius: 0, y: 0)
}

public extension View {
    func traceShadow(_ s: TraceShadow) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}
