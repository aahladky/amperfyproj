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
        MixCard(name: "Daily Mix 1", subtitle: "Radiohead, Sigur Rós, Bon Iver", colors: [DeejAIColors.teal, DeejAIColors.tealMuted]),
        MixCard(name: "Daily Mix 2", subtitle: "Khruangbin, Tame Impala, Men I Trust", colors: [DeejAIColors.terracotta, DeejAIColors.terracottaDark]),
        MixCard(name: "Daily Mix 3", subtitle: "Nils Frahm, Ólafur Arnalds, Max Richter", colors: [DeejAIColors.brownMedium, DeejAIColors.teal]),
        MixCard(name: "Mellow Flow", subtitle: "The National, Iron & Wine, Sufjan Stevens", colors: [DeejAIColors.terracotta, DeejAIColors.tealMuted])
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
            DeejAIColors.cream
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
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(DeejAIColors.brownDark)

            Text("Here's what DeejAI has lined up for you.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(DeejAIColors.tan)
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
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(2.5)
            .foregroundStyle(DeejAIColors.tan)
            .padding(.bottom, 14)
    }

    // MARK: - Mix Cards

    private var mixCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(mixes) { mix in
                    mixCard(mix)
                }
            }
        }
    }

    private func mixCard(_ mix: MixCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(DeejAIColors.cream.opacity(0.7))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(DeejAIColors.cream.opacity(0.15)))
                            .padding(.bottom, 14)
                    }
                )

            Text(mix.name)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(DeejAIColors.brownDark)
                .lineLimit(1)

            Text(mix.subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(DeejAIColors.tan)
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
        VStack(spacing: 10) {
            // Placeholder circle with initial
            ZStack {
                Circle()
                    .fill(artistGradient(for: artist.name))
                    .frame(width: 88, height: 88)

                Text(String(artist.name.prefix(1)).uppercased())
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(DeejAIColors.cream.opacity(0.85))
            }

            Text(artist.name)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(DeejAIColors.brownDark)
                .lineLimit(1)

            Text("\(artist.plays) plays")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(DeejAIColors.tanLight)
        }
        .frame(width: 100)
    }

    private func artistGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let palette: [(Color, Color)] = [
            (DeejAIColors.teal, DeejAIColors.tealMuted),
            (DeejAIColors.terracotta, DeejAIColors.terracottaDark),
            (DeejAIColors.brownMedium, DeejAIColors.teal),
            (DeejAIColors.tealMuted, DeejAIColors.terracotta),
            (DeejAIColors.brownDark, DeejAIColors.teal)
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
                        .overlay(DeejAIColors.trackBackground.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeejAIColors.creamCard)
        )
    }

    private func suggestedTrackRow(_ track: SuggestedTrackCard, index: Int) -> some View {
        HStack(spacing: 14) {
            // Number badge
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(DeejAIColors.tanLight)
                .frame(width: 20, alignment: .trailing)

            // Color swatch
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(index % 2 == 0 ? DeejAIColors.teal : DeejAIColors.terracotta)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(DeejAIColors.brownDark)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(DeejAIColors.tan)
                    .lineLimit(1)
            }

            Spacer()

            // Score pill
            if let score = track.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(DeejAIColors.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(DeejAIColors.teal.opacity(0.10)))
            }

            // Play button
            Button {} label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DeejAIColors.terracotta)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(DeejAIColors.terracotta.opacity(0.10)))
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
                        .overlay(DeejAIColors.trackBackground.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeejAIColors.creamCard)
        )
    }

    private func recentPlayRow(_ play: RecentPlayCard) -> some View {
        HStack(spacing: 14) {
            // Status indicator
            Image(systemName: play.completed ? "checkmark.circle.fill" : "forward.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(play.completed ? DeejAIColors.teal : DeejAIColors.tanLight)
                .frame(width: 28, height: 28)

            // Track art swatch
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(play.completed
                    ? DeejAIColors.teal.opacity(0.6)
                    : DeejAIColors.trackBackground)
                .frame(width: 40, height: 40)

            // Track info
            VStack(alignment: .leading, spacing: 3) {
                Text(play.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(DeejAIColors.brownDark)
                    .lineLimit(1)

                Text(play.artist)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(DeejAIColors.tan)
                    .lineLimit(1)
            }

            Spacer()

            // Status label
            Text(play.completed ? "Listened" : "Skipped")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(play.completed ? DeejAIColors.teal : DeejAIColors.tanLight)
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
