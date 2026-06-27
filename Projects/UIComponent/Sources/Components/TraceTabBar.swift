import SwiftUI

/// One bottom-nav item. `icon` maps to a TRACE glyph; `capture` renders as the raised coral FAB.
public struct TraceTab: Identifiable {
    public enum Icon: String {
        case exhibit, map, capture, legacy, me

        /// Glyph from components/core/TabBar.jsx ICONS.
        public var glyph: String {
            switch self {
            case .exhibit: return "❖"
            case .map:     return "◉"
            case .capture: return "＋"
            case .legacy:  return "❐"
            case .me:      return "●"
            }
        }
    }

    public let id: String
    public let label: String
    public let icon: Icon

    public init(id: String, label: String, icon: Icon) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

/// Bottom navigation with a raised coral capture FAB in the center.
/// Defaults to TRACE's 5 tabs (전시·지도·남기기·레거시·나). Mirrors components/core/TabBar.jsx.
/// (Add safe-area bottom inset at the app level.)
public struct TraceTabBar: View {
    let items: [TraceTab]
    @Binding var selection: String

    public static let defaultTabs: [TraceTab] = [
        TraceTab(id: "exhibit", label: "전시",  icon: .exhibit),
        TraceTab(id: "map",     label: "지도",  icon: .map),
        TraceTab(id: "capture", label: "남기기", icon: .capture),
        TraceTab(id: "legacy",  label: "레거시", icon: .legacy),
        TraceTab(id: "me",      label: "나",    icon: .me),
    ]

    public init(items: [TraceTab] = TraceTabBar.defaultTabs, selection: Binding<String>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(items) { it in
                if it.icon == .capture {
                    captureFAB(it)
                } else {
                    standardTab(it)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(TraceColor.surfaceCard)
        .overlay(alignment: .top) {
            Rectangle().fill(TraceColor.hairline).frame(height: 1)
        }
    }

    private func standardTab(_ it: TraceTab) -> some View {
        let active = it.id == selection
        return Button { selection = it.id } label: {
            VStack(spacing: 4) {
                Text(it.icon.glyph).font(.system(size: 17))
                Text(it.label).font(.custom(TraceFontFamily.sans, size: 10.5).weight(active ? .bold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(active ? TraceColor.accent : TraceColor.textMuted)
        }
        .buttonStyle(.plain)
    }

    private func captureFAB(_ it: TraceTab) -> some View {
        Button { selection = it.id } label: {
            VStack(spacing: 3) {
                Text(it.icon.glyph)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(TraceColor.paper0)
                    .frame(width: 46, height: 46)
                    .background(TraceColor.accent, in: Circle())
                    .traceShadow(.coral)
                    .offset(y: -22)
                    .padding(.bottom, -22)
                Text(it.label)
                    .font(.custom(TraceFontFamily.sans, size: 10.5).weight(.semibold))
                    .foregroundStyle(TraceColor.accentStrong)
            }
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }
}
