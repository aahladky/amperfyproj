// OpenDJForYouView.swift
// OpenDJ — "For You" home screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - For You View

struct OpenDJForYouView: View {

    // MARK: Dependencies

    /// Loads the home payload from the OpenDJ sidecar (`/api/home`).
    /// `nil` → no live load (e.g. SwiftUI previews); the screen shows its empty state.
    let homeProvider: (() async throws -> HomeResponse)?

    /// Resolves a Navidrome track id to a local library entity, for cover art. Optional.
    let resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)?

    init(
        homeProvider: (() async throws -> HomeResponse)? = nil,
        resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)? = nil
    ) {
        self.homeProvider = homeProvider
        self.resolveEntity = resolveEntity
    }

    /// User preference: show real album art in cards, or the minimalist color blocks.
    @AppStorage("opendjShowAlbumArt") private var showAlbumArt = true

    // MARK: State

    @State private var mixes: [MixCard] = []
    @State private var topArtists: [TopArtistCard] = []
    @State private var suggestedTracks: [SuggestedTrackCard] = []
    @State private var recentPlays: [RecentPlayCard] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var loadErrorDetail: String?

    private var isEmptyAll: Bool {
        mixes.isEmpty && topArtists.isEmpty && suggestedTracks.isEmpty && recentPlays.isEmpty
    }

    // MARK: Body

    var body: some View {
        ZStack {
            OpenDJColors.surfaceColor
                .ignoresSafeArea()

            if isLoading && isEmptyAll {
                ProgressView()
                    .tint(OpenDJColors.accentPrimaryColor)
            } else if loadFailed && isEmptyAll {
                statusView(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't reach OpenDJ",
                    detail: loadErrorDetail ?? "Your recommendations will appear here once the server responds."
                )
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await loadHome() }
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // 1. Greeting header
                greetingHeader
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // 2. Mix cards (hidden until the sidecar serves mixes)
                if !mixes.isEmpty {
                    sectionLabel("YOUR MIXES")
                    mixCardsSection
                        .padding(.bottom, 32)
                }

                // 3. Top Artists
                if !topArtists.isEmpty {
                    sectionLabel("TOP ARTISTS")
                    topArtistsSection
                        .padding(.bottom, 32)
                }

                // 4. Suggested Tracks
                if !suggestedTracks.isEmpty {
                    sectionLabel("SUGGESTED FOR YOU")
                    suggestedTracksSection
                        .padding(.bottom, 32)
                }

                // 5. Recently Played
                if !recentPlays.isEmpty {
                    sectionLabel("RECENTLY PLAYED")
                    recentlyPlayedSection
                        .padding(.bottom, 40)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadHome() async {
        guard let homeProvider else { return }
        isLoading = true
        loadFailed = false
        do {
            let home = try await homeProvider()
            topArtists = home.topArtists.map { a in
                let artistEntity = (a.trackId.flatMap { resolveEntity?($0) } as? Song)?.artist
                return TopArtistCard(name: a.artist, plays: a.playCount, entity: artistEntity)
            }
            suggestedTracks = home.suggested.map {
                SuggestedTrackCard(
                    artist: $0.artist, title: $0.title, score: $0.score,
                    entity: $0.trackId.flatMap { resolveEntity?($0) }
                )
            }
            recentPlays = home.recent.map {
                RecentPlayCard(
                    artist: $0.artist, title: $0.title, playedAt: $0.playedAt,
                    entity: $0.trackId.flatMap { resolveEntity?($0) }
                )
            }
        } catch {
            loadErrorDetail = String(describing: error)
            loadFailed = true
        }
        isLoading = false
    }

    // MARK: - Status View (loading failure / empty)

    private func statusView(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(OpenDJFonts.serifDisplay)
                .foregroundStyle(OpenDJColors.textTertiaryColor)

            Text(title)
                .font(OpenDJFonts.serifHeadline)
                .foregroundStyle(OpenDJColors.textPrimaryColor)

            Text(detail)
                .font(OpenDJFonts.sansSubheadline)
                .foregroundStyle(OpenDJColors.textTertiaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 48)
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
            // Real artist artwork (toggle on + resolved) or the initial circle
            Group {
                if showAlbumArt, let entity = artist.entity {
                    OpenDJCoverArtView(entity: entity, cornerRadius: 44)
                } else {
                    Circle()
                        .fill(artistGradient(for: artist.name))
                        .overlay(
                            Text(String(artist.name.prefix(1)).uppercased())
                                .font(OpenDJFonts.serifDisplay)
                                .foregroundStyle(OpenDJColors.surfaceColor.opacity(0.85))
                        )
                }
            }
            .frame(width: 88, height: 88)

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

            // Artwork (toggle on) or color swatch (toggle off)
            Group {
                if showAlbumArt {
                    OpenDJCoverArtView.thumbnail(entity: track.entity)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(index % 2 == 0 ? OpenDJColors.accentSecondaryColor : OpenDJColors.accentPrimaryColor)
                }
            }
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

            // Score pill (playback wiring is the next increment)
            if let score = track.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(OpenDJFonts.sansCaptionBold)
                    .foregroundStyle(OpenDJColors.accentSecondaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OpenDJColors.accentSecondaryColor.opacity(0.10)))
            }
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
            // Neutral status indicator — the /api/home `recent` payload carries no
            // finish/skip flag, so we don't claim one (design honesty rule).
            Image(systemName: "clock.arrow.circlepath")
                .font(OpenDJFonts.sansBody)
                .foregroundStyle(OpenDJColors.textQuaternaryColor)
                .frame(width: 28, height: 28)

            // Artwork (toggle on) or color swatch (toggle off)
            Group {
                if showAlbumArt {
                    OpenDJCoverArtView.thumbnail(entity: play.entity)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OpenDJColors.trackBackgroundColor)
                }
            }
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

            // When it was played (relative), if the server provided a timestamp
            if let when = Self.relativeTime(play.playedAt) {
                Text(when)
                    .font(OpenDJFonts.sansCaption)
                    .foregroundStyle(OpenDJColors.textQuaternaryColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFraction = ISO8601DateFormatter()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static func relativeTime(_ iso: String?) -> String? {
        guard let iso else { return nil }
        let date = isoFormatter.date(from: iso) ?? isoFormatterNoFraction.date(from: iso)
        guard let date else { return nil }
        return relativeFormatter.localizedString(for: date, relativeTo: .now)
    }
}

// MARK: - Card Data Models

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
    let entity: AbstractLibraryEntity?
}

private struct SuggestedTrackCard: Identifiable {
    let id = UUID()
    let artist: String
    let title: String
    let score: Double?
    let entity: AbstractLibraryEntity?
}

private struct RecentPlayCard: Identifiable {
    let id = UUID()
    let artist: String
    let title: String
    let playedAt: String?
    let entity: AbstractLibraryEntity?
}
