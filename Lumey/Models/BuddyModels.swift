//
//  BuddyModels.swift
//  Lumey
//

import Foundation

// MARK: - Announcement

struct BuddyAnnouncement: Codable, Identifiable {
    let id: String
    let ownerUserId: String
    let ownerDisplayName: String
    let bookTitle: String
    let bookAuthor: String?
    let bookCoverUrl: String?
    let bookKey: String?
    let message: String?
    let currentChapter: Int?
    let currentPage: Int?
    let maxMembers: Int
    let groupId: String?
    let isActive: Bool
    let status: String?
    let activeMemberCount: Int?
    let pendingMemberCount: Int?
    let spotsLeft: Int?
    let expiresAt: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ownerUserId, ownerDisplayName
        case bookTitle, bookAuthor, bookCoverUrl, bookKey
        case message, currentChapter, currentPage
        case maxMembers, groupId, isActive, expiresAt, createdAt
        case status, activeMemberCount, pendingMemberCount, spotsLeft
    }

    var isClosed: Bool { status == "closed" }
    var isArchived: Bool { status == "archived" }
    var isDeleted: Bool { status == "deleted" }
    var availableSpots: Int {
        spotsLeft ?? max(maxMembers - (activeMemberCount ?? 1), 0)
    }
}

// MARK: - Group

struct BuddyMember: Codable, Identifiable {
    let userId: String
    let displayName: String
    let status: String      // "pending" | "joined" | "left"
    let joinedAt: String?
    let requestedAt: String

    var id: String { userId }

    var isPending: Bool { status == "pending" }
    var isJoined: Bool  { status == "joined" }
    var hasLeft: Bool   { status == "left" }
}

struct BuddyGroup: Codable, Identifiable {
    let id: String
    let announcementId: String
    /// Who posted the announcement. Display only — grants no permissions.
    let ownerUserId: String?
    let ownerDisplayName: String?
    let bookTitle: String
    let bookAuthor: String?
    let bookCoverUrl: String?
    let bookKey: String?
    let maxMembers: Int
    let members: [BuddyMember]
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case announcementId, ownerUserId, ownerDisplayName
        case bookTitle, bookAuthor, bookCoverUrl, bookKey
        case maxMembers, members, isActive, createdAt
    }

    var joinedMembers: [BuddyMember] {
        members.filter { $0.isJoined }
    }

    var pendingMembers: [BuddyMember] {
        members.filter { $0.isPending }
    }

    func isOwnedBy(_ userId: String) -> Bool {
        ownerUserId == userId
    }

    /// "Your read" when it's yours, otherwise "<name>'s read".
    func ownerLabel(currentUserId: String) -> String? {
        guard let ownerUserId, !ownerUserId.isEmpty else { return nil }
        if ownerUserId == currentUserId { return "Your read" }
        guard let name = ownerDisplayName, !name.isEmpty else { return nil }
        return "\(name)'s read"
    }
}

// MARK: - Message

struct BuddyMessage: Codable, Identifiable {
    let id: String
    let groupId: String
    let senderUserId: String
    let senderDisplayName: String
    let type: String        // "text" | "progress_update" | "system"
    let text: String
    let progressChapter: Int?
    let progressPage: Int?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case groupId, senderUserId, senderDisplayName
        case type, text, progressChapter, progressPage, createdAt
    }

    var isSystem: Bool          { type == "system" }
    var isProgressUpdate: Bool  { type == "progress_update" }
}

// MARK: - API Response wrappers

struct BuddyAnnouncementsResponse: Codable {
    let success: Bool
    let announcements: [BuddyAnnouncement]?
}

struct BuddyAnnouncementResponse: Codable {
    let success: Bool
    let announcement: BuddyAnnouncement?
}

struct BuddyGroupResponse: Codable {
    let success: Bool
    let group: BuddyGroup?
}

struct BuddyGroupsResponse: Codable {
    let success: Bool
    let groups: [BuddyGroup]?
}

struct BuddyMessagesResponse: Codable {
    let success: Bool
    let messages: [BuddyMessage]?
}

struct BuddyMessageResponse: Codable {
    let success: Bool
    let message: BuddyMessage?
}

struct BuddySuccessResponse: Codable {
    let success: Bool
}

// MARK: - Request bodies

struct PostAnnouncementBody: Encodable {
    let ownerUserId: String
    let ownerDisplayName: String
    let bookTitle: String
    let bookAuthor: String?
    let bookCoverUrl: String?
    let bookKey: String?
    let message: String?
    let currentChapter: Int?
    let currentPage: Int?
    let maxMembers: Int
}

struct RequestToJoinBody: Encodable {
    let announcementId: String
    let requesterUserId: String
    let requesterDisplayName: String
}

struct RespondToJoinBody: Encodable {
    let actorUserId: String
    let targetUserId: String
    let accept: Bool
}

struct LeaveGroupBody: Encodable {
    let userId: String
}

struct SendMessageBody: Encodable {
    let senderUserId: String
    let senderDisplayName: String
    let type: String
    let text: String
    let progressChapter: Int?
    let progressPage: Int?
}

struct UpdateAnnouncementBody: Encodable {
    let ownerUserId: String
    let message: String?
    let currentChapter: Int?
    let currentPage: Int?
    let maxMembers: Int?
}

struct OwnerAnnouncementActionBody: Encodable {
    let ownerUserId: String
}
