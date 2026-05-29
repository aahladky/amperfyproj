// DeejAIColors.swift
// DeejAI — Mid-Century Modern color palette
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).
// See LICENSE for details.

import SwiftUI

/// Mid-Century Modern palette for DeejAI.
/// Warm, flat, solid color blocks — anti-frosted-glass, anti-Liquid-Glass.
enum DeejAIColors {

    // MARK: - Backgrounds

    /// Primary cream background — warm, not sterile.
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88) // #F5EFE2

    /// Slightly deeper cream for cards and elevated surfaces.
    static let creamCard = Color(red: 0.93, green: 0.90, blue: 0.83)

    /// Album-art tint wash — a desaturated terracotta that bleeds behind cover art.
    static let albumTint = Color(red: 0.88, green: 0.74, blue: 0.62)

    // MARK: - Accents

    /// Terracotta / burnt orange — the hero accent.
    /// Used for play button, progress fill, heart, and interactive highlights.
    static let terracotta = Color(red: 0.82, green: 0.45, blue: 0.24) // #D1733D

    /// Slightly darker terracotta for pressed/hover states.
    static let terracottaDark = Color(red: 0.70, green: 0.36, blue: 0.18)

    /// Deep teal — secondary accent, used sparingly for variety.
    static let teal = Color(red: 0.15, green: 0.42, blue: 0.40) // #266B66

    /// Muted teal for subtle backgrounds or pills.
    static let tealMuted = Color(red: 0.30, green: 0.52, blue: 0.48)

    // MARK: - Text

    /// Dark brown — primary text color. Warm, never pure black.
    static let brownDark = Color(red: 0.22, green: 0.16, blue: 0.12) // #38291E

    /// Medium brown — secondary headings.
    static let brownMedium = Color(red: 0.40, green: 0.32, blue: 0.25)

    /// Muted tan — secondary/tertiary text, labels, captions.
    static let tan = Color(red: 0.62, green: 0.54, blue: 0.44) // #9E8A70

    /// Lighter tan for very muted labels.
    static let tanLight = Color(red: 0.72, green: 0.65, blue: 0.55)

    // MARK: - System

    /// Track background for progress bars and sliders.
    static let trackBackground = Color(red: 0.85, green: 0.80, blue: 0.72)
}
