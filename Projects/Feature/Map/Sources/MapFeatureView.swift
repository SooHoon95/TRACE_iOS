import SwiftUI
import MapKit
import UIComponent
import Domain
import LeaveTrace

/// Loads places (that have exhibitions) for the map from the shared store.
@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var places: [Place] = []
    private let store: any TraceStore
    init(store: any TraceStore) { self.store = store }

    func load() async {
        places = (try? await store.nearby(Coordinate(latitude: 33.38, longitude: 126.55),
                                          radiusMeters: 5_000_000)) ?? []
    }
}

/// 🗺️ 지도 — PlacePin(기억 밀도)로 전시 있는 장소 표시. 핀 탭 → 미리보기 → 전시·남기기.
public struct MapFeatureView: View {
    @StateObject private var vm: MapViewModel
    private let store: any TraceStore
    private let user: User
    private let photoStore: any PhotoStore
    @State private var preview: Place?
    @State private var opening: Place?

    private static let jeju = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.38, longitude: 126.55),
        span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
    )

    public init(store: any TraceStore = Demo.store(),
                user: User = .demo,
                photoStore: any PhotoStore = LocalPhotoStore()) {
        self.store = store
        self.user = user
        self.photoStore = photoStore
        _vm = StateObject(wrappedValue: MapViewModel(store: store))
    }

    public var body: some View {
        Map(initialPosition: .region(Self.jeju)) {
            ForEach(vm.places) { place in
                Annotation(place.displayName, coordinate: coord(place)) {
                    Button { preview = place } label: {
                        PlacePin(density: density(place),
                                 variant: .exhibition,
                                 count: place.contributorCount)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) { previewCard }
        .task { await vm.load() }
        .sheet(item: $opening) { place in
            ClaimSheet(store: store, user: user, photoStore: photoStore, place: place)
        }
    }

    @ViewBuilder private var previewCard: some View {
        if let place = preview {
            VStack(alignment: .leading, spacing: 12) {
                Text(place.displayName)
                    .traceType(.displaySM).fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textPrimary)
                Text(place.contributorCount > 0 ? "여기 \(place.contributorCount)명이 남겼어" : "아직 비어있어 — 첫 순간을 남겨봐")
                    .traceType(.bodyMD).foregroundStyle(TraceColor.textSecondary)
                TraceButton("여기 전시 · 남기기", size: .lg) {
                    opening = place
                    preview = nil
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TraceColor.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1))
            .traceShadow(.lg)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func coord(_ p: Place) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)
    }

    private func density(_ p: Place) -> Double {
        min(1, Double(p.momentCount) / 5.0)
    }
}

/// 핀 미리보기에서 여는 전시·클레임 플로우(공유 스토어).
private struct ClaimSheet: View {
    let store: any TraceStore
    let user: User
    let photoStore: any PhotoStore
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LeaveTraceFeatureView(store: store, user: user, photoStore: photoStore, place: place)
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
