// OpenDJNowPlayingView.swift
// OpenDJ — Now Playing screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - Now Playing View

struct OpenDJNowPlayingView: View {

    // MARK: State
    
    @ObservedObject var state: OpenDJPlayerState
    
    @State private var loveScale: CGFloat = 1.0
    
    // Player instance passed from parent
    let player: PlayerFacade

    // MARK: Body

    var body: some View {
        ZStack {
            // 1. Background: solid MCM cream
            OpenDJColors.surfaceColor
                .ignoresSafeArea()

            // 2. Warm tint bleed behind album art area
            backgroundGradient
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // 3. Context header
                        contextHeader
                            .padding(.top, 24)
                            .padding(.bottom, 20)

                        // 4. Album art
                        albumArt
                            .padding(.bottom, 24)

                        // 5. Track info
                        trackInfo
                            .padding(.bottom, 16)

                        // 6. Love heart — wired to real isFavorite
                        loveButton
                            .padding(.bottom, 24)

                        // 7. Progress bar
                        progressBar
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)

                        // 8. Playback controls
                        playbackControls
                            .padding(.bottom, 32)

                        // 9. Up next card
                        if !state.nextTrackTitle.isEmpty {
                            upNextCard
                                .padding(.horizontal, 24)
                                .padding(.bottom, 28)
                        }

                        // 10. Bottom: infinity + feel pill
                        bottomBar
                            .padding(.bottom, 40)
                        
                        // Spacer to ensure content pushes up
                        Spacer(minLength: 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Components

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: OpenDJColors.albumTintColor.opacity(0.45), location: 0.0),
                .init(color: OpenDJColors.albumTintColor.opacity(0.15), location: 0.4),
                .init(color: .clear, location: 1.0)
            ]),
            center: .init(x: 0.5, y: 0.28),
            startRadius: 40,
            endRadius: 500
        )
    }

    private var contextHeader: some View {
        Text(contextLabel)
            .font(OpenDJFonts.sansCaption)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(OpenDJColors.textTertiaryColor)
    }

    private var contextLabel: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let weekday = Calendar.current.weekdaySymbols[
            Calendar.current.component(.weekday, from: .now) - 1
        ]

        let timeOfDay: String
        switch hour {
        case 5..<8:   timeOfDay = "early morning"
        case 8..<12:  timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<20: timeOfDay = "evening"
        case 20..<23: timeOfDay = "winding down"
        default:      timeOfDay = "late night"
        }

        return "\(timeOfDay), \(weekday.lowercased())"
    }

    private var albumArt: some View {
        ZStack {
            // Approved spec shadow: black at 12% opacity, y-offset 4, blur 12
            OpenDJCoverArtView(
                entity: state.currentPlayable,
                cornerRadius: 20,
                placeholderColors: [
                    OpenDJColors.textSecondaryColor,
                    OpenDJColors.accentPrimaryDarkColor,
                    OpenDJColors.textPrimaryColor
                ]
            )
            .frame(width: 280, height: 280)
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
    }

    private var artPlaceholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                OpenDJColors.textSecondaryColor,
                OpenDJColors.accentPrimaryDarkColor,
                OpenDJColors.textPrimaryColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(state.currentTrackTitle)
                .font(OpenDJFonts.serifTitle)
                .foregroundStyle(OpenDJColors.textPrimaryColor)
                .lineLimit(1)

            Text(state.currentArtistName)
                .font(OpenDJFonts.sansBody)
                .foregroundStyle(OpenDJColors.textTertiaryColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 32)
    }

    private var loveButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                state.toggleFavorite()
                loveScale = 1.4
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15)) {
                loveScale = 1.0
            }
        } label: {
            Image(systemName: state.isFavorite ? "heart.fill" : "heart")
                .font(OpenDJFonts.serifTitle)
                .foregroundStyle(state.isFavorite ? OpenDJColors.accentPrimaryColor : OpenDJColors.textQuaternaryColor)
                .scaleEffect(loveScale)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OpenDJColors.trackBackgroundColor)
                        .frame(height: 4)

                    Capsule()
                        .fill(OpenDJColors.accentPrimaryColor)
                        .frame(width: geo.size.width * state.progress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(state.elapsedText)
                    .font(OpenDJFonts.monoTime)
                    .foregroundStyle(OpenDJColors.textQuaternaryColor)
                Spacer()
                Text(state.durationText)
                    .font(OpenDJFonts.monoTime)
                    .foregroundStyle(OpenDJColors.textQuaternaryColor)
            }
        }
    }

    private var playbackControls: some View {
        HStack(alignment: .center, spacing: 40) {
            Button { player.playPreviousOrReplay() } label: {
                Image(systemName: "backward.fill")
                    .font(OpenDJFonts.serifTitle)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Button { player.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(OpenDJColors.accentPrimaryColor)
                        .frame(width: 68, height: 68)

                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(OpenDJFonts.serifDisplay)
                        .foregroundStyle(OpenDJColors.surfaceColor)
                        .offset(x: state.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)

            Button { player.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(OpenDJFonts.serifTitle)
                    .foregroundStyle(OpenDJColors.textPrimaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var upNextCard: some View {
        Button {
            player.playNext()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("UP NEXT")
                    .font(OpenDJFonts.sansCaption)
                    .tracking(2.5)
                    .foregroundStyle(OpenDJColors.textTertiaryColor)

                HStack(spacing: 16) {
                    OpenDJCoverArtView(entity: state.nextPlayable, cornerRadius: 8)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.nextTrackTitle)
                            .font(OpenDJFonts.serifHeadline)
                            .foregroundStyle(OpenDJColors.textPrimaryColor)
                            .lineLimit(1)

                        Text(state.nextArtistName)
                            .font(OpenDJFonts.sansSubheadline)
                            .foregroundStyle(OpenDJColors.textTertiaryColor)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(OpenDJFonts.serifSubheadline)
                        .foregroundStyle(OpenDJColors.textQuaternaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(OpenDJColors.surfaceElevatedColor)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack(spacing: 20) {
            Button { state.toggleContinuation() } label: {
                Image(systemName: "infinity")
                    .font(OpenDJFonts.serifTitle)
                    .foregroundStyle(state.isRadioMode ? OpenDJColors.accentSecondaryColor : OpenDJColors.textQuaternaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text("feel · settled")
                .font(OpenDJFonts.sansSubheadline)
                .tracking(1)
                .foregroundStyle(OpenDJColors.accentSecondaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(OpenDJColors.accentSecondaryColor.opacity(0.10)))
                .overlay(Capsule().stroke(OpenDJColors.accentSecondaryColor.opacity(0.25), lineWidth: 1))
        }
    }
}
