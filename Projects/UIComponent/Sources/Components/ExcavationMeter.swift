import SwiftUI
import Domain

/// On-site AR excavation meter (warm dark) — 4-step warm/cold heat + distance + 발굴하기 CTA.
/// Mirrors components/map/ExcavationMeter.jsx. Levels reuse Domain's `Warmth` (cold/cool/warm/hot).
/// The CTA is enabled only when physically `onSite`.
public struct ExcavationMeter: View {
    let level: Warmth
    let distance: Int
    let onSite: Bool
    let onExcavate: (() -> Void)?

    public init(level: Warmth = .warm, distance: Int = 12, onSite: Bool = false, onExcavate: (() -> Void)? = nil) {
        self.level = level
        self.distance = distance
        self.onSite = onSite
        self.onExcavate = onExcavate
    }

    private let order: [Warmth] = [.cold, .cool, .warm, .hot]
    private var idx: Int { level.stepIndex }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("발굴 신호")
                    .traceType(.eyebrow)
                    .foregroundStyle(TraceColor.coral300)
                Spacer()
                Text(onSite ? "현장 도착" : "\(distance)m 남음")
                    .traceType(.bodySM)
                    .fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }
            .padding(.bottom, 14)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(level.excavationLabel)
                    .traceType(.displayLG)
                    .fontWeight(.heavy)
                    .foregroundStyle(level.excavationColor)
                Text(level.excavationHint)
                    .traceType(.bodySM)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }
            .padding(.bottom, 16)

            HStack(spacing: 5) {
                ForEach(Array(order.enumerated()), id: \.offset) { i, step in
                    Capsule()
                        .fill(i <= idx ? step.excavationColor : TraceColor.surfaceDarkRaised)
                        .frame(height: 7)
                }
            }
            .padding(.bottom, 18)

            TraceButton(onSite ? "발굴하기" : "현장에서만 발굴할 수 있어요", size: .lg) {
                onExcavate?()
            }
            .disabled(!onSite)
        }
        .padding(20)
        .frame(width: 320, alignment: .leading)
        .background(TraceColor.surfaceDarkCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous)
                .strokeBorder(TraceColor.surfaceDarkLine, lineWidth: 1)
        )
        .traceShadow(.lg)
    }
}
