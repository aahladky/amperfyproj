// OpenDJForYouView.swift
// OpenDJ — "For You" home screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - For You View

struct OpenDJForYouView: View {

    // MARK: State

    /// Placeholder mixes until we wire up real data.
    @State private var mixes: [MixCard] = {
#if DEBUG
        [
            MixCard(name: "Everything In Its Right Place Mix", subtitle: "Radiohead, Sigur Rós, Bon Iver", colors: [OpenDJColors.accentSecondaryColor, OpenDJColors.accentSecondaryMutedColor]),
            MixCard(name: "Evan Finds the Third Room Mix", subtitle: "Khruangbin, Tame Impala, Men I Trust", colors: [OpenDJColors.accentPrimaryColor, OpenDJColors.accentPrimaryDarkColor]),
            MixCard(name: "Says Mix", subtitle: "Nils Frahm, Ólafur Arnalds, Max Richter", colors: [OpenDJColors.textSecondaryColor, OpenDJColors.accentSecondaryColor]),
            MixCard(name: "Pink Rabbits Mix", subtitle: "The National, Iron & Wine, Sufjan Stevens", colors: [OpenDJColors.accentPrimaryColor, OpenDJColors.accentSecondaryMutedColor])
        ]
#else
        []
#endif
    }()

    /// Placeholder top artists until OpenDJ /home endpoint is wired.
    @State private var topArtists: [TopArtistCard] = {
#if DEBUG
        [
            TopArtistCard(name: "Radiohead", plays: 142),
            TopArtistCard(name: "Khruangbin", plays: 118),
            TopArtistCard(name: "Nils Frahm", plays: 97),
            TopArtistCard(name: "Tame Impala", plays: 85),
            TopArtistCard(name: "Bon Iver", plays: 73),
            TopArtistCard(name: "Sigur Rós", plays: 64)
        ]
#else
        []
#endif
    }()

    /// Placeholder suggested tracks.
    @State private var suggestedTracks: [SuggestedTrackCard] = {
#if DEBUG
        [
            SuggestedTrackCard(artist: "Radiohead", title: "Everything In Its Right Place", score: 0.94),
            SuggestedTrackCard(artist: "Khruangbin", title: "Evan Finds the Third Room", score: 0.91),
            SuggestedTrackCard(artist: "Nils Frahm", title: "Says", score: 0.88),
            SuggestedTrackCard(artist: "Bon Iver", title: "Holocene", score: 0.86),
            SuggestedTrackCard(artist: "Tame Impala", title: "Let It Happen", score: 0.83)
        ]
#else
        []
#endif
    }()

    /// Placeholder recent plays.
    @State private var recentPlays: [RecentPlayCard] = {
#if DEBUG
        [
            RecentPlayCard(artist: "Sigur Rós", title: "Svefn-g-englar", completed: true),
            RecentPlayCard(artist: "The National", title: "Bloodbuzz Ohio", completed: true),
            RecentPlayCard(artist: "Radiohead", title: "Reckoner", completed: false),
            RecentPlayCard(artist: "Men I Trust", title: "Tailwhip", completed: true),
            RecentPlayCard(artist: "Max Richter", title: "On the Nature of Daylight", completed: false)
        ]
#else
        []
#endif
    }()

    // MARK: Body

    var body: some View {
        ZStack {
            OpenDJColors.surfaceColor
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
                .font(OpenDJFonts.serifDisplay)
                .foregroundStyle(OpenDJColors.textPrimaryColor)

            Text("Here's what OpenDJ has lined up for you.")
                .font(OpenDJFonts.sansBody)
                .foregroundStyle(OpenDJColors.textTertiaryColor)
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
            .font(OpenDJFonts.sansCaption)
            .tracking(2.5)
            .foregroundStyle(OpenDJColors.textTertiaryColor)
            .padding(.bottom, 12)
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
                            .font(OpenDJFonts.serifHeadline)
                            .foregroundStyle(OpenDJColors.surfaceColor.opacity(0.7))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(OpenDJColors.surfaceColor.opacity(0.15)))
                            .padding(.bottom, 12)
                    }
                )

            Text(mix.name)
                .font(OpenDJFonts.serifHeadline)
                .foregroundStyle(OpenDJColors.textPrimaryColor)
                .lineLimit(1)

            Text(mix.subtitle)
                .font(OpenDJFonts.sansSubheadline)
                .foregroundStyle(OpenDJColors.textTertiaryColor)
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
                    .font(OpenDJFonts.serifDisplay)
                    .foregroundStyle(OpenDJColors.surfaceColor.opacity(0.85))
            }

            Text(artist.name)
                .font(OpenDJFonts.serifSubheadline)
                .foregroundStyle(OpenDJColors.textPrimaryColor)
                .lineLimit(1)

            Text("\(artist.plays) plays")
                .font(OpenDJFonts.sansCaption)
                .foregroundStyle(OpenDJColors.textQuaternaryColor)
        }
        .frame(width: 100)
    }

    private func artistGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let palette: [(Color, Color)] = [
            (OpenDJColors.accentSecondaryColor, OpenDJColors.accentSecondaryMutedColor),
            (OpenDJColors.accentPrimaryColor, OpenDJColors.accentPrimaryDarkColor),
            (OpenDJColors.textSecondaryColor, OpenDJColors.accentSecondaryColor),
            (OpenDJColors.accentSecondaryMutedColor, OpenDJColors.accentPrimaryColor),
            (OpenDJColors.textPrimaryColor, OpenDJColors.accentSecondaryColor)
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
                        .overlay(OpenDJColors.trackBackgroundColor.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OpenDJColors.surfaceElevatedColor)
        )
    }

    private func suggestedTrackRow(_ track: SuggestedTrackCard, index: Int) -> some View {
        HStack(spacing: 16) {
            // Number badge
            Text("\(index + 1)")
                .font(OpenDJFonts.sansCaptionBold)
                .foregroundStyle(OpenDJColors.textQuaternaryColor)
                .frame(width: 20, alignment: .trailing)

            // Color swatch
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(index % 2 == 0 ? OpenDJColors.accentSecondaryColor : OpenDJColors.accentPrimaryColor)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(OpenDJFonts.serifHeadline)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                    .lineLimit(1)

                Text(track.artist)
                    .font(OpenDJFonts.sansSubheadline)
                    .foregroundStyle(OpenDJColors.textTertiaryColor)
                    .lineLimit(1)
            }

            Spacer()

            // Score pill
            if let score = track.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(OpenDJFonts.sansCaptionBold)
                    .foregroundStyle(OpenDJColors.accentSecondaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OpenDJColors.accentSecondaryColor.opacity(0.10)))
            }

            // Play button
            Button {} label: {
                Image(systemName: "play.fill")
                    .font(OpenDJFonts.sansSubheadline)
                    .foregroundStyle(OpenDJColors.accentPrimaryColor)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(OpenDJColors.accentPrimaryColor.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Recently Played

    private var recentlyPlayedSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(recentPlays.enumerated()), id: \.offset) { index, play in
                recentPlayRow(play)
                if index < recentPlays.count - 1 {
                    Divider()
                        .overlay(OpenDJColors.trackBackgroundColor.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OpenDJColors.surfaceElevatedColor)
        )
    }

    private func recentPlayRow(_ play: RecentPlayCard) -> some View {
        HStack(spacing: 16) {
            // Status indicator
            Image(systemName: play.completed ? "checkmark.circle.fill" : "forward.fill")
                .font(OpenDJFonts.sansBody)
                .foregroundStyle(play.completed ? OpenDJColors.accentSecondaryColor : OpenDJColors.textQuaternaryColor)
                .frame(width: 28, height: 28)

            // Track art swatch
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(play.completed
                    ? OpenDJColors.accentSecondaryColor.opacity(0.6)
                    : OpenDJColors.trackBackgroundColor)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(play.title)
                    .font(OpenDJFonts.serifHeadline)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                    .lineLimit(1)

                Text(play.artist)
                    .font(OpenDJFonts.sansSubheadline)
                    .foregroundStyle(OpenDJColors.textTertiaryColor)
                    .lineLimit(1)
            }

            Spacer()

            // Status label
            Text(play.completed ? "Listened" : "Skipped")
                .font(OpenDJFonts.sansCaption)
                .foregroundStyle(play.completed ? OpenDJColors.accentSecondaryColor : OpenDJColors.textQuaternaryColor)
        }
        .padding(.horizontal, 12)
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
