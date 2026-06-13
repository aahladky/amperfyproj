//
//  OpenDJAppearance.swift
//  Amperfy
//
//  OpenDJ — Token-driven UIKit appearance proxies.
//
//  All UIKit chrome (nav bars, tab bars, switches, sliders, window tint)
//  is styled from OpenDJColors semantic tokens. This file is the single
//  source of truth for appearance — call OpenDJAppearance.configure() once
//  at app launch.
//
//  Copyright © 2026 aahladky and contributors.
//  Licensed under the GNU General Public License v3.0 (GPLv3).
//  See LICENSE for details.
//

import UIKit

/// Configures UIKit appearance proxies with OpenDJ semantic color tokens.
/// Ensures all UIKit chrome uses the MCM palette instead of system blue.
/// Must be called from AppDelegate.application(_:didFinishLaunchingWithOptions:).
enum OpenDJAppearance {

    static func configure() {
        configureNavigationBar()
        configureTabBar()
        configureControls()
    }

    // MARK: - UINavigationBar

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = OpenDJColors.surface
        appearance.titleTextAttributes = [.foregroundColor: OpenDJColors.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: OpenDJColors.textPrimary]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = OpenDJColors.accentPrimary
    }

    // MARK: - UITabBar

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = OpenDJColors.surface

        appearance.stackedLayoutAppearance.normal.iconColor = OpenDJColors.textTertiary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: OpenDJColors.textTertiary
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = OpenDJColors.accentPrimary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: OpenDJColors.accentPrimary
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Controls

    private static func configureControls() {
        // Window-level global tint (set early via appearance proxy for system-level controls)
        UIView.appearance().tintColor = OpenDJColors.accentPrimary

        // UISwitch
        UISwitch.appearance().onTintColor = OpenDJColors.accentSecondary
        UISwitch.appearance().thumbTintColor = OpenDJColors.surface

        // UISlider min/max track
        UISlider.appearance().minimumTrackTintColor = OpenDJColors.accentPrimary
        UISlider.appearance().maximumTrackTintColor = OpenDJColors.trackBackground

        // UITableView selection tint
        UITableView.appearance().tintColor = OpenDJColors.accentPrimary
        UITableViewCell.appearance().selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = OpenDJColors.accentSecondary.withAlphaComponent(0.12)
            return view
        }()

        // Section index (A–Z scrubber) — was system blue.
        UITableView.appearance().sectionIndexColor = OpenDJColors.accentPrimary
        UITableView.appearance().sectionIndexBackgroundColor = .clear

        // Content surfaces — cream, matching the themed nav/tab chrome (was system white).
        // SwiftUI OpenDJ screens set their own background, so this only affects the
        // inherited UIKit list/collection screens (Library, Search, detail views).
        UITableView.appearance().backgroundColor = OpenDJColors.surface
        UICollectionView.appearance().backgroundColor = OpenDJColors.surface

        // Search bar cursor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
            .tintColor = OpenDJColors.accentPrimary

        // Window-level global tint (applied when a window is available)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
           let window = windowScene.windows.first {
            window.tintColor = OpenDJColors.accentPrimary
        }
    }
}
