// BuddyService.swift
// Lystaria

import Foundation

final class BuddyService {
    static let shared = BuddyService()
    private init() {}

    private let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !url.isEmpty else {
            return "https://vox-api-production-31fd.up.railway.app"
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
        let request = URLRequest(url: url(path, query: query))
        let (data, _) = try await session.data(for: request)
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

    private func patch<B: Encodable, R: Decodable>(_ path: String, body: B, as _: R.Type) async throws -> R {
        var request = URLRequest(url: url(path))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(R.self, from: data)
    }

    private func delete<R: Decodable>(_ path: String, query: [String: String] = [:], as _: R.Type) async throws -> R {
        var request = URLRequest(url: url(path, query: query))
        request.httpMethod = "DELETE"
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(R.self, from: data)
    }

    // MARK: - Announcements

    func postAnnouncement(body: PostAnnouncementBody) async throws -> BuddyAnnouncement {
        let response = try await post("/api/buddy/announcements", body: body, as: BuddyAnnouncementResponse.self)
        guard let announcement = response.announcement else { throw BuddyServiceError.serverError }
        return announcement
    }

    func getBoard(userId: String) async throws -> [BuddyAnnouncement] {
        let response = try await get("/api/buddy/announcements", query: ["userId": userId], as: BuddyAnnouncementsResponse.self)
        return response.announcements ?? []
    }

    func getMyAnnouncement(userId: String) async throws -> [BuddyAnnouncement] {
        let response = try await get("/api/buddy/announcements/mine", query: ["userId": userId], as: BuddyAnnouncementsResponse.self)
        return response.announcements ?? []
    }

    func removeAnnouncement(id: String, userId: String) async throws {
        _ = try await delete("/api/buddy/announcements/\(id)", query: ["userId": userId], as: BuddySuccessResponse.self)
    }

    func updateAnnouncement(id: String, body: UpdateAnnouncementBody) async throws -> BuddyAnnouncement {
        let response = try await patch("/api/buddy/announcements/\(id)", body: body, as: BuddyAnnouncementResponse.self)
        guard let announcement = response.announcement else { throw BuddyServiceError.serverError }
        return announcement
    }

    func archiveAnnouncement(id: String, ownerUserId: String) async throws -> BuddyAnnouncement {
        let body = OwnerAnnouncementActionBody(ownerUserId: ownerUserId)
        let response = try await post("/api/buddy/announcements/\(id)/archive", body: body, as: BuddyAnnouncementResponse.self)
        guard let announcement = response.announcement else { throw BuddyServiceError.serverError }
        return announcement
    }

    func closeAnnouncement(id: String, ownerUserId: String) async throws -> BuddyAnnouncement {
        let body = OwnerAnnouncementActionBody(ownerUserId: ownerUserId)
        let response = try await post("/api/buddy/announcements/\(id)/close", body: body, as: BuddyAnnouncementResponse.self)
        guard let announcement = response.announcement else { throw BuddyServiceError.serverError }
        return announcement
    }

    // MARK: - Groups

    func requestToJoin(body: RequestToJoinBody) async throws -> BuddyGroup {
        let response = try await post("/api/buddy/groups/request", body: body, as: BuddyGroupResponse.self)
        guard let group = response.group else { throw BuddyServiceError.serverError }
        return group
    }

    func respondToJoinRequest(groupId: String, body: RespondToJoinBody) async throws -> BuddyGroup {
        let response = try await post("/api/buddy/groups/\(groupId)/respond", body: body, as: BuddyGroupResponse.self)
        guard let group = response.group else { throw BuddyServiceError.serverError }
        return group
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        _ = try await post("/api/buddy/groups/\(groupId)/leave", body: LeaveGroupBody(userId: userId), as: BuddySuccessResponse.self)
    }

    func getMyGroups(userId: String) async throws -> [BuddyGroup] {
        let response = try await get("/api/buddy/groups/mine", query: ["userId": userId], as: BuddyGroupsResponse.self)
        return response.groups ?? []
    }

    func getGroup(groupId: String, userId: String) async throws -> BuddyGroup {
        let response = try await get("/api/buddy/groups/\(groupId)", query: ["userId": userId], as: BuddyGroupResponse.self)
        guard let group = response.group else { throw BuddyServiceError.serverError }
        return group
    }

    // MARK: - Messages

    func sendMessage(groupId: String, body: SendMessageBody) async throws -> BuddyMessage {
        let response = try await post("/api/buddy/groups/\(groupId)/messages", body: body, as: BuddyMessageResponse.self)
        guard let message = response.message else { throw BuddyServiceError.serverError }
        return message
    }

    func getMessages(groupId: String, userId: String, before: String? = nil) async throws -> [BuddyMessage] {
        var query: [String: String] = ["userId": userId]
        if let before { query["before"] = before }
        let response = try await get("/api/buddy/groups/\(groupId)/messages", query: query, as: BuddyMessagesResponse.self)
        return (response.messages ?? []).reversed()
    }

    func clearGroupMessages(groupId: String, userId: String) async throws {
        _ = try await delete("/api/buddy/groups/\(groupId)/messages", query: ["userId": userId], as: BuddySuccessResponse.self)
    }
}

enum BuddyServiceError: Error {
    case serverError
}
