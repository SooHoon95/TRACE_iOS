import SwiftUI
import UIComponent
import Domain
import Home
import Collection
import Identity
import LeaveTrace
import Map

/// App shell — the 5-tab root (홈·지도·＋남기기·도감·나).
/// A single shared `TraceStore` + `User` are injected at the app root and threaded to every tab,
/// so a moment left via ＋ shows up in 도감/전시 when you navigate there.
/// 홈·지도 are branded placeholders for now. The center ＋ presents the 순간 남기기 flow full-screen.
public struct MainTabFeatureView: View {
  private let store: any TraceStore
  private let user: User
  private let photoStore: any PhotoStore
  private let location: any LocationProviding
  private let onSignOut: () -> Void
  @State private var selection = "home"
  @State private var presentingClaim = false

  public init(store: any TraceStore = Demo.store(),
              user: User = .demo,
              photoStore: any PhotoStore = LocalPhotoStore(),
              location: any LocationProviding = FixedLocationProvider(),
              onSignOut: @escaping () -> Void = {}) {
    self.store = store
    self.user = user
    self.photoStore = photoStore
    self.location = location
    self.onSignOut = onSignOut
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
      ClaimModal(store: store, user: user, photoStore: photoStore, location: location)
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
    case "map":        MapFeatureView(store: store, user: user, photoStore: photoStore)
    case "collection": CollectionFeatureView(store: store, userID: user.id, photoStore: photoStore)
    case "me":         IdentityFeatureView(user: user, onSignOut: onSignOut)
    default:           HomeView(store: store, user: user, photoStore: photoStore)
    }
  }
}

// MARK: - ＋ claim flow (full-screen, shared store)

/// Hosts LeaveTrace's exhibition + claim flow against the shared store, with a 닫기 affordance.
private struct ClaimModal: View {
  let store: any TraceStore
  let user: User
  let photoStore: any PhotoStore
  let location: any LocationProviding
  @Environment(\.dismiss) private var dismiss
  @State private var place: Place?
  @State private var failed = false

  var body: some View {
    NavigationStack {
      Group {
        if let place {
          LeaveTraceFeatureView(store: store, user: user, photoStore: photoStore, place: place)
        } else if failed {
          locationUnavailable
        } else {
          loading
        }
      }
      .toolbar(.hidden, for: .navigationBar)
      .safeAreaInset(edge: .top) {
        HStack {
          Spacer()
          Button { dismiss() } label: {
            Text("닫기").traceType(.bodyMD).fontWeight(.bold)
              .foregroundStyle(TraceColor.textSecondary)
              .padding(.horizontal, 6).padding(.vertical, 4)
          }
        }
        .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 8)
        .background(TraceColor.paper50)
      }
    }
    .task { await resolveHere() }
  }

  /// Get the device's current position, then resolve-or-create the place there so the ＋ flow
  /// claims at the user's real location (snaps to an existing place within radius).
  private func resolveHere() async {
    do {
      let coord = try await location.current()
      place = try await store.resolveOrCreate(at: coord, snapRadiusMeters: 40, suggestedName: "현재 위치")
    } catch {
      failed = true
    }
  }

  private var loading: some View {
    VStack(spacing: 12) {
      ProgressView().controlSize(.large).tint(TraceColor.accent)
      Text("현재 위치 확인 중…")
        .traceType(.bodyMD).foregroundStyle(TraceColor.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }

  private var locationUnavailable: some View {
    VStack(spacing: 10) {
      Text("📍").font(.system(size: 40))
      Text("위치를 가져오지 못했어요")
        .traceType(.bodyLG).fontWeight(.bold).foregroundStyle(TraceColor.textPrimary)
      Text("설정에서 위치 권한을 허용하면 지금 이 자리에 남길 수 있어요")
        .traceType(.bodyMD).foregroundStyle(TraceColor.textMuted)
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}

