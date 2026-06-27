import SwiftUI
import Domain
import UIComponent

/// 장소 전시 — a place's "모두의 순간" as a newest-first grid, with the FOMO header
/// ("여기 N명이 남겼어") and the big "너도 남겨" claiming CTA.
public struct PlaceExhibitionView: View {
    @ObservedObject var vm: ClaimViewModel

    public init(vm: ClaimViewModel) {
        self.vm = vm
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if vm.exhibition == nil && vm.isLoading {
                        TraceLoadingView().frame(height: 220)
                    } else if vm.exhibition == nil, let msg = vm.errorMessage {
                        TraceErrorView(message: msg) { Task { await vm.load() } }
                            .frame(height: 220)
                    } else if let ex = vm.exhibition, !ex.isEmpty {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ex.moments) { MomentGridCell(moment: $0) }
                        }
                    } else {
                        emptyState
                    }
                    Color.clear.frame(height: 84)   // room for the floating CTA
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
            claimCTA
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .overlay(alignment: .top) { joinFeedback }
        .task { await vm.load() }
        .sheet(isPresented: $vm.isComposing) {
            LeaveMomentView(vm: vm)
                .presentationDetents([.large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("장소 전시")
                .traceType(.eyebrow)
                .foregroundStyle(TraceColor.accent)
            Text(vm.placeDisplayName)
                .traceType(.displayLG)
                .fontWeight(.heavy)
                .foregroundStyle(TraceColor.textPrimary)
            if vm.contributorCount > 0 {
                Text("여기 \(vm.contributorCount)명이 순간을 남겼어")
                    .traceType(.bodyMD)
                    .foregroundStyle(TraceColor.textSecondary)
            } else {
                Text("아직 아무도 남기지 않았어 — 첫 순간을 남겨봐")
                    .traceType(.bodyMD)
                    .foregroundStyle(TraceColor.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("📷")
                .font(.system(size: 40))
            Text("이 자리의 첫 순간이 되어줘")
                .traceType(.bodyMD)
                .foregroundStyle(TraceColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var claimCTA: some View {
        TraceButton("＋ 너도 여기 남겨", size: .lg) {
            vm.isComposing = true
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var joinFeedback: some View {
        if let msg = vm.errorMessage, vm.exhibition != nil {
            TraceErrorBanner(msg)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    withAnimation { vm.errorMessage = nil }
                }
        } else if vm.justJoinedAt != nil {
            Text("이 자리에 합류했어 ✨")
                .traceType(.bodyMD)
                .fontWeight(.semibold)
                .foregroundStyle(TraceColor.paper0)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(TraceColor.accent, in: Capsule())
                .traceShadow(.lg)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    withAnimation { vm.justJoinedAt = nil }
                }
        }
    }
}

// MomentGridCell now lives in UIComponent (shared by 장소 전시 and 도감).
