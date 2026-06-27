import SwiftUI

/// Coral gradient star badge marking a Top-12 curated photo / featured place.
/// Mirrors components/core/TopBadge.jsx. If `rank` is set, shows "#<rank>"; otherwise `label`.
public struct TopBadge: View {
    public enum Size { case sm, md }

    let rank: Int?
    let label: String
    let size: Size

    public init(rank: Int? = nil, label: String = "TOP 12", size: Size = .md) {
        self.rank = rank
        self.label = label
        self.size = size
    }

    private var sm: Bool { size == .sm }

    public var body: some View {
        HStack(spacing: 6) {
            Text("★").font(.system(size: sm ? 10 : 12))
            Text(rank != nil ? "#\(rank!)" : label)
        }
        .traceType(sm ? .eyebrow : .bodyXS)
        .fontWeight(.bold)
        .tracking(0.1 * (sm ? 11 : 11.5))
        .foregroundStyle(TraceColor.paper0)
        .padding(.vertical, sm ? 4 : 5)
        .padding(.horizontal, sm ? 8 : 11)
        .background(
            LinearGradient(
                colors: [TraceColor.coral500, TraceColor.coral600],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .traceShadow(.sm)
    }
}
