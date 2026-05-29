//
//  DeejAISyncer.swift
//  AmperfyKit
//
//  Created by Hermes Agent.
//  Copyright (c) 2026 Aaron Hladky. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import os.log

// MARK: - DeejAISyncer

/// Reports play/skip events to the DeejAI recommendation engine.
/// Hooks into the same MusicPlayable notifications as ScrobbleSyncer.
@MainActor
public class DeejAISyncer {
  private let log = OSLog(subsystem: "Amperfy", category: "DeejAISyncer")
  private let player: PlayerFacade
  private let api: DeejAIApi

  // Track play state
  private var currentTrackStart: Date?
  private var currentTrackTitle: String = ""
  private var currentTrackArtist: String = ""
  private var currentTrackAlbum: String = ""
  private var currentTrackDuration: TimeInterval = 0
  private var isPlaying: Bool = false

  // Skip threshold — if played less than this fraction, count as skip
  private let skipThreshold: Double = 0.7

  public init(player: PlayerFacade, api: DeejAIApi) {
    self.player = player
    self.api = api
  }

  // MARK: - Private

  private func startTracking() {
    guard let playable = player.currentlyPlaying else { return }

    currentTrackTitle = playable.title
    currentTrackArtist = playable.creatorName
    currentTrackAlbum = playable.subsubtitle ?? ""
    currentTrackDuration = TimeInterval(playable.duration)
    currentTrackStart = Date()
    isPlaying = true

    os_log(
      "Started tracking: %s by %s (%ds)",
      log: log,
      type: .debug,
      currentTrackTitle,
      currentTrackArtist,
      playable.duration
    )
  }

  private func reportPlay(completed: Bool) {
    guard let startTime = currentTrackStart else { return }

    let msPlayed = Int(Date().timeIntervalSince(startTime) * 1000)

    // Don't report very short plays (< 3 seconds) — likely just skipping through
    guard msPlayed > 3000 else {
      os_log("Skipping report — played only %dms", log: log, type: .debug, msPlayed)
      clearTracking()
      return
    }

    let context = getContext()

    os_log(
      "Reporting to DeejAI: %s by %s — %dms, completed=%d, ctx=%s",
      log: log,
      type: .info,
      currentTrackTitle,
      currentTrackArtist,
      msPlayed,
      completed ? 1 : 0,
      context
    )

    let event = PlayedRequest(
      artist: currentTrackArtist,
      title: currentTrackTitle,
      album: currentTrackAlbum,
      msPlayed: msPlayed,
      completed: completed,
      context: context
    )

    Task {
      do {
        try await api.reportPlayed(event)
        os_log("DeejAI play event reported successfully", log: self.log, type: .debug)
      } catch {
        os_log(
          "DeejAI play report failed: %s",
          log: self.log,
          type: .error,
          error.localizedDescription
        )
      }
    }
  }

  private func clearTracking() {
    currentTrackStart = nil
    currentTrackTitle = ""
    currentTrackArtist = ""
    currentTrackAlbum = ""
    currentTrackDuration = 0
    isPlaying = false
  }

  /// Returns "gym" on weekday evenings (16:30-21:00 ET), "home" otherwise.
  /// Matches the logic in SpotifySkipTracker's plays-db-bridge.ts.
  private func getContext() -> String {
    let now = Date()
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "America/New_York")
    formatter.dateFormat = "EEE"
    let weekday = formatter.string(from: now)
    formatter.dateFormat = "HH"
    let hour = Int(formatter.string(from: now)) ?? 0
    formatter.dateFormat = "mm"
    let minute = Int(formatter.string(from: now)) ?? 0
    let timeDecimal = Double(hour) + Double(minute) / 60.0

    let isWeekday = ["Mon", "Tue", "Wed", "Thu", "Fri"].contains(weekday)
    if isWeekday && timeDecimal >= 16.5 && timeDecimal <= 21.0 {
      return "gym"
    }
    return "home"
  }
}

// MARK: - MusicPlayable

extension DeejAISyncer: MusicPlayable {
  public func didStartPlayingFromBeginning() {
    // New track — report the previous one as stopped (completed or skipped)
    if currentTrackStart != nil {
      // If we were tracking a previous track, determine if it was completed or skipped
      let elapsed = Date().timeIntervalSince(currentTrackStart ?? Date())
      let fraction = currentTrackDuration > 0 ? elapsed / currentTrackDuration : 0
      let completed = fraction >= skipThreshold
      reportPlay(completed: completed)
    }
    startTracking()
  }

  public func didStartPlaying() {
    if currentTrackStart == nil {
      // Resuming after app restart or something — start fresh tracking
      startTracking()
    } else {
      // Resuming from pause — just mark as playing again
      isPlaying = true
    }
  }

  public func didPause() {
    isPlaying = false
    // Don't report yet — might resume
  }

  public func didStopPlaying() {
    // Playback stopped entirely — report as skip (user stopped, not completed)
    if currentTrackStart != nil {
      reportPlay(completed: false)
    }
    clearTracking()
  }

  public func didElapsedTimeChange() {}
  public func didPlaylistChange() {}
  public func didArtworkChange() {}
  public func didShuffleChange() {}
  public func didRepeatChange() {}
  public func didPlaybackRateChange() {}
}
