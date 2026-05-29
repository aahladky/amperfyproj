//
//  DeejAIApi.swift
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

// MARK: - DeejAIError

/// Errors produced by ``DeejAIApi``.
public enum DeejAIError: Error, LocalizedError, Sendable {
    /// The provided base URL is invalid.
    case invalidBaseURL
    /// The server returned an unexpected HTTP status code.
    case httpError(statusCode: Int, message: String?)
    /// The response body could not be decoded.
    case decodingError(Error)
    /// A network-level error occurred.
    case networkError(Error)
    /// The server response was missing expected data.
    case unexpectedResponse

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The DeejAI server URL is invalid."
        case .httpError(let code, let msg):
            return "HTTP \(code): \(msg ?? "Unknown error")"
        case .decodingError(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .unexpectedResponse:
            return "The server returned an unexpected response."
        }
    }
}

// MARK: - DeejAIApi

/// Lightweight async client for the DeejAI recommendation engine.
///
/// Uses `URLSession` with Swift concurrency (`async`/`await`) and
/// requires no third-party dependencies.
///
/// ```swift
/// let api = DeejAIApi(baseURL: URL(string: "https://music.myhouse.fyi")!,
///                      apiKey: "secret")
/// let health = try await api.healthCheck()
/// ```
public final class DeejAIApi: Sendable {

    // MARK: Properties

    /// Base URL of the DeejAI server (e.g. `https://music.myhouse.fyi`).
    private let baseURL: URL

    /// Bearer token for authentication.
    private let apiKey: String

    /// Shared URL session.
    private let session: URLSession

    /// JSON encoder used for request bodies.
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        return enc
    }()

    /// JSON decoder used for response bodies.
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return dec
    }()

    // MARK: Lifecycle

    /// Creates a new DeejAI API client.
    /// - Parameters:
    ///   - baseURL: Root URL of the DeejAI server.
    ///   - apiKey: Bearer token for authentication.
    ///   - session: URLSession to use (defaults to `.shared`).
    public init(baseURL: URL,
                apiKey: String,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Endpoints

    /// Checks server connectivity.
    ///
    /// `GET /api/health`
    /// - Returns: ``HealthResponse`` with status information.
    /// - Throws: ``DeejAIError`` on failure.
    public func healthCheck() async throws -> HealthResponse {
        try await get(path: "/api/health")
    }

    /// Requests seed-based track recommendations.
    ///
    /// `GET /api/recommend`
    /// - Parameters:
    ///   - artist: Seed artist name.
    ///   - title: Seed track title.
    ///   - n: Number of recommendations to return.
    ///   - epsilon: Exploration factor (0.0–1.0).
    /// - Returns: ``RecommendResponse`` containing recommended tracks.
    public func recommend(artist: String,
                          title: String,
                          n: Int = 10,
                          epsilon: Double = 0.2) async throws -> RecommendResponse {
        var params: [String: String] = [
            "artist": artist,
            "title": title,
            "n": String(n),
        ]
        params["epsilon"] = String(epsilon)
        return try await get(path: "/api/recommend", queryItems: params)
    }

    /// Starts a new DJ session.
    ///
    /// `POST /api/dj/start`
    /// - Parameters:
    ///   - hour: Current hour (0–23) for time-of-day awareness.
    ///   - seedArtist: Seed artist name.
    ///   - seedTitle: Seed track title.
    /// - Returns: ``DJSessionResponse`` with a session ID and first track.
    public func djStart(hour: Int,
                        seedArtist: String,
                        seedTitle: String) async throws -> DJSessionResponse {
        let body: [String: Any] = [
            "hour": hour,
            "seed_artist": seedArtist,
            "seed_title": seedTitle,
        ]
        return try await post(path: "/api/dj/start", body: body)
    }

    /// Requests the next track in an active DJ session.
    ///
    /// `POST /api/dj/next`
    /// - Parameters:
    ///   - sessionId: The session identifier from ``djStart(hour:seedArtist:seedTitle:)``.
    ///   - completed: Whether the previous track was played to completion.
    ///   - msPlayed: Milliseconds the previous track was played.
    /// - Returns: ``DJNextResponse`` with the next track.
    public func djNext(sessionId: String,
                       completed: Bool,
                       msPlayed: Int) async throws -> DJNextResponse {
        let body: [String: Any] = [
            "session_id": sessionId,
            "completed": completed,
            "ms_played": msPlayed,
        ]
        return try await post(path: "/api/dj/next", body: body)
    }

    /// Reports a play or skip event to the server.
    ///
    /// `POST /api/played`
    /// - Parameter request: A ``PlayedRequest`` describing the event.
    /// - Throws: ``DeejAIError`` on failure.
    public func reportPlayed(_ request: PlayedRequest) async throws {
        let _: EmptyResponse = try await post(path: "/api/played", encodable: request)
    }

    /// Fetches the home-screen payload.
    ///
    /// `GET /api/home`
    /// - Returns: ``HomeResponse`` with top artists, suggestions, and recent plays.
    public func home() async throws -> HomeResponse {
        try await get(path: "/api/home")
    }

    // MARK: - Private Helpers

    /// Builds an authenticated URL request for the given path and method.
    private func makeRequest(path: String,
                             method: String,
                             queryItems: [String: String]? = nil) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else {
            throw DeejAIError.invalidBaseURL
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw DeejAIError.invalidBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    /// Performs a GET request and decodes the response.
    private func get<T: Decodable>(path: String,
                                   queryItems: [String: String]? = nil) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", queryItems: queryItems)
        return try await perform(request)
    }

    /// Performs a POST request with a JSON-encodable body and decodes the response.
    private func post<T: Decodable, B: Encodable>(path: String,
                                                   encodable body: B) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    /// Performs a POST request with a dictionary body and decodes the response.
    private func post<T: Decodable>(path: String,
                                    body: [String: Any]) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    /// Sends the request, validates the HTTP status, and decodes the response.
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DeejAIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw DeejAIError.unexpectedResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw DeejAIError.httpError(statusCode: http.statusCode, message: message)
        }

        // Handle empty responses (e.g. POST /api/played returns 204).
        if T.self == EmptyResponse.self, (data.isEmpty || http.statusCode == 204) {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DeejAIError.decodingError(error)
        }
    }
}

// MARK: - EmptyResponse

/// Sentinel type for endpoints that return no body.
private struct EmptyResponse: Decodable, Sendable {}
