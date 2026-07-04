import SwiftUI
import Domain

/// 나의 여행 정체성 카드 — the live card. Pure presentation over a `TravelIdentityModel`
/// (computed deterministically in Domain). Renders at a fixed 320pt width so `ImageRenderer`
/// output (Task 6 share) is stable. `placeName` is PRE-RESOLVED by the VM (Task 5); this view
/// never touches the store.
public struct TravelIdentityCardView: View {
    private let model: TravelIdentityModel
    private let name: String
    private let placeName: String?

    public init(model: TravelIdentityModel, name: String, placeName: String? = nil) {
        self.model = model
        self.name = name
        self.placeName = placeName
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if model.dataLevel == .empty {
                emptyBody
            } else {
                filledBody
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 24)
        .frame(width: 320, alignment: .leading)
        .background(
            LinearGradient(colors: [TraceColor.char700, TraceColor.char900],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous)
                .strokeBorder(TraceColor.surfaceDarkLine, lineWidth: 1)
        )
        .traceShadow(.lg)
    }

    // MARK: header (eyebrow + headline 칭호)

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("여행 정체성")
                .traceType(.eyebrow)
                .foregroundStyle(TraceColor.coral300)
            Text(model.headline)
                .traceType(.displayLG)
                .fontWeight(.heavy)
                .foregroundStyle(TraceColor.paper0)
                .padding(.top, 6)
            Text("\(name)님의 여행 성향")
                .traceType(.bodySM)
                .foregroundStyle(TraceColor.textOnDarkMuted)
        }
    }

    // MARK: empty

    private var emptyBody: some View {
        Text(model.lowDataHint ?? TravelIdentity.lowDataHintText)
            .traceType(.bodySM)
            .foregroundStyle(TraceColor.textOnDarkMuted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 22)
    }

    // MARK: filled (low or full)

    private var filledBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            section("무드 분포") { TraitDistributionBar(slices: vibeSlices) }
            if !companionsPresent.isEmpty {
                section("동행") { companionRow }
            }
            section("시간대") { TraitDistributionBar(slices: timeBandSlices) }
            regionStat
            if !model.highlights.isEmpty {
                section("하이라이트") { highlightsStrip }
            }
            if let hint = model.lowDataHint {
                Text(hint)
                    .traceType(.bodyXS)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }
        }
        .padding(.top, 22)
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .traceType(.bodySM)
                .fontWeight(.semibold)
                .foregroundStyle(TraceColor.textOnDarkMuted)
            content()
        }
    }

    // MARK: distribution slices (via the pure helper)

    private var vibeSlices: [CompositionSlice] {
        distributionSlices(model.distribution.vibeCounts, order: VibeTag.allCases,
                           label: { $0.label }, color: { $0.color })
    }

    private var timeBandSlices: [CompositionSlice] {
        distributionSlices(model.distribution.timeBandCounts, order: TimeBand.allCases,
                           label: { $0.bandLabel }, color: { $0.bandColor })
    }

    // MARK: companion chips

    private var companionsPresent: [Companion] {
        Companion.allCases.filter { (model.distribution.companionCounts[$0] ?? 0) > 0 }
    }

    private var companionRow: some View {
        HStack(spacing: 8) {
            ForEach(companionsPresent, id: \.self) { c in
                let isDominant = c == model.distribution.dominantCompanion
                HStack(spacing: 5) {
                    Text(c.glyph)
                    Text(c.label)
                }
                .traceType(.bodyXS)
                .foregroundStyle(isDominant ? TraceColor.char900 : TraceColor.textOnDark)
                .padding(.vertical, 6)
                .padding(.horizontal, 11)
                .background(isDominant ? TraceColor.coral300 : TraceColor.surfaceDarkCard,
                            in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: region

    private var regionStat: some View {
        HStack(spacing: 6) {
            Text("장소 \(model.distribution.regionCounts.count)곳")
                .traceType(.bodySM)
                .fontWeight(.semibold)
                .foregroundStyle(TraceColor.textOnDark)
            if let placeName {
                Text("· 자주 간 곳 \(placeName)")
                    .traceType(.bodyXS)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: highlights

    private var highlightsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.highlights, id: \.moment.id) { h in
                HStack(spacing: 11) {
                    Circle()
                        .fill(h.moment.vibe?.color ?? TraceColor.surfaceDarkCard)
                        .frame(width: 34, height: 34)
                        .overlay(Text(h.moment.vibe?.label.prefix(1) ?? "·")
                            .traceType(.bodyXS)
                            .foregroundStyle(TraceColor.char900))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reasonLabel(h.reason))
                            .traceType(.eyebrow)
                            .foregroundStyle(TraceColor.coral300)
                        Text(h.moment.caption ?? "남긴 순간")
                            .traceType(.bodyXS)
                            .foregroundStyle(TraceColor.textOnDark)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func reasonLabel(_ r: HighlightReason) -> String {
        switch r {
        case .representative: return "대표"
        case .rare:           return "희귀"
        }
    }
}

// MARK: - Previews

#Preview("full") {
    let coord = Coordinate(latitude: 33.45, longitude: 126.56)
    let place = UUID()
    func m(_ v: VibeTag?, _ c: Companion?, _ cap: String?) -> Moment {
        Moment(placeID: place, authorID: UUID(), photoRef: "p", caption: cap,
               companion: c, vibe: v, coordinate: coord)
    }
    return TravelIdentityCardView(
        model: TravelIdentity.compute([
            m(.scenic, .partner, "노을 좋았다"), m(.scenic, .solo, "혼자 걷기"),
            m(.calm, .family, "고요"), m(.foodie, .friends, "맛집")
        ]),
        name: "지민", placeName: "월정리 해변"
    ).padding().background(TraceColor.paper50)
}

#Preview("low") {
    let coord = Coordinate(latitude: 33.45, longitude: 126.56)
    let one = Moment(placeID: UUID(), authorID: UUID(), photoRef: "p",
                     companion: .solo, vibe: .scenic, coordinate: coord)
    return TravelIdentityCardView(model: TravelIdentity.compute([one]), name: "지민")
        .padding().background(TraceColor.paper50)
}

#Preview("empty") {
    TravelIdentityCardView(model: TravelIdentity.compute([]), name: "지민")
        .padding().background(TraceColor.paper50)
}
