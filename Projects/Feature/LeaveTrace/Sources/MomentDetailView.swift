import SwiftUI
import Domain
import UIComponent

/// 순간 상세 (S9) — 사진 풀뷰 + 한마디 + 작성자·날짜·장소 + 동행·무드 + 액션(하트·공유·⋯ 신고/숨김).
/// Renders the real photo via `photoURL`; the vibe gradient stays as loading/fallback.
public struct MomentDetailView: View {
    let moment: Moment
    let photoURL: URL?
    let placeName: String
    let onReport: () -> Void
    let onHide: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var liked = false
    @State private var showActions = false

    public init(moment: Moment,
                photoURL: URL? = nil,
                placeName: String,
                onReport: @escaping () -> Void,
                onHide: @escaping () -> Void) {
        self.moment = moment
        self.photoURL = photoURL
        self.placeName = placeName
        self.onReport = onReport
        self.onHide = onHide
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photo
                VStack(alignment: .leading, spacing: 16) {
                    if let caption = moment.caption, !caption.isEmpty {
                        Text(caption)
                            .traceType(.displaySM).fontWeight(.heavy)
                            .foregroundStyle(TraceColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    authorRow
                    if moment.companion != nil || moment.vibe != nil {
                        HStack(spacing: 6) {
                            if let c = moment.companion { CompanionTag(c, size: .md) }
                            if let v = moment.vibe { VibeTagChip(v, size: .md, selected: false) {} }
                        }
                    }
                    Divider().overlay(TraceColor.hairline)
                    actionBar
                }
                .padding(18)
            }
        }
        .background(TraceColor.paper50.ignoresSafeArea())
        .safeAreaInset(edge: .top) { topBar }
        .confirmationDialog("이 순간", isPresented: $showActions, titleVisibility: .hidden) {
            Button("신고하기", role: .destructive) { onReport(); dismiss() }
            Button("내 화면에서 숨기기") { onHide(); dismiss() }
            Button("취소", role: .cancel) {}
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹").font(.system(size: 26)).foregroundStyle(TraceColor.textSecondary)
            }
            Spacer()
            Button { showActions = true } label: {
                Text("⋯").font(.system(size: 22)).foregroundStyle(TraceColor.textSecondary)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(TraceColor.paper50)
    }

    private var photo: some View {
        LinearGradient(colors: [(moment.vibe ?? .scenic).color, TraceColor.paper100],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(height: 360)
            .frame(maxWidth: .infinity)
            .overlay {
                if let photoURL {
                    AsyncImage(url: photoURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 360)
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if moment.visibility == .privateOnly {
                    Text("🔒 나만")
                        .traceType(.bodyXS).fontWeight(.bold)
                        .foregroundStyle(TraceColor.paper0)
                        .padding(.vertical, 4).padding(.horizontal, 9)
                        .background(TraceColor.textSecondary.opacity(0.9), in: Capsule())
                        .padding(14)
                }
            }
            .clipped()
    }

    private var authorRow: some View {
        HStack(spacing: 10) {
            Avatar(name: "여행자", size: .sm)
            VStack(alignment: .leading, spacing: 2) {
                Text("익명 여행자")
                    .traceType(.bodySM).fontWeight(.bold)
                    .foregroundStyle(TraceColor.textPrimary)
                Text("\(Self.dateText(moment.createdAt)) · 📍\(placeName)")
                    .traceType(.bodyXS)
                    .foregroundStyle(TraceColor.textMuted)
            }
            Spacer()
        }
    }

    private var actionBar: some View {
        HStack(spacing: 24) {
            Button { liked.toggle() } label: {
                HStack(spacing: 6) {
                    Text(liked ? "♥" : "♡")
                        .font(.system(size: 20))
                        .foregroundStyle(liked ? TraceColor.accent : TraceColor.textSecondary)
                    Text("반응").traceType(.bodySM).foregroundStyle(TraceColor.textSecondary)
                }
            }
            Button {} label: {
                HStack(spacing: 6) {
                    Text("↗").font(.system(size: 20)).foregroundStyle(TraceColor.textSecondary)
                    Text("공유").traceType(.bodySM).foregroundStyle(TraceColor.textSecondary)
                }
            }
            Spacer()
        }
        .buttonStyle(.plain)
    }

    private static func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일"
        return f.string(from: date)
    }
}
