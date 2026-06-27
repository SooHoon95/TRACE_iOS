import SwiftUI
import Domain

/// Browsable gallery of every TRACE v2 design-system component, in light-paper and
/// warm-dark surfaces. Public so the UIComponent SampleApp can render it without
/// importing Domain itself (Domain types stay encapsulated here).
public struct DesignSystemCatalog: View {
    @State private var selectedVibes: Set<VibeTag> = [.scenic, .foodie]
    @State private var tab = "map"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TraceSpace.s8) {
                SectionHeader(eyebrow: "TRACE", title: "디자인 시스템", action: "v2")

                group("Buttons") {
                    TraceButton("primary 버튼") {}
                    TraceButton("soft 버튼", variant: .soft) {}
                    TraceButton("ghost 버튼", variant: .ghost) {}
                    TraceButton("비활성", action: {}).disabled(true)
                    HStack(spacing: TraceSpace.s2) {
                        TraceButton("sm", size: .sm, fullWidth: false) {}
                        TraceButton("md", size: .md, fullWidth: false) {}
                        TraceButton("lg", size: .lg, fullWidth: false) {}
                    }
                }

                group("Vibe Tags") {
                    flow(VibeTag.allCases) { v in
                        VibeTagChip(v, selected: selectedVibes.contains(v)) {
                            if selectedVibes.contains(v) { selectedVibes.remove(v) } else { selectedVibes.insert(v) }
                        }
                    }
                }

                group("Companion Tags") {
                    flow(Companion.allCases) { c in CompanionTag(c) }
                }

                group("Top Badges") {
                    HStack(spacing: TraceSpace.s3) {
                        TopBadge()
                        TopBadge(rank: 3)
                        TopBadge(label: "큐레이션", size: .sm)
                    }
                }

                group("Avatars") {
                    HStack(spacing: TraceSpace.s4) {
                        Avatar(name: "최수훈", size: .xs)
                        Avatar(name: "인선", size: .sm)
                        Avatar(name: "지민", size: .md, ring: true)
                        Avatar(name: "AB", size: .lg)
                    }
                }

                group("Moment Cards (도감)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: TraceSpace.s4) {
                            MomentCard(caption: "협재 노을 미쳤다", companion: .partner, vibe: .scenic,
                                       date: "2024.06", place: "협재 해변", variant: .featured)
                            MomentCard(caption: "숨은 국숫집 발견", companion: .friends, vibe: .foodie,
                                       date: "2023.09", place: "성수동")
                            MomentCard(caption: "그때 그 골목", companion: .solo, vibe: .hidden,
                                       date: "2019.04", place: "성수동", variant: .myPast)
                        }
                    }
                }

                group("Exhibition Tiles") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: TraceSpace.s4) {
                            ExhibitionTile(place: "성수동 적산가옥", region: "서울 성동구",
                                           contributors: 128, visited: true,
                                           avatars: ["지민", "인선", "수훈"])
                            ExhibitionTile(place: "협재 해변", region: "제주 한림읍",
                                           contributors: 342, hasTop12: false,
                                           avatars: ["A", "B"])
                        }
                    }
                }

                group("Capture Composer") {
                    CaptureComposer(place: "성수동 적산가옥") { _ in }
                }

                group("Return Timeline (★ 레거시 히어로)") {
                    ReturnTimeline(place: "성수동 적산가옥", layers: sampleLayers)
                }

                group("Tab Bar") {
                    TraceTabBar(selection: $tab)
                        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
                }

                darkGroup("On Dark — Map / AR / Identity") {
                    HStack(alignment: .bottom, spacing: 28) {
                        PlacePin(density: 0.9, variant: .visited, count: 24, label: "성수")
                        PlacePin(density: 0.5, variant: .exhibition, label: "한림")
                        PlacePin(density: 0.15, variant: .exhibition)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TraceSpace.s5)

                    ExcavationMeter(level: .hot, distance: 0, onSite: true) {}
                    ExcavationMeter(level: .cool, distance: 180, onSite: false) {}
                    IdentityCard()
                }
            }
            .padding(TraceSpace.s5)
        }
        .background(TraceColor.surfaceApp.ignoresSafeArea())
    }

    private var sampleLayers: [ReturnLayer] {
        [
            ReturnLayer(year: "2024", caption: "다시 이 자리. 여전히 좋다.", companion: .partner, vibe: .scenic),
            ReturnLayer(year: "2021", caption: "친구들과 왁자지껄했던 날", companion: .friends, vibe: .lively),
            ReturnLayer(year: "2019", caption: "혼자 조용히 머문 오후", companion: .solo, vibe: .calm),
        ]
    }

    // MARK: - layout helpers

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TraceSpace.s3) {
            Text(title).traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
            content()
        }
    }

    @ViewBuilder
    private func darkGroup<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TraceSpace.s3) {
            Text(title).traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
            VStack(alignment: .leading, spacing: TraceSpace.s4) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(TraceSpace.s5)
                .background(TraceColor.surfaceDark, in: RoundedRectangle(cornerRadius: TraceRadius.xl, style: .continuous))
        }
    }

    @ViewBuilder
    private func flow<T: Hashable>(_ items: [T], @ViewBuilder _ cell: @escaping (T) -> some View) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { cell($0) }
        }
    }
}

#Preview {
    DesignSystemCatalog()
        .onAppear { TraceFonts.registerAll() }
}
