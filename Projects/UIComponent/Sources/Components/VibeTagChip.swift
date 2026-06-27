import SwiftUI
import Domain

/// Mood chip with a color dot — one of TRACE's fixed 6 vibes (차분·활기·풍경·맛집·모험·숨은곳).
/// Outlined on card surface by default; filled with the vibe color (white text) when selected.
/// Mirrors components/core/VibeTag.jsx. Sizes: sm · md.
public struct VibeTagChip: View {
    public enum Size { case sm, md }

    let vibe: VibeTag
    let size: Size
    let selected: Bool
    let action: (() -> Void)?

    public init(_ vibe: VibeTag, size: Size = .md, selected: Bool = false, action: (() -> Void)? = nil) {
        self.vibe = vibe
        self.size = size
        self.selected = selected
        self.action = action
    }

    private var sm: Bool { size == .sm }
    private var dot: CGFloat { sm ? 7 : 9 }

    private var chip: some View {
        HStack(spacing: sm ? 5 : 7) {
            Circle()
                .fill(selected ? TraceColor.paper0 : vibe.color)
                .frame(width: dot, height: dot)
            Text(vibe.label)
        }
        .traceType(sm ? .bodyXS : .bodySM)
        .padding(.vertical, sm ? 5 : 7)
        .padding(.horizontal, sm ? 10 : 13)
        .foregroundStyle(selected ? TraceColor.paper0 : TraceColor.textPrimary)
        .background(selected ? vibe.color : TraceColor.surfaceCard, in: Capsule())
        .overlay(
            Capsule().strokeBorder(selected ? vibe.color : TraceColor.hairline, lineWidth: 1)
        )
    }

    public var body: some View {
        if let action {
            Button(action: action) { chip }.buttonStyle(.plain)
        } else {
            chip
        }
    }
}
