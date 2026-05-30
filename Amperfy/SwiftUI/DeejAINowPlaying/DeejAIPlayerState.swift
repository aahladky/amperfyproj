//
//  DeejAIPlayerState.swift
//  Amperfy
//
//  Created by Hermes Agent.
//  Copyright (c) 2026 Aaron Hladky. All rights reserved.
//

import SwiftUI
import AmperfyKit
import Combine

/// Bridges the Amperfy PlayerFacade to SwiftUI.
/// Implements MusicPlayable to receive real-time updates from the audio engine.
@MainActor
class DeejAIPlayerState: NSObject, ObservableObject, MusicPlayable {
    
    @Published var currentTrackTitle: String = "Not Playing"
    @Published var currentArtistName: String = ""
    @Published var currentAlbumTitle: String = ""
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0
    @Published var elapsedText: String = "0:00"
    @Published var durationText: String = "0:00"
    @Published var nextTrackTitle: String = ""
    @Published var nextArtistName: String = ""
    @Published var isFavorite: Bool = false
    @Published var isRadioMode: Bool = false
    @Published var currentPlayable: AbstractPlayable?
    
    private let player: PlayerFacade
    private var timer: AnyCancellable?
    
    /// Optional closure for server-synced favorite toggle (set by the hosting view controller).
    /// When nil, `toggleFavorite()` falls back to local Core Data toggle only.
    var onToggleFavorite: (() async -> Void)?

    init(player: PlayerFacade) {
        self.player = player
        super.init()
        
        // Register as a notifier to get track changes, play/pause, etc.
        player.addNotifier(notifier: self)
        
        // Initialize radio mode from the player's current repeat mode
        isRadioMode = player.repeatMode == .all
        
        // Start a timer for smooth progress updates (since elapsedTime doesn't notify every second)
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isPlaying else { return }
                self.updateProgress()
            }
        
        refresh()
    }
    
    func refresh() {
        guard let playable = player.currentlyPlaying else {
            currentTrackTitle = "Not Playing"
            currentArtistName = ""
            currentAlbumTitle = ""
            isPlaying = false
            isFavorite = false
            return
        }
        
        currentPlayable = playable
        currentTrackTitle = playable.title
        currentArtistName = playable.creatorName
        currentAlbumTitle = playable.subsubtitle ?? ""
        isPlaying = player.isPlaying
        isFavorite = playable.isFavorite
        isRadioMode = player.repeatMode == .all
        updateProgress()
        
        // Peek at the next item in the queue
        if player.nextQueueCount > 0, let next = player.getNextQueueItems(from: 0, to: 1).first {
            nextTrackTitle = next.title
            nextArtistName = next.creatorName
        } else {
            nextTrackTitle = ""
            nextArtistName = ""
        }
    }
    
    /// Toggles favorite on the currently playing track.
    /// Uses the `onToggleFavorite` closure when available for server sync;
    /// otherwise toggles locally on Core Data directly.
    func toggleFavorite() {
        Task { @MainActor in
            if let onToggleFavorite = onToggleFavorite {
                await onToggleFavorite()
            } else {
                // Fallback: toggle locally on Core Data only
                guard let playable = player.currentlyPlaying, playable.isFavoritable else { return }
                playable.isFavorite.toggle()
            }
            // Refresh published state from the model
            isFavorite = player.currentlyPlaying?.isFavorite ?? false
        }
    }
    
    /// Toggles radio/infinity mode by setting repeat mode to .all (on) or .off (off).
    func toggleRadioMode() {
        let newMode: RepeatMode = isRadioMode ? .off : .all
        player.setRepeatMode(newMode)
        isRadioMode = player.repeatMode == .all
    }
    
    private func updateProgress() {
        let elapsed = player.elapsedTime
        let duration = player.duration
        
        self.progress = duration > 0 ? elapsed / duration : 0
        self.elapsedText = formatTime(elapsed)
        self.durationText = formatTime(duration)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        return String(format: "%d:%02d", min, sec)
    }
    
    // MARK: - MusicPlayable Implementation
    
    func didStartPlayingFromBeginning() { refresh() }
    func didStartPlaying() { isPlaying = true }
    func didPause() { isPlaying = false }
    func didStopPlaying() { refresh() }
    func didElapsedTimeChange() { updateProgress() }
    func didPlaylistChange() { refresh() }
    func didArtworkChange() { }
    func didShuffleChange() { }
    func didRepeatChange() {
        isRadioMode = player.repeatMode == .all
    }
    func didPlaybackRateChange() { }
}
