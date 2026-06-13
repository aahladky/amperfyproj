// OpenDJCoverArtView.swift
// OpenDJ — Reusable cover art component (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit
import Combine
import UIKit

// MARK: - Cover Art Cache

/// In-memory cache for decoded cover art images.
/// Shared across all OpenDJCoverArtView instances.
@MainActor
final class OpenDJCoverArtCache {
    static let shared = OpenDJCoverArtCache()
    private let cache: NSCache<NSString, UIImage>

    private init() {
        self.cache = NSCache<NSString, UIImage>()
        self.cache.countLimit = 100   // Keep up to 100 images in memory
        self.cache.totalCostLimit = 50 * 1024 * 1024  // ~50 MB
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

// MARK: - OpenDJCoverArtView

/// A SwiftUI view that displays cover art for an `AbstractLibraryEntity`.
///
/// Uses Amperfy's cached-on-disk artwork (downloaded via `ArtworkDownloadManager`).
/// Shows an MCM gradient placeholder while loading / when no artwork is available.
/// Triggers artwork download if the entity has an artwork reference that isn't cached yet.
struct OpenDJCoverArtView: View {

    /// The library entity to show artwork for (e.g. a Song, Album, Artist).
    let entity: AbstractLibraryEntity?

    /// Corner radius for the rendered image.
    let cornerRadius: CGFloat

    /// Placeholder gradient colors (MCM palette).
    /// Defaults to the album-tint gradient used elsewhere in OpenDJ.
    let placeholderColors: [Color]

    /// Whether to trigger artwork download via Amperfy's download manager
    /// when the artwork isn't cached on disk yet.
    let triggersDownload: Bool

    /// When true, only render a real (server `CustomImage`) cover; stay transparent
    /// otherwise so a caller-provided fallback (e.g. an artist initial) shows through.
    let realArtOnly: Bool

    // MARK: State

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    // MARK: Init

    /// Creates a cover art view for the given entity.
    /// - Parameters:
    ///   - entity: The library entity (song, album, etc.) whose artwork to display.
    ///   - cornerRadius: Corner radius for the image (default: 20).
    ///   - placeholderColors: Gradient colors for the placeholder (default: MCM album tint).
    ///   - triggersDownload: If true, triggers artwork download when not cached (default: true).
    init(
        entity: AbstractLibraryEntity?,
        cornerRadius: CGFloat = 20,
        placeholderColors: [Color] = [
            OpenDJColors.textSecondaryColor,
            OpenDJColors.accentPrimaryDarkColor,
            OpenDJColors.textPrimaryColor
        ],
        triggersDownload: Bool = true,
        realArtOnly: Bool = false
    ) {
        self.entity = entity
        self.cornerRadius = cornerRadius
        self.placeholderColors = placeholderColors
        self.triggersDownload = triggersDownload
        self.realArtOnly = realArtOnly
    }

    // MARK: Body

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if realArtOnly {
                // No real server cover — stay transparent so the caller's fallback shows through.
                Color.clear
            } else {
                // MCM gradient placeholder
                LinearGradient(
                    colors: placeholderColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Music note icon overlay
                    Image(systemName: "music.note")
                        .font(OpenDJFonts.serifDisplay)
                        .foregroundStyle(OpenDJColors.surfaceColor.opacity(0.3))
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task {
            await loadArtwork()
        }
        .onChange(of: entity?.objectID) { _, _ in
            Task { @MainActor in
                loadedImage = nil
                isLoading = true
                await loadArtwork()
            }
        }
    }

    /// Estimated placeholder size for icon sizing (derived from geometry).
    /// Uses 40pt as a reasonable default for inline thumbnails.
    private var placeholderSize: CGFloat { 40 }

    // MARK: - Artwork Loading

    @MainActor
    private func loadArtwork() async {
        guard let entity else {
            isLoading = false
            return
        }

        // realArtOnly: bail to the caller's fallback unless a real custom image exists or
        // might still arrive (NotChecked). Never display Amperfy's default image.
        if realArtOnly {
            let s = entity.artwork?.status
            if s != .CustomImage && s != .NotChecked {
                isLoading = false
                return
            }
        }

        let isRealArt = entity.artwork?.status == .CustomImage

        // 1. Cached path from the artwork's local file
        let imagePath = entity.imagePath(setting: .preferServerArtwork)

        // 1+2. In-memory cache / on-disk file — in realArtOnly mode only for a confirmed real image
        if (!realArtOnly || isRealArt), let imagePath {
            if let cachedImage = OpenDJCoverArtCache.shared.image(forKey: imagePath) {
                loadedImage = cachedImage
                isLoading = false
                return
            }
            if let diskImage = UIImage(contentsOfFile: imagePath) {
                let decoded = await diskImage.byPreparingForDisplay() ?? diskImage
                OpenDJCoverArtCache.shared.setImage(decoded, forKey: imagePath)
                loadedImage = decoded
                isLoading = false
                return
            }
        }

        // 3. Trigger a download and poll the on-disk path so art appears as soon as it
        //    downloads (no global-notification dependency).
        if triggersDownload, let artwork = entity.artwork,
           let accountInfo = entity.account?.info {
            let meta = AmperKit.shared.getMeta(accountInfo)
            meta.artworkDownloadManager.download(object: artwork)

            for _ in 0 ..< 15 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1s
                if Task.isCancelled { return }
                if realArtOnly {
                    let s = entity.artwork?.status
                    if s == .IsDefaultImage || s == .FetchError { return }  // no real art → fallback
                    if s != .CustomImage { continue }                       // still NotChecked → wait
                }
                if let path = entity.imagePath(setting: .preferServerArtwork),
                   let img = UIImage(contentsOfFile: path) {
                    let decoded = await img.byPreparingForDisplay() ?? img
                    OpenDJCoverArtCache.shared.setImage(decoded, forKey: path)
                    loadedImage = decoded
                    isLoading = false
                    return
                }
            }
        }

        isLoading = false
    }

    /// Refreshes the displayed image (called externally when a download completes).
    @MainActor
    mutating func refresh() async {
        loadedImage = nil
        isLoading = true
        await loadArtwork()
    }
}

// MARK: - Convenience Initializers

extension OpenDJCoverArtView {

    /// Creates a cover art view sized for the Now Playing screen (large hero art).
    /// - Parameter entity: The currently playing track.
    static func nowPlaying(entity: AbstractPlayable?) -> OpenDJCoverArtView {
        OpenDJCoverArtView(
            entity: entity,
            cornerRadius: 20
                        )
    }

    /// Creates a cover art view for a mini thumbnail (e.g. up-next, suggestion rows).
    /// - Parameter entity: The playable to show artwork for.
    static func thumbnail(entity: AbstractLibraryEntity?) -> OpenDJCoverArtView {
        OpenDJCoverArtView(
            entity: entity,
            cornerRadius: 8,
            placeholderColors: [
                OpenDJColors.accentSecondaryColor,
                OpenDJColors.accentSecondaryMutedColor
            ]
        )
    }

    /// Creates a cover art view for a medium card (e.g. alternative picks on Home).
    /// - Parameter entity: The entity to show artwork for.
    static func card(entity: AbstractLibraryEntity?) -> OpenDJCoverArtView {
        OpenDJCoverArtView(
            entity: entity,
            cornerRadius: 8
        )
    }

    /// Creates a cover art view for a mix card on the For You screen.
    /// - Parameter entity: The entity to show artwork for.
    static func mixCard(entity: AbstractLibraryEntity?) -> OpenDJCoverArtView {
        OpenDJCoverArtView(
            entity: entity,
            cornerRadius: 14
        )
    }
}
