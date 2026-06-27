import SwiftUI
import UIComponent
import Domain

/// 도감 — the signed-in user's own moments accruing over time, newest-first grid,
/// with a summary bar and a "나만" lock badge on private moments.
public struct CollectionFeatureView: View {
  @StateObject private var vm: CollectionViewModel

  public init() {
    _vm = StateObject(wrappedValue: CollectionViewModel(store: CollectionDemo.store(),
                                                        userID: CollectionDemo.user.id))
  }

  private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        summaryBar
        if vm.moments.isEmpty {
          emptyState
        } else {
          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(vm.moments) { MomentGridCell(moment: $0, showPrivateLock: true) }
          }
        }
      }
      .padding(.horizontal, 18)
      .padding(.top, 12)
    }
    .background(TraceColor.paper50.ignoresSafeArea())
    .task { await vm.load() }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("도감")
        .traceType(.eyebrow)
        .foregroundStyle(TraceColor.accent)
      Text("내 순간")
        .traceType(.displayLG)
        .fontWeight(.heavy)
        .foregroundStyle(TraceColor.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var summaryBar: some View {
    HStack(spacing: 0) {
      stat(value: vm.moments.count, label: "남긴 순간")
      Rectangle().fill(TraceColor.hairline).frame(width: 1, height: 28)
      stat(value: vm.placeCount, label: "다녀간 장소")
    }
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity)
    .background(TraceColor.surfaceCard)
    .clipShape(RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: TraceRadius.lg, style: .continuous)
        .strokeBorder(TraceColor.hairline, lineWidth: 1)
    )
  }

  private func stat(value: Int, label: String) -> some View {
    VStack(spacing: 3) {
      Text("\(value)")
        .traceType(.displaySM)
        .fontWeight(.heavy)
        .foregroundStyle(TraceColor.textPrimary)
      Text(label)
        .traceType(.bodySM)
        .foregroundStyle(TraceColor.textMuted)
    }
    .frame(maxWidth: .infinity)
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Text("📖").font(.system(size: 40))
      Text("아직 남긴 순간이 없어")
        .traceType(.bodyLG).fontWeight(.bold)
        .foregroundStyle(TraceColor.textSecondary)
      Text("지금 이 자리에서 시작해")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.textMuted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }
}
