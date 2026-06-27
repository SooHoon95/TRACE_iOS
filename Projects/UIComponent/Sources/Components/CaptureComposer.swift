import SwiftUI
import Domain

/// Composer for leaving a moment at a place.
///
/// **Photo is the only required field** (low-friction claim): caption, companion, vibe and
/// visibility are all optional. `canSubmit` is driven solely by whether a photo exists.
/// The owning screen presents the on-device camera via `onCapture` and passes the result
/// back through `photo`; with no `onCapture` (catalog/preview) tapping the frame simulates a capture.
/// Mirrors components/content/CaptureComposer.jsx.
public struct CaptureComposer: View {
    /// The composed draft returned on submit. All fields optional except the (already-attached) photo.
    public struct Draft {
        public let caption: String?
        public let companion: Companion?
        public let vibe: VibeTag?
        public let visibility: MomentVisibility
    }

    let place: String
    /// "여기 N명이 남겼어" FOMO peek; hidden when 0.
    let contributorCount: Int
    /// The captured photo (nil = not captured yet).
    let photo: Image?
    /// Tap the frame to capture. nil → catalog mode (tap simulates a capture).
    let onCapture: (() -> Void)?
    let onSubmit: ((Draft) -> Void)?

    @State private var caption: String = ""
    @State private var companion: Companion? = nil
    @State private var vibe: VibeTag? = nil
    @State private var isPrivate: Bool = false
    @State private var demoCaptured: Bool = false   // catalog-mode stand-in for a real photo

    public init(place: String = "성수동 적산가옥",
                contributorCount: Int = 0,
                photo: Image? = nil,
                onCapture: (() -> Void)? = nil,
                onSubmit: ((Draft) -> Void)? = nil) {
        self.place = place
        self.contributorCount = contributorCount
        self.photo = photo
        self.onCapture = onCapture
        self.onSubmit = onSubmit
    }

    private var hasPhoto: Bool { photo != nil || demoCaptured }
    private var canSubmit: Bool { hasPhoto }   // photo-only requirement

    public var body: some View {
        VStack(spacing: 0) {
            photoFrame
            VStack(alignment: .leading, spacing: 18) {
                header
                captionField
                pickerRow(title: "누구와 (선택)") {
                    HStack(spacing: 7) {
                        ForEach(Companion.allCases, id: \.self) { c in
                            CompanionTag(c, size: .sm)
                                .opacity(companion == c ? 1 : 0.5)
                                .overlay(
                                    Capsule().strokeBorder(
                                        companion == c ? TraceColor.accentSoft : .clear, lineWidth: 2
                                    )
                                )
                                .onTapGesture { companion = (companion == c ? nil : c) }
                        }
                    }
                }
                pickerRow(title: "무드 (선택)") {
                    FlowVibes(selected: vibe) { vibe = (vibe == $0 ? nil : $0) }
                }
                visibilityRow
                TraceButton("이 자리에 남기기", size: .lg) {
                    onSubmit?(Draft(caption: caption.isEmpty ? nil : caption,
                                    companion: companion,
                                    vibe: vibe,
                                    visibility: isPrivate ? .privateOnly : .publicExhibit))
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .frame(width: 360)
        .background(TraceColor.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TraceRadius.xxl, style: .continuous)
                .strokeBorder(TraceColor.hairline, lineWidth: 1)
        )
        .traceShadow(.lg)
    }

    private var photoFrame: some View {
        Button {
            if let onCapture { onCapture() } else { demoCaptured = true }
        } label: {
            ZStack {
                if let photo {
                    photo.resizable().scaledToFill()
                } else if demoCaptured {
                    LinearGradient(colors: [(vibe ?? .scenic).color, TraceColor.paper100],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(captureLabel("촬영됨 · 다시 찍기"))
                } else {
                    LinearGradient(colors: [TraceColor.surfaceSunken, TraceColor.paper100],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(captureLabel("📷 이 자리에서 촬영하기"))
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .buttonStyle(.plain)
    }

    private func captureLabel(_ text: String) -> some View {
        Text(text)
            .traceType(.bodySM)
            .fontWeight(.semibold)
            .foregroundStyle(demoCaptured ? Color.white.opacity(0.95) : TraceColor.textSecondary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("이 자리에 남기기")
                .traceType(.eyebrow)
                .foregroundStyle(TraceColor.accent)
            HStack(spacing: 8) {
                Text("📍 \(place)")
                    .traceType(.bodySM)
                    .foregroundStyle(TraceColor.textMuted)
                if contributorCount > 0 {
                    Text("· 여기 \(contributorCount)명이 남겼어")
                        .traceType(.bodyXS)
                        .foregroundStyle(TraceColor.accent)
                }
            }
        }
    }

    private var captionField: some View {
        ZStack(alignment: .topLeading) {
            if caption.isEmpty {
                Text("한마디 남긴다면… (선택)")
                    .traceType(.displaySM)
                    .fontWeight(.heavy)
                    .foregroundStyle(TraceColor.textMuted)
            }
            TextField("", text: $caption, axis: .vertical)
                .traceType(.displaySM)
                .fontWeight(.heavy)
                .foregroundStyle(TraceColor.textPrimary)
                .lineLimit(2...3)
                .textFieldStyle(.plain)
        }
    }

    private var visibilityRow: some View {
        Toggle(isOn: $isPrivate) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isPrivate ? "나만 보기" : "전시에 공개")
                    .traceType(.bodySM).fontWeight(.semibold)
                    .foregroundStyle(TraceColor.textSecondary)
                Text(isPrivate ? "이 순간은 나만 볼 수 있어요" : "이 자리의 '모두의 순간'에 합류해요")
                    .traceType(.bodyXS)
                    .foregroundStyle(TraceColor.textMuted)
            }
        }
        .tint(TraceColor.accent)
    }

    @ViewBuilder
    private func pickerRow<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).traceType(.bodySM).fontWeight(.semibold).foregroundStyle(TraceColor.textSecondary)
            content()
        }
    }
}

/// Wrapping row of selectable vibe chips for the composer.
private struct FlowVibes: View {
    let selected: VibeTag?
    let onPick: (VibeTag) -> Void

    var body: some View {
        // Two rows of three to fit the 360-wide composer without horizontal scroll.
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                ForEach(Array(VibeTag.allCases.prefix(3)), id: \.self) { chip($0) }
            }
            HStack(spacing: 7) {
                ForEach(Array(VibeTag.allCases.suffix(VibeTag.allCases.count - 3)), id: \.self) { chip($0) }
            }
        }
    }

    private func chip(_ v: VibeTag) -> some View {
        VibeTagChip(v, size: .sm, selected: selected == v) { onPick(v) }
    }
}
