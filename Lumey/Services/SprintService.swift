//
//  SprintService.swift
//  Lumey
//

import Foundation

final class SprintService {
    static let shared = SprintService()
    private init() {}

    private let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !url.isEmpty else {
            return "https://appapi.voxiverse.ink"
        }
        return url
    }()

    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - HTTP helpers

    private func url(_ path: String, query: [String: String] = [:]) -> URL {
        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url!
    }

    private func get<R: Decodable>(_ path: String, query: [String: String] = [:], as _: R.Type) async throws -> R {
        let (data, _) = try await session.data(for: URLRequest(url: url(path, query: query)))
        return try decoder.decode(R.self, from: data)
    }

    private func post<B: Encodable, R: Decodable>(_ path: String, body: B, as _: R.Type) async throws -> R {
        var request = URLRequest(url: url(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(R.self, from: data)
    }

    // MARK: - Sprint

    func getActiveSprint() async throws -> Sprint? {
        let response = try await get("/api/sprint/active", as: SprintResponse.self)
        return response.sprint
    }

    func startSprint(body: StartSprintBody) async throws -> Sprint {
        let response = try await post("/api/sprint/start", body: body, as: SprintResponse.self)
        guard let sprint = response.sprint else { throw SprintServiceError.serverError }
        return sprint
    }

    func joinSprint(sprintId: String, body: JoinSprintBody) async throws -> Sprint {
        let response = try await post("/api/sprint/\(sprintId)/join", body: body, as: SprintResponse.self)
        guard let sprint = response.sprint else { throw SprintServiceError.serverError }
        return sprint
    }

    func submitEndPage(sprintId: String, body: SubmitEndPageBody) async throws -> Sprint {
        let response = try await post("/api/sprint/\(sprintId)/submit", body: body, as: SprintResponse.self)
        guard let sprint = response.sprint else { throw SprintServiceError.serverError }
        return sprint
    }

    // MARK: - Messages

    func getMessages(before: String? = nil) async throws -> [SprintMessage] {
        var query: [String: String] = [:]
        if let before { query["before"] = before }
        let response = try await get("/api/sprint/messages", query: query, as: SprintMessagesResponse.self)
        return (response.messages ?? []).reversed()
    }

    func sendMessage(body: SendSprintMessageBody) async throws -> SprintMessage {
        let response = try await post("/api/sprint/messages", body: body, as: SprintMessageResponse.self)
        guard let message = response.message else { throw SprintServiceError.serverError }
        return message
    }

    func clearMessages(userId: String) async throws {
        var request = URLRequest(url: url("/api/sprint/messages", query: ["userId": userId]))
        request.httpMethod = "DELETE"
        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(SprintSuccessResponse.self, from: data)
        if !response.success { throw SprintServiceError.serverError }
    }

    // MARK: - Leaderboard

    func getAllTimeLeaderboard() async throws -> [SprintLeaderboardEntry] {
        let response = try await get("/api/sprint/leaderboard", as: SprintLeaderboardResponse.self)
        return response.leaderboard ?? []
    }

    func getUserLeaderboardEntry(userId: String) async throws -> SprintLeaderboardEntry? {
        let response = try await get("/api/sprint/leaderboard/\(userId)", as: SprintLeaderboardEntryResponse.self)
        return response.entry
    }
}

enum SprintServiceError: Error {
    case serverError
}
