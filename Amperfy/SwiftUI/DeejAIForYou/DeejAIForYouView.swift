// DeejAIForYouView.swift
// DeejAI — "For You" home screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - For You View

struct DeejAIForYouView: View {

    // MARK: State

    /// Placeholder mixes until we wire up real data.
    @State private var mixes: [MixCard] = [
        MixCard(name: "Everything In Its Right Place Mix", subtitle: "Radiohead, Sigur Rós, Bon Iver", colors: [DeejAIColors.accentSecondaryColor, DeejAIColors.accentSecondaryMutedColor]),
        MixCard(name: "Evan Finds the Third Room Mix", subtitle: "Khruangbin, Tame Impala, Men I Trust", colors: [DeejAIColors.accentPrimaryColor, DeejAIColors.accentPrimaryDarkColor]),
        MixCard(name: "Says Mix", subtitle: "Nils Frahm, Ólafur Arnalds, Max Richter", colors: [DeejAIColors.textSecondaryColor, DeejAIColors.accentSecondaryColor]),
        MixCard(name: "Pink Rabbits Mix", subtitle: "The National, Iron & Wine, Sufjan Stevens", colors: [DeejAIColors.accentPrimaryColor, DeejAIColors.accentSecondaryMutedColor])
    ]

    /// Placeholder top artists until DeejAI /home endpoint is wired.
    @State private var topArtists: [TopArtistCard] = [
        TopArtistCard(name: "Radiohead", plays: 142),
        TopArtistCard(name: "Khruangbin", plays: 118),
        TopArtistCard(name: "Nils Frahm", plays: 97),
        TopArtistCard(name: "Tame Impala", plays: 85),
        TopArtistCard(name: "Bon Iver", plays: 73),
        TopArtistCard(name: "Sigur Rós", plays: 64)
    ]

    /// Placeholder suggested tracks.
    @State private var suggestedTracks: [SuggestedTrackCard] = [
        SuggestedTrackCard(artist: "Radiohead", title: "Everything In Its Right Place", score: 0.94),
        SuggestedTrackCard(artist: "Khruangbin", title: "Evan Finds the Third Room", score: 0.91),
        SuggestedTrackCard(artist: "Nils Frahm", title: "Says", score: 0.88),
        SuggestedTrackCard(artist: "Bon Iver", title: "Holocene", score: 0.86),
        SuggestedTrackCard(artist: "Tame Impala", title: "Let It Happen", score: 0.83)
    ]

    /// Placeholder recent plays.
    @State private var recentPlays: [RecentPlayCard] = [
        RecentPlayCard(artist: "Sigur Rós", title: "Svefn-g-englar", completed: true),
        RecentPlayCard(artist: "The National", title: "Bloodbuzz Ohio", completed: true),
        RecentPlayCard(artist: "Radiohead", title: "Reckoner", completed: false),
        RecentPlayCard(artist: "Men I Trust", title: "Tailwhip", completed: true),
        RecentPlayCard(artist: "Max Richter", title: "On the Nature of Daylight", completed: false)
    ]

    // MARK: Body

    var body: some View {
        ZStack {
            DeejAIColors.surfaceColor
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 1. Greeting header
                    greetingHeader
                        .padding(.top, 24)
                        .padding(.bottom, 28)

                    // 2. Mix cards
                    sectionLabel("YOUR MIXES")
                    mixCardsSection
                        .padding(.bottom, 32)

                    // 3. Top Artists
                    sectionLabel("TOP ARTISTS")
                    topArtistsSection
                        .padding(.bottom, 32)

                    // 4. Suggested Tracks
                    sectionLabel("SUGGESTED FOR YOU")
                    suggestedTracksSection
                        .padding(.bottom, 32)

                    // 5. Recently Played
                    sectionLabel("RECENTLY PLAYED")
                    recentlyPlayedSection
                        .padding(.bottom, 40)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(DeejAIFonts.serifDisplay)
                .foregroundStyle(DeejAIColors.textPrimaryColor)

            Text("Here's what DeejAI has lined up for you.")
                .font(DeejAIFonts.sansBody)
                .foregroundStyle(DeejAIColors.textTertiaryColor)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning, Aaron"
        case 12..<17: return "Good afternoon, Aaron"
        case 17..<21: return "Good evening, Aaron"
        default:      return "Good night, Aaron"
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DeejAIFonts.sansCaption)
            .tracking(2.5)
            .foregroundStyle(DeejAIColors.textTertiaryColor)
            .padding(.bottom, 14)
    }

    // MARK: - Mix Cards

    private var mixCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(mixes) { mix in
                    mixCard(mix)
                }
            }
        }
    }

    private func mixCard(_ mix: MixCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mix.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)
                .overlay(
                    VStack {
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(DeejAIFonts.serifHeadline)
                            .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.7))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(DeejAIColors.surfaceColor.opacity(0.15)))
                            .padding(.bottom, 14)
                    }
                )

            Text(mix.name)
                .font(DeejAIFonts.serifHeadline)
                .foregroundStyle(DeejAIColors.textPrimaryColor)
                .lineLimit(1)

            Text(mix.subtitle)
                .font(DeejAIFonts.sansSubheadline)
                .foregroundStyle(DeejAIColors.textTertiaryColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 150)
    }

    // MARK: - Top Artists

    private var topArtistsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(topArtists) { artist in
                    topArtistCard(artist)
                }
            }
        }
    }

    private func topArtistCard(_ artist: TopArtistCard) -> some View {
        VStack(spacing: 12) {
            // Placeholder circle with initial
            ZStack {
                Circle()
                    .fill(artistGradient(for: artist.name))
                    .frame(width: 88, height: 88)

                Text(String(artist.name.prefix(1)).uppercased())
                    .font(DeejAIFonts.serifDisplay)
                    .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.85))
            }

            Text(artist.name)
                .font(DeejAIFonts.serifSubheadline)
                .foregroundStyle(DeejAIColors.textPrimaryColor)
                .lineLimit(1)

            Text("\(artist.plays) plays")
                .font(DeejAIFonts.sansCaption)
                .foregroundStyle(DeejAIColors.textQuaternaryColor)
        }
        .frame(width: 100)
    }

    private func artistGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let palette: [(Color, Color)] = [
            (DeejAIColors.accentSecondaryColor, DeejAIColors.accentSecondaryMutedColor),
            (DeejAIColors.accentPrimaryColor, DeejAIColors.accentPrimaryDarkColor),
            (DeejAIColors.textSecondaryColor, DeejAIColors.accentSecondaryColor),
            (DeejAIColors.accentSecondaryMutedColor, DeejAIColors.accentPrimaryColor),
            (DeejAIColors.textPrimaryColor, DeejAIColors.accentSecondaryColor)
        ]
        let pair = palette[hash % palette.count]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Suggested Tracks

    private var suggestedTracksSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestedTracks.enumerated()), id: \.offset) { index, track in
                suggestedTrackRow(track, index: index)
                if index < suggestedTracks.count - 1 {
                    Divider()
                        .overlay(DeejAIColors.trackBackgroundColor.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeejAIColors.surfaceElevatedColor)
        )
    }

    private func suggestedTrackRow(_ track: SuggestedTrackCard, index: Int) -> some View {
        HStack(spacing: 16) {
            // Number badge
            Text("\(index + 1)")
                .font(DeejAIFonts.sansCaptionBold)
                .foregroundStyle(DeejAIColors.textQuaternaryColor)
                .frame(width: 20, alignment: .trailing)

            // Color swatch
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(index % 2 == 0 ? DeejAIColors.accentSecondaryColor : DeejAIColors.accentPrimaryColor)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(DeejAIFonts.serifHeadline)
                    .foregroundStyle(DeejAIColors.textPrimaryColor)
                    .lineLimit(1)

                Text(track.artist)
                    .font(DeejAIFonts.sansSubheadline)
                    .foregroundStyle(DeejAIColors.textTertiaryColor)
                    .lineLimit(1)
            }

            Spacer()

            // Score pill
            if let score = track.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(DeejAIFonts.sansCaptionBold)
                    .foregroundStyle(DeejAIColors.accentSecondaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(DeejAIColors.accentSecondaryColor.opacity(0.10)))
            }

            // Play button
            Button {} label: {
                Image(systemName: "play.fill")
                    .font(DeejAIFonts.sansSubheadline)
                    .foregroundStyle(DeejAIColors.accentPrimaryColor)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(DeejAIColors.accentPrimaryColor.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Recently Played

    private var recentlyPlayedSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(recentPlays.enumerated()), id: \.offset) { index, play in
                recentPlayRow(play)
                if index < recentPlays.count - 1 {
                    Divider()
                        .overlay(DeejAIColors.trackBackgroundColor.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeejAIColors.surfaceElevatedColor)
        )
    }

    private func recentPlayRow(_ play: RecentPlayCard) -> some View {
        HStack(spacing: 16) {
            // Status indicator
            Image(systemName: play.completed ? "checkmark.circle.fill" : "forward.fill")
                .font(DeejAIFonts.sansBody)
                .foregroundStyle(play.completed ? DeejAIColors.accentSecondaryColor : DeejAIColors.textQuaternaryColor)
                .frame(width: 28, height: 28)

            // Track art swatch
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(play.completed
                    ? DeejAIColors.accentSecondaryColor.opacity(0.6)
                    : DeejAIColors.trackBackgroundColor)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(play.title)
                    .font(DeejAIFonts.serifHeadline)
                    .foregroundStyle(DeejAIColors.textPrimaryColor)
                    .lineLimit(1)

                Text(play.artist)
                    .font(DeejAIFonts.sansSubheadline)
                    .foregroundStyle(DeejAIColors.textTertiaryColor)
                    .lineLimit(1)
            }

            Spacer()

            // Status label
            Text(play.completed ? "Listened" : "Skipped")
                .font(DeejAIFonts.sansCaption)
                .foregroundStyle(play.completed ? DeejAIColors.accentSecondaryColor : DeejAIColors.textQuaternaryColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Placeholder Data Models

private struct MixCard: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let colors: [Color]
}

private struct TopArtistCard: Identifiable {
    let id = UUID()
    let name: String
    let plays: Int
}

private struct SuggestedTrackCard: Identifiable {
    let id = UUID()
    let artist: String
    let title: String
    let score: Double?
}

private struct RecentPlayCard: Identifiable {
    let id = UUID()
    let artist: String
    let title: String
    let completed: Bool
}
