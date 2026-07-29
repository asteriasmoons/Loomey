//
//  ChallengeSocialService.swift
//  Lumey
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Challenge Social Service

final class ChallengeSocialService {

    static let shared = ChallengeSocialService()

    private let baseURL: String

    init(baseURL: String = "https://appapi.voxiverse.ink") {
        self.baseURL = baseURL
    }

    // MARK: - Feed

    func fetchFeed() async throws -> ChallengeFeedResponseDTO {
        let url = try makeURL("/api/lumey/challenges/feed")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔥 RAW FEED RESPONSE:")
        print(String(data: data, encoding: .utf8) ?? "Could not decode feed data")

        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeFeedResponseDTO.self, from: data)
    }

    // MARK: - Submissions

    func createSubmission(_ submission: ChallengeSubmissionDTO) async throws -> ChallengeSubmissionDTO {
        let url = try makeURL("/api/lumey/challenges/submissions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(submission)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeSubmissionDTO.self, from: data)
    }

    func approveSubmission(
        submissionID: String,
        validationMessage: String? = nil,
        challengeTitle: String? = nil
    ) async throws -> ChallengeApprovedSubmissionResponseDTO {
        let url = try makeURL("/api/lumey/challenges/submissions/\(submissionID)/approve")

        let body = ChallengeApproveSubmissionRequestDTO(
            validationMessage: validationMessage,
            challengeTitle: challengeTitle
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(
            ChallengeApprovedSubmissionResponseDTO.self,
            from: data
        )
    }

    // MARK: - User Feed Posts

    func createFeedPost(
        userID: String,
        username: String,
        text: String,
        photoURL: String? = nil,
        photoBase64: String? = nil,
        photoCaption: String? = nil,
        linkedBookID: String? = nil,
        linkedChallengeID: String? = nil,
        mood: String? = nil,
        containsSpoilers: Bool = false,
        visibility: String = "public"
    ) async throws -> ChallengeFeedItemDTO {
        let url = try makeURL("/api/lumey/challenges/feed/posts")

        let body = ChallengeCreateFeedPostRequestDTO(
            userID: userID,
            username: username,
            text: text,
            photoURL: photoURL,
            photoBase64: photoBase64,
            photoCaption: photoCaption,
            linkedBookID: linkedBookID,
            linkedChallengeID: linkedChallengeID,
            mood: mood,
            containsSpoilers: containsSpoilers,
            visibility: visibility
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeFeedItemDTO.self, from: data)
    }
    
    func deleteFeedPost(postID: String) async throws {
        let url = try makeURL("/api/lumey/challenges/feed/posts/\(postID)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }
    
    func uploadProfileAvatar(imageData: Data) async throws -> String {
        let url = try makeURL("/api/lumey/challenges/profiles/upload-avatar")

        guard let uiImage = UIImage(data: imageData),
              let compressed = uiImage.jpegData(compressionQuality: 0.7) else {
            throw ChallengeSocialServiceError.invalidResponse
        }

        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(compressed)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder.challengeDecoder.decode(
            ChallengeUploadProfileAvatarResponseDTO.self,
            from: data
        )

        return decoded.avatarURL
    }
    
    func uploadFeedPhoto(imageData: Data) async throws -> String {
        let url = try makeURL("/api/lumey/challenges/feed/upload-photo")

        guard let uiImage = UIImage(data: imageData),
              let compressed = uiImage.jpegData(compressionQuality: 0.7) else {
            throw ChallengeSocialServiceError.invalidResponse
        }

        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(compressed)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder.challengeDecoder.decode(
            ChallengeUploadFeedPhotoResponseDTO.self,
            from: data
        )

        return decoded.photoURL
    }

    // MARK: - Feed Item Likes

    func toggleFeedItemLike(
        feedItemID: String,
        userID: String
    ) async throws -> ChallengeLikeToggleResponseDTO {
        let url = try makeURL("/api/lumey/challenges/feed/items/\(feedItemID)/like")

        let body = ChallengeLikeToggleRequestDTO(userID: userID)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(
            ChallengeLikeToggleResponseDTO.self,
            from: data
        )
    }

    // MARK: - Feed Item Comments

    func addFeedItemComment(
        feedItemID: String,
        userID: String,
        username: String,
        avatarName: String? = nil,
        avatarURL: String? = nil,
        text: String,
        parentCommentID: String? = nil
    ) async throws -> ChallengeCommentDTO {
        let url = try makeURL("/api/lumey/challenges/feed/items/\(feedItemID)/comments")

        let body = ChallengeAddFeedItemCommentRequestDTO(
            userID: userID,
            username: username,
            avatarName: avatarName,
            avatarURL: avatarURL,
            text: text,
            parentCommentID: parentCommentID
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeCommentDTO.self, from: data)
    }

    func deleteComment(commentID: String) async throws {
        let url = try makeURL("/api/lumey/challenges/comments/\(commentID)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    func toggleCommentLike(
        commentID: String,
        userID: String
    ) async throws -> ChallengeLikeToggleResponseDTO {
        let url = try makeURL("/api/lumey/challenges/comments/\(commentID)/like")

        let body = ChallengeLikeToggleRequestDTO(userID: userID)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(
            ChallengeLikeToggleResponseDTO.self,
            from: data
        )
    }

    // MARK: - Profiles

    func fetchProfile(userID: String) async throws -> ChallengeUserProfileDTO {
        let url = try makeURL("/api/lumey/challenges/profiles/\(userID)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeUserProfileDTO.self, from: data)
    }

    func updateProfile(
        userID: String,
        username: String,
        avatarName: String?,
        avatarURL: String?,
        bio: String?,
        favoriteGenre: String?,
        readingStreak: Int? = nil,
        challengePoints: Int? = nil,
        challengesCompleted: Int? = nil,
        followersCount: Int? = nil,
        followingCount: Int? = nil
    ) async throws -> ChallengeUserProfileDTO {
        let url = try makeURL("/api/lumey/challenges/profiles/\(userID)")

        let body = ChallengeUpdateProfileRequestDTO(
            username: username,
            avatarName: avatarName,
            avatarURL: avatarURL,
            bio: bio,
            favoriteGenre: favoriteGenre,
            readingStreak: readingStreak,
            challengePoints: challengePoints,
            challengesCompleted: challengesCompleted,
            followersCount: followersCount,
            followingCount: followingCount
        )

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeUserProfileDTO.self, from: data)
    }

    // MARK: - Announcements

    func createAnnouncement(
        title: String,
        body: String,
        userID: String,
        username: String,
        avatarURL: String? = nil,
        avatarName: String? = nil
    ) async throws -> ChallengeFeedAnnouncementDTO {
        let url = try makeURL("/api/lumey/challenges/feed/announcements")

        let requestBody = ChallengeCreateAnnouncementRequestDTO(
            title: title,
            body: body,
            userID: userID,
            username: username,
            avatarURL: avatarURL,
            avatarName: avatarName
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ChallengeFeedAnnouncementDTO.self, from: data)
    }
    
    func deleteAnnouncement(announcementID: String) async throws {
        let url = try makeURL("/api/lumey/challenges/feed/announcements/\(announcementID)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    // MARK: - Messaging

    func fetchConversations(userID: String) async throws -> [ConversationDTO] {
        let url = try makeURL("/api/lumey/messages/conversations?userID=\(userID)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode([ConversationDTO].self, from: data)
    }

    func createConversation(
        senderUserID: String,
        senderUsername: String,
        recipientUserID: String,
        recipientUsername: String
    ) async throws -> ConversationDTO {
        let url = try makeURL("/api/lumey/messages/conversations")

        let requestBody = CreateConversationRequestDTO(
            senderUserID: senderUserID,
            senderUsername: senderUsername,
            recipientUserID: recipientUserID,
            recipientUsername: recipientUsername
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(ConversationDTO.self, from: data)
    }

    func fetchMessages(conversationID: String, userID: String) async throws -> [DirectMessageDTO] {
        let url = try makeURL("/api/lumey/messages/conversations/\(conversationID)/messages?userID=\(userID)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode([DirectMessageDTO].self, from: data)
    }

    func sendMessage(
        conversationID: String,
        senderUserID: String,
        senderUsername: String,
        text: String
    ) async throws -> DirectMessageDTO {
        let url = try makeURL("/api/lumey/messages/conversations/\(conversationID)/messages")

        let requestBody = SendMessageRequestDTO(
            senderUserID: senderUserID,
            senderUsername: senderUsername,
            text: text
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode(DirectMessageDTO.self, from: data)
    }

    func markMessagesRead(conversationID: String, userID: String) async throws {
        let url = try makeURL("/api/lumey/messages/conversations/\(conversationID)/read")

        let requestBody = MarkReadRequestDTO(userID: userID)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.challengeEncoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    func fetchMessageableUsers(userID: String) async throws -> [MessageableUserDTO] {
        let url = try makeURL("/api/lumey/messages/messageable-users?userID=\(userID)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder.challengeDecoder.decode([MessageableUserDTO].self, from: data)
    }

    // MARK: - Helpers

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw ChallengeSocialServiceError.invalidURL
        }

        return url
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeSocialServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error."
            throw ChallengeSocialServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }
    }
}

// MARK: - Feed DTOs

struct ChallengeFeedResponseDTO: Codable {
    var feedItems: [ChallengeFeedItemDTO]
    var submissions: [ChallengeSubmissionDTO]
    var posts: [ChallengeFeedPostDTO]
    var comments: [ChallengeCommentDTO]
    var likes: [ChallengeLikeDTO]
    var commentLikes: [ChallengeCommentLikeDTO]
    var profiles: [ChallengeUserProfileDTO]
    var announcements: [ChallengeFeedAnnouncementDTO]?
}

struct ChallengeFeedItemDTO: Codable, Identifiable {
    let id: String?
    let feedType: String

    let submissionID: String?
    let postID: String?

    let userID: String
    let username: String

    let challengeID: String?
    let challengeTitle: String?
    var cycleID: String? = nil
    var cycleStartDate: Date? = nil
    var cycleEndDate: Date? = nil

    let text: String
    let photoURL: String?
    let photoBase64: String?

    let likeCount: Int
    let commentCount: Int

    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case feedType
        case submissionID
        case postID
        case userID
        case username
        case challengeID
        case challengeTitle
        case cycleID
        case cycleStartDate
        case cycleEndDate
        case text
        case photoURL
        case photoBase64
        case likeCount
        case commentCount
        case createdDate
    }
}

struct ChallengeFeedPostDTO: Codable, Identifiable {
    let id: String?
    let userID: String
    let username: String
    let text: String
    let photoURL: String?
    let photoBase64: String?
    let photoCaption: String?
    let linkedBookID: String?
    let linkedChallengeID: String?
    let mood: String?
    let containsSpoilers: Bool
    let visibility: String
    let createdDate: Date?
    let editedDate: Date?
    let isEdited: Bool
    let isDeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID
        case username
        case text
        case photoURL
        case photoBase64
        case photoCaption
        case linkedBookID
        case linkedChallengeID
        case mood
        case containsSpoilers
        case visibility
        case createdDate
        case editedDate
        case isEdited
        case isDeleted
    }
}

// MARK: - Submission DTOs

struct ChallengeSubmissionDTO: Codable, Identifiable {
    let id: String?
    let challengeID: String
    let entryID: String?
    let userID: String
    let username: String

    let linkedBookIDs: [String]
    let linkedSessionIDs: [String]
    let linkedReviewIDs: [String]
    let linkedReadingListIDs: [String]

    let submissionNote: String
    let proofSummary: String

    let validationStatus: String
    let validationMessage: String?

    let submittedDate: Date?
    let approvedDate: Date?
    var cycleID: String? = nil
    var cycleStartDate: Date? = nil
    var cycleEndDate: Date? = nil

    let postedToFeed: Bool?
    let feedItemID: String?

    let likeCount: Int
    let commentCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case challengeID
        case entryID
        case userID
        case username
        case linkedBookIDs
        case linkedSessionIDs
        case linkedReviewIDs
        case linkedReadingListIDs
        case submissionNote
        case proofSummary
        case validationStatus
        case validationMessage
        case submittedDate
        case approvedDate
        case cycleID
        case cycleStartDate
        case cycleEndDate
        case postedToFeed
        case feedItemID
        case likeCount
        case commentCount
    }
}

struct ChallengeApprovedSubmissionResponseDTO: Codable {
    let submission: ChallengeSubmissionDTO
    let feedItem: ChallengeFeedItemDTO?
}

struct ChallengeApproveSubmissionRequestDTO: Codable {
    let validationMessage: String?
    let challengeTitle: String?
}

// MARK: - Comment / Like DTOs

struct ChallengeCommentDTO: Codable, Identifiable {
    let id: String?
    let feedItemID: String
    let parentCommentID: String?
    let userID: String
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let text: String
    let likeCount: Int
    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case feedItemID
        case parentCommentID
        case userID
        case username
        case avatarName
        case avatarURL
        case text
        case likeCount
        case createdDate
    }
}

struct ChallengeLikeDTO: Codable, Identifiable {
    let id: String?
    let feedItemID: String
    let userID: String
    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case feedItemID
        case userID
        case createdDate
    }
}

struct ChallengeCommentLikeDTO: Codable, Identifiable {
    let id: String?
    let commentID: String
    let userID: String
    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case commentID
        case userID
        case createdDate
    }
}

struct ChallengeLikeToggleRequestDTO: Codable {
    let userID: String
}

struct ChallengeLikeToggleResponseDTO: Codable {
    let liked: Bool
    let likeCount: Int
}

struct ChallengeAddFeedItemCommentRequestDTO: Codable {
    let userID: String
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let text: String
    let parentCommentID: String?
}

// MARK: - Profile DTOs

struct ChallengeUserProfileDTO: Codable, Identifiable {
    var id: String { userID }

    let userID: String
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let bio: String?
    let favoriteGenre: String?
    let readingStreak: Int
    let challengePoints: Int
    let challengesCompleted: Int
    let followersCount: Int
    let followingCount: Int
}

struct ChallengeUpdateProfileRequestDTO: Codable {
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let bio: String?
    let favoriteGenre: String?
    let readingStreak: Int?
    let challengePoints: Int?
    let challengesCompleted: Int?
    let followersCount: Int?
    let followingCount: Int?
}

// MARK: - Create Post Request

struct ChallengeCreateFeedPostRequestDTO: Codable {
    let userID: String
    let username: String
    let text: String
    let photoURL: String?
    let photoBase64: String?
    let photoCaption: String?
    let linkedBookID: String?
    let linkedChallengeID: String?
    let mood: String?
    let containsSpoilers: Bool
    let visibility: String
}

struct ChallengeUploadFeedPhotoResponseDTO: Codable {
    let photoURL: String
}

struct ChallengeUploadProfileAvatarResponseDTO: Codable {
    let avatarURL: String
}

// MARK: - Encoder / Decoder

private extension JSONEncoder {
    static var challengeEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var challengeDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            if container.decodeNil() {
                return Date.distantPast
            }

            let raw = try container.decode(String.self)

            if let date = ISO8601DateFormatter.challengeFormatter.date(from: raw) {
                return date
            }

            if let fallbackDate = ISO8601DateFormatter.challengeFallbackFormatter.date(from: raw) {
                return fallbackDate
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date string: \(raw)"
            )
        }

        return decoder
    }
}

private extension ISO8601DateFormatter {
    static let challengeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let challengeFallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - Admin

enum VoxAdmin {
    /// Set this to your Apple User ID to enable admin features.
    /// Only this userID can create feed announcements.
    static let adminUserID = "001664.f2fefbb84f024544b98e865fa6c6b49e.1524"
}

// MARK: - Announcement DTO

struct ChallengeFeedAnnouncementDTO: Codable, Identifiable {
    let id: String?
    let title: String
    let body: String
    let userID: String
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let isActive: Bool
    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case body

        case userID
        case username
        case avatarName
        case avatarURL

        case authorUserID
        case authorUsername
        case authorAvatarName
        case authorAvatarURL

        case isActive
        case createdDate
    }

    init(
        id: String?,
        title: String,
        body: String,
        userID: String,
        username: String,
        avatarName: String?,
        avatarURL: String?,
        isActive: Bool,
        createdDate: Date?
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.userID = userID
        self.username = username
        self.avatarName = avatarName
        self.avatarURL = avatarURL
        self.isActive = isActive
        self.createdDate = createdDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)

        userID =
            try container.decodeIfPresent(String.self, forKey: .userID)
            ?? container.decodeIfPresent(String.self, forKey: .authorUserID)
            ?? ""

        username =
            try container.decodeIfPresent(String.self, forKey: .username)
            ?? container.decodeIfPresent(String.self, forKey: .authorUsername)
            ?? "Reader"

        avatarName =
            try container.decodeIfPresent(String.self, forKey: .avatarName)
            ?? container.decodeIfPresent(String.self, forKey: .authorAvatarName)

        avatarURL =
            try container.decodeIfPresent(String.self, forKey: .avatarURL)
            ?? container.decodeIfPresent(String.self, forKey: .authorAvatarURL)

        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)

        try container.encode(userID, forKey: .userID)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(avatarName, forKey: .avatarName)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)

        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
    }
}

struct ChallengeCreateAnnouncementRequestDTO: Codable {
    let title: String
    let body: String
    let userID: String
    let username: String
    let avatarURL: String?
    let avatarName: String?
}

// MARK: - Messaging DTOs

struct ConversationDTO: Codable, Identifiable {
    let id: String?
    let participantA: String
    let participantB: String
    let participantAUsername: String
    let participantBUsername: String
    let lastMessageText: String
    let lastMessageSenderUserID: String
    let lastMessageDate: Date?
    let unreadCountA: Int
    let unreadCountB: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participantA
        case participantB
        case participantAUsername
        case participantBUsername
        case lastMessageText
        case lastMessageSenderUserID
        case lastMessageDate
        case unreadCountA
        case unreadCountB
    }

    func otherUserID(currentUserID: String) -> String {
        participantA == currentUserID ? participantB : participantA
    }

    func otherUsername(currentUserID: String) -> String {
        if participantA == currentUserID && participantB == currentUserID {
            return "Me"
        }

        return participantA == currentUserID ? participantBUsername : participantAUsername
    }

    func unreadCount(for userID: String) -> Int {
        participantA == userID ? unreadCountA : unreadCountB
    }
}

struct DirectMessageDTO: Codable, Identifiable {
    let id: String?
    let conversationID: String
    let senderUserID: String
    let senderUsername: String
    let text: String
    let isRead: Bool
    let createdDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationID
        case senderUserID
        case senderUsername
        case text
        case isRead
        case createdDate
    }
}

struct CreateConversationRequestDTO: Codable {
    let senderUserID: String
    let senderUsername: String
    let recipientUserID: String
    let recipientUsername: String
}

struct SendMessageRequestDTO: Codable {
    let senderUserID: String
    let senderUsername: String
    let text: String
}

struct MarkReadRequestDTO: Codable {
    let userID: String
}

struct MessageableUserDTO: Codable, Identifiable {
    var id: String { userID }
    let userID: String
    let username: String
    let avatarName: String?
    let avatarURL: String?
    let bio: String?
}

// MARK: - Global Avatar View

struct UserAvatarView: View {
    let avatarURL: String?
    let avatarName: String?
    var size: CGFloat = 40
    var iconSize: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(LColors.glassSurface)
                .overlay(
                    Circle()
                        .strokeBorder(LGradients.header, lineWidth: 1)
                )

            if let avatarURL,
               let url = URL(string: avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)),
               !avatarURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size - 6, height: size - 6)
                            .clipShape(Circle())

                    default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackAvatar: some View {
        Group {
            if let avatarName,
               !avatarName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Image(avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 6, height: size - 6)
                    .clipShape(Circle())
            } else {
                Image("profilewavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(LGradients.header)
            }
        }
    }
}

// MARK: - Errors

enum ChallengeSocialServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid social challenge URL."
        case .invalidResponse:
            return "Received an invalid response from the challenge server."
        case .serverError(let statusCode, let message):
            return "Challenge server error (\(statusCode)): \(message)"
        }
    }
}
