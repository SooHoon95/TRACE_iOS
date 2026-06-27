import SwiftUI
import Domain

/// The core unit of TRACE — a photo moment left at a place.
/// Photo + bold one-liner caption + companion + vibe + date · place.
/// Mirrors components/content/MomentCard.jsx. Variants: default · featured (Top-12, larger) · myPast.
public struct MomentCard: View {
    public enum Variant { case `default`, featured, myPast }

    let image: Image?
    let caption: String
    let companion: Companion
    let vibe: VibeTag
    let date: String?
    let place: String?
    let variant: Variant

    public init(image: Image? = nil,
                caption: String,
                companion: Companion = .solo,
                vibe: VibeTag = .scenic,
                date: String? = nil,
                place: String? = nil,
                variant: Variant = .default) {
        self.image = image
        self.caption = caption
        self.companion = companion
        self.vibe = vibe
        self.date = date
        self.place = place
        self.variant = variant
    }

    private var featured: Bool { variant == .featured }
    private var myPast: Bool { variant == .myPast }
    private var width: CGFloat { featured ? 320 : 240 }
    private var photoHeight: CGFloat { featured ? 200 : 150 }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            VStack(alignment: .leading, spacing: 12) {
                Text(caption)
                    .traceType(featured ? .displaySM : .bodyLG)
                    .fontWeight(.heavy)
                    .lineSpacing(featured ? 4 : 2)
                    .foregroundStyle(TraceColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    CompanionTag(companion, size: .sm)
                    VibeTagChip(vibe, size: .sm)
                }

                if date != nil || place != nil {
                    HStack(spacing: 8) {
                        if let date {
                            Text(date).traceType(.bodySM).fontWeight(.semibold).foregroundStyle(TraceColor.textSecondary)
                        }
                        if date != nil && place != nil {
                            Text("·").foregroundStyle(TraceColor.rule)
                        }
                        if let place {
                            Text(place).traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
                        }
                    }
                    .padding(.top, 10)
                    .overlay(alignment: .top) {
                        Rectangle().fill(TraceColor.hairline).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .frame(width: width)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
                .strokeBorder(myPast ? TraceColor.accentSoft : TraceColor.hairline, lineWidth: 1)
        )
        .traceShadow(featured ? .lg : .sm)
    }

    private var photo: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image {
                    image.resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [vibe.color, TraceColor.paper100],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(
                            Text("PHOTO")
                                .traceType(.bodyXS)
                                .tracking(0.12 * 11.5)
                                .foregroundStyle(Color.white.opacity(0.85))
                        )
                }
            }
            .frame(width: width, height: photoHeight)
            .clipped()

            if featured {
                TopBadge().padding(12)
            } else if myPast {
                Text("내 과거")
                    .traceType(.eyebrow)
                    .fontWeight(.bold)
                    .foregroundStyle(TraceColor.paper0)
                    .padding(.vertical, 4).padding(.horizontal, 9)
                    .background(TraceColor.accentStrong, in: Capsule())
                    .padding(12)
            }
        }
    }
}
