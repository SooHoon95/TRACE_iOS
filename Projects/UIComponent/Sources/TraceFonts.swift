import CoreText
import Foundation

/// Registers the bundled TRACE fonts (Pretendard, weights 400–800) at runtime
/// so `Font.custom("Pretendard", …)` resolves. Call once at app launch
/// (e.g. in the App's `init`). Idempotent. v2 is Pretendard-only — no serif.
public enum TraceFonts {
    private static var didRegister = false

    private static let files: [(name: String, ext: String)] = [
        ("Pretendard-Regular", "otf"),
        ("Pretendard-Medium", "otf"),
        ("Pretendard-SemiBold", "otf"),
        ("Pretendard-Bold", "otf"),
        ("Pretendard-ExtraBold", "otf"),
    ]

    public static func registerAll() {
        guard !didRegister else { return }
        didRegister = true
        for file in files {
            let url = Bundle.module.url(forResource: file.name, withExtension: file.ext, subdirectory: "Fonts")
                ?? Bundle.module.url(forResource: file.name, withExtension: file.ext)
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
