// OpenDJHomeView.swift
// OpenDJ — Home screen (Mid-Century Modern)
//
// The audio / embedding plane: sound-station rails lifted from the AudioMuse
// feature store (your core sound from the embedding centroid, plus energy/tempo
// stations) rather than play history. Renders with the same shared rails UI as
// For You (OpenDJRailsList), so the two top-level screens are visually unified.
// Home additionally owns the Settings gear — the only entry to Settings in the
// OpenDJ shell.
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - Home View

struct OpenDJHomeView: View {

    // MARK: Dependencies

    /// Loads the Home payload from the OpenDJ sidecar (`/api/home`, rails schema).
    /// `nil` → no live load (e.g. SwiftUI previews); the screen shows its empty state.
    let homeProvider: (() async throws -> ForYouResponse)?

    /// Resolves a seed track id to a local library entity, for cover art. Optional.
    let resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)?

    /// Starts radio from a seed track id (tap-to-play). Optional; wired next increment.
    let startRadio: (@MainActor (String) -> Void)?

    /// Presents the Settings screen. Wired by the hosting controller; nil = no-op.
    let onOpenSettings: (() -> Void)?

    init(
        homeProvider: (() async throws -> ForYouResponse)? = nil,
        resolveEntity: (@MainActor (String) -> AbstractLibraryEntity?)? = nil,
        startRadio: (@MainActor (String) -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.homeProvider = homeProvider
        self.resolveEntity = resolveEntity
        self.startRadio = startRadio
        self.onOpenSettings = onOpenSettings
    }

    /// User preference: show real album art in tiles, or minimalist color blocks.
    @AppStorage("opendjShowAlbumArt") private var showAlbumArt = true

    // MARK: State

    @State private var rails: [OpenDJRail] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var loadErrorDetail: String?

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
                    detail: loadErrorDetail ?? "Your sound stations will appear here once the server responds."
                )
            } else if rails.isEmpty {
                OpenDJRailsStatus(
                    icon: "waveform",
                    title: "Building your sound",
                    detail: "Once your library is analyzed, your stations show up here."
                )
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            settingsButton
                .padding(.top, 4)
                .padding(.trailing, 20)
        }
        .task { await loadHome() }
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                OpenDJGreetingHeader(
                    title: OpenDJGreeting.text(name: "Aaron"),
                    subtitle: "Sound stations from across your library."
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                // Leave room for the settings gear in the top-right.
                .padding(.trailing, 52)

                OpenDJRailsList(
                    rails: rails,
                    showAlbumArt: showAlbumArt,
                    startRadio: startRadio
                )

                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadHome() async {
        guard let homeProvider else { return }
        isLoading = true
        loadFailed = false
        do {
            let response = try await homeProvider()
            rails = OpenDJRail.from(response.rails, resolveEntity: resolveEntity)
        } catch {
            loadErrorDetail = String(describing: error)
            loadFailed = true
        }
        isLoading = false
    }

    // MARK: - Settings Button

    /// Settings entry point — the OpenDJ shell has no nav-bar account button,
    /// so this gear is the app's only door to Settings.
    private var settingsButton: some View {
        Button {
            onOpenSettings?()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(OpenDJColors.textSecondaryColor)
                .frame(width: 44, height: 44)
                .background(Circle().fill(OpenDJColors.surfaceElevatedColor))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}
