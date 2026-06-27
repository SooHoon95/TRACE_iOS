import SwiftUI

/// Editorial section header — coral eyebrow over an extrabold title, with optional trailing action.
/// Mirrors components/core/SectionHeader.jsx. Title uses display weight 800; eyebrow is coral accent.
public struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    let action: String?
    let onAction: (() -> Void)?

    public init(eyebrow: String? = nil, title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: TraceSpace.s4) {
            VStack(alignment: .leading, spacing: 6) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .traceType(.eyebrow)
                        .foregroundStyle(TraceColor.accent)
                }
                Text(title)
                    .traceType(.displaySM)
                    .lineSpacing(0)
                    .foregroundStyle(TraceColor.textPrimary)
            }
            Spacer(minLength: 0)
            if let action {
                let label = Text(action).traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
                if let onAction {
                    Button(action: onAction) { label }.buttonStyle(.plain)
                } else {
                    label.fixedSize()
                }
            }
        }
    }
}
