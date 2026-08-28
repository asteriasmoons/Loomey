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
        let seedChallenges = ChallengeSeedData.allChallenges()
        let seedIdentities = Set(seedChallenges.map { seedIdentity(for: $0) })
        let descriptor = FetchDescriptor<ReadingChallenge>()
        var existingChallenges = (try? modelContext.fetch(descriptor)) ?? []
        let didConsolidateDuplicates = consolidateDuplicateSeedChallenges(
            existingChallenges: existingChallenges,
            seedIdentities: seedIdentities
        )

        if didConsolidateDuplicates {
            existingChallenges = (try? modelContext.fetch(descriptor)) ?? []
        }

        let existingKeys = Set(existingChallenges.map { seedIdentity(for: $0) })
        var didUpdateExistingChallenge = false

        for seedChallenge in seedChallenges {
            guard let existing = existingChallenges.first(where: {
                seedIdentity(for: $0) == seedIdentity(for: seedChallenge)
            }) else { continue }

            didUpdateExistingChallenge = syncSeedChallenge(existing, from: seedChallenge) || didUpdateExistingChallenge
        }

        let challenges = seedChallenges.filter {
            !existingKeys.contains(seedIdentity(for: $0))
        }

        guard !challenges.isEmpty || didUpdateExistingChallenge || didConsolidateDuplicates else { return }

        for challenge in challenges {
            modelContext.insert(challenge)
        }
        try? modelContext.save()
    }

    private func seedIdentity(for challenge: ReadingChallenge) -> String {
        [
            challenge.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            challenge.category.rawValue
        ].joined(separator: "|")
    }

    private func consolidateDuplicateSeedChallenges(
        existingChallenges: [ReadingChallenge],
        seedIdentities: Set<String>
    ) -> Bool {
        let grouped = Dictionary(grouping: existingChallenges) { seedIdentity(for: $0) }
        let duplicateGroups = grouped
            .filter { seedIdentities.contains($0.key) && $0.value.count > 1 }
            .map(\.value)

        guard !duplicateGroups.isEmpty else { return false }

        var duplicateToCanonicalID: [UUID: UUID] = [:]
        var duplicatesToDelete: [ReadingChallenge] = []

        for group in duplicateGroups {
            let sorted = group.sorted {
                if $0.createdDate != $1.createdDate {
                    return $0.createdDate < $1.createdDate
                }

                return $0.id.uuidString < $1.id.uuidString
            }

            guard let canonical = sorted.first else { continue }

            for duplicate in sorted.dropFirst() {
                duplicateToCanonicalID[duplicate.id] = canonical.id
                duplicatesToDelete.append(duplicate)
            }
        }

        guard !duplicateToCanonicalID.isEmpty else { return false }

        let entryDescriptor = FetchDescriptor<ChallengeEntry>()
        let entries = (try? modelContext.fetch(entryDescriptor)) ?? []
        for entry in entries {
            if let canonicalID = duplicateToCanonicalID[entry.challengeID] {
                entry.challengeID = canonicalID
            }
        }

        let submissionDescriptor = FetchDescriptor<ChallengeSubmission>()
        let submissions = (try? modelContext.fetch(submissionDescriptor)) ?? []
        for submission in submissions {
            if let canonicalID = duplicateToCanonicalID[submission.challengeID] {
                submission.challengeID = canonicalID
            }
        }

        let bookmarkDescriptor = FetchDescriptor<ChallengeBookmark>()
        let bookmarks = (try? modelContext.fetch(bookmarkDescriptor)) ?? []
        for bookmark in bookmarks {
            if let canonicalID = duplicateToCanonicalID[bookmark.challengeID] {
                bookmark.challengeID = canonicalID
            }
        }

        for duplicate in duplicatesToDelete {
            modelContext.delete(duplicate)
        }

        return true
    }

    private func syncSeedChallenge(_ existing: ReadingChallenge, from seed: ReadingChallenge) -> Bool {
        var changed = false

        func assign<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<ReadingChallenge, T>, _ value: T) {
            if existing[keyPath: keyPath] != value {
                existing[keyPath: keyPath] = value
                changed = true
            }
        }

        assign(\.challengeDescription, seed.challengeDescription)
        assign(\.iconName, seed.iconName)
        assign(\.categoryRawValue, seed.categoryRawValue)
        assign(\.points, seed.points)
        assign(\.durationDays, seed.durationDays)
        assign(\.requirementText, seed.requirementText)
        assign(\.validationTypeRawValue, seed.validationTypeRawValue)
        assign(\.recurrenceRawValue, seed.recurrenceRawValue)
        assign(\.requiredBookCount, seed.requiredBookCount)
        assign(\.requiredPageCount, seed.requiredPageCount)
        assign(\.requiredSessionCount, seed.requiredSessionCount)
        assign(\.requiredReviewCount, seed.requiredReviewCount)
        assign(\.requiredRating, seed.requiredRating)
        assign(\.requiredGenre, seed.requiredGenre)
        assign(\.requiredTagsStorage, seed.requiredTagsStorage)
        assign(\.requiredThemesStorage, seed.requiredThemesStorage)
        assign(\.requiresAIValidation, seed.requiresAIValidation)
        assign(\.requiredSessionMinutes, seed.requiredSessionMinutes)
        assign(\.requiredWordCount, seed.requiredWordCount)
        assign(\.requiredUniqueAuthorCount, seed.requiredUniqueAuthorCount)
        assign(\.requiredSameAuthorCount, seed.requiredSameAuthorCount)
        assign(\.requiredMinPages, seed.requiredMinPages)
        assign(\.requiredMaxPages, seed.requiredMaxPages)
        assign(\.requiredDaysStreak, seed.requiredDaysStreak)
        assign(\.isFeatured, seed.isFeatured)
        assign(\.isWeekly, seed.isWeekly)
        assign(\.featuredStartDate, seed.featuredStartDate)
        assign(\.featuredEndDate, seed.featuredEndDate)

        if existing.cycleAnchorDate == nil, let seedAnchor = seed.cycleAnchorDate {
            existing.cycleAnchorDate = seedAnchor
            changed = true
        }

        return changed
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
        print("Submission photoURL:", submission.photoURL)

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
            if submission.hasPhotoProof {
                await runPhotoValidation(challenge: challenge, entry: entry, submission: submission)
                return
            }

            submission.validationStatus = .inProgress
            submission.validationMessage = message
            entry.status = .inProgress

        case .needsMoreInfo(let message):
            if submission.hasPhotoProof {
                await runPhotoValidation(challenge: challenge, entry: entry, submission: submission)
                return
            }

            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = message
            entry.status = .needsMoreInfo

        case .rejected(let message):
            if submission.hasPhotoProof {
                await runPhotoValidation(challenge: challenge, entry: entry, submission: submission)
                return
            }

            submission.validationStatus = .rejected
            submission.validationMessage = message
            entry.status = .rejected

        case .requiresAI(let preMessage):
            if submission.hasPhotoProof {
                submission.validationMessage = preMessage
                await runPhotoValidation(challenge: challenge, entry: entry, submission: submission)
                return
            }

            // Step 2: Call AI validation
            submission.validationMessage = preMessage
            await runAIValidation(challenge: challenge, entry: entry, submission: submission)
        }

        lastValidationResult = result
        try? modelContext.save()
    }

    // MARK: - Photo Validation

    private func runPhotoValidation(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) async {
        let descriptor = FetchDescriptor<Book>()
        let allBooks = (try? modelContext.fetch(descriptor)) ?? []
        let linkedBooks = allBooks.filter { submission.linkedBookIDs.contains($0.id) }

        submission.validationStatus = .validating
        submission.photoValidationStatus = .validating
        submission.photoValidationMessage = "Checking your photo proof."
        entry.status = .submitted
        try? modelContext.save()

        let packet = ChallengeAIValidationService.buildPhotoPacket(
            challenge: challenge,
            books: linkedBooks,
            submission: submission
        )

        do {
            let response = try await aiService.validatePhoto(packet: packet)
            let photoResult = validationResult(from: response)

            submission.photoValidationConfidence = response.confidence
            submission.photoValidationMessage = response.message
            submission.photoValidationJSON = encodedPhotoValidationJSON(response)

            switch photoResult {
            case .approved(let message):
                submission.photoValidationStatus = .approved
                await approveSubmission(submission, entry: entry, challenge: challenge, message: message)

            case .inProgress(let message):
                submission.photoValidationStatus = .inProgress
                submission.validationStatus = .inProgress
                submission.validationMessage = message
                entry.status = .inProgress

            case .needsMoreInfo(let message):
                submission.photoValidationStatus = .needsMoreInfo
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = message
                entry.status = .needsMoreInfo

            case .rejected(let message):
                submission.photoValidationStatus = .rejected
                submission.validationStatus = .rejected
                submission.validationMessage = message
                entry.status = .rejected

            case .requiresAI:
                submission.photoValidationStatus = .needsMoreInfo
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = "Photo validation needs a little more proof before this challenge can be approved."
                entry.status = .needsMoreInfo
            }

            lastValidationResult = photoResult
        } catch {
            submission.photoValidationStatus = .needsMoreInfo
            submission.photoValidationMessage = "Could not validate this photo right now. Please try again soon."
            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = "Could not validate this photo right now. Please try again soon."
            entry.status = .needsMoreInfo
            lastValidationResult = .needsMoreInfo("Photo validation service unavailable.")
        }

        try? modelContext.save()
    }

    private func validationResult(from response: ChallengePhotoValidationResponse) -> ChallengeValidationResult {
        switch response.status.lowercased() {
        case "approved":
            return .approved(response.message)
        case "rejected":
            return .rejected(response.message)
        default:
            return .needsMoreInfo(response.message)
        }
    }

    private func encodedPhotoValidationJSON(_ response: ChallengePhotoValidationResponse) -> String {
        guard let data = try? JSONEncoder().encode(response),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
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
            photoURL: submission.photoURL,
            validationStatus: validationStatus,
            validationMessage: submission.validationMessage,
            photoValidationStatus: submission.photoValidationStatus.rawValue,
            photoValidationMessage: submission.photoValidationMessage,
            photoValidationConfidence: submission.photoValidationConfidence,
            photoValidationJSON: submission.photoValidationJSON,
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
