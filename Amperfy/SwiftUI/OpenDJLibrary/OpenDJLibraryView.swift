// OpenDJLibraryView.swift
// OpenDJ — Library screen (Mid-Century Modern)
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

/// The three browse types in the OpenDJ library.
enum LibrarySegment: String, CaseIterable, Identifiable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"

    var id: String { rawValue }
}

// MARK: - Filter Chips

/// Simple filter chips for the Artists/Albums segments. (Songs uses the richer
/// metadata filter sheet instead.) "Recently Played" was removed — it was a no-op on
/// Artists and unsupported on Songs, and For You's "On heavy rotation" already covers it.
enum LibraryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease"
        case .favorites: return "heart.fill"
        }
    }

    /// Map to AmperfyKit's ArtistCategoryFilter.
    var toArtistCategoryFilter: ArtistCategoryFilter {
        switch self {
        case .all: return .all
        case .favorites: return .favorites
        }
    }

    /// Map to AmperfyKit's DisplayCategoryFilter.
    var toDisplayCategoryFilter: DisplayCategoryFilter {
        switch self {
        case .all: return .all
        case .favorites: return .favorites
        }
    }
}

// MARK: - Decade (Songs metadata filter)

/// Decade buckets for the Songs filter sheet. Each rawValue is the decade-start year,
/// matching year in [start, start+9] — the model SongMetadataFilter.decades expects.
enum LibraryDecade: Int, CaseIterable, Identifiable {
    case y2020 = 2020, y2010 = 2010, y2000 = 2000, y1990 = 1990
    case y1980 = 1980, y1970 = 1970, y1960 = 1960, y1950 = 1950

    var id: Int { rawValue }
    var label: String { "\(rawValue)s" }
}

// MARK: - Sort Options

/// Sort options that map to each segment's available sort types.
enum LibrarySortOption: String, CaseIterable {
    case name = "A-Z"
    case newest = "Date Added"
    case recent = "Recently Played"
    case rating = "Rating"
    case year = "Year"

    /// Sort options offered per segment (Year is Songs-only for now).
    static func options(for segment: LibrarySegment) -> [LibrarySortOption] {
        switch segment {
        case .songs: return [.name, .year, .newest, .rating]
        default:     return [.name, .newest, .rating]
        }
    }

    var systemImage: String {
        switch self {
        case .name: return "textformat"
        case .newest: return "clock"
        case .recent: return "clock.arrow.circlepath"
        case .rating: return "star.fill"
        case .year: return "calendar"
        }
    }

    /// Convert to ArtistElementSortType.
    var toArtistSortType: ArtistElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .newest
        case .recent: return .name
        case .rating: return .rating
        case .year: return .name
        }
    }

    /// Convert to AlbumElementSortType.
    var toAlbumSortType: AlbumElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .newest
        case .recent: return .recent
        case .rating: return .rating
        case .year: return .name
        }
    }

    /// Convert to SongElementSortType.
    var toSongSortType: SongElementSortType {
        switch self {
        case .name: return .name
        case .newest: return .addedDate
        case .recent: return .starredDate
        case .rating: return .rating
        case .year: return .year
        }
    }
}


// MARK: - OpenDJ Library View

struct OpenDJLibraryView: View {

    let account: Account

    @State private var selectedSegment: LibrarySegment = .artists
    @State private var selectedSort: LibrarySortOption = .name
    @State private var selectedFilter: LibraryFilter = .all
    // Songs-only metadata filter (genre / decade / rating / favorite), Plexamp-style.
    @State private var songFilter = SongMetadataFilter()
    @State private var songSortDescending = false
    @State private var showFilterSheet = false
    @State private var availableGenres: [String] = []
    @Namespace private var namespace

    var body: some View {
        ZStack {
            // Background: solid MCM cream
            OpenDJColors.surfaceColor
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
                    .padding(.top, 6)
                    .padding(.bottom, 8)

                // 3. Filter row — simple pills for Artists/Albums; for Songs, active
                //    metadata chips only when set (no empty "No filters" row taking space).
                if selectedSegment == .songs {
                    if songFilter.isActive {
                        songFilterChips
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
                } else {
                    filterChips
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }

                // 4. Content (embedded UIKit VC with built-in search + A-Z scrubber)
                contentView
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            SongFilterSheet(filter: $songFilter, availableGenres: availableGenres)
        }
        .task {
            availableGenres = AmperKit.shared.storage.main.library
                .getGenres(for: account)
                .compactMap { $0.name }
                .filter { !$0.isEmpty }
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
                    // Drop a sort option the new segment doesn't offer (e.g. Year on Artists).
                    if !LibrarySortOption.options(for: segment).contains(selectedSort) {
                        selectedSort = .name
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(OpenDJFonts.serifHeadline)
                        .foregroundStyle(
                            selectedSegment == segment
                                ? OpenDJColors.accentPrimaryColor
                                : OpenDJColors.textTertiaryColor
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            VStack(spacing: 0) {
                                Spacer()
                                if selectedSegment == segment {
                                    Rectangle()
                                        .fill(OpenDJColors.accentPrimaryColor)
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
                .fill(OpenDJColors.trackBackgroundColor.opacity(0.3))
                .frame(height: 1)
                .offset(y: 16),
            alignment: .bottom
        )
    }

    // MARK: - Sort + Filter Control Bar

    private var controlBar: some View {
        HStack(spacing: 8) {
            Spacer()

            // Filter button (Songs only) — opens the metadata sheet.
            if selectedSegment == .songs {
                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: songFilter.isActive
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                            .font(OpenDJFonts.sansCaption)
                        Text("Filter")
                            .font(OpenDJFonts.sansCaption)
                    }
                    .foregroundStyle(songFilter.isActive
                                     ? OpenDJColors.accentPrimaryColor
                                     : OpenDJColors.accentSecondaryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            (songFilter.isActive ? OpenDJColors.accentPrimaryColor
                                                 : OpenDJColors.accentSecondaryColor).opacity(0.10)
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            // Sort menu
            Menu {
                ForEach(LibrarySortOption.options(for: selectedSegment), id: \.self) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        Label(option.rawValue, systemImage: option.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedSort.systemImage)
                        .font(OpenDJFonts.sansCaption)

                    Text(selectedSort.rawValue)
                        .font(OpenDJFonts.sansCaption)
                }
                .foregroundStyle(OpenDJColors.accentSecondaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(OpenDJColors.accentSecondaryColor.opacity(0.10))
                )
            }

            // Ascending/descending toggle (Songs only).
            if selectedSegment == .songs {
                Button {
                    songSortDescending.toggle()
                } label: {
                    Image(systemName: songSortDescending ? "arrow.down" : "arrow.up")
                        .font(OpenDJFonts.sansCaption)
                        .foregroundStyle(OpenDJColors.accentSecondaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(OpenDJColors.accentSecondaryColor.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
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
                                .font(OpenDJFonts.sansCaption)

                            Text(filter.rawValue)
                                .font(OpenDJFonts.sansCaption)
                        }
                        .foregroundStyle(
                            selectedFilter == filter
                                ? OpenDJColors.surfaceColor
                                : OpenDJColors.textSecondaryColor
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    selectedFilter == filter
                                        ? OpenDJColors.accentPrimaryColor
                                        : OpenDJColors.surfaceElevatedColor
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Songs Active-Filter Chips

    @ViewBuilder
    private var songFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if songFilter.onlyFavorites {
                    removableChip("Favorites", icon: "heart.fill") { songFilter.onlyFavorites = false }
                }
                ForEach(songFilter.genres, id: \.self) { g in
                    removableChip(g, icon: "guitars") { songFilter.genres.removeAll { $0 == g } }
                }
                ForEach(songFilter.decades.sorted(by: >), id: \.self) { d in
                    removableChip("\(d)s", icon: "calendar") { songFilter.decades.removeAll { $0 == d } }
                }
                if songFilter.minRating > 0 {
                    removableChip("\(songFilter.minRating)★+", icon: "star.fill") { songFilter.minRating = 0 }
                }
            }
        }
    }

    private func removableChip(_ label: String, icon: String,
                               remove: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { remove() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(OpenDJFonts.sansCaption)
                Text(label).font(OpenDJFonts.sansCaption)
                Image(systemName: "xmark").font(OpenDJFonts.sansCaption)
            }
            .foregroundStyle(OpenDJColors.surfaceColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(OpenDJColors.accentPrimaryColor))
        }
        .buttonStyle(.plain)
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
                metadata: songFilter,
                sort: selectedSort,
                descending: songSortDescending
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Song Filter Sheet (Plexamp-style metadata facets)

struct SongFilterSheet: View {
    @Binding var filter: SongMetadataFilter
    let availableGenres: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Favorites only", isOn: $filter.onlyFavorites)
                }

                Section("Minimum rating") {
                    Picker("Minimum rating", selection: $filter.minRating) {
                        Text("Any").tag(0)
                        ForEach(1 ... 5, id: \.self) { Text("\($0)★").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Decade") {
                    ForEach(LibraryDecade.allCases) { decade in
                        toggleRow(decade.label, isOn: filter.decades.contains(decade.rawValue)) {
                            toggleMember(&filter.decades, decade.rawValue)
                        }
                    }
                }

                if !availableGenres.isEmpty {
                    Section("Genre") {
                        ForEach(availableGenres, id: \.self) { genre in
                            toggleRow(genre, isOn: filter.genres.contains(genre)) {
                                toggleMember(&filter.genres, genre)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { filter = SongMetadataFilter() }
                        .disabled(!filter.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggleRow(_ label: String, isOn: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(OpenDJColors.accentPrimaryColor)
                }
            }
        }
    }

    private func toggleMember<T: Equatable>(_ array: inout [T], _ value: T) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
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
        // The OpenDJ segmented control is the screen title — suppress the VC's own
        // large title so it doesn't leak under the directly-hidden bar and overlap
        // the Play/Shuffle header + first row.
        vc.navigationItem.largeTitleDisplayMode = .never
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? ArtistsVC else { return }
        let newFilter = filter.toArtistCategoryFilter
        let newSort = sort.toArtistSortType
        var changed = false
        if vc.sortType != newSort {
            vc.change(sortType: newSort)  // recreates the FRC with the new sort
            changed = true
        }
        if vc.displayFilter != newFilter {
            vc.displayFilter = newFilter
            changed = true
        }
        // updateSearchResults is the ONLY path that reads displayFilter and routes to
        // search/showAllResults. change(sortType:) ignores the filter, so without this
        // a filter change shows the wrong (unfiltered) set and a sort change silently
        // drops an active filter.
        if changed {
            vc.updateSearchResults(for: vc.searchController)
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
        // Suppress the VC's own large title (see ArtistsListContainer).
        vc.navigationItem.largeTitleDisplayMode = .never
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? AlbumsVC else { return }
        let newFilter = filter.toDisplayCategoryFilter
        let newSort = sort.toAlbumSortType
        var changed = false
        if vc.common.sortType != newSort {
            vc.common.change(sortType: newSort)
            changed = true
        }
        if vc.displayFilter != newFilter {
            vc.displayFilter = newFilter
            changed = true
        }
        if changed {
            vc.updateSearchResults(for: vc.searchController)
        }
    }
}

/// Wraps Amperfy's SongsVC — preserves Core Data fetched results,
/// built-in search, and A-Z scrubber.
struct SongsListContainer: UIViewControllerRepresentable {
    let account: Account
    let metadata: SongMetadataFilter
    let sort: LibrarySortOption
    let descending: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = SongsVC(account: account)
        vc.displayFilter = .all                 // favorites is folded into metadata
        vc.metadataFilter = metadata
        vc.sortDescending = descending
        vc.change(sortType: sort.toSongSortType)
        // Suppress the VC's own large title (see ArtistsListContainer).
        vc.navigationItem.largeTitleDisplayMode = .never
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? SongsVC else { return }
        let newSort = sort.toSongSortType
        var changed = false
        if vc.sortType != newSort || vc.sortDescending != descending {
            vc.sortDescending = descending
            vc.change(sortType: newSort)  // recreates the FRC (Songs path doesn't fetch here)
            changed = true
        }
        if vc.metadataFilter != metadata {
            vc.metadataFilter = metadata
            changed = true
        }
        // SongsVC.change(sortType:) never fetches, so updateSearchResults is what
        // populates the list and applies the metadata filter.
        if changed {
            vc.updateSearchResults(for: vc.searchController)
        }
    }
}
