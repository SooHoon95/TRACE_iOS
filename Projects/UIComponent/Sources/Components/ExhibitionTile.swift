import SwiftUI

/// Place exhibition tile — cover photo, place name, contributor count, Top-12 badge, my-visit mark.
/// Mirrors components/content/ExhibitionTile.jsx. Cover has a dark bottom scrim for legible text.
public struct ExhibitionTile: View {
    let image: Image?
    let place: String
    let region: String?
    let contributors: Int
    let hasTop12: Bool
    let visited: Bool
    let avatars: [String]

    public init(image: Image? = nil,
                place: String,
                region: String? = nil,
                contributors: Int = 0,
                hasTop12: Bool = true,
                visited: Bool = false,
                avatars: [String] = []) {
        self.image = image
        self.place = place
        self.region = region
        self.contributors = contributors
        self.hasTop12 = hasTop12
        self.visited = visited
        self.avatars = avatars
    }

    public var body: some View {
        VStack(spacing: 0) {
            cover
            footer
        }
        .frame(width: 280)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1)
        )
        .traceShadow(.md)
    }

    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image {
                    image.resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [TraceColor.vibeCalm, TraceColor.char700],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(width: 280, height: 200)
            .clipped()

            // bottom scrim
            LinearGradient(
                colors: [Color(hex: 0x241C16).opacity(0.72), .clear],
                startPoint: .bottom, endPoint: .center
            )
            .frame(width: 280, height: 200)

            // top-left Top-12, top-right visited
            VStack {
                HStack(alignment: .top) {
                    if hasTop12 { TopBadge() }
                    Spacer()
                    if visited { visitedBadge }
                }
                Spacer()
            }
            .padding(12)
            .frame(width: 280, height: 200, alignment: .top)

            // place name + region
            VStack(alignment: .leading, spacing: 3) {
                Text(place)
                    .traceType(.displaySM)
                    .fontWeight(.heavy)
                    .foregroundStyle(TraceColor.paper0)
                if let region {
                    Text(region)
                        .traceType(.bodySM)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: 0xF4ECE0).opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(width: 280, height: 200)
    }

    private var visitedBadge: some View {
        HStack(spacing: 5) {
            Text("✓").foregroundStyle(TraceColor.coral300)
            Text("다녀감")
        }
        .traceType(.eyebrow)
        .fontWeight(.bold)
        .foregroundStyle(TraceColor.paper0)
        .padding(.vertical, 4).padding(.horizontal, 9)
        .background(Color(hex: 0x241C16).opacity(0.55), in: Capsule())
    }

    private var footer: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(avatars.prefix(3).enumerated()), id: \.offset) { idx, a in
                    Avatar(name: a, size: .xs)
                        .overlay(Circle().strokeBorder(TraceColor.surfaceCard, lineWidth: 2))
                        .padding(.leading, idx == 0 ? 0 : -8)
                        .zIndex(Double(3 - idx))
                }
                Text("기여 \(contributors)")
                    .traceType(.bodySM)
                    .fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textSecondary)
                    .padding(.leading, 8)
            }
            Spacer(minLength: 0)
            Text("둘러보기 ›")
                .traceType(.bodySM)
                .fontWeight(.bold)
                .foregroundStyle(TraceColor.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
