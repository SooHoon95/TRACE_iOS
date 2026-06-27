import SwiftUI

/// Warm-dark map pin sized + lit by memory density (0–1). Designed to sit on the char-900 map surface.
/// Mirrors components/map/PlacePin.jsx. Variants: exhibition (others' gallery) · visited (you've been).
public struct PlacePin: View {
    public enum Variant { case exhibition, visited }

    let density: Double
    let variant: Variant
    let count: Int?
    let label: String?

    public init(density: Double = 0.5, variant: Variant = .exhibition, count: Int? = nil, label: String? = nil) {
        self.density = min(1, max(0, density))
        self.variant = variant
        self.count = count
        self.label = label
    }

    private var size: CGFloat { 28 + CGFloat((density * 30).rounded()) }      // 28–58
    private var glow: CGFloat { 4 + CGFloat((density * 10).rounded()) }       // halo width
    private var visited: Bool { variant == .visited }
    private var ringColor: Color { visited ? TraceColor.coral300 : TraceColor.vibeCalm }
    private var fillColor: Color { visited ? TraceColor.accent : TraceColor.char600 }
    private var glowColor: Color {
        visited ? TraceColor.coral500.opacity(0.16) : TraceColor.vibeCalm.opacity(0.14)
    }
    private var glyph: String { count != nil ? "\(count!)" : (visited ? "✓" : "❖") }

    public var body: some View {
        VStack(spacing: 5) {
            Text(glyph)
                .font(.custom(TraceFontFamily.sans, size: 11 + CGFloat((density * 4).rounded())).weight(.bold))
                .foregroundStyle(TraceColor.paper0)
                .frame(width: size, height: size)
                .background(fillColor, in: Circle())
                .overlay(Circle().strokeBorder(ringColor, lineWidth: 2))
                .background(
                    Circle().fill(glowColor).frame(width: size + glow * 2, height: size + glow * 2)
                )
                .traceShadow(.md)
            if let label {
                Text(label)
                    .traceType(.bodyXS)
                    .fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textOnDark)
                    .padding(.vertical, 2).padding(.horizontal, 8)
                    .background(Color(hex: 0x241C16).opacity(0.6), in: Capsule())
                    .fixedSize()
            }
        }
    }
}
