//
//  ChallengeSubmission.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeSubmission {
    var id: UUID = UUID()
    var challengeID: UUID = UUID()
    var entryID: UUID = UUID()
    var userID: String = ""

    // Linked proof (stored as JSON arrays of UUID strings)
    var linkedBookIDsStorage: String = "[]"
    var linkedSessionIDsStorage: String = "[]"
    var linkedReviewIDsStorage: String = "[]"
    var linkedReadingListIDsStorage: String = "[]"

    // User content
    var submissionNote: String = ""
    var proofSummary: String = ""
    var photoURL: String = ""

    // Validation
    var validationStatusRawValue: String = ChallengeSubmissionStatus.submitted.rawValue
    var validationMessage: String?
    var photoValidationStatusRawValue: String = ChallengeSubmissionStatus.submitted.rawValue
    var photoValidationMessage: String?
    var photoValidationConfidence: Double = 0
    var photoValidationJSON: String = ""

    // Dates
    var submittedDate: Date = Date()
    var approvedDate: Date?
    var cycleID: String = ""
    var cycleStartDate: Date?
    var cycleEndDate: Date?

    // Social
    var likeCount: Int = 0
    var commentCount: Int = 0
    var remoteSubmissionID: String?
    var postedToFeed: Bool = false
    var feedItemID: String?

    // Display info (denormalized for feed)
    var username: String = ""
    var challengeTitle: String = ""

    init(
        challengeID: UUID,
        entryID: UUID,
        userID: String,
        username: String = "",
        challengeTitle: String = "",
        linkedBookIDs: [UUID] = [],
        linkedSessionIDs: [UUID] = [],
        linkedReviewIDs: [UUID] = [],
        linkedReadingListIDs: [UUID] = [],
        submissionNote: String = "",
        proofSummary: String = "",
        photoURL: String = "",
        cycleID: String = "",
        cycleStartDate: Date? = nil,
        cycleEndDate: Date? = nil
    ) {
        self.id = UUID()
        self.challengeID = challengeID
        self.entryID = entryID
        self.userID = userID
        self.username = username
        self.challengeTitle = challengeTitle
        self.linkedBookIDs = linkedBookIDs
        self.linkedSessionIDs = linkedSessionIDs
        self.linkedReviewIDs = linkedReviewIDs
        self.linkedReadingListIDs = linkedReadingListIDs
        self.submissionNote = submissionNote
        self.proofSummary = proofSummary
        self.photoURL = photoURL
        self.submittedDate = Date()
        self.cycleID = cycleID
        self.cycleStartDate = cycleStartDate
        self.cycleEndDate = cycleEndDate
    }
}

// MARK: - Computed Properties

extension ChallengeSubmission {
    var validationStatus: ChallengeSubmissionStatus {
        get { ChallengeSubmissionStatus(rawValue: validationStatusRawValue) ?? .submitted }
        set { validationStatusRawValue = newValue.rawValue }
    }

    var photoValidationStatus: ChallengeSubmissionStatus {
        get { ChallengeSubmissionStatus(rawValue: photoValidationStatusRawValue) ?? .submitted }
        set { photoValidationStatusRawValue = newValue.rawValue }
    }

    var linkedBookIDs: [UUID] {
        get { Self.decodeUUIDArray(from: linkedBookIDsStorage) }
        set { linkedBookIDsStorage = Self.encodeUUIDArray(newValue) }
    }

    var linkedSessionIDs: [UUID] {
        get { Self.decodeUUIDArray(from: linkedSessionIDsStorage) }
        set { linkedSessionIDsStorage = Self.encodeUUIDArray(newValue) }
    }

    var linkedReviewIDs: [UUID] {
        get { Self.decodeUUIDArray(from: linkedReviewIDsStorage) }
        set { linkedReviewIDsStorage = Self.encodeUUIDArray(newValue) }
    }

    var linkedReadingListIDs: [UUID] {
        get { Self.decodeUUIDArray(from: linkedReadingListIDsStorage) }
        set { linkedReadingListIDsStorage = Self.encodeUUIDArray(newValue) }
    }

    var isApproved: Bool {
        validationStatus == .approved
    }

    var hasPhotoProof: Bool {
        !photoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - JSON Helpers

    private static func decodeUUIDArray(from storage: String) -> [UUID] {
        guard let data = storage.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    private static func encodeUUIDArray(_ values: [UUID]) -> String {
        let strings = values.map { $0.uuidString }
        guard let data = try? JSONEncoder().encode(strings),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}
