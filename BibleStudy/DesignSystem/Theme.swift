import SwiftUI

/// Central design system. The brief: beautiful, minimalist, white/black with
/// tasteful splashes of color. No sepia, no browns. Everything that touches
/// color, type, or spacing routes through here so the look stays consistent.
enum Theme {

    // MARK: Accent palette
    //
    // A small set of clean "splash" colors. The user can pick one in Settings;
    // it tints buttons, the active tab, verse numbers, and highlights.
    enum Accent: String, CaseIterable, Identifiable, Codable {
        case indigo
        case blue
        case teal
        case rose
        case amber
        case violet

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .indigo: return Color(red: 0.35, green: 0.34, blue: 0.84)
            case .blue:   return Color(red: 0.15, green: 0.47, blue: 0.95)
            case .teal:   return Color(red: 0.07, green: 0.64, blue: 0.63)
            case .rose:   return Color(red: 0.92, green: 0.30, blue: 0.45)
            case .amber:  return Color(red: 0.96, green: 0.62, blue: 0.10)
            case .violet: return Color(red: 0.58, green: 0.30, blue: 0.90)
            }
        }

        var label: String { rawValue.capitalized }
    }

    // MARK: Semantic colors
    //
    // These adapt to light/dark automatically. The brief is white/black, so the
    // surfaces are pure-ish neutrals — never warm/sepia tones.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.04) : Color.white
    }

    static func secondaryBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.10) : Color(white: 0.965)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.96) : Color(white: 0.07)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.62) : Color(white: 0.42)
    }

    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.18) : Color(white: 0.90)
    }

    // MARK: Spacing scale
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 14
        static let l: CGFloat = 22
    }
}

// MARK: - Reading typography

/// The reader supports a serif scripture face and an adjustable size. We keep a
/// neutral, classic serif for the text itself and a crisp sans for chrome.
struct ReadingTypography {
    var pointSize: CGFloat
    var lineSpacing: CGFloat { pointSize * 0.45 }

    var verseFont: Font { .custom("Georgia", size: pointSize) }
    var verseNumberFont: Font { .system(size: pointSize * 0.62, weight: .semibold, design: .rounded) }
    var headingFont: Font { .system(size: pointSize * 0.85, weight: .semibold, design: .default) }

    static let minSize: Double = 15
    static let maxSize: Double = 30
}
