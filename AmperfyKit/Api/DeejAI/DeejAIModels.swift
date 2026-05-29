//
//  DeejAIModels.swift
//  AmperfyKit
//
//  Copyright (C) 2024 DeejAI Contributors
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

// MARK: - Track Info

/// A track recommendation from DeejAI.
public struct TrackInfo: Codable, Sendable {
    /// Artist name.
    public let artist: String
    /// Track title.
    public let title: String
    /// Album name (optional).
    public let album: String?
    /// Relative path to the audio file on the server.
    public let relativePath: String?
    /// Relevance score (0.0–1.0).
    public let score: Double?

    enum CodingKeys: String, CodingKey {
        case artist, title, album, score
        case relativePath = "relative_path"
    }
}

// MARK: - Health Response

/// Response from the health-check endpoint.
public struct HealthResponse: Codable, Sendable {
    /// Server status, typically `"ok"`.
    public let status: String
}

// MARK: - Recommend Response

/// Response from the seed-based recommendation endpoint.
public struct RecommendResponse: Codable, Sendable {
    /// List of recommended tracks.
    public let tracks: [TrackInfo]
}

// MARK: - DJ Session Response

/// Response when starting a DJ session.
public struct DJSessionResponse: Codable, Sendable {
    /// Unique identifier for the DJ session.
    public let sessionId: String
    /// The first track to play.
    public let track: TrackInfo

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case track
    }
}

// MARK: - DJ Next Response

/// Response when requesting the next track in a DJ session.
public struct DJNextResponse: Codable, Sendable {
    /// The next track to play.
    public let track: TrackInfo
}

// MARK: - Played Request

/// Payload for reporting a play or skip event.
public struct PlayedRequest: Codable, Sendable {
    /// Artist name.
    public let artist: String
    /// Track title.
    public let title: String
    /// Album name (optional).
    public let album: String?
    /// Milliseconds the track was played.
    public let msPlayed: Int
    /// Whether the track was played to completion.
    public let completed: Bool
    /// Context string (e.g. `"dj"`, `"recommend"`, `"library"`).
    public let context: String?

    enum CodingKeys: String, CodingKey {
        case artist, title, album, completed, context
        case msPlayed = "ms_played"
    }
}

// MARK: - Home Response

/// Payload for the home screen.
public struct HomeResponse: Codable, Sendable {
    /// User's top artists.
    public let topArtists: [TopArtist]
    /// Suggested tracks.
    public let suggested: [SuggestedTrack]
    /// Recently played tracks.
    public let recent: [RecentPlay]

    enum CodingKeys: String, CodingKey {
        case topArtists = "top_artists"
        case suggested, recent
    }
}

/// An artist ranked by play count.
public struct TopArtist: Codable, Sendable {
    /// Artist name.
    public let artist: String
    /// Number of plays.
    public let playCount: Int

    enum CodingKeys: String, CodingKey {
        case artist
        case playCount = "play_count"
    }
}

/// A suggested track for the home screen.
public struct SuggestedTrack: Codable, Sendable {
    /// Track information.
    public let artist: String
    public let title: String
    public let album: String?
    public let score: Double?
}

/// A recently played track.
public struct RecentPlay: Codable, Sendable {
    /// Artist name.
    public let artist: String
    /// Track title.
    public let title: String
    /// Album name (optional).
    public let album: String?
    /// ISO 8601 timestamp of when the track was played.
    public let playedAt: String?

    enum CodingKeys: String, CodingKey {
        case artist, title, album
        case playedAt = "played_at"
    }
}
