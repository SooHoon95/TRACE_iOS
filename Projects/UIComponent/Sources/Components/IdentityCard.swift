import SwiftUI

/// One slice of the companion-composition bar on IdentityCard.
public struct CompositionSlice: Identifiable {
    public let id = UUID()
    public let label: String
    public let pct: Int
    public let color: Color

    public init(label: String, pct: Int, color: Color) {
        self.label = label
        self.pct = pct
        self.color = color
    }
}

/// ★ Shareable Wrapped identity card (warm dark) — earned title, footstep stats, companion composition.
/// Mirrors components/legacy/IdentityCard.jsx.
public struct IdentityCard: View {
    let title: String
    let name: String
    let year: String
    let places: Int
    let years: Int
    let moments: Int
    let composition: [CompositionSlice]

    public init(title: String = "성수동의 단골",
                name: String = "지민",
                year: String = "2024",
                places: Int = 37,
                years: Int = 9,
                moments: Int = 214,
                composition: [CompositionSlice]? = nil) {
        self.title = title
        self.name = name
        self.year = year
        self.places = places
        self.years = years
        self.moments = moments
        self.composition = composition ?? [
            CompositionSlice(label: "연인", pct: 38, color: TraceColor.coral500),
            CompositionSlice(label: "가족", pct: 27, color: TraceColor.vibeLively),
            CompositionSlice(label: "친구", pct: 22, color: TraceColor.vibeScenery),
            CompositionSlice(label: "혼자", pct: 13, color: TraceColor.vibeCalm),
        ]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TRACE WRAPPED")
                    .traceType(.eyebrow)
                    .foregroundStyle(TraceColor.coral300)
                Spacer()
                Text(year)
                    .traceType(.bodyXS)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(name)님의 칭호")
                    .traceType(.bodySM)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
                Text(title)
                    .traceType(.displayLG)
                    .fontWeight(.heavy)
                    .foregroundStyle(TraceColor.paper0)
            }
            .padding(.top, 18)

            HStack(spacing: 10) {
                stat(places, "장소")
                stat(years, "년차")
                stat(moments, "순간")
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 0) {
                Text("동행 구성")
                    .traceType(.bodySM)
                    .fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textOnDarkMuted)
                    .padding(.bottom, 9)
                compositionBar
                    .padding(.bottom, 11)
                legend
            }
            .padding(.top, 22)
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

    private func stat(_ n: Int, _ l: String) -> some View {
        VStack(spacing: 5) {
            Text("\(n)")
                .traceType(.displayMD)
                .fontWeight(.heavy)
                .foregroundStyle(TraceColor.coral300)
            Text(l)
                .traceType(.bodyXS)
                .foregroundStyle(TraceColor.textOnDarkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(TraceColor.surfaceDarkCard, in: RoundedRectangle(cornerRadius: TraceRadius.md, style: .continuous))
    }

    private var compositionBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(composition) { slice in
                    Rectangle()
                        .fill(slice.color)
                        .frame(width: geo.size.width * CGFloat(slice.pct) / 100)
                }
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
    }

    private var legend: some View {
        FlexibleLegend(slices: composition)
    }
}

/// Wrapping legend row for the composition slices.
private struct FlexibleLegend: View {
    let slices: [CompositionSlice]

    var body: some View {
        // 4 slices fit comfortably in two columns at width 320.
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(stride(from: 0, to: slices.count, by: 2)), id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row..<min(row + 2, slices.count), id: \.self) { i in
                        item(slices[i])
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func item(_ s: CompositionSlice) -> some View {
        HStack(spacing: 6) {
            Circle().fill(s.color).frame(width: 8, height: 8)
            Text("\(s.label) \(s.pct)%")
                .traceType(.bodyXS)
                .foregroundStyle(TraceColor.textOnDark)
        }
    }
}
