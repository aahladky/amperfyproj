// OpenDJForYouView.swift
// OpenDJ — "For You" screen (Mid-Century Modern)
//
// The behavioral / contextual plane: horizontal rails of startable album "mix"
// tiles, lifted from the reward log (recent rotation, rediscover, …). Each tile
// is an album with a seed track that drives the cover art and tap-to-start-radio.
//
// This file also hosts the SHARED rails UI (OpenDJRail / OpenDJRailTile /
// OpenDJRailsList / OpenDJRailsStatus) reused by the Home screen, so both the
// behavioral plane (For You) and the audio/embedding plane (Home) render with
// one identical rails component. (The Xcode project isn't using synchronized
// file groups, so the shared component lives here rather than in its own file.)
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

    @State private var rails: [OpenDJRail] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var loadErrorDetail: String?
    @State private var didInitialLoad = false

    // MARK: Body

    var body: some View {
        ZStack {
            OpenDJColors.surfaceColor
                .ignoresSafeArea()

            if isLoading && rails.isEmpty {
                ProgressView()
                    .tint(OpenDJColors.accentPrimaryColor)
            } else if loadFailed && rails.isEmpty {
                OpenDJRailsStatus(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't reach OpenDJ",
                    detail: loadErrorDetail ?? "Your stations will appear here once the server responds."
                )
            } else if rails.isEmpty {
                OpenDJRailsStatus(
                    icon: "music.note.list",
                    title: "Nothing here yet",
                    detail: "Play some music and your stations will start to build."
                )
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if !didInitialLoad { didInitialLoad = true; await loadForYou() }
        }
        // Re-fetch each time the tab is shown again so stations reflect recent listening.
        .onAppear {
            if didInitialLoad { Task { await loadForYou(silent: !rails.isEmpty) } }
        }
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                OpenDJGreetingHeader(
                    title: greetingText,
                    subtitle: "Stations built from how you've been listening."
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)

                OpenDJRailsList(
                    rails: rails,
                    showAlbumArt: showAlbumArt,
                    startRadio: startRadio
                )

                Spacer(minLength: 20)
            }
        }
        .refreshable { await loadForYou(silent: true) }
    }

    // MARK: - Data Loading

    /// Loads the rails. When `silent`, doesn't toggle the loading/error chrome — used for
    /// background refreshes (tab re-appear, pull-to-refresh) so existing content stays put
    /// and a transient failure doesn't replace good rails with an error screen.
    @MainActor
    private func loadForYou(silent: Bool = false) async {
        guard let forYouProvider else { return }
        if !silent { isLoading = true; loadFailed = false }
        do {
            let response = try await forYouProvider()
            rails = OpenDJRail.from(response.rails, resolveEntity: resolveEntity)
            loadFailed = false
        } catch {
            if !silent {
                loadErrorDetail = String(describing: error)
                loadFailed = true
            }
        }
        if !silent { isLoading = false }
    }

    private var greetingText: String { OpenDJGreeting.text(name: "Aaron") }
}

// MARK: - Shared Rails UI (reused by Home)

/// A rail resolved for display: title + tiles with their library entities attached.
struct OpenDJRail: Identifiable {
    let id: String
    let title: String
    let tiles: [OpenDJRailTile]

    /// Build display rails from the decoded API rails, resolving each tile's seed
    /// track id to a local entity for cover art.
    @MainActor
    static func from(
        _ apiRails: [Rail],
        resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)?
    ) -> [OpenDJRail] {
        apiRails.map { rail in
            OpenDJRail(
                id: rail.id,
                title: rail.title,
                tiles: rail.items.map { item in
                    OpenDJRailTile(
                        id: item.id,
                        title: item.title,
                        subtitle: item.subtitle,
                        seedTrackId: item.seedTrackId,
                        entity: item.seedTrackId.flatMap { resolveEntity?($0) }
                    )
                }
            )
        }
    }
}

/// A tile resolved for display: an album mix with its seed-track entity (for cover art).
struct OpenDJRailTile: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let seedTrackId: String?
    let entity: AbstractLibraryEntity?
}

/// Vertical stack of horizontal rails of startable cover-art tiles.
/// Shared by For You (behavioral plane) and Home (audio/embedding plane).
struct OpenDJRailsList: View {
    let rails: [OpenDJRail]
    let showAlbumArt: Bool
    let startRadio: (@MainActor (String) -> Void)?

    private let tileSize: CGFloat = 150
    private let railSpacing: CGFloat = 16
    private let edgePadding: CGFloat = 20

    var body: some View {
        ForEach(rails) { rail in
            sectionLabel(rail.title.uppercased())
                .padding(.horizontal, edgePadding)
                .padding(.bottom, 12)

            railScroll(rail)
                .padding(.bottom, 32)
        }
    }

    private func railScroll(_ rail: OpenDJRail) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: railSpacing) {
                ForEach(rail.tiles) { tile in
                    tileView(tile)
                }
            }
            .padding(.horizontal, edgePadding)
        }
    }

    private func tileView(_ tile: OpenDJRailTile) -> some View {
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
                                .fill(OpenDJTileGradient.gradient(for: tile.title))
                        }
                    }
                    .frame(width: tileSize, height: tileSize)

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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(OpenDJFonts.sansCaption)
            .tracking(2.5)
            .foregroundStyle(OpenDJColors.textTertiaryColor)
    }
}

/// A greeting block (serif title + sans subtitle) shared by both rails screens.
struct OpenDJGreetingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(OpenDJFonts.serifDisplay)
                .foregroundStyle(OpenDJColors.textPrimaryColor)

            Text(subtitle)
                .font(OpenDJFonts.sansBody)
                .foregroundStyle(OpenDJColors.textTertiaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Centered status block for loading-failure / empty states.
struct OpenDJRailsStatus: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
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
}

/// Deterministic MCM gradient used when album art is hidden.
enum OpenDJTileGradient {
    static func gradient(for key: String) -> LinearGradient {
        let hash = abs(key.hashValue)
        let palette: [(Color, Color)] = [
            (OpenDJColors.accentSecondaryColor, OpenDJColors.accentSecondaryMutedColor),
            (OpenDJColors.accentPrimaryColor, OpenDJColors.accentPrimaryDarkColor),
            (OpenDJColors.textSecondaryColor, OpenDJColors.accentSecondaryColor),
            (OpenDJColors.accentSecondaryMutedColor, OpenDJColors.accentPrimaryColor),
            (OpenDJColors.textPrimaryColor, OpenDJColors.accentSecondaryColor)
        ]
        let pair = palette[hash % palette.count]
        return LinearGradient(colors: [pair.0, pair.1],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Time-of-day greeting shared by both rails screens.
enum OpenDJGreeting {
    static func text(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        case 17..<21: return "Good evening, \(name)"
        default:      return "Good night, \(name)"
        }
    }
}
