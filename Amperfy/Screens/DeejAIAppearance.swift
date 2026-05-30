//
//  DeejAIAppearance.swift
//  Amperfy
//
//  DeejAI — Token-driven UIKit appearance proxies.
//
//  All UIKit chrome (nav bars, tab bars, switches, sliders, window tint)
//  is styled from DeejAIColors semantic tokens. This file is the single
//  source of truth for appearance — call DeejAIAppearance.configure() once
//  at app launch.
//
//  Copyright © 2026 aahladky and contributors.
//  Licensed under the GNU General Public License v3.0 (GPLv3).
//  See LICENSE for details.
//

import UIKit

/// Configures UIKit appearance proxies with DeejAI semantic color tokens.
/// Ensures all UIKit chrome uses the MCM palette instead of system blue.
/// Must be called from AppDelegate.application(_:didFinishLaunchingWithOptions:).
enum DeejAIAppearance {

    static func configure() {
        configureNavigationBar()
        configureTabBar()
        configureControls()
    }

    // MARK: - UINavigationBar

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DeejAIColors.surface
        appearance.titleTextAttributes = [.foregroundColor: DeejAIColors.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: DeejAIColors.textPrimary]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = DeejAIColors.accentPrimary
    }

    // MARK: - UITabBar

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DeejAIColors.surface

        appearance.stackedLayoutAppearance.normal.iconColor = DeejAIColors.textTertiary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: DeejAIColors.textTertiary
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = DeejAIColors.accentPrimary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: DeejAIColors.accentPrimary
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Controls

    private static func configureControls() {
        // UISwitch
        UISwitch.appearance().onTintColor = DeejAIColors.accentPrimary
        UISwitch.appearance().thumbTintColor = DeejAIColors.surface

        // UISlider min/max track
        UISlider.appearance().minimumTrackTintColor = DeejAIColors.accentPrimary
        UISlider.appearance().maximumTrackTintColor = DeejAIColors.trackBackground

        // UITableView selection tint
        UITableView.appearance().tintColor = DeejAIColors.accentPrimary
        UITableViewCell.appearance().selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = DeejAIColors.accentSecondary.withAlphaComponent(0.12)
            return view
        }()

        // Search bar cursor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
            .tintColor = DeejAIColors.accentPrimary

        // Window-level global tint (applied when a window is available)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
           let window = windowScene.windows.first {
            window.tintColor = DeejAIColors.accentPrimary
        }
    }
}
