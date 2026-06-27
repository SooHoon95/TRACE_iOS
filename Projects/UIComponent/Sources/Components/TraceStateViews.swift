import SwiftUI

/// Centered loading state with TRACE tint.
public struct TraceLoadingView: View {
    let label: String
    public init(_ label: String = "불러오는 중…") { self.label = label }
    public var body: some View {
        VStack(spacing: 12) {
            ProgressView().tint(TraceColor.accent)
            Text(label).traceType(.bodySM).foregroundStyle(TraceColor.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Full-screen error state with a 다시 시도 retry button (replaces content when load fails).
public struct TraceErrorView: View {
    let message: String
    let retry: () -> Void
    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }
    public var body: some View {
        VStack(spacing: 14) {
            Text("⚠️").font(.system(size: 34))
            Text(message)
                .traceType(.bodyMD).fontWeight(.semibold)
                .foregroundStyle(TraceColor.textSecondary)
                .multilineTextAlignment(.center)
            TraceButton("다시 시도", variant: .soft, size: .md, fullWidth: false) { retry() }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Transient error banner (toast) for action failures that don't replace the whole screen.
public struct TraceErrorBanner: View {
    let message: String
    public init(_ message: String) { self.message = message }
    public var body: some View {
        Text(message)
            .traceType(.bodySM).fontWeight(.semibold)
            .foregroundStyle(TraceColor.paper0)
            .padding(.vertical, 10).padding(.horizontal, 16)
            .background(TraceColor.accentStrong, in: Capsule())
            .traceShadow(.lg)
    }
}
