// DeejAINowPlayingView.swift
// DeejAI — Now Playing screen (Mid-Century Modern)
//
// Copyright © 2026 aahladky and contributors.
// Licensed under the GNU General Public License v3.0 (GPLv3).
// See LICENSE for details.
//
// The primary surface of DeejAI. Radio is the default verb —
// the user is already listening. This screen is where they land,
// not something they invoke.

import SwiftUI

// MARK: - Now Playing View

struct DeejAINowPlayingView: View {

    // MARK: State

    @State private var isPlaying = true
    @State private var isLoved = false
    @State private var progress: Double = 0.38
    @State private var loveScale: CGFloat = 1.0
    @State private var radioContinues = true

    // MARK: Placeholder data

    private let trackTitle = "Harvest Moon"
    private let artistName = "Neil Young"
    private let albumTitle = "Harvest Moon"
    private let duration = "5:03"
    private let elapsed = "1:55"

    private let nextTrackTitle = "Into the Mystic"
    private let nextArtistName = "Van Morrison"

    // MARK: Body

    var body: some View {
        ZStack {
            // Background: cream with warm tint bleed from album art
            backgroundGradient
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // 1. Context header
                    contextHeader
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    // 2. Album art
                    albumArt
                        .padding(.bottom, 24)

                    // 3. Track info
                    trackInfo
                        .padding(.bottom, 16)

                    // 4. Love heart
                    loveButton
                        .padding(.bottom, 24)

                    // 5. Progress bar
                    progressBar
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)

                    // 6. Playback controls
                    playbackControls
                        .padding(.bottom, 32)

                    // 7. Up next card
                    upNextCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    // 8. Bottom: infinity + feel pill
                    bottomBar
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            DeejAIColors.cream

            // Warm tint bleed from album art — radial, desaturated terracotta
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: DeejAIColors.albumTint.opacity(0.45), location: 0.0),
                    .init(color: DeejAIColors.albumTint.opacity(0.15), location: 0.4),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .init(x: 0.5, y: 0.28),
                startRadius: 40,
                endRadius: 500
            )
        }
    }

    // MARK: - 1. Context Header

    private var contextHeader: some View {
        Text(contextLabel)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(DeejAIColors.tan)
    }

    /// Time-of-day engine: derives a human context label from the current moment.
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

    // MARK: - 2. Album Art

    private var albumArt: some View {
        ZStack {
            // Warm shadow layer
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DeejAIColors.albumTint.opacity(0.3))
                .frame(width: 296, height: 296)
                .offset(x: 4, y: 6)
                .blur(radius: 12)

            // Placeholder album art — solid MCM color block
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(artPlaceholderGradient)
                .frame(width: 280, height: 280)
                .overlay(
                    // Simulated album art label
                    VStack(spacing: 8) {
                        Circle()
                            .fill(DeejAIColors.cream.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .fill(DeejAIColors.brownDark.opacity(0.15))
                                    .frame(width: 24, height: 24)
                            )
                        Text(albumTitle)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundStyle(DeejAIColors.cream.opacity(0.8))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    /// Placeholder gradient for album art — warm, Harvest-Moon inspired tones.
    private var artPlaceholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                DeejAIColors.brownMedium,
                DeejAIColors.terracottaDark,
                DeejAIColors.brownDark
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - 3. Track Info

    private var trackInfo: some View {
        VStack(spacing: 6) {
            Text(trackTitle)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(DeejAIColors.brownDark)

            Text(artistName)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(DeejAIColors.tan)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 4. Love Heart

    private var loveButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                isLoved.toggle()
                loveScale = 1.4
            }
            // Return to resting scale
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.15)) {
                loveScale = 1.0
            }
        } label: {
            Image(systemName: isLoved ? "heart.fill" : "heart")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isLoved ? DeejAIColors.terracotta : DeejAIColors.tanLight)
                .scaleEffect(loveScale)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLoved)
    }

    // MARK: - 5. Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(DeejAIColors.trackBackground)
                        .frame(height: 4)

                    // Progress fill — terracotta
                    Capsule()
                        .fill(DeejAIColors.terracotta)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
            .contentShape(Rectangle())
            .onTapGesture {
                // TODO: Wire up scrubbing to playback engine
            }

            // Time labels
            HStack {
                Text(elapsed)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeejAIColors.tanLight)
                Spacer()
                Text(duration)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeejAIColors.tanLight)
            }
        }
    }

    // MARK: - 6. Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Previous
            Button { } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(DeejAIColors.brownDark)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            // Play / Pause — large terracotta circle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPlaying.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(DeejAIColors.terracotta)
                        .frame(width: 68, height: 68)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DeejAIColors.cream)
                        .offset(x: isPlaying ? 0 : 2) // optical centering for play
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPlaying)

            // Next
            Button { } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(DeejAIColors.brownDark)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 7. Up Next Card

    private var upNextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            Text("UP NEXT · FLOWS ON")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(DeejAIColors.tan)

            HStack(spacing: 14) {
                // Small album art thumbnail
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DeejAIColors.teal,
                                DeejAIColors.tealMuted
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DeejAIColors.cream.opacity(0.2), lineWidth: 1)
                    )

                // Next track info
                VStack(alignment: .leading, spacing: 3) {
                    Text(nextTrackTitle)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(DeejAIColors.brownDark)
                        .lineLimit(1)

                    Text(nextArtistName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(DeejAIColors.tan)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DeejAIColors.tanLight)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeejAIColors.creamCard)
        )
    }

    // MARK: - 8. Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 20) {
            // Infinity symbol — radio toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    radioContinues.toggle()
                }
            } label: {
                Image(systemName: "infinity")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        radioContinues ? DeejAIColors.teal : DeejAIColors.tanLight
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            // "feel · settled" pill
            Text("feel · settled")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(DeejAIColors.teal)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(DeejAIColors.teal.opacity(0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(DeejAIColors.teal.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#Preview("Now Playing — Dark Evening") {
    DeejAINowPlayingView()
        .preferredColorScheme(.light)
}
