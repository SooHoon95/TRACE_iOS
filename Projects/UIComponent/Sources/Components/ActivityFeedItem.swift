import SwiftUI
import Domain

/// 🔥 방금 남들이 남긴 순간 — compact card for the home activity feed (horizontal scroll).
/// Vibe-tinted thumbnail + place + companion + time-ago. FOMO surface.
public struct ActivityFeedItem: View {
    let placeName: String
    let vibe: VibeTag?
    let companion: Companion?
    let timeAgo: String

    public init(placeName: String, vibe: VibeTag?, companion: Companion?, timeAgo: String) {
        self.placeName = placeName
        self.vibe = vibe
        self.companion = companion
        self.timeAgo = timeAgo
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LinearGradient(colors: [(vibe ?? .scenic).color, TraceColor.paper100],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 150, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
            Text(placeName)
                .traceType(.bodySM).fontWeight(.bold)
                .foregroundStyle(TraceColor.textPrimary)
                .lineLimit(1)
            HStack(spacing: 6) {
                if let companion { CompanionTag(companion, size: .sm) }
                Text(timeAgo).traceType(.bodyXS).foregroundStyle(TraceColor.textMuted)
            }
        }
        .padding(10)
        .frame(width: 170, alignment: .leading)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
            .strokeBorder(TraceColor.hairline, lineWidth: 1))
    }
}
