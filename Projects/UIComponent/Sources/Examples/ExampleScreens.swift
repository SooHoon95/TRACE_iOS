import SwiftUI
import Domain

/// The set of v2 example screens, composed from translated TRACE components.
/// Drives the SampleApp screen switcher (brief §D).
public enum TraceExampleScreen: String, CaseIterable, Identifiable {
    case returnLegacy   // 1. 재방문 레거시 소환 (ReturnTimeline 중심) ★
    case exhibition     // 2. 장소 전시 (ExhibitionTile 그리드 + TopBadge)
    case map            // 3. 지도 (PlacePin)
    case capture        // 4. 순간 남기기 (CaptureComposer)
    case identity       // 5. 여행 정체성 Wrapped (IdentityCard)
    case codex          // 6. 도감 (MomentCard 그리드)

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .returnLegacy: return "재방문 레거시 소환"
        case .exhibition:   return "장소 전시"
        case .map:          return "지도"
        case .capture:      return "순간 남기기"
        case .identity:     return "여행 정체성 Wrapped"
        case .codex:        return "도감"
        }
    }

    @ViewBuilder public var view: some View {
        switch self {
        case .returnLegacy: ReturnLegacyScreen()
        case .exhibition:   ExhibitionScreen()
        case .map:          MapScreen()
        case .capture:      CaptureScreen()
        case .identity:     IdentityScreen()
        case .codex:        CodexScreen()
        }
    }
}

// MARK: - 1. Return-to-place legacy (★ hero)

public struct ReturnLegacyScreen: View {
    public init() {}
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s6) {
                SectionHeader(eyebrow: "다시 이 자리", title: "레거시 소환", action: "성수동")
                ReturnTimeline(place: "성수동 적산가옥", layers: [
                    ReturnLayer(year: "2024", caption: "5년 만에 다시 왔다. 골목이 바뀌었어도 이 자리는 그대로.", companion: .partner, vibe: .scenic),
                    ReturnLayer(year: "2022", caption: "비 오던 날의 적산가옥", companion: .solo, vibe: .calm),
                    ReturnLayer(year: "2021", caption: "친구들과 첫 방문, 다들 사진 찍느라 정신없었지", companion: .friends, vibe: .lively),
                    ReturnLayer(year: "2019", caption: "엄마랑 처음 왔던 그날", companion: .family, vibe: .hidden),
                ])
                .frame(maxWidth: .infinity)
                TraceButton("이 자리에 오늘을 더하기") {}
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }
}

// MARK: - 2. Place exhibition grid

public struct ExhibitionScreen: View {
    public init() {}
    private let tiles: [(place: String, region: String, contributors: Int, top12: Bool, visited: Bool, avatars: [String])] = [
        ("성수동 적산가옥", "서울 성동구", 128, true, true, ["지민", "인선", "수훈"]),
        ("협재 해변", "제주 한림읍", 342, true, false, ["A", "B", "C"]),
        ("감천문화마을", "부산 사하구", 87, false, false, ["하늘", "바다"]),
        ("전주 한옥마을", "전북 전주시", 215, true, true, ["민", "준", "서"]),
    ]
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s6) {
                SectionHeader(eyebrow: "EXHIBITION", title: "장소 전시", action: "전국 1,204곳")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: TraceSpace.s4)], spacing: TraceSpace.s4) {
                    ForEach(tiles, id: \.place) { t in
                        ExhibitionTile(place: t.place, region: t.region, contributors: t.contributors,
                                       hasTop12: t.top12, visited: t.visited, avatars: t.avatars)
                    }
                }
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }
}

// MARK: - 3. Map (PlacePin on warm dark)

public struct MapScreen: View {
    public init() {}
    public var body: some View {
        ZStack(alignment: .bottom) {
            TraceColor.surfaceDark.ignoresSafeArea()

            // scattered pins
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    pin(0.92, .visited, 24, "성수", x: 0.30, y: 0.28, w: w, h: h)
                    pin(0.62, .exhibition, nil, "한림", x: 0.70, y: 0.22, w: w, h: h)
                    pin(0.45, .exhibition, 8, nil, x: 0.52, y: 0.46, w: w, h: h)
                    pin(0.78, .visited, 15, "전주", x: 0.24, y: 0.60, w: w, h: h)
                    pin(0.20, .exhibition, nil, nil, x: 0.80, y: 0.62, w: w, h: h)
                }
            }

            // bottom card
            VStack(alignment: .leading, spacing: TraceSpace.s3) {
                Text("기억의 밀도")
                    .traceType(.eyebrow)
                    .foregroundStyle(TraceColor.coral300)
                Text("핀이 클수록 더 많은 순간이 쌓인 곳이에요")
                    .traceType(.bodyMD)
                    .foregroundStyle(TraceColor.textOnDark)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TraceSpace.s5)
            .background(TraceColor.surfaceDarkCard, in: RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous).strokeBorder(TraceColor.surfaceDarkLine, lineWidth: 1))
            .padding(TraceSpace.s4)
        }
    }

    private func pin(_ density: Double, _ variant: PlacePin.Variant, _ count: Int?, _ label: String?,
                     x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        PlacePin(density: density, variant: variant, count: count, label: label)
            .position(x: w * x, y: h * y)
    }
}

// MARK: - 4. Leave a moment (CaptureComposer)

public struct CaptureScreen: View {
    public init() {}
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s6) {
                SectionHeader(eyebrow: "남기기", title: "순간 남기기")
                CaptureComposer(place: "성수동 적산가옥") { _ in }
                    .frame(maxWidth: .infinity)
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }
}

// MARK: - 5. Travel identity Wrapped

public struct IdentityScreen: View {
    public init() {}
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s6) {
                SectionHeader(eyebrow: "WRAPPED", title: "여행 정체성", action: "2024")
                IdentityCard(title: "성수동의 단골", name: "지민", year: "2024",
                             places: 37, years: 9, moments: 214)
                    .frame(maxWidth: .infinity)
                TraceButton("공유하기", variant: .soft) {}
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }
}

// MARK: - 6. Codex (MomentCard grid)

public struct CodexScreen: View {
    public init() {}
    private let moments: [(caption: String, companion: Companion, vibe: VibeTag, date: String, place: String, variant: MomentCard.Variant)] = [
        ("협재 노을 미쳤다", .partner, .scenic, "2024.06", "협재 해변", .featured),
        ("숨은 국숫집 발견", .friends, .foodie, "2023.09", "성수동", .default),
        ("오름 정상에서", .solo, .adventure, "2023.05", "새별오름", .default),
        ("그때 그 골목", .solo, .hidden, "2019.04", "성수동", .myPast),
        ("가족 모두 모인 날", .family, .lively, "2022.12", "전주", .default),
        ("조용한 카페 오후", .partner, .calm, "2024.02", "감천", .default),
    ]
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s6) {
                SectionHeader(eyebrow: "CODEX", title: "도감", action: "214 순간")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: TraceSpace.s4)], alignment: .leading, spacing: TraceSpace.s4) {
                    ForEach(moments, id: \.caption) { m in
                        MomentCard(caption: m.caption, companion: m.companion, vibe: m.vibe,
                                   date: m.date, place: m.place, variant: m.variant)
                    }
                }
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }
}

#Preview("Return Legacy") { ReturnLegacyScreen().onAppear { TraceFonts.registerAll() } }
#Preview("Codex") { CodexScreen().onAppear { TraceFonts.registerAll() } }
