import SwiftUI

/// 📍 내 주변 남길 자리 — a nearby place with a "너도 남겨" mini CTA (claiming nudge).
public struct PlacePromptCard: View {
    let placeName: String
    let distance: String
    let onClaim: () -> Void

    public init(placeName: String, distance: String, onClaim: @escaping () -> Void) {
        self.placeName = placeName
        self.distance = distance
        self.onClaim = onClaim
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("📍 \(placeName)")
                    .traceType(.bodyMD).fontWeight(.bold)
                    .foregroundStyle(TraceColor.textPrimary)
                Text(distance)
                    .traceType(.bodySM)
                    .foregroundStyle(TraceColor.textMuted)
            }
            Spacer()
            TraceButton("너도 남겨", variant: .soft, size: .sm, fullWidth: false) { onClaim() }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
            .strokeBorder(TraceColor.hairline, lineWidth: 1))
    }
}
