// DeejAIFonts.swift
// DeejAI — Mid-Century Modern font tokens
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).
// See LICENSE for details.

import SwiftUI

/// Mid-Century Modern semantic font tokens for DeejAI.
///
/// Custom fonts registered via UIAppFonts:
/// - **Lora** (variable font, OFL) — warm transitional serif for titles and
///   track/album names (liner-notes feel).
/// - **Nunito** (variable font, OFL) — rounded humanist sans for body text,
///   labels, and captions.
///
/// Every font uses `Font.custom(_:size:relativeTo:)` so Dynamic Type
/// accessibility scaling is preserved — never bare `.system(size:)`.
enum DeejAIFonts {

    // MARK: - Serif (Lora)

    /// Large serif for prominent headings / hero text.
    /// Uses `.largeTitle` text style for Dynamic Type scaling.
    /// Example: greeting header ("Good morning, Aaron").
    static let serifDisplay = Font
        .custom("Lora", size: 32, relativeTo: .largeTitle)
        .weight(.bold)

    /// Serif for primary track/album titles.
    /// Uses `.title` text style for Dynamic Type scaling.
    /// Example: "Everything In Its Right Place".
    static let serifTitle = Font
        .custom("Lora", size: 24, relativeTo: .title)
        .weight(.bold)

    /// Serif for secondary titles and cards.
    /// Uses `.headline` text style for Dynamic Type scaling.
    /// Example: mix names, artist names on cards, suggested track titles.
    static let serifHeadline = Font
        .custom("Lora", size: 15, relativeTo: .headline)
        .weight(.semibold)

    /// Small serif for album-art overlay text.
    /// Uses `.subheadline` text style for Dynamic Type scaling.
    static let serifSubheadline = Font
        .custom("Lora", size: 13, relativeTo: .subheadline)
        .weight(.semibold)

    // MARK: - Sans (Nunito)

    /// Sans for primary body text.
    /// Uses `.body` text style for Dynamic Type scaling.
    /// Example: artist names, mix subtitles.
    static let sansBody = Font
        .custom("Nunito", size: 16, relativeTo: .body)
        .weight(.medium)

    /// Sans for secondary body / smaller text blocks.
    /// Uses `.body` text style for Dynamic Type scaling.
    /// Example: next-track artist, suggested-track artist.
    static let sansSubheadline = Font
        .custom("Nunito", size: 13, relativeTo: .body)
        .weight(.medium)

    /// Sans for pill labels, small section markers.
    /// Uses `.callout` text style for Dynamic Type scaling.
    /// Example: "feel · settled", "UP NEXT", section labels.
    static let sansLabel = Font
        .custom("Nunito", size: 13, relativeTo: .callout)
        .weight(.medium)

    /// Sans for uppercase section headers / metadata.
    /// Uses `.caption` text style for Dynamic Type scaling.
    /// Example: "YOUR MIXES", "early morning, friday", play counts, scores.
    static let sansCaption = Font
        .custom("Nunito", size: 11, relativeTo: .caption)
        .weight(.semibold)

    /// Bold condensed sans for numeric / badge text.
    /// Uses `.caption` text style for Dynamic Type scaling.
    /// Example: numbered track positions, score percentages.
    static let sansCaptionBold = Font
        .custom("Nunito", size: 11, relativeTo: .caption)
        .weight(.bold)

    // MARK: - Monospace (system — for times only)

    /// Monospace for elapsed/duration time labels.
    /// System SF Mono is preferred here — no custom monospace needed.
    static let monoTime = Font
        .system(size: 11, weight: .medium, design: .monospaced)

    // MARK: - UIFont Variants (for UIKit views)

    private static func uifont(_ name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    /// Sans caption (Nunito 11 semibold) as UIFont for UIKit labels.
    static var sansCaptionUIFont: UIFont {
        uifont("Nunito", size: 11, weight: .semibold)
    }

    /// Sans body (Nunito 16 medium) as UIFont for UIKit labels.
    static var sansBodyUIFont: UIFont {
        uifont("Nunito", size: 16, weight: .medium)
    }

    /// Sans subheadline (Nunito 13 medium) as UIFont for UIKit labels.
    static var sansSubheadlineUIFont: UIFont {
        uifont("Nunito", size: 13, weight: .medium)
    }
}
