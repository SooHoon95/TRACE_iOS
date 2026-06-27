import SwiftUI
import Domain

/// Who-you-were-with pill: 연인 / 가족 / 친구 / 혼자. Neutral sunken chip with a coral glyph.
/// Mirrors components/core/CompanionTag.jsx. Sizes: sm · md.
public struct CompanionTag: View {
    public enum Size { case sm, md }

    let companion: Companion
    let size: Size

    public init(_ companion: Companion = .solo, size: Size = .md) {
        self.companion = companion
        self.size = size
    }

    private var sm: Bool { size == .sm }

    public var body: some View {
        HStack(spacing: sm ? 5 : 6) {
            Text(companion.glyph)
                .font(.system(size: sm ? 10 : 12))
                .foregroundStyle(TraceColor.accent)
            Text(companion.label)
        }
        .traceType(sm ? .bodyXS : .bodySM)
        .padding(.vertical, sm ? 4 : 6)
        .padding(.horizontal, sm ? 9 : 12)
        .foregroundStyle(TraceColor.textSecondary)
        .background(TraceColor.surfaceSunken, in: Capsule())
        .overlay(Capsule().strokeBorder(TraceColor.hairline, lineWidth: 1))
    }
}
