import SwiftUI

/// TRACE action button. Mirrors components/core/Button.jsx.
/// Variants: primary (coral + warm shadow) · soft (coral wash) · ghost (hairline outline).
/// Sizes: sm · md · lg. Optional leading / trailing icons. Press = scale(0.97).
public struct TraceButton<Label: View>: View {
    public enum Variant { case primary, soft, ghost }
    public enum Size { case sm, md, lg }

    let variant: Variant
    let size: Size
    let fullWidth: Bool
    let action: () -> Void
    let iconLeft: AnyView?
    let iconRight: AnyView?
    @ViewBuilder let label: () -> Label

    @Environment(\.isEnabled) private var isEnabled

    public init(variant: Variant = .primary,
                size: Size = .md,
                fullWidth: Bool = true,
                iconLeft: AnyView? = nil,
                iconRight: AnyView? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label) {
        self.variant = variant
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
        self.iconLeft = iconLeft
        self.iconRight = iconRight
        self.label = label
    }

    // SIZES from Button.jsx: sm 8/14, md 11/20, lg 15/26.
    private var vPad: CGFloat { switch size { case .sm: return 8;  case .md: return 11; case .lg: return 15 } }
    private var hPad: CGFloat { switch size { case .sm: return 14; case .md: return 20; case .lg: return 26 } }
    private var radius: CGFloat { size == .lg ? TraceRadius.md : TraceRadius.sm }
    private var type: TraceType { switch size { case .sm: return .bodySM; case .md: return .bodyMD; case .lg: return .bodyLG } }
    private var weight: Font.Weight { size == .lg ? TraceWeight.bold : TraceWeight.semibold }

    private var bg: Color {
        switch variant {
        case .primary: return TraceColor.accent
        case .soft:    return TraceColor.coralWash
        case .ghost:   return .clear
        }
    }
    private var fg: Color {
        switch variant {
        case .primary: return TraceColor.paper0       // #FFFDF8
        case .soft:    return TraceColor.accentStrong
        case .ghost:   return TraceColor.textSecondary
        }
    }
    private var borderColor: Color { variant == .ghost ? TraceColor.hairline : .clear }
    private var shadow: TraceShadow { variant == .primary ? .coral : .none }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: TraceSpace.s2) {
                iconLeft
                label()
                iconRight
            }
            .font(type.font.weight(weight))
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, vPad)
            .padding(.horizontal, hPad)
            .foregroundStyle(fg)
            .background(bg, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .traceShadow(shadow)
        }
        .buttonStyle(TracePressStyle())
        .opacity(isEnabled ? 1 : 0.45)
    }
}

public extension TraceButton where Label == Text {
    /// Convenience text-only button.
    init(_ title: String,
         variant: Variant = .primary,
         size: Size = .md,
         fullWidth: Bool = true,
         action: @escaping () -> Void) {
        self.init(variant: variant, size: size, fullWidth: fullWidth, action: action) { Text(title) }
    }
}

/// Soft scale-on-press, matching the DS's transform: scale(0.97).
public struct TracePressStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
