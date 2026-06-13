//
//  OpenDJModels.swift
//  AmperfyKit
//
//  Copyright (C) 2024 OpenDJ Contributors
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
// Note: snake_case mapping is handled by the explicit CodingKeys on each model.
// OpenDJApi's coder must NOT also set convert*SnakeCase, or the two conflict and decoding fails.

// MARK: - Track Info

/// A track recommendation from OpenDJ.
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

// MARK: - Rails (For You + Home)

/// The rails payload shared by `/api/foryou` (behavioral plane) and `/api/home`
/// (audio/embedding plane): a list of startable rails.
public struct ForYouResponse: Codable, Sendable {
    public let rails: [Rail]
}

/// A horizontal rail (e.g. "Your recent rotation", "Rediscover").
public struct Rail: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let items: [RailItem]
}

/// A startable tile in a rail: an album "mix" with a seed track for cover art + radio.
public struct RailItem: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let seedTrackId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle
        case seedTrackId = "seed_track_id"
    }
}
