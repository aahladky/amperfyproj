// DeejAIColors.swift
// DeejAI — Mid-Century Modern color tokens
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).
// See LICENSE for details.

import UIKit
import SwiftUI

/// Mid-Century Modern semantic color tokens for DeejAI.
///
/// All colors are `UIColor`-based with explicit light/dark dynamic providers,
/// exposed to SwiftUI via `Color(uiColor:)`. The same tokens drive UIKit
/// appearance proxies — nav bars, tab bars, switches, etc.
///
/// Design: warm, flat, solid color blocks — anti-frosted-glass, anti-Liquid-Glass.
/// Palette: cream backgrounds, terracotta hero accent, deep teal secondary, warm brown text.
/// Dark mode: warm deep-brown backgrounds with warm cream text, keeping MCM warmth.
enum DeejAIColors {

    // MARK: - Light Palette (preserved from original)

    private enum Light {
        static let cream          = UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0) // #F5EFE2
        static let creamCard      = UIColor(red: 0.93, green: 0.90, blue: 0.83, alpha: 1.0) // #EDE8D4
        static let albumTint      = UIColor(red: 0.88, green: 0.74, blue: 0.62, alpha: 1.0) // #E0BD9E
        static let terracotta     = UIColor(red: 0.82, green: 0.45, blue: 0.24, alpha: 1.0) // #D1733D
        static let terracottaDark = UIColor(red: 0.70, green: 0.36, blue: 0.18, alpha: 1.0) // #B35C2E
        static let teal           = UIColor(red: 0.15, green: 0.42, blue: 0.40, alpha: 1.0) // #266B66
        static let tealMuted      = UIColor(red: 0.30, green: 0.52, blue: 0.48, alpha: 1.0) // #4D857A
        static let brownDark      = UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1.0) // #38291E
        static let brownMedium    = UIColor(red: 0.40, green: 0.32, blue: 0.25, alpha: 1.0) // #665240
        static let tan            = UIColor(red: 0.62, green: 0.54, blue: 0.44, alpha: 1.0) // #9E8A70
        static let tanLight       = UIColor(red: 0.72, green: 0.65, blue: 0.55, alpha: 1.0) // #B8A68C
        static let trackBg        = UIColor(red: 0.85, green: 0.80, blue: 0.72, alpha: 1.0) // #D9CCB8
    }

    // MARK: - Dark Palette (warm MCM dark)

    private enum Dark {
        static let surface          = UIColor(red: 0.16, green: 0.12, blue: 0.08, alpha: 1.0) // #291F14 — warm dark walnut
        static let surfaceElevated  = UIColor(red: 0.22, green: 0.17, blue: 0.12, alpha: 1.0) // #382B1E
        static let albumTint        = UIColor(red: 0.40, green: 0.28, blue: 0.18, alpha: 1.0) // #66472E
        static let textPrimary      = UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0) // #F5EFE2 — cream on dark
        static let textSecondary    = UIColor(red: 0.88, green: 0.84, blue: 0.76, alpha: 1.0) // #E0D6C2
        static let textTertiary     = UIColor(red: 0.70, green: 0.63, blue: 0.52, alpha: 1.0) // #B3A185
        static let textQuaternary   = UIColor(red: 0.58, green: 0.50, blue: 0.40, alpha: 1.0) // #94806A
        static let trackBg          = UIColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1.0) // #4D3D2E
        static let terracotta       = UIColor(red: 0.87, green: 0.49, blue: 0.28, alpha: 1.0) // #DE7D47 — slightly brighter
        static let terracottaDark   = UIColor(red: 0.75, green: 0.38, blue: 0.18, alpha: 1.0) // #BF612E
        static let teal             = UIColor(red: 0.18, green: 0.50, blue: 0.48, alpha: 1.0) // #2E807A — slightly lighter
        static let tealMuted        = UIColor(red: 0.36, green: 0.58, blue: 0.54, alpha: 1.0) // #5C948A
    }

    // MARK: - Semantic Tokens (UIColor, dynamic light/dark)

    // - MARK: Text

    /// Primary text — warm dark brown (light) / warm cream (dark).
    static var textPrimary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.textPrimary : Light.brownDark }
    }

    /// Secondary text — medium brown (light) / warm cream (dark).
    static var textSecondary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.textSecondary : Light.brownMedium }
    }

    /// Tertiary text — muted tan (light) / muted warm tan (dark).
    static var textTertiary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.textTertiary : Light.tan }
    }

    /// Quaternary text — light tan for captions, duration labels (light) / muted (dark).
    static var textQuaternary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.textQuaternary : Light.tanLight }
    }

    // - MARK: Surfaces

    /// Primary surface background — cream (light) / warm dark walnut (dark).
    static var surface: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.surface : Light.cream }
    }

    /// Elevated surface — card backgrounds, containers (light) / slightly lighter dark (dark).
    static var surfaceElevated: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.surfaceElevated : Light.creamCard }
    }

    /// Album-art tint wash — desaturated terracotta bleed behind cover art.
    static var albumTint: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.albumTint : Light.albumTint }
    }

    /// Track background for progress bars and sliders.
    static var trackBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.trackBg : Light.trackBg }
    }

    // - MARK: Accents

    /// Hero accent — terracotta / burnt orange for play button, progress fill, heart.
    static var accentPrimary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.terracotta : Light.terracotta }
    }

    /// Darker terracotta — pressed / hover states.
    static var accentPrimaryDark: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.terracottaDark : Light.terracottaDark }
    }

    /// Secondary accent — deep teal, used sparingly.
    static var accentSecondary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.teal : Light.teal }
    }

    /// Muted teal — subtle backgrounds or pills.
    static var accentSecondaryMuted: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? Dark.tealMuted : Light.tealMuted }
    }

    // MARK: - SwiftUI Convenience Properties

    /// Primary text color (SwiftUI).
    static var textPrimaryColor: Color { Color(uiColor: textPrimary) }

    /// Secondary text color (SwiftUI).
    static var textSecondaryColor: Color { Color(uiColor: textSecondary) }

    /// Tertiary text color (SwiftUI).
    static var textTertiaryColor: Color { Color(uiColor: textTertiary) }

    /// Quaternary text color (SwiftUI).
    static var textQuaternaryColor: Color { Color(uiColor: textQuaternary) }

    /// Primary surface background color (SwiftUI).
    static var surfaceColor: Color { Color(uiColor: surface) }

    /// Elevated surface / card background color (SwiftUI).
    static var surfaceElevatedColor: Color { Color(uiColor: surfaceElevated) }

    /// Album tint wash color (SwiftUI).
    static var albumTintColor: Color { Color(uiColor: albumTint) }

    /// Track / progress bar background color (SwiftUI).
    static var trackBackgroundColor: Color { Color(uiColor: trackBackground) }

    /// Hero accent color — terracotta (SwiftUI).
    static var accentPrimaryColor: Color { Color(uiColor: accentPrimary) }

    /// Darker terracotta accent (SwiftUI).
    static var accentPrimaryDarkColor: Color { Color(uiColor: accentPrimaryDark) }

    /// Secondary accent — teal (SwiftUI).
    static var accentSecondaryColor: Color { Color(uiColor: accentSecondary) }

    /// Muted teal accent (SwiftUI).
    static var accentSecondaryMutedColor: Color { Color(uiColor: accentSecondaryMuted) }

    // MARK: - Backward Compatible Paint Names

    /// Primary cream background.
    @available(*, deprecated, message: "Use DeejAIColors.surfaceColor instead")
    static var cream: Color { surfaceColor }

    /// Slightly deeper cream for cards and elevated surfaces.
    @available(*, deprecated, message: "Use DeejAIColors.surfaceElevatedColor instead")
    static var creamCard: Color { surfaceElevatedColor }

    /// Album-art tint wash.
    // (Removed deprecated alias — use DeejAIColors.albumTintColor or .albumTint UIColor)

    /// Terracotta / burnt orange — hero accent.
    @available(*, deprecated, message: "Use DeejAIColors.accentPrimaryColor instead")
    static var terracotta: Color { accentPrimaryColor }

    /// Darker terracotta — pressed states.
    @available(*, deprecated, message: "Use DeejAIColors.accentPrimaryDarkColor instead")
    static var terracottaDark: Color { accentPrimaryDarkColor.opacity(0.95) } // approximate darkening

    /// Deep teal — secondary accent.
    @available(*, deprecated, message: "Use DeejAIColors.accentSecondaryColor instead")
    static var teal: Color { accentSecondaryColor }

    /// Muted teal.
    @available(*, deprecated, message: "Use DeejAIColors.accentSecondaryMutedColor instead")
    static var tealMuted: Color { accentSecondaryMutedColor }

    /// Dark brown — primary text.
    @available(*, deprecated, message: "Use DeejAIColors.textPrimaryColor instead")
    static var brownDark: Color { textPrimaryColor }

    /// Medium brown — secondary text.
    @available(*, deprecated, message: "Use DeejAIColors.textSecondaryColor instead")
    static var brownMedium: Color { textSecondaryColor }

    /// Muted tan — tertiary text.
    @available(*, deprecated, message: "Use DeejAIColors.textTertiaryColor instead")
    static var tan: Color { textTertiaryColor }

    /// Light tan — quaternary text.
    @available(*, deprecated, message: "Use DeejAIColors.textQuaternaryColor instead")
    static var tanLight: Color { textQuaternaryColor }

    /// Track background — progress bars.
    // (Removed deprecated alias — use DeejAIColors.trackBackgroundColor or .trackBackground UIColor)
}
