import SwiftUI
import UIComponent
import Domain
import Collection
import Identity
import LeaveTrace

/// App shell — the 5-tab root (홈·지도·＋남기기·도감·나).
/// A single shared `TraceStore` + `User` are injected at the app root and threaded to every tab,
/// so a moment left via ＋ shows up in 도감/전시 when you navigate there.
/// 홈·지도 are branded placeholders for now. The center ＋ presents the 순간 남기기 flow full-screen.
public struct MainTabFeatureView: View {
  private let store: any TraceStore
  private let user: User
  @State private var selection = "home"
  @State private var presentingClaim = false

  public init(store: any TraceStore = Demo.store(), user: User = .demo) {
    self.store = store
    self.user = user
  }

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
    .fullScreenCover(isPresented: $presentingClaim) {
      ClaimModal(store: store, user: user)
    }
  }

  /// The ＋ tab doesn't switch tabs — it presents the claim flow against the shared store.
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
    case "collection": CollectionFeatureView(store: store, userID: user.id)
    case "me":         IdentityFeatureView(user: user)
    default:           HomePlaceholder()
    }
  }
}

// MARK: - ＋ claim flow (full-screen, shared store)

/// Hosts LeaveTrace's exhibition + claim flow against the shared store, with a 닫기 affordance.
private struct ClaimModal: View {
  let store: any TraceStore
  let user: User
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      LeaveTraceFeatureView(store: store, user: user, place: Demo.seongsan)
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
