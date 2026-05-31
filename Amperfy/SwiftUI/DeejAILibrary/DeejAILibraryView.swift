// DeejAILibraryView.swift
// DeejAI — Library screen (Mid-Century Modern)
//
// Replaces Amperfy's ~10-row server-browser taxonomy with a single
// segmented control (Artists / Albums / Songs) + sort/filter controls.
// Embeds the existing UIKit VCs via UIViewControllerRepresentable to
// preserve Core Data fetched results, detail navigation, search, and A-Z scrubber.
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).
// See LICENSE for details.

import AmperfyKit
import SwiftUI
import UIKit

// MARK: - Library Segment

/// The three browse types in the DeejAI library.
enum LibrarySegment: String, CaseIterable, Identifiable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"

    var id: String { rawValue }
}

// MARK: - Filter Chips

/// Filter chips available across all segments.
enum LibraryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case recentlyPlayed = "Recently Played"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease"
        case .favorites: return "heart.fill"
        case .recentlyPlayed: return "clock.arrow.circlepath"
        }
    }

    /// Map to AmperfyKit's ArtistCategoryFilter.
    var toArtistCategoryFilter: ArtistCategoryFilter {
        switch self {
        case .all: return .all
        case .favorites: return .favorites
        case .recentlyPlayed: return .all
        }
    }

    /// Map to AmperfyKit's DisplayCategoryFilter.
    var toDisplayCategoryFilter: DisplayCategoryFilter {
        switch self {
        case .all: return .all
        case .favorites: return .favorites
        case .recentlyPlayed: return .recent
        }
    }
}

// MARK: - Sort Options

/// Sort options that map to each segment's available sort types.
enum LibrarySortOption: String, CaseIterable {
    case name = "A-Z"
    case newest = "Date Added"
    case recent = "Recently Played"
    case rating = "Rating"

    var systemImage: String {
        switch self {
        case .name: return "textformat"
        case .newest: return "clock"
        case .recent: return "clock.arrow.circlepath"
        case .rating: return "star.fill"
        }
    }

    /// Convert to ArtistElementSortType.
    var toArtistSortType: ArtistElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .newest
        case .recent: return .name
        case .rating: return .rating
        }
    }

    /// Convert to AlbumElementSortType.
    var toAlbumSortType: AlbumElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .newest
        case .recent: return .recent
        case .rating: return .rating
        }
    }

    /// Convert to SongElementSortType.
    var toSongSortType: SongElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .addedDate
        case .recent: return .starredDate
        case .rating: return .rating
        }
    }
}


// MARK: - DeejAI Library View

struct DeejAILibraryView: View {

    let account: Account

    @State private var selectedSegment: LibrarySegment = .artists
    @State private var selectedSort: LibrarySortOption = .name
    @State private var selectedFilter: LibraryFilter = .all
    @Namespace private var namespace

    var body: some View {
        ZStack {
            // Background: solid MCM cream
            DeejAIColors.surfaceColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Segmented control
                segmentPicker
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // 2. Sort + filter bar
                controlBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // 3. Filter chips
                filterChips
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // 4. Content (embedded UIKit VC with built-in search + A-Z scrubber)
                contentView
            }
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(LibrarySegment.allCases) { segment in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(DeejAIFonts.serifHeadline)
                        .foregroundStyle(
                            selectedSegment == segment
                                ? DeejAIColors.accentPrimaryColor
                                : DeejAIColors.textTertiaryColor
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            VStack(spacing: 0) {
                                Spacer()
                                if selectedSegment == segment {
                                    Rectangle()
                                        .fill(DeejAIColors.accentPrimaryColor)
                                        .frame(height: 2)
                                        .matchedGeometryEffect(id: "segmentIndicator", in: namespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Rectangle()
                .fill(DeejAIColors.trackBackgroundColor.opacity(0.3))
                .frame(height: 1)
                .offset(y: 16),
            alignment: .bottom
        )
    }

    // MARK: - Sort + Filter Control Bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            // Current filter label
            Text(filterLabel)
                .font(DeejAIFonts.sansSubheadline)
                .foregroundStyle(DeejAIColors.textTertiaryColor)

            Spacer()

            // Sort menu
            Menu {
                ForEach(LibrarySortOption.allCases, id: \.self) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        Label(option.rawValue, systemImage: option.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedSort.systemImage)
                        .font(DeejAIFonts.sansCaption)

                    Text(selectedSort.rawValue)
                        .font(DeejAIFonts.sansCaption)
                }
                .foregroundStyle(DeejAIColors.accentSecondaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(DeejAIColors.accentSecondaryColor.opacity(0.10))
                )
            }
        }
    }

    private var filterLabel: String {
        let segment = selectedSegment.rawValue
        switch selectedFilter {
        case .all: return "All \(segment)"
        case .favorites: return "Favorite \(segment)"
        case .recentlyPlayed: return "Recent \(segment)"
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.systemImage)
                                .font(DeejAIFonts.sansCaption)

                            Text(filter.rawValue)
                                .font(DeejAIFonts.sansCaption)
                        }
                        .foregroundStyle(
                            selectedFilter == filter
                                ? DeejAIColors.surfaceColor
                                : DeejAIColors.textSecondaryColor
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    selectedFilter == filter
                                        ? DeejAIColors.accentPrimaryColor
                                        : DeejAIColors.surfaceElevatedColor
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Content View (Embedded UIKit VC)

    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .artists:
            ArtistsListContainer(
                account: account,
                filter: selectedFilter,
                sort: selectedSort
            )
            .ignoresSafeArea(edges: .bottom)

        case .albums:
            AlbumsListContainer(
                account: account,
                filter: selectedFilter,
                sort: selectedSort
            )
            .ignoresSafeArea(edges: .bottom)

        case .songs:
            SongsListContainer(
                account: account,
                filter: selectedFilter,
                sort: selectedSort
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - UIViewControllerRepresentable Wrappers

/// Wraps Amperfy's ArtistsVC — preserves Core Data fetched results,
/// detail navigation (tap → ArtistDetailVC), built-in search, and A-Z scrubber.
struct ArtistsListContainer: UIViewControllerRepresentable {
    let account: Account
    let filter: LibraryFilter
    let sort: LibrarySortOption

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = ArtistsVC(account: account)
        vc.displayFilter = filter.toArtistCategoryFilter
        vc.change(sortType: sort.toArtistSortType)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? ArtistsVC else { return }
        if vc.displayFilter != filter.toArtistCategoryFilter {
            vc.displayFilter = filter.toArtistCategoryFilter
            vc.change(sortType: vc.sortType)
        }
        if vc.sortType != sort.toArtistSortType {
            vc.change(sortType: sort.toArtistSortType)
        }
    }
}

/// Wraps Amperfy's AlbumsVC — preserves Core Data fetched results,
/// detail navigation (tap → AlbumDetailVC), built-in search, and A-Z scrubber.
struct AlbumsListContainer: UIViewControllerRepresentable {
    let account: Account
    let filter: LibraryFilter
    let sort: LibrarySortOption

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = AlbumsVC(account: account)
        vc.displayFilter = filter.toDisplayCategoryFilter
        vc.common.change(sortType: sort.toAlbumSortType)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? AlbumsVC else { return }
        if vc.displayFilter != filter.toDisplayCategoryFilter {
            vc.displayFilter = filter.toDisplayCategoryFilter
            vc.common.change(sortType: vc.common.sortType)
        }
        if vc.common.sortType != sort.toAlbumSortType {
            vc.common.change(sortType: sort.toAlbumSortType)
        }
    }
}

/// Wraps Amperfy's SongsVC — preserves Core Data fetched results,
/// built-in search, and A-Z scrubber.
struct SongsListContainer: UIViewControllerRepresentable {
    let account: Account
    let filter: LibraryFilter
    let sort: LibrarySortOption

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = SongsVC(account: account)
        vc.displayFilter = filter.toDisplayCategoryFilter
        vc.change(sortType: sort.toSongSortType)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? SongsVC else { return }
        if vc.displayFilter != filter.toDisplayCategoryFilter {
            vc.displayFilter = filter.toDisplayCategoryFilter
            vc.change(sortType: vc.sortType)
        }
        if vc.sortType != sort.toSongSortType {
            vc.change(sortType: sort.toSongSortType)
        }
    }
}
