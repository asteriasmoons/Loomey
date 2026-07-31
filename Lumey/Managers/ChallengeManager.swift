//
//  ChallengeManager.swift
//  Lumey
//

import Foundation
import SwiftData
import Combine

// MARK: - Challenge Manager

@MainActor
final class ChallengeManager: ObservableObject {

    private let modelContext: ModelContext
    private let validationEngine: ChallengeValidationEngine
    private let aiService: ChallengeAIValidationService

    @Published var isValidating: Bool = false
    @Published var lastValidationResult: ChallengeValidationResult?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.validationEngine = ChallengeValidationEngine(modelContext: modelContext)
        self.aiService = ChallengeAIValidationService()
    }

    // MARK: - Seed Challenges

    func seedChallengesIfNeeded() {
        let descriptor = FetchDescriptor<ReadingChallenge>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let challenges = ChallengeSeedData.allChallenges()
        for challenge in challenges {
            modelContext.insert(challenge)
        }
        try? modelContext.save()
    }

    // MARK: - Join Challenge

    func joinChallenge(_ challenge: ReadingChallenge, userID: String) -> ChallengeEntry {
        if let existingEntry = currentEntry(for: challenge, userID: userID) {
            return existingEntry
        }

        let cycle = challenge.cycle()
        let startDate = challenge.isRecurring ? cycle.startDate : Date()
        let endDate = challenge.isRecurring
            ? cycle.endDate
            : Calendar.current.date(byAdding: .day, value: challenge.durationDays, to: startDate) ?? startDate

        let entry = ChallengeEntry(
            challengeID: challenge.id,
            userID: userID,
            startDate: startDate,
            durationDays: challenge.durationDays,
            endDate: endDate,
            cycleID: challenge.isRecurring ? cycle.id : "\(challenge.id.uuidString):one-time"
        )
        modelContext.insert(entry)
        challenge.participantCount += 1
        try? modelContext.save()
        return entry
    }

    // MARK: - Submit Challenge

    func submitChallenge(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) async {
        guard entry.status != .approved, submission.validationStatus != .approved else {
            lastValidationResult = .approved(
                challenge.isRecurring
                    ? "This challenge has already been approved for the current cycle."
                    : "This challenge has already been approved."
            )
            return
        }

        print("===== MANAGER SUBMIT START =====")
        print("Challenge:", challenge.title)
        print("Requirement:", challenge.requirementText)
        print("Submission linkedBookIDs:", submission.linkedBookIDs)
        print("Submission linkedSessionIDs:", submission.linkedSessionIDs)
        print("Submission proofSummary:", submission.proofSummary)
        print("Submission note:", submission.submissionNote)

        isValidating = true
        defer { isValidating = false }

        submission.validationStatus = .validating
        entry.status = .submitted
        entry.submittedDate = Date()
        try? modelContext.save()

        // Step 1: Run database validation
        let result = validationEngine.validate(
            challenge: challenge,
            entry: entry,
            submission: submission
        )

        switch result {
        case .approved(let message):
            await approveSubmission(submission, entry: entry, challenge: challenge, message: message)

        case .inProgress(let message):
            submission.validationStatus = .inProgress
            submission.validationMessage = message
            entry.status = .inProgress

        case .needsMoreInfo(let message):
            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = message
            entry.status = .needsMoreInfo

        case .rejected(let message):
            submission.validationStatus = .rejected
            submission.validationMessage = message
            entry.status = .rejected

        case .requiresAI(let preMessage):
            // Step 2: Call AI validation
            submission.validationMessage = preMessage
            await runAIValidation(challenge: challenge, entry: entry, submission: submission)
        }

        lastValidationResult = result
        try? modelContext.save()
    }

    // MARK: - AI Validation

    private func runAIValidation(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) async {
        // Fetch linked books for the packet
        let descriptor = FetchDescriptor<Book>()
        let allBooks = (try? modelContext.fetch(descriptor)) ?? []
        let linkedBooks = allBooks.filter { submission.linkedBookIDs.contains($0.id) }

        let sessionDescriptor = FetchDescriptor<ReadingSession>()
        let allSessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        let linkedSessions = allSessions.filter { submission.linkedSessionIDs.contains($0.id) }

        print("===== MANAGER AI VALIDATION =====")
        print("All sessions count:", allSessions.count)
        print("Submission linkedSessionIDs:", submission.linkedSessionIDs)
        print("Resolved linkedSessions count:", linkedSessions.count)

        for session in linkedSessions {
            print("Resolved session:", session.linkedBookTitle, "\(session.durationMinutes) min", "\(session.pagesRead) pages", session.date)
        }

        // Fetch review text if relevant
        var reviewText: String? = nil
        if !submission.linkedReviewIDs.isEmpty {
            let reviewDescriptor = FetchDescriptor<BookReview>()
            let allReviews = (try? modelContext.fetch(reviewDescriptor)) ?? []
            let linkedReviews = allReviews.filter { submission.linkedReviewIDs.contains($0.id) }
            reviewText = linkedReviews.map(\.content).joined(separator: "\n\n")
        }
        
        print("Books going into AI packet:", linkedBooks.count)
        print("Sessions available before AI packet:", linkedSessions.count)
        print("Proof summary before AI packet:", submission.proofSummary)

        let packet = ChallengeAIValidationService.buildPacket(
            challenge: challenge,
            books: linkedBooks,
            submissionNote: submission.submissionNote,
            reviewText: reviewText
        )

        do {
            let aiResult = try await aiService.validate(packet: packet)

            switch aiResult {
            case .approved(let message):
                await approveSubmission(submission, entry: entry, challenge: challenge, message: message)

            case .inProgress(let message):
                submission.validationStatus = .inProgress
                submission.validationMessage = message
                entry.status = .inProgress

            case .needsMoreInfo(let message):
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = message
                entry.status = .needsMoreInfo

            case .rejected(let message):
                submission.validationStatus = .rejected
                submission.validationMessage = message
                entry.status = .rejected

            case .requiresAI:
                // Shouldn't happen from AI, but handle gracefully
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = "Validation is taking longer than expected. Please try again."
                entry.status = .needsMoreInfo
            }

            lastValidationResult = aiResult
        } catch {
            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = "Could not reach the validation server. Please try again later."
            entry.status = .needsMoreInfo
            lastValidationResult = .needsMoreInfo("Validation service unavailable.")
        }

        try? modelContext.save()
    }

    // MARK: - Approve Submission

    private func approveSubmission(
        _ submission: ChallengeSubmission,
        entry: ChallengeEntry,
        challenge: ReadingChallenge,
        message: String
    ) async {
        guard !entry.pointsAwarded else { return } // Prevent duplicate rewards

        submission.validationStatus = .approved
        submission.validationMessage = message
        submission.approvedDate = Date()

        entry.status = .approved
        entry.approvedDate = Date()
        entry.earnedPoints = challenge.points
        entry.pointsAwarded = true

        challenge.completedCount += 1

        // Award points to user profile if it exists
        awardPoints(points: challenge.points, userID: entry.userID)
        ReadingXPService.awardChallengeApproval(entry: entry, challenge: challenge, modelContext: modelContext)

        try? modelContext.save()

        await postApprovedSubmissionToFeedIfNeeded(submission, challenge: challenge)
    }

    func postApprovedSubmissionToFeedIfNeeded(
        _ submission: ChallengeSubmission,
        challenge: ReadingChallenge
    ) async {
        guard submission.validationStatus == .approved else { return }
        guard !submission.postedToFeed || submission.feedItemID == nil else { return }

        do {
            let remoteSubmissionID: String

            if let existingRemoteID = submission.remoteSubmissionID,
               !existingRemoteID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                remoteSubmissionID = existingRemoteID
            } else {
                let remoteSubmission = try await ChallengeSocialService.shared.createSubmission(
                    remoteDTO(for: submission, validationStatus: "submitted")
                )

                guard let createdID = remoteSubmission.id,
                      !createdID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }

                submission.remoteSubmissionID = createdID
                remoteSubmissionID = createdID
                try? modelContext.save()
            }

            let approvedResponse = try await ChallengeSocialService.shared.approveSubmission(
                submissionID: remoteSubmissionID,
                validationMessage: submission.validationMessage,
                challengeTitle: challenge.title
            )

            submission.remoteSubmissionID = approvedResponse.submission.id ?? remoteSubmissionID
            submission.postedToFeed = approvedResponse.submission.postedToFeed ?? (approvedResponse.feedItem != nil)
            submission.feedItemID = approvedResponse.submission.feedItemID ?? approvedResponse.feedItem?.id
            try? modelContext.save()
        } catch {
            print("Failed to post approved challenge submission to feed:", error)
        }
    }

    private func remoteDTO(
        for submission: ChallengeSubmission,
        validationStatus: String
    ) -> ChallengeSubmissionDTO {
        ChallengeSubmissionDTO(
            id: nil,
            challengeID: submission.challengeID.uuidString,
            entryID: submission.entryID.uuidString,
            userID: submission.userID,
            username: submission.username,
            linkedBookIDs: submission.linkedBookIDs.map { $0.uuidString },
            linkedSessionIDs: submission.linkedSessionIDs.map { $0.uuidString },
            linkedReviewIDs: submission.linkedReviewIDs.map { $0.uuidString },
            linkedReadingListIDs: submission.linkedReadingListIDs.map { $0.uuidString },
            submissionNote: submission.submissionNote,
            proofSummary: submission.proofSummary,
            validationStatus: validationStatus,
            validationMessage: submission.validationMessage,
            submittedDate: submission.submittedDate,
            approvedDate: nil,
            cycleID: submission.cycleID,
            cycleStartDate: submission.cycleStartDate,
            cycleEndDate: submission.cycleEndDate,
            postedToFeed: false,
            feedItemID: nil,
            likeCount: submission.likeCount,
            commentCount: submission.commentCount
        )
    }

    // MARK: - Award Points

    private func awardPoints(points: Int, userID: String) {
        let descriptor = FetchDescriptor<ChallengeUserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: { $0.userID == userID })
        else { return }

        profile.challengePoints += points
        profile.challengesCompleted += 1
    }

    // MARK: - Fetch Helpers

    func fetchEntry(for challengeID: UUID, userID: String) -> ChallengeEntry? {
        let descriptor = FetchDescriptor<ChallengeEntry>()
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        let challenges = fetchAllChallenges()
        guard let challenge = challenges.first(where: { $0.id == challengeID }) else {
            return entries.first(where: { $0.challengeID == challengeID && $0.userID == userID })
        }
        return currentEntry(for: challenge, userID: userID, entries: entries)
    }

    func fetchSubmissions(for challengeID: UUID) -> [ChallengeSubmission] {
        let descriptor = FetchDescriptor<ChallengeSubmission>(
            sortBy: [SortDescriptor(\ChallengeSubmission.submittedDate, order: .reverse)]
        )
        let submissions = (try? modelContext.fetch(descriptor)) ?? []
        return submissions.filter { $0.challengeID == challengeID }
    }

    func fetchUserSubmission(for entryID: UUID) -> ChallengeSubmission? {
        let descriptor = FetchDescriptor<ChallengeSubmission>()
        let submissions = (try? modelContext.fetch(descriptor)) ?? []
        return submissions.first(where: { $0.entryID == entryID })
    }

    func fetchAllChallenges() -> [ReadingChallenge] {
        let descriptor = FetchDescriptor<ReadingChallenge>(
            sortBy: [SortDescriptor(\ReadingChallenge.createdDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchFeaturedChallenge() -> ReadingChallenge? {
        let all = fetchAllChallenges()
        return ReadingChallenge.rotatingFeaturedChallenge(from: all)
    }

    func fetchWeeklyChallenges() -> [ReadingChallenge] {
        let all = fetchAllChallenges()
        return all.filter { $0.isWeekly }
    }

    func fetchChallenges(for category: ChallengeCategory) -> [ReadingChallenge] {
        let all = fetchAllChallenges()
        return all.filter { $0.category == category }
    }

    func currentEntry(
        for challenge: ReadingChallenge,
        userID: String,
        entries existingEntries: [ChallengeEntry]? = nil
    ) -> ChallengeEntry? {
        let entries: [ChallengeEntry]
        if let existingEntries {
            entries = existingEntries
        } else {
            let descriptor = FetchDescriptor<ChallengeEntry>(
                sortBy: [SortDescriptor(\ChallengeEntry.startDate, order: .reverse)]
            )
            entries = (try? modelContext.fetch(descriptor)) ?? []
        }

        let matchingEntries = entries.filter {
            $0.challengeID == challenge.id && $0.userID == userID
        }

        guard challenge.isRecurring else {
            return matchingEntries.first
        }

        let cycle = challenge.cycle()
        return matchingEntries.first {
            $0.cycleID == cycle.id || (
                Calendar.current.isDate($0.startDate, inSameDayAs: cycle.startDate) &&
                Calendar.current.isDate($0.endDate, inSameDayAs: cycle.endDate)
            )
        }
    }

    func backfillCycleMetadata() {
        let challenges = fetchAllChallenges()
        let challengeByID = Dictionary(uniqueKeysWithValues: challenges.map { ($0.id, $0) })

        let entryDescriptor = FetchDescriptor<ChallengeEntry>()
        let entries = (try? modelContext.fetch(entryDescriptor)) ?? []
        let entryByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

        let submissionDescriptor = FetchDescriptor<ChallengeSubmission>()
        let submissions = (try? modelContext.fetch(submissionDescriptor)) ?? []

        var didChange = false

        for challenge in challenges where challenge.isRecurring {
            if challenge.recurrenceRawValue == ChallengeRecurrence.oneTime.rawValue {
                challenge.recurrence = challenge.isWeekly ? .weekly : .custom
                didChange = true
            }

            if challenge.cycleAnchorDate == nil {
                challenge.cycleAnchorDate = challenge.featuredStartDate ?? challenge.createdDate
                didChange = true
            }
        }

        for entry in entries {
            guard let challenge = challengeByID[entry.challengeID] else { continue }

            if challenge.isRecurring {
                let cycle = challenge.cycle(containingEntryStart: entry.startDate)
                if entry.cycleID != cycle.id {
                    entry.cycleID = cycle.id
                    didChange = true
                }
                if entry.startDate != cycle.startDate {
                    entry.startDate = cycle.startDate
                    didChange = true
                }
                if entry.endDate != cycle.endDate {
                    entry.endDate = cycle.endDate
                    didChange = true
                }
            } else if entry.cycleID.isEmpty {
                entry.cycleID = "\(challenge.id.uuidString):one-time"
                didChange = true
            }
        }

        for submission in submissions {
            if let entry = entryByID[submission.entryID] {
                if submission.cycleID != entry.cycleID {
                    submission.cycleID = entry.cycleID
                    didChange = true
                }
                if submission.cycleStartDate != entry.startDate {
                    submission.cycleStartDate = entry.startDate
                    didChange = true
                }
                if submission.cycleEndDate != entry.endDate {
                    submission.cycleEndDate = entry.endDate
                    didChange = true
                }
                continue
            }

            guard let challenge = challengeByID[submission.challengeID] else { continue }
            let cycle = challenge.isRecurring
                ? challenge.cycle(containing: submission.submittedDate)
                : ChallengeCycle(
                    id: "\(challenge.id.uuidString):one-time",
                    startDate: submission.submittedDate,
                    endDate: submission.submittedDate
                )

            if submission.cycleID != cycle.id {
                submission.cycleID = cycle.id
                didChange = true
            }
            if submission.cycleStartDate != cycle.startDate {
                submission.cycleStartDate = cycle.startDate
                didChange = true
            }
            if submission.cycleEndDate != cycle.endDate {
                submission.cycleEndDate = cycle.endDate
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }
}
