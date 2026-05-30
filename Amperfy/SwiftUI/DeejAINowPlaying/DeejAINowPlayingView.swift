// DeejAINowPlayingView.swift
// DeejAI — Now Playing screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).

import SwiftUI
import AmperfyKit

// MARK: - Now Playing View

struct DeejAINowPlayingView: View {

    // MARK: State
    
    @ObservedObject var state: DeejAIPlayerState
    
    @State private var loveScale: CGFloat = 1.0
    
    // Player instance passed from parent
    let player: PlayerFacade

    // MARK: Body

    var body: some View {
        ZStack {
            // 1. Background: solid MCM cream
            DeejAIColors.surfaceColor
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
                .init(color: DeejAIColors.albumTintColor.opacity(0.45), location: 0.0),
                .init(color: DeejAIColors.albumTintColor.opacity(0.15), location: 0.4),
                .init(color: .clear, location: 1.0)
            ]),
            center: .init(x: 0.5, y: 0.28),
            startRadius: 40,
            endRadius: 500
        )
    }

    private var contextHeader: some View {
        Text(contextLabel)
            .font(DeejAIFonts.sansCaption)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(DeejAIColors.textTertiaryColor)
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
            // Warm shadow layer
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DeejAIColors.albumTintColor.opacity(0.3))
                .frame(width: 296, height: 296)
                .offset(x: 4, y: 6)
                .blur(radius: 12)

            // Real cover art from Amperfy's cached artwork, or placeholder gradient
            DeejAICoverArtView(
                entity: state.currentPlayable,
                cornerRadius: 20,
                placeholderColors: [
                    DeejAIColors.textSecondaryColor,
                    DeejAIColors.accentPrimaryDarkColor,
                    DeejAIColors.textPrimaryColor
                ]
            )
            .frame(width: 280, height: 280)
        }
    }

    private var artPlaceholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                DeejAIColors.textSecondaryColor,
                DeejAIColors.accentPrimaryDarkColor,
                DeejAIColors.textPrimaryColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(state.currentTrackTitle)
                .font(DeejAIFonts.serifTitle)
                .foregroundStyle(DeejAIColors.textPrimaryColor)
                .lineLimit(1)

            Text(state.currentArtistName)
                .font(DeejAIFonts.sansBody)
                .foregroundStyle(DeejAIColors.textTertiaryColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 32)
    }

    private var loveButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                state.toggleFavorite()
                loveScale = 1.4
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.15)) {
                loveScale = 1.0
            }
        } label: {
            Image(systemName: state.isFavorite ? "heart.fill" : "heart")
                .font(DeejAIFonts.serifTitle)
                .foregroundStyle(state.isFavorite ? DeejAIColors.accentPrimaryColor : DeejAIColors.textQuaternaryColor)
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
                        .fill(DeejAIColors.trackBackgroundColor)
                        .frame(height: 4)

                    Capsule()
                        .fill(DeejAIColors.accentPrimaryColor)
                        .frame(width: geo.size.width * state.progress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(state.elapsedText)
                    .font(DeejAIFonts.monoTime)
                    .foregroundStyle(DeejAIColors.textQuaternaryColor)
                Spacer()
                Text(state.durationText)
                    .font(DeejAIFonts.monoTime)
                    .foregroundStyle(DeejAIColors.textQuaternaryColor)
            }
        }
    }

    private var playbackControls: some View {
        HStack(alignment: .center, spacing: 40) {
            Button { player.playPreviousOrReplay() } label: {
                Image(systemName: "backward.fill")
                    .font(DeejAIFonts.serifTitle)
                    .foregroundStyle(DeejAIColors.textPrimaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Button { player.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(DeejAIColors.accentPrimaryColor)
                        .frame(width: 68, height: 68)

                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(DeejAIFonts.serifDisplay)
                        .foregroundStyle(DeejAIColors.surfaceColor)
                        .offset(x: state.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)

            Button { player.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(DeejAIFonts.serifTitle)
                    .foregroundStyle(DeejAIColors.textPrimaryColor)
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
                    .font(DeejAIFonts.sansCaption)
                    .tracking(2.5)
                    .foregroundStyle(DeejAIColors.textTertiaryColor)

                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DeejAIColors.accentSecondaryColor)
                        .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.nextTrackTitle)
                            .font(DeejAIFonts.serifHeadline)
                            .foregroundStyle(DeejAIColors.textPrimaryColor)
                            .lineLimit(1)

                        Text(state.nextArtistName)
                            .font(DeejAIFonts.sansSubheadline)
                            .foregroundStyle(DeejAIColors.textTertiaryColor)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(DeejAIFonts.serifSubheadline)
                        .foregroundStyle(DeejAIColors.textQuaternaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DeejAIColors.surfaceElevatedColor)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack(spacing: 20) {
            Button { state.toggleRadioMode() } label: {
                Image(systemName: "infinity")
                    .font(DeejAIFonts.serifTitle)
                    .foregroundStyle(state.isRadioMode ? DeejAIColors.accentSecondaryColor : DeejAIColors.textQuaternaryColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text("feel · settled")
                .font(DeejAIFonts.sansSubheadline)
                .tracking(1)
                .foregroundStyle(DeejAIColors.accentSecondaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(DeejAIColors.accentSecondaryColor.opacity(0.10)))
                .overlay(Capsule().stroke(DeejAIColors.accentSecondaryColor.opacity(0.25), lineWidth: 1))
        }
    }
}
