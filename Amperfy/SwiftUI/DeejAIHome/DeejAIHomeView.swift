// DeejAIHomeView.swift
// DeejAI — Home/Launch screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - Home View

/// The first screen the user sees when opening the app.
///
/// Zero-friction design: one big context-aware pick, one tap to start the radio.
/// No browsing, no grid, no wall of options — just "here's what you should play."
struct DeejAIHomeView: View {

    // MARK: State

    /// Placeholder hero pick — the one thing DeejAI decided for you.
    @State private var heroPick = HomePick(
        title: "Everything In Its Right Place",
        artist: "Radiohead",
        album: "Kid A"
    )

    /// Placeholder up-next track (sequencer's first follow-on).
    @State private var nextPick = HomePick(
        title: "The National Anthem",
        artist: "Radiohead",
        album: "Kid A"
    )

    /// Placeholder alternative picks (2–3 smaller cards below the hero).
    @State private var alternativePicks: [HomePick] = [
        HomePick(title: "Evan Finds the Third Room", artist: "Khruangbin", album: "Texas Sun"),
        HomePick(title: "Says", artist: "Nils Frahm", album: "Spaces"),
        HomePick(title: "Holocene", artist: "Bon Iver", album: "Bon Iver, Bon Iver")
    ]

    /// Animations
    @State private var heroScale: CGFloat = 0.92
    @State private var heroOpacity: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    @State private var altPicksOpacity: CGFloat = 0.0

    // MARK: Body

    var body: some View {
        ZStack {
            // 1. Background: solid MCM cream
            DeejAIColors.surfaceColor
                .ignoresSafeArea()

            // 2. Warm tint bleed behind album art area
            backgroundGradient
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // 3. Context header
                        contextHeader
                            .padding(.top, 28)
                            .padding(.bottom, 12)

                        // 4. "Your next listen" label
                        yourNextListenLabel
                            .padding(.bottom, 20)

                        // 5. Hero album art
                        heroAlbumArt
                            .padding(.bottom, 20)

                        // 6. Track info
                        trackInfo
                            .padding(.bottom, 16)

                        // 7. Play radio button — big, terracotta, one tap
                        playRadioButton
                            .padding(.bottom, 24)

                        // 8. Up next card
                        upNextCard
                            .padding(.horizontal, 40)
                            .padding(.bottom, 32)

                        // 9. Alternative picks
                        if !alternativePicks.isEmpty {
                            alternativeSection
                                .padding(.bottom, 28)
                        }

                        // 10. Feel pill
                        feelPill
                            .padding(.bottom, 40)

                        Spacer(minLength: 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                heroScale = 1.0
                heroOpacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
                altPicksOpacity = 1.0
            }
        }
    }

    // MARK: - Components

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: DeejAIColors.albumTintColor.opacity(0.40), location: 0.0),
                .init(color: DeejAIColors.albumTintColor.opacity(0.12), location: 0.4),
                .init(color: .clear, location: 1.0)
            ]),
            center: .init(x: 0.5, y: 0.30),
            startRadius: 40,
            endRadius: 520
        )
    }

    private var contextHeader: some View {
        Text(contextLabel)
            .font(DeejAIFonts.sansCaption)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(DeejAIColors.textTertiaryColor)
    }

    private var contextLabel: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let weekday = Calendar.current.weekdaySymbols[
            Calendar.current.component(.weekday, from: .now) - 1
        ]

        let timeOfDay: String
        switch hour {
        case 5..<8:   timeOfDay = "early morning"
        case 8..<12:  timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<20: timeOfDay = "evening"
        case 20..<23: timeOfDay = "winding down"
        default:      timeOfDay = "late night"
        }

        return "\(timeOfDay), \(weekday.lowercased())"
    }

    private var yourNextListenLabel: some View {
        Text("Your next listen")
            .font(DeejAIFonts.serifDisplay)
            .foregroundStyle(DeejAIColors.textPrimaryColor)
    }

    private var heroAlbumArt: some View {
        ZStack {
            // Approved spec shadow: black at 12% opacity, y-offset 4, blur 12
            // Hero album art color block
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(heroArtGradient)
                .frame(width: 280, height: 280)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
                .overlay(
                    VStack(spacing: 12) {
                        Circle()
                            .fill(DeejAIColors.surfaceColor.opacity(0.25))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(DeejAIFonts.serifDisplay)
                                    .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.7))
                            )

                        Text(heroPick.album)
                            .font(DeejAIFonts.serifSubheadline)
                            .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.8))
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                    }
                )
                .scaleEffect(heroScale)
                .opacity(heroOpacity)
        }
    }

    private var heroArtGradient: LinearGradient {
        LinearGradient(
            colors: [
                DeejAIColors.textSecondaryColor,
                DeejAIColors.accentPrimaryDarkColor,
                DeejAIColors.textPrimaryColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(heroPick.title)
                .font(DeejAIFonts.serifTitle)
                .foregroundStyle(DeejAIColors.textPrimaryColor)
                .lineLimit(1)
                .padding(.horizontal, 32)

            Text(heroPick.artist)
                .font(DeejAIFonts.sansBody)
                .foregroundStyle(DeejAIColors.textTertiaryColor)
                .lineLimit(1)
        }
    }

    private var playRadioButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                buttonScale = 0.92
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    buttonScale = 1.0
                }
                // TODO: Wire to real radio/queue-extend — start context-aware playback
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(DeejAIFonts.sansBody)

                Text("Play Radio")
                    .font(DeejAIFonts.sansBody)
                    .fontWeight(.bold)
            }
            .foregroundStyle(DeejAIColors.surfaceColor)
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(DeejAIColors.accentPrimaryColor)
            )
            .overlay(
                Capsule()
                    .stroke(DeejAIColors.accentPrimaryDarkColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.12),
                radius: 12, x: 0, y: 4
            )
            .scaleEffect(buttonScale)
        }
        .buttonStyle(.plain)
    }

    private var upNextCard: some View {
        Button {
            // TODO: Wire to real skip-to-next action
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("UP NEXT")
                    .font(DeejAIFonts.sansCaption)
                    .tracking(2.5)
                    .foregroundStyle(DeejAIColors.textTertiaryColor)

                HStack(spacing: 16) {
                    // Mini art swatch
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DeejAIColors.accentSecondaryColor.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(DeejAIFonts.sansBody)
                                .foregroundStyle(DeejAIColors.accentSecondaryColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextPick.title)
                            .font(DeejAIFonts.serifHeadline)
                            .foregroundStyle(DeejAIColors.textPrimaryColor)
                            .lineLimit(1)

                        Text(nextPick.artist)
                            .font(DeejAIFonts.sansSubheadline)
                            .foregroundStyle(DeejAIColors.textTertiaryColor)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DeejAIFonts.serifSubheadline)
                        .foregroundStyle(DeejAIColors.textQuaternaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DeejAIColors.surfaceElevatedColor)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alternative Picks

    private var alternativeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALSO FOR YOU")
                .font(DeejAIFonts.sansCaption)
                .tracking(2.5)
                .foregroundStyle(DeejAIColors.textTertiaryColor)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(alternativePicks) { pick in
                        alternativeCard(pick)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .opacity(altPicksOpacity)
    }

    private func alternativeCard(_ pick: HomePick) -> some View {
        Button {
            // TODO: Wire to play this specific track / start radio from here
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Smaller art swatch
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(alternativeArtGradient(for: pick))
                    .frame(width: 130, height: 130)
                    .overlay(
                        VStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(DeejAIFonts.serifTitle)
                                .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.7))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(DeejAIColors.surfaceColor.opacity(0.15)))
                                .padding(.bottom, 12)
                        }
                    )

                Text(pick.title)
                    .font(DeejAIFonts.serifHeadline)
                    .foregroundStyle(DeejAIColors.textPrimaryColor)
                    .lineLimit(1)

                Text(pick.artist)
                    .font(DeejAIFonts.sansSubheadline)
                    .foregroundStyle(DeejAIColors.textTertiaryColor)
                    .lineLimit(1)
            }
            .frame(width: 130)
        }
        .buttonStyle(.plain)
    }

    private func alternativeArtGradient(for pick: HomePick) -> LinearGradient {
        let hash = abs(pick.title.hashValue)
        let palettes: [(Color, Color)] = [
            (DeejAIColors.accentSecondaryColor, DeejAIColors.accentSecondaryMutedColor),
            (DeejAIColors.accentPrimaryColor, DeejAIColors.accentPrimaryDarkColor),
            (DeejAIColors.textSecondaryColor, DeejAIColors.accentSecondaryColor),
            (DeejAIColors.accentSecondaryMutedColor, DeejAIColors.accentPrimaryColor),
            (DeejAIColors.textPrimaryColor, DeejAIColors.accentSecondaryColor)
        ]
        let pair = palettes[hash % palettes.count]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Feel Pill

    private var feelPill: some View {
        HStack(spacing: 8) {
            Text("feel")
                .font(DeejAIFonts.sansSubheadline)
                .foregroundStyle(DeejAIColors.textQuaternaryColor)

            Text("·")
                .font(DeejAIFonts.sansSubheadline)
                .foregroundStyle(DeejAIColors.textQuaternaryColor)

            Text("settled")
                .font(DeejAIFonts.sansSubheadline)
                .foregroundStyle(DeejAIColors.accentSecondaryColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Capsule().fill(DeejAIColors.accentSecondaryColor.opacity(0.08)))
        .overlay(Capsule().stroke(DeejAIColors.accentSecondaryColor.opacity(0.20), lineWidth: 1))
    }
}

// MARK: - Placeholder Data Model

private struct HomePick: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String
}
