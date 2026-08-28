//
//  ReadingXPService.swift
//  Lumey
//

import Foundation
import SwiftData

struct ReadingXPLevelSummary {
    let level: Int
    let title: String
    let totalXP: Int
    let currentLevelXP: Int
    let nextLevelXP: Int
    let xpIntoLevel: Int
    let xpNeededForNextLevel: Int
    let progress: Double
}

enum ReadingXPService {
    private static let sessionCap = 250
    private static let noteDailyCap = 50
    private static let quoteDailyCap = 40
    private static let epubAnnotationDailyCap = 50
    private static let buddyMessageDailyCap = 20
    private static let buddyProgressDailyCap = 20
    private static let challengeSocialDailyCap = 30
    private static let sprintDailyCap = 250

    private static let titles: [String] = [
        "Page Starter",
        "Fresh Bookmark",
        "Chapter Seeker",
        "Margin Scribbler",
        "Steady Reader",
        "Quote Keeper",
        "Story Chaser",
        "Shelf Builder",
        "Night Reader",
        "Book Devotee",
        "Streak Tender",
        "Annotation Adept",
        "Library Spark",
        "Review Weaver",
        "Plot Pilgrim",
        "Series Scout",
        "Challenge Reader",
        "Tome Traveler",
        "Canon Collector",
        "Luminary Reader",
        "Arc Keeper",
        "Page Alchemist",
        "Story Oracle",
        "Shelf Sage",
        "Lorekeeper",
        "Bookbound",
        "Infinite Reader",
        "Lumey Legend"
    ]

    @discardableResult
    static func awardReadingSession(
        _ session: ReadingSession,
        stats: ReadingStats,
        modelContext: ModelContext
    ) -> Int {
        guard session.durationMinutes > 0 || session.pagesRead > 0 else { return 0 }

        var total = award(
            amount: sessionXP(minutes: session.durationMinutes, pages: session.pagesRead),
            sourceType: "readingSession",
            sourceID: session.id.uuidString,
            capKey: "readingSession",
            reason: "Reading session",
            occurredAt: session.date,
            modelContext: modelContext
        )

        let dayKey = dayKey(for: session.date)
        total += award(
            amount: 25,
            sourceType: "dailyReading",
            sourceID: dayKey,
            capKey: "dailyReading",
            reason: "First reading session of the day",
            occurredAt: session.date,
            modelContext: modelContext
        )

        if stats.currentReadingStreak > 1 {
            total += award(
                amount: 10,
                sourceType: "streakContinue",
                sourceID: dayKey,
                capKey: "streakContinue",
                reason: "Reading streak continued",
                occurredAt: session.date,
                modelContext: modelContext
            )
        }

        total += awardStreakMilestones(
            currentStreak: stats.currentReadingStreak,
            occurredAt: session.date,
            modelContext: modelContext
        )

        return total
    }

    @discardableResult
    static func awardStreakCheckIn(
        _ session: ReadingSession,
        stats: ReadingStats,
        modelContext: ModelContext
    ) -> Int {
        guard session.hasLinkedGoal else { return 0 }

        let dayKey = dayKey(for: session.date)
        var total = award(
            amount: 25,
            sourceType: "dailyReading",
            sourceID: dayKey,
            capKey: "dailyReading",
            reason: "First reading check-in of the day",
            occurredAt: session.date,
            modelContext: modelContext
        )

        if stats.currentReadingStreak > 1 {
            total += award(
                amount: 10,
                sourceType: "streakContinue",
                sourceID: dayKey,
                capKey: "streakContinue",
                reason: "Reading streak continued",
                occurredAt: session.date,
                modelContext: modelContext
            )
        }

        total += awardStreakMilestones(
            currentStreak: stats.currentReadingStreak,
            occurredAt: session.date,
            modelContext: modelContext
        )

        return total
    }

    @discardableResult
    static func awardBookStatusChange(
        book: Book,
        previousStatus: BookStatus,
        newStatus: BookStatus,
        modelContext: ModelContext
    ) -> Int {
        guard previousStatus != newStatus else { return 0 }

        var total = 0
        if newStatus == .reading {
            total += award(
                amount: 25,
                sourceType: "bookStarted",
                sourceID: book.id.uuidString,
                capKey: "bookStarted",
                reason: "Book started",
                modelContext: modelContext
            )
        }

        if newStatus == .finished {
            let pageBonus = min(max(book.totalPages, book.currentPage, 0) / 10, 100)
            total += award(
                amount: 150 + pageBonus,
                sourceType: "bookFinished",
                sourceID: book.id.uuidString,
                capKey: "bookFinished",
                reason: "Book finished",
                modelContext: modelContext
            )
        }

        return total
    }

    @discardableResult
    static func awardBookNote(_ note: BookNote, modelContext: ModelContext) -> Int {
        award(
            amount: 10,
            sourceType: "bookNote",
            sourceID: note.id.uuidString,
            capKey: "bookNote",
            reason: "Book note saved",
            occurredAt: note.dateCreated,
            dailyCap: noteDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardBookQuote(_ quote: BookQuote, modelContext: ModelContext) -> Int {
        award(
            amount: 8,
            sourceType: "bookQuote",
            sourceID: quote.id.uuidString,
            capKey: "bookQuote",
            reason: "Quote saved",
            occurredAt: quote.dateCreated,
            dailyCap: quoteDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardBookReview(_ review: BookReview, modelContext: ModelContext) -> Int {
        let wordCount = review.content.split { $0.isWhitespace || $0.isNewline }.count
        let amount = wordCount >= 80 ? 90 : 60
        return award(
            amount: amount,
            sourceType: "bookReview",
            sourceID: review.id.uuidString,
            capKey: "bookReview",
            reason: "Review written",
            occurredAt: review.dateCreated,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardGoalNote(_ note: GoalNote, modelContext: ModelContext) -> Int {
        award(
            amount: 10,
            sourceType: "goalNote",
            sourceID: note.id.uuidString,
            capKey: "bookNote",
            reason: "Goal note saved",
            occurredAt: note.createdAt,
            dailyCap: noteDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardEPUBBookmark(_ bookmark: EPUBBookmark, modelContext: ModelContext) -> Int {
        award(
            amount: 5,
            sourceType: "epubBookmark",
            sourceID: bookmark.id.uuidString,
            capKey: "epubAnnotation",
            reason: "EPUB bookmark saved",
            occurredAt: bookmark.createdAt,
            dailyCap: epubAnnotationDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardEPUBHighlight(_ highlight: EPUBHighlight, modelContext: ModelContext) -> Int {
        let amount = highlight.isQuote ? 8 : (highlight.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 6 : 10)
        let sourceType = highlight.isQuote ? "epubQuote" : (highlight.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "epubHighlight" : "epubNote")
        return award(
            amount: amount,
            sourceType: sourceType,
            sourceID: highlight.id.uuidString,
            capKey: "epubAnnotation",
            reason: highlight.isQuote ? "EPUB quote saved" : "EPUB annotation saved",
            occurredAt: highlight.createdAt,
            dailyCap: epubAnnotationDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardGoalCompletion(
        goal: ReadingGoals,
        occurredAt: Date = Date(),
        modelContext: ModelContext
    ) -> Int {
        award(
            amount: 100,
            sourceType: "goalCompleted",
            sourceID: goalCompletionSourceID(goal, occurredAt: occurredAt),
            capKey: "goalCompleted",
            reason: "Goal completed",
            occurredAt: occurredAt,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardChallengeApproval(
        entry: ChallengeEntry,
        challenge: ReadingChallenge,
        modelContext: ModelContext
    ) -> Int {
        award(
            amount: 100 + min(challenge.points / 5, 200),
            sourceType: "challengeApproved",
            sourceID: entry.id.uuidString,
            capKey: "challengeApproved",
            reason: "Challenge approved",
            occurredAt: entry.approvedDate ?? Date(),
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardChallengeFeedPost(_ feedItem: ChallengeFeedItemDTO, modelContext: ModelContext) -> Int {
        guard let id = feedItem.id else { return 0 }
        return award(
            amount: 15,
            sourceType: "challengeFeedPost",
            sourceID: id,
            capKey: "challengeSocial",
            reason: "Challenge feed post",
            dailyCap: challengeSocialDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardChallengeFeedComment(_ comment: ChallengeCommentDTO, modelContext: ModelContext) -> Int {
        guard let id = comment.id else { return 0 }
        return award(
            amount: 5,
            sourceType: "challengeFeedComment",
            sourceID: id,
            capKey: "challengeSocial",
            reason: "Challenge feed comment",
            dailyCap: challengeSocialDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardBuddyProgressUpdate(_ message: BuddyMessage, modelContext: ModelContext) -> Int {
        award(
            amount: 20,
            sourceType: "buddyProgressUpdate",
            sourceID: message.id,
            capKey: "buddyProgressUpdate",
            reason: "Buddy read progress update",
            dailyCap: buddyProgressDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardBuddyMessage(_ message: BuddyMessage, modelContext: ModelContext) -> Int {
        award(
            amount: 5,
            sourceType: "buddyMessage",
            sourceID: message.id,
            capKey: "buddyMessage",
            reason: "Buddy read message",
            dailyCap: buddyMessageDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardSprintSubmission(
        sprint: Sprint,
        userID: String,
        endPage: Int,
        modelContext: ModelContext
    ) -> Int {
        guard let participant = sprint.participants.first(where: { $0.userId == userID }) else { return 0 }
        let pagesRead = participant.pagesRead ?? max(endPage - participant.startPage, 0)
        guard pagesRead > 0 else { return 0 }

        return award(
            amount: 15 + min(pagesRead * 3, 150),
            sourceType: "sprintSubmitted",
            sourceID: "\(sprint.id):\(userID)",
            capKey: "sprintSubmitted",
            reason: "Sprint pages submitted",
            dailyCap: sprintDailyCap,
            modelContext: modelContext
        )
    }

    @discardableResult
    static func awardReadingMissionCompletion(_ mission: ReadingMission, modelContext: ModelContext) -> Int {
        award(
            amount: 125,
            sourceType: "readingMissionCompleted",
            sourceID: mission.id.uuidString,
            capKey: "readingMissionCompleted",
            reason: "Reading mission completed",
            occurredAt: mission.completedAt ?? Date(),
            metadataJSON: missionXPMetadata(for: mission),
            modelContext: modelContext
        )
    }

    static func preferredProfile(from profiles: [ReadingXPProfile]) -> ReadingXPProfile? {
        profiles.max { $0.updatedAt < $1.updatedAt }
    }

    static func fetchOrCreateProfile(in modelContext: ModelContext) -> ReadingXPProfile {
        let profiles = (try? modelContext.fetch(FetchDescriptor<ReadingXPProfile>())) ?? []
        if let profile = preferredProfile(from: profiles) {
            if profile.selectedTitle.isEmpty {
                profile.selectedTitle = title(for: level(for: profile.totalXP))
                profile.updatedAt = Date()
            }
            return profile
        }

        let profile = ReadingXPProfile(selectedTitle: title(for: 1))
        modelContext.insert(profile)
        return profile
    }

    static func levelSummary(totalXP: Int) -> ReadingXPLevelSummary {
        let currentLevel = level(for: totalXP)
        let currentLevelXP = cumulativeXP(for: currentLevel)
        let nextLevelXP = cumulativeXP(for: currentLevel + 1)
        let xpIntoLevel = max(totalXP - currentLevelXP, 0)
        let xpNeeded = max(nextLevelXP - totalXP, 0)
        let span = max(nextLevelXP - currentLevelXP, 1)

        return ReadingXPLevelSummary(
            level: currentLevel,
            title: title(for: currentLevel),
            totalXP: totalXP,
            currentLevelXP: currentLevelXP,
            nextLevelXP: nextLevelXP,
            xpIntoLevel: xpIntoLevel,
            xpNeededForNextLevel: xpNeeded,
            progress: min(max(Double(xpIntoLevel) / Double(span), 0), 1)
        )
    }

    static func title(for level: Int) -> String {
        let index = min(max(level - 1, 0), titles.count - 1)
        return titles[index]
    }

    static func dayKey(for date: Date = Date()) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    @discardableResult
    private static func award(
        amount: Int,
        sourceType: String,
        sourceID: String,
        capKey: String,
        reason: String,
        occurredAt: Date = Date(),
        dailyCap: Int? = nil,
        metadataJSON: String = "{}",
        modelContext: ModelContext
    ) -> Int {
        guard amount > 0, !sourceType.isEmpty, !sourceID.isEmpty else { return 0 }

        let events = (try? modelContext.fetch(FetchDescriptor<ReadingXPEvent>())) ?? []
        guard !events.contains(where: { $0.sourceType == sourceType && $0.sourceID == sourceID }) else {
            return 0
        }

        let targetDayKey = dayKey(for: occurredAt)
        let cappedAmount: Int
        if let dailyCap {
            let alreadyAwarded = events
                .filter { $0.capKey == capKey && $0.dayKey == targetDayKey }
                .reduce(0) { $0 + $1.amount }
            let available = max(dailyCap - alreadyAwarded, 0)
            cappedAmount = min(amount, available)
        } else {
            cappedAmount = amount
        }

        guard cappedAmount > 0 else { return 0 }

        let profile = fetchOrCreateProfile(in: modelContext)
        let event = ReadingXPEvent(
            sourceType: sourceType,
            sourceID: sourceID,
            capKey: capKey,
            amount: cappedAmount,
            reason: reason,
            dayKey: targetDayKey,
            occurredAt: occurredAt,
            metadataJSON: metadataJSON
        )

        modelContext.insert(event)
        profile.totalXP += cappedAmount
        profile.selectedTitle = title(for: level(for: profile.totalXP))
        profile.updatedAt = Date()
        try? modelContext.save()

        return cappedAmount
    }

    private static func sessionXP(minutes: Int, pages: Int) -> Int {
        guard minutes > 0 || pages > 0 else { return 0 }
        return min(15 + max(minutes * 2, pages * 3), sessionCap)
    }

    private static func awardStreakMilestones(
        currentStreak: Int,
        occurredAt: Date,
        modelContext: ModelContext
    ) -> Int {
        guard currentStreak > 0 else { return 0 }

        let milestoneAmount: Int?
        switch currentStreak {
        case 3:
            milestoneAmount = 75
        case 7:
            milestoneAmount = 150
        case 14:
            milestoneAmount = 250
        case 30:
            milestoneAmount = 500
        case let value where value > 30 && value % 30 == 0:
            milestoneAmount = 500
        default:
            milestoneAmount = nil
        }

        guard let milestoneAmount else { return 0 }

        return award(
            amount: milestoneAmount,
            sourceType: "streakMilestone",
            sourceID: "reading-streak-\(currentStreak)",
            capKey: "streakMilestone",
            reason: "\(currentStreak)-day reading streak",
            occurredAt: occurredAt,
            modelContext: modelContext
        )
    }

    private static func goalCompletionSourceID(_ goal: ReadingGoals, occurredAt: Date) -> String {
        guard goal.isRecurringGoal else { return goal.id.uuidString }

        return "\(goal.id.uuidString):\(goal.cadence.rawValue):\(periodKey(for: occurredAt, cadence: goal.cadence))"
    }

    private static func missionXPMetadata(for mission: ReadingMission) -> String {
        let payload = [
            "bookTitle": mission.bookTitle,
            "bookAuthor": mission.bookAuthor
        ]

        guard let data = try? JSONEncoder().encode(payload),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return string
    }

    private static func periodKey(for date: Date, cadence: ReadingGoalCadence) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: date)
        let year = components.year ?? 0

        switch cadence {
        case .daily:
            return dayKey(for: date)
        case .weekly:
            return String(format: "%04d-W%02d", year, components.weekOfYear ?? 0)
        case .monthly:
            return String(format: "%04d-%02d", year, components.month ?? 0)
        case .seasonal:
            let month = components.month ?? 1
            let season = (max(month - 1, 0) / 3) + 1
            return "\(year)-S\(season)"
        case .yearly:
            return "\(year)"
        case .lifetime, .custom:
            return goalFallbackPeriodKey(for: date)
        }
    }

    private static func goalFallbackPeriodKey(for date: Date) -> String {
        dayKey(for: date)
    }

    private static func level(for totalXP: Int) -> Int {
        var level = 1
        while totalXP >= cumulativeXP(for: level + 1), level < 250 {
            level += 1
        }
        return level
    }

    private static func cumulativeXP(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int((120 * pow(Double(level - 1), 1.65)).rounded())
    }
}
