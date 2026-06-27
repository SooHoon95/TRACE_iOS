import SwiftUI

/// TRACE color tokens — 1:1 from claude.ai/design v2 "TRACE Design System" tokens/colors.css.
/// Warm humanist minimal: paper (light) + warm charcoal (dark/map/AR), one coral accent family,
/// plus 6 vibe moods. Hex values are unchanged from v1; only the semantic alias names move to v2.
public enum TraceColor {
    // MARK: Light · Paper surfaces
    public static let paper0   = Color(hex: 0xFFFDF8) // brightest card
    public static let paper50  = Color(hex: 0xFBF6EC) // app background (paper)
    public static let paper100 = Color(hex: 0xF4ECE0) // sunken / empty slot
    public static let border   = Color(hex: 0xEFE6D8) // hairline border on paper
    public static let divider  = Color(hex: 0xE6D3BD) // stronger divider / rule

    // MARK: Dark · Charcoal (map / AR)
    public static let char900 = Color(hex: 0x241C16) // deepest
    public static let char700 = Color(hex: 0x2E2823) // dark card base
    public static let char600 = Color(hex: 0x3A322B) // raised dark surface
    public static let char500 = Color(hex: 0x463D34) // dark line / stroke

    // MARK: Coral · the one accent family
    public static let coral300  = Color(hex: 0xF2A98E) // soft accent
    public static let coral500  = Color(hex: 0xE8775B) // PRIMARY accent
    public static let coral600  = Color(hex: 0xC75D43) // hover / pressed / strong text accent
    public static let coralWash = Color(hex: 0xFDEAE2) // tinted surface behind accents

    // MARK: Ink · text on paper
    public static let ink900 = Color(hex: 0x2A241F) // primary text / headings
    public static let ink600 = Color(hex: 0x6B5F54) // secondary text
    public static let ink500 = Color(hex: 0x9C8E7E) // muted / captions
    public static let ink400 = Color(hex: 0xB6A899) // faintest label

    // MARK: Vibe · mood (6)
    public static let vibeCalm      = Color(hex: 0x8FB0C4) // 차분
    public static let vibeLively    = Color(hex: 0xE89A4F) // 활기
    public static let vibeScenery   = Color(hex: 0x88B07A) // 풍경
    public static let vibeFood      = Color(hex: 0xD98A6A) // 맛집
    public static let vibeAdventure = Color(hex: 0xC77B5A) // 모험
    public static let vibeHidden    = Color(hex: 0x9B89B5) // 숨은곳

    // MARK: Semantic aliases — light surfaces (v2)
    public static let surfaceApp    = paper50
    public static let surfaceCard   = paper0
    public static let surfaceSunken = paper100
    public static let surfaceWash   = coralWash
    public static let textPrimary   = ink900
    public static let textSecondary = ink600
    public static let textMuted     = ink500
    public static let textFaint     = ink400
    public static let accent        = coral500
    public static let accentStrong  = coral600
    public static let accentSoft    = coral300
    public static let hairline      = border
    public static let rule          = divider

    // MARK: Semantic aliases — dark surfaces (map / AR) (v2)
    public static let surfaceDark       = char900
    public static let surfaceDarkCard   = char700
    public static let surfaceDarkRaised = char600
    public static let surfaceDarkLine   = char500
    public static let textOnDark        = Color(hex: 0xF4ECE0)
    public static let textOnDarkMuted   = Color(hex: 0xB6A899)
}
