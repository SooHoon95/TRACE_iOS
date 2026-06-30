import SwiftUI
import PhotosUI
import UIKit
import Domain

/// Composer for leaving a moment at a place.
///
/// **Photo is the only required field** (low-friction claim): caption, companion, vibe and
/// visibility are all optional. `canSubmit` is driven solely by whether a photo exists.
/// The photo is chosen via the system `PhotosPicker` (works in the simulator); the selected
/// bytes ride along in `Draft.photoData` so the owning screen can upload them. On a real
/// device this frame can be swapped for the on-device camera with no change to `Draft`.
/// Mirrors components/content/CaptureComposer.jsx.
public struct CaptureComposer: View {
    /// The composed draft returned on submit. All fields optional except the photo bytes.
    public struct Draft {
        public let caption: String?
        public let companion: Companion?
        public let vibe: VibeTag?
        public let visibility: MomentVisibility
        /// The selected image bytes to upload (nil only on the catalog/preview path).
        public let photoData: Data?

        public init(caption: String?,
                    companion: Companion?,
                    vibe: VibeTag?,
                    visibility: MomentVisibility,
                    photoData: Data?) {
            self.caption = caption
            self.companion = companion
            self.vibe = vibe
            self.visibility = visibility
            self.photoData = photoData
        }
    }

    let place: String
    /// "여기 N명이 남겼어" FOMO peek; hidden when 0.
    let contributorCount: Int
    /// An optional preset preview image (e.g. catalog). Real captures come from the picker.
    let photo: Image?
    let onSubmit: ((Draft) -> Void)?

    @State private var caption: String = ""
    @State private var companion: Companion? = nil
    @State private var vibe: VibeTag? = nil
    @State private var isPrivate: Bool = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: Image?
    @State private var pickedData: Data?

    public init(place: String = "성수동 적산가옥",
                contributorCount: Int = 0,
                photo: Image? = nil,
                onSubmit: ((Draft) -> Void)? = nil) {
        self.place = place
        self.contributorCount = contributorCount
        self.photo = photo
        self.onSubmit = onSubmit
    }

    private var hasPhoto: Bool { pickedImage != nil || photo != nil }
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
                                    visibility: isPrivate ? .privateOnly : .publicExhibit,
                                    photoData: pickedData))
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
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            ZStack {
                if let shown = pickedImage ?? photo {
                    shown.resizable().scaledToFill()
                        .overlay(alignment: .bottomTrailing) {
                            Text(pickedImage != nil ? "다시 고르기" : "사진 바꾸기")
                                .traceType(.bodyXS).fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(.black.opacity(0.45), in: Capsule())
                                .padding(10)
                        }
                } else {
                    LinearGradient(colors: [TraceColor.surfaceSunken, TraceColor.paper100],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(captureLabel("📷 이 자리의 사진 고르기"))
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .buttonStyle(.plain)
        .onChange(of: pickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        pickedData = data
                        pickedImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    private func captureLabel(_ text: String) -> some View {
        Text(text)
            .traceType(.bodySM)
            .fontWeight(.semibold)
            .foregroundStyle(TraceColor.textSecondary)
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
