import SwiftUI

/// Round contributor avatar with coral-wash initials fallback. Optional coral ring marks "me".
/// Mirrors components/core/Avatar.jsx. Sizes: xs 24 · sm 32 · md 40 · lg 56.
public struct Avatar: View {
    public enum Size: CGFloat { case xs = 24, sm = 32, md = 40, lg = 56 }

    let name: String
    let image: Image?
    let size: Size
    let ring: Bool

    public init(name: String = "", image: Image? = nil, size: Size = .md, ring: Bool = false) {
        self.name = name
        self.image = image
        self.size = size
        self.ring = ring
    }

    private var px: CGFloat { size.rawValue }

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "·" : String(trimmed.prefix(2))
    }

    public var body: some View {
        Group {
            if let image {
                image.resizable().scaledToFill()
            } else {
                Text(initials)
                    .font(.custom(TraceFontFamily.sans, size: px * 0.4).weight(TraceWeight.bold))
                    .foregroundStyle(TraceColor.accentStrong)
            }
        }
        .frame(width: px, height: px)
        .background(TraceColor.coralWash)
        .clipShape(Circle())
        .overlay {
            // ring = "0 0 0 2px surface-card, 0 0 0 4px accent-soft" → inner paper gap + coral ring.
            if ring {
                Circle().strokeBorder(TraceColor.surfaceCard, lineWidth: 2).padding(-2)
                    .overlay(Circle().strokeBorder(TraceColor.accentSoft, lineWidth: 2).padding(-4))
            }
        }
    }
}
