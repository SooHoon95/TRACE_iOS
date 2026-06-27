import SwiftUI
import Domain

/// Compact moment cell for newest-first grids (장소 전시 · 도감).
/// Photo is a vibe-tinted placeholder in Phase 1 (real image loads via PhotoStore later).
/// Set `showPrivateLock` in 도감 so a "나만" moment shows a lock badge.
public struct MomentGridCell: View {
    let moment: Moment
    let showPrivateLock: Bool

    public init(moment: Moment, showPrivateLock: Bool = false) {
        self.moment = moment
        self.showPrivateLock = showPrivateLock
    }

    private var isPrivate: Bool { moment.visibility == .privateOnly }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            photo
            if let caption = moment.caption, !caption.isEmpty {
                Text(caption)
                    .traceType(.bodyMD)
                    .fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if moment.companion != nil || moment.vibe != nil {
                HStack(spacing: 6) {
                    if let c = moment.companion { CompanionTag(c, size: .sm) }
                    if let v = moment.vibe { VibeTagChip(v, size: .sm, selected: false) {} }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1)
        )
        .traceShadow(.sm)
    }

    private var photo: some View {
        LinearGradient(colors: [(moment.vibe ?? .scenic).color, TraceColor.paper100],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .aspectRatio(1, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if showPrivateLock && isPrivate {
                    Text("🔒 나만")
                        .traceType(.bodyXS)
                        .fontWeight(.bold)
                        .foregroundStyle(TraceColor.paper0)
                        .padding(.vertical, 3).padding(.horizontal, 7)
                        .background(TraceColor.textSecondary.opacity(0.9), in: Capsule())
                        .padding(8)
                }
            }
    }
}
