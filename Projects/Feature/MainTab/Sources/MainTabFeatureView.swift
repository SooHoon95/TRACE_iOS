import SwiftUI
import UIComponent
import Domain
import Collection
import Identity
import LeaveTrace

/// App shell — the 5-tab root (홈·지도·＋남기기·도감·나).
/// 도감/나 are real feature roots; 홈·지도 are branded placeholders for now.
/// The center ＋ presents the 순간 남기기(claim) flow full-screen instead of switching tabs.
///
/// Note: each tab feature currently owns its own in-memory demo store, so data isn't shared
/// across tabs yet — that arrives with the real composition root + auth (Phase 2).
public struct MainTabFeatureView: View {
  @State private var selection = "home"
  @State private var presentingClaim = false

  public init() {}

  private let tabs: [TraceTab] = [
    TraceTab(id: "home",       label: "홈",     icon: .exhibit),
    TraceTab(id: "map",        label: "지도",   icon: .map),
    TraceTab(id: "capture",    label: "남기기", icon: .capture),
    TraceTab(id: "collection", label: "도감",   icon: .legacy),
    TraceTab(id: "me",         label: "나",     icon: .me)
  ]

  public var body: some View {
    VStack(spacing: 0) {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      TraceTabBar(items: tabs, selection: tabSelection)
    }
    .background(TraceColor.paper50.ignoresSafeArea())
    .fullScreenCover(isPresented: $presentingClaim) { ClaimModal() }
  }

  /// The ＋ tab doesn't switch tabs — it presents the claim flow.
  private var tabSelection: Binding<String> {
    Binding(
      get: { selection },
      set: { newValue in
        if newValue == "capture" { presentingClaim = true }
        else { selection = newValue }
      }
    )
  }

  @ViewBuilder private var content: some View {
    switch selection {
    case "map":        MapPlaceholder()
    case "collection": CollectionFeatureView()
    case "me":         IdentityFeatureView()
    default:           HomePlaceholder()
    }
  }
}

// MARK: - ＋ claim flow (full-screen)

/// Hosts LeaveTrace's exhibition + claim flow with a 닫기 affordance.
private struct ClaimModal: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      LeaveTraceFeatureView()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
          HStack {
            Spacer()
            Button { dismiss() } label: {
              Text("닫기").traceType(.bodyMD).fontWeight(.bold)
                .foregroundStyle(TraceColor.textSecondary)
            }
          }
          .padding(.horizontal, 18).padding(.vertical, 10)
          .background(TraceColor.paper50)
        }
    }
  }
}

// MARK: - Placeholders (홈 · 지도)

/// 홈 — activity feed lands here later (ActivityFeedItem/PlacePromptCard). Branded empty state for now.
private struct HomePlaceholder: View {
  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      Text("TRACE").traceType(.displayLG).fontWeight(.heavy)
        .foregroundStyle(TraceColor.textPrimary)
      Text("오늘은 어디에 남길까?")
        .traceType(.bodyLG).foregroundStyle(TraceColor.textSecondary)
      Text("🔥 방금 남들이 남긴 순간 · 📍 내 주변 남길 자리")
        .traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
      Text("홈 피드 준비 중")
        .traceType(.eyebrow).foregroundStyle(TraceColor.accent)
        .padding(.top, 6)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}

/// 지도 — MapKit + PlacePin lands here later. Warm-dark themed placeholder.
private struct MapPlaceholder: View {
  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      Text("◉").font(.system(size: 40)).foregroundStyle(TraceColor.accentSoft)
      Text("이 근처는 아직 비어있어")
        .traceType(.bodyLG).fontWeight(.bold)
        .foregroundStyle(TraceColor.textOnDark)
      Text("첫 핀을 꽂아봐")
        .traceType(.bodyMD).foregroundStyle(TraceColor.textOnDarkMuted)
      Text("지도 준비 중")
        .traceType(.eyebrow).foregroundStyle(TraceColor.accentSoft)
        .padding(.top, 6)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.surfaceDark)
  }
}
