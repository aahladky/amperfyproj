// OpenDJForYouView.swift
// OpenDJ — "For You" screen (Mid-Century Modern)
//
// The behavioral / contextual plane: horizontal rails of startable album "mix"
// tiles, lifted from the reward log (recent rotation, rediscover, …). Each tile
// is an album with a seed track that drives the cover art and — next increment —
// tap-to-start-radio. This replaces the old top-artists / suggested-track-list /
// recently-played layout, which mixed all-time stats and single-track rows onto a
// top-level screen.
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - For You View

struct OpenDJForYouView: View {

    // MARK: Dependencies

    /// Loads the For You payload from the OpenDJ sidecar (`/api/foryou`).
    /// `nil` → no live load (e.g. SwiftUI previews); the screen shows its empty state.
    let forYouProvider: (() async throws -> ForYouResponse)?

    /// Resolves a seed track id to a local library entity, for cover art. Optional.
    let resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)?

    /// Starts radio from a seed track id (tap-to-play). Optional; wired next increment.
    let startRadio: (@MainActor (String) -> Void)?

    init(
        forYouProvider: (() async throws -> ForYouResponse)? = nil,
        resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)? = nil,
        startRadio: (@MainActor (String) -> Void)? = nil
    ) {
        self.forYouProvider = forYouProvider
        self.resolveEntity = resolveEntity
        self.startRadio = startRadio
    }

    /// User preference: show real album art in tiles, or minimalist color blocks.
    @AppStorage("opendjShowAlbumArt") private var showAlbumArt = true

    // MARK: State

    @State private var rails: [DisplayRail] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var loadErrorDetail: String?

    // MARK: Layout constants

    private let tileSize: CGFloat = 150
    private let railSpacing: CGFloat = 16
    private let edgePadding: CGFloat = 20

    // MARK: Body

    var body: some View {
        ZStack {
            OpenDJColors.surfaceColor
                .ignoresSafeArea()

            if isLoading && rails.isEmpty {
                ProgressView()
                    .tint(OpenDJColors.accentPrimaryColor)
            } else if loadFailed && rails.isEmpty {
                statusView(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't reach OpenDJ",
                    detail: loadErrorDetail ?? "Your stations will appear here once the server responds."
                )
            } else if rails.isEmpty {
                statusView(
                    icon: "music.note.list",
                    title: "Nothing here yet",
                    detail: "Play some music and your stations will start to build."
                )
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await loadForYou() }
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                greetingHeader
                    .padding(.horizontal, edgePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                ForEach(rails) { rail in
                    sectionLabel(rail.title.uppercased())
                        .padding(.horizontal, edgePadding)
                        .padding(.bottom, 12)

                    railScroll(rail)
                        .padding(.bottom, 32)
                }

                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadForYou() async {
        guard let forYouProvider else { return }
        isLoading = true
        loadFailed = false
        do {
            let response = try await forYouProvider()
            rails = response.rails.map { rail in
                DisplayRail(
                    id: rail.id,
                    title: rail.title,
                    tiles: rail.items.map { item in
                        DisplayTile(
                            id: item.id,
                            title: item.title,
                            subtitle: item.subtitle,
                            seedTrackId: item.seedTrackId,
                            entity: item.seedTrackId.flatMap { resolveEntity?($0) }
                        )
                    }
                )
            }
        } catch {
            loadErrorDetail = String(describing: error)
            loadFailed = true
        }
        isLoading = false
    }

    // MARK: - Rails

    private func railScroll(_ rail: DisplayRail) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: railSpacing) {
                ForEach(rail.tiles) { tile in
                    tileView(tile)
                }
            }
            .padding(.horizontal, edgePadding)
        }
    }

    private func tileView(_ tile: DisplayTile) -> some View {
        Button {
            if let seed = tile.seedTrackId {
                startRadio?(seed)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Group {
                        if showAlbumArt {
                            OpenDJCoverArtView(entity: tile.entity, cornerRadius: 14)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tileGradient(for: tile.title))
                        }
                    }
                    .frame(width: tileSize, height: tileSize)

                    // Play affordance — these tiles start radio.
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(OpenDJFonts.sansSubheadline)
                                .foregroundStyle(OpenDJColors.surfaceColor)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(OpenDJColors.accentPrimaryColor.opacity(0.9)))
                                .padding(10)
                        }
                    }
                    .frame(width: tileSize, height: tileSize)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)

                Text(tile.title)
                    .font(OpenDJFonts.serifHeadline)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                    .lineLimit(1)

                if !tile.subtitle.isEmpty {
                    Text(tile.subtitle)
                        .font(OpenDJFonts.sansSubheadline)
                        .foregroundStyle(OpenDJColors.textTertiaryColor)
                        .lineLimit(1)
                }
            }
            .frame(width: tileSize, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func tileGradient(for key: String) -> LinearGradient {
        let hash = abs(key.hashValue)
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

            Text("Stations built from how you've been listening.")
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
    }
}

// MARK: - Display Models

/// A rail resolved for display: title + tiles with their library entities attached.
private struct DisplayRail: Identifiable {
    let id: String
    let title: String
    let tiles: [DisplayTile]
}

/// A tile resolved for display: an album mix with its seed-track entity (for cover art).
private struct DisplayTile: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let seedTrackId: String?
    let entity: AbstractLibraryEntity?
}
