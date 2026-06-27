import SwiftUI
import Domain

/// One past visit layer for ReturnTimeline.
public struct ReturnLayer: Identifiable {
    public let id = UUID()
    public let year: String
    public let caption: String
    public let companion: Companion
    public let vibe: VibeTag
    public let image: Image?

    public init(year: String, caption: String, companion: Companion, vibe: VibeTag = .scenic, image: Image? = nil) {
        self.year = year
        self.caption = caption
        self.companion = companion
        self.vibe = vibe
        self.image = image
    }
}

/// ★ Emotional hero — vertical time layers of return visits to the SAME place.
/// Newest first (index 0 = "오늘", highlighted in coral). Mirrors components/legacy/ReturnTimeline.jsx.
public struct ReturnTimeline: View {
    let place: String
    let layers: [ReturnLayer]

    public init(place: String = "성수동 적산가옥", layers: [ReturnLayer]) {
        self.place = place
        self.layers = layers
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(layers.enumerated()), id: \.element.id) { idx, layer in
                    layerRow(layer, isNow: idx == 0, isLast: idx == layers.count - 1)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 22)
        }
        .frame(width: 360)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1)
        )
        .traceShadow(.lg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이 자리에 다시 서다")
                .traceType(.eyebrow)
                .foregroundStyle(TraceColor.accent)
            Text(place)
                .traceType(.displayMD)
                .fontWeight(.heavy)
                .foregroundStyle(TraceColor.textPrimary)
                .padding(.top, 6)
            Text("\(layers.count)번의 방문이 이 자리에 쌓였어요")
                .traceType(.bodySM)
                .foregroundStyle(TraceColor.textMuted)
                .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    private func layerRow(_ layer: ReturnLayer, isNow: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // timeline node + connector
            VStack(spacing: 0) {
                Circle()
                    .fill(isNow ? TraceColor.accent : TraceColor.surfaceCard)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().strokeBorder(isNow ? TraceColor.accent : TraceColor.rule, lineWidth: 2))
                    .background(
                        isNow ? Circle().fill(TraceColor.coralWash).frame(width: 21, height: 21) : nil
                    )
                    .padding(.top, 4)
                if !isLast {
                    Rectangle().fill(TraceColor.rule).frame(width: 2)
                        .padding(.top, 4)
                }
            }
            .frame(width: 21)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(layer.year)
                        .traceType(.displaySM)
                        .fontWeight(.heavy)
                        .foregroundStyle(isNow ? TraceColor.accentStrong : TraceColor.textPrimary)
                    if isNow {
                        Text("오늘")
                            .traceType(.eyebrow)
                            .fontWeight(.bold)
                            .foregroundStyle(TraceColor.paper0)
                            .padding(.vertical, 3).padding(.horizontal, 8)
                            .background(TraceColor.accent, in: Capsule())
                    }
                }
                HStack(alignment: .top, spacing: 12) {
                    thumbnail(layer)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(layer.caption)
                            .traceType(.bodyMD)
                            .fontWeight(.bold)
                            .lineSpacing(2)
                            .foregroundStyle(TraceColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        CompanionTag(layer.companion, size: .sm)
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 22)
        }
    }

    private func thumbnail(_ layer: ReturnLayer) -> some View {
        Group {
            if let image = layer.image {
                image.resizable().scaledToFill()
            } else {
                LinearGradient(colors: [layer.vibe.color, TraceColor.paper100],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1)
        )
    }
}
