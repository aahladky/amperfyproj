// DeejAICoverArtView.swift
// DeejAI — Reusable cover art component (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit
import Combine
import UIKit

// MARK: - Cover Art Cache

/// In-memory cache for decoded cover art images.
/// Shared across all DeejAICoverArtView instances.
@MainActor
final class DeejAICoverArtCache {
    static let shared = DeejAICoverArtCache()
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

// MARK: - DeejAICoverArtView

/// A SwiftUI view that displays cover art for an `AbstractLibraryEntity`.
///
/// Uses Amperfy's cached-on-disk artwork (downloaded via `ArtworkDownloadManager`).
/// Shows an MCM gradient placeholder while loading / when no artwork is available.
/// Triggers artwork download if the entity has an artwork reference that isn't cached yet.
struct DeejAICoverArtView: View {

    /// The library entity to show artwork for (e.g. a Song, Album, Artist).
    let entity: AbstractLibraryEntity?

    /// Corner radius for the rendered image.
    let cornerRadius: CGFloat

    /// Placeholder gradient colors (MCM palette).
    /// Defaults to the album-tint gradient used elsewhere in DeejAI.
    let placeholderColors: [Color]

    /// Whether to trigger artwork download via Amperfy's download manager
    /// when the artwork isn't cached on disk yet.
    let triggersDownload: Bool

    // MARK: State

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    // MARK: Init

    /// Creates a cover art view for the given entity.
    /// - Parameters:
    ///   - entity: The library entity (song, album, etc.) whose artwork to display.
    ///   - cornerRadius: Corner radius for the image (default: 16).
    ///   - placeholderColors: Gradient colors for the placeholder (default: MCM album tint).
    ///   - triggersDownload: If true, triggers artwork download when not cached (default: true).
    init(
        entity: AbstractLibraryEntity?,
        cornerRadius: CGFloat = 16,
        placeholderColors: [Color] = [
            DeejAIColors.textSecondaryColor,
            DeejAIColors.accentPrimaryDarkColor,
            DeejAIColors.textPrimaryColor
        ],
        triggersDownload: Bool = true
    ) {
        self.entity = entity
        self.cornerRadius = cornerRadius
        self.placeholderColors = placeholderColors
        self.triggersDownload = triggersDownload
    }

    // MARK: Body

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
                        .font(.system(size: min(placeholderSize, 40), weight: .medium))
                        .foregroundStyle(DeejAIColors.surfaceColor.opacity(0.3))
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

        // 1. Try to get the cached image path from the artwork's local file
        let imagePath = entity.imagePath(
            setting: .preferServerArtwork
        )

        if let imagePath, let cachedImage = DeejAICoverArtCache.shared.image(forKey: imagePath) {
            // Fast path: already in our in-memory cache
            loadedImage = cachedImage
            isLoading = false
            return
        }

        if let imagePath {
            // 2. Try to load from disk (Amperfy already saved it here)
            if let diskImage = UIImage(contentsOfFile: imagePath) {
                // Decode for display on background thread
                let decoded = await diskImage.byPreparingForDisplay()
                if let decoded {
                    DeejAICoverArtCache.shared.setImage(decoded, forKey: imagePath)
                    loadedImage = decoded
                    isLoading = false
                    return
                }
            }
        }

        // 3. If we have an artwork reference but it's not cached on disk,
        //    trigger a download via Amperfy's infrastructure
        if triggersDownload, let artwork = entity.artwork,
           let accountInfo = entity.account?.info {
            let artworkId = artwork.id
            let meta = AmperKit.shared.getMeta(accountInfo)
            meta.artworkDownloadManager.download(object: artwork)
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

extension DeejAICoverArtView {

    /// Creates a cover art view sized for the Now Playing screen (large hero art).
    /// - Parameter entity: The currently playing track.
    static func nowPlaying(entity: AbstractPlayable?) -> DeejAICoverArtView {
        DeejAICoverArtView(
            entity: entity,
            cornerRadius: 16
        )
    }

    /// Creates a cover art view for a mini thumbnail (e.g. up-next, suggestion rows).
    /// - Parameter entity: The playable to show artwork for.
    static func thumbnail(entity: AbstractLibraryEntity?) -> DeejAICoverArtView {
        DeejAICoverArtView(
            entity: entity,
            cornerRadius: 6,
            placeholderColors: [
                DeejAIColors.accentSecondaryColor,
                DeejAIColors.accentSecondaryMutedColor
            ]
        )
    }

    /// Creates a cover art view for a medium card (e.g. alternative picks on Home).
    /// - Parameter entity: The entity to show artwork for.
    static func card(entity: AbstractLibraryEntity?) -> DeejAICoverArtView {
        DeejAICoverArtView(
            entity: entity,
            cornerRadius: 10
        )
    }

    /// Creates a cover art view for a mix card on the For You screen.
    /// - Parameter entity: The entity to show artwork for.
    static func mixCard(entity: AbstractLibraryEntity?) -> DeejAICoverArtView {
        DeejAICoverArtView(
            entity: entity,
            cornerRadius: 12
        )
    }
}
