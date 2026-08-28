//
//  ChallengeBookmark.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeBookmark {
    var id: UUID = UUID()
    var userID: String = ""
    var challengeID: UUID = UUID()
    var challengeTitle: String = ""
    var challengeIconName: String = "starmark"
    var challengeCategoryRawValue: String = ChallengeCategory.readingHabit.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    init(
        userID: String,
        challenge: ReadingChallenge,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.userID = userID
        self.challengeID = challenge.id
        self.challengeTitle = challenge.title
        self.challengeIconName = challenge.iconName
        self.challengeCategoryRawValue = challenge.category.rawValue
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.deletedAt = nil
    }
}

extension ChallengeBookmark {
    var category: ChallengeCategory {
        get { ChallengeCategory(rawValue: challengeCategoryRawValue) ?? .readingHabit }
        set { challengeCategoryRawValue = newValue.rawValue }
    }

    var isActive: Bool {
        deletedAt == nil
    }

    func refreshSnapshot(from challenge: ReadingChallenge) {
        challengeTitle = challenge.title
        challengeIconName = challenge.iconName
        challengeCategoryRawValue = challenge.category.rawValue
        updatedAt = Date()
    }
}
