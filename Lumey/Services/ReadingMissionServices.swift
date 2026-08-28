//
//  ReadingMissionServices.swift
//  Lumey
//

import Foundation
import SwiftData

struct ReadingMissionBookContext: Codable {
    let title: String
    let author: String
    let synopsis: String
    let genres: [String]
    let tags: [String]
    let pageCount: Int
    let seriesName: String
    let seriesNumber: String
}

struct GeneratedReadingMissionTask: Codable, Identifiable {
    var id: String { "\(category)-\(title)" }
    let title: String
    let description: String
    let category: String
    let difficulty: String
}

struct ReadingMissionAIRequest: Codable {
    let book: ReadingMissionBookContext
}

struct ReadingMissionAIResponse: Codable {
    let missions: [GeneratedReadingMissionTask]
}

struct ReadingMissionScorePrompt: Codable {
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let answer: String
}

struct ReadingMissionScoreRequest: Codable {
    let book: ReadingMissionBookContext
    let prompts: [ReadingMissionScorePrompt]
}

struct ReadingMissionPromptScoreResponse: Codable {
    let title: String
    let score: Int
    let feedback: String
}

struct ReadingMissionScoreResponse: Codable {
    let overallScore: Int
    let ratingLabel: String
    let summary: String
    let strengths: [String]
    let nextStep: String
    let promptScores: [ReadingMissionPromptScoreResponse]
}

struct ReadingMissionErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum ReadingMissionAIServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case invalidMissionCount
    case invalidMissionScore
    case missingMissionAnswers

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The reading mission service URL is invalid."
        case .invalidResponse:
            return "The reading mission service returned an invalid response."
        case .serverError(_, let message):
            return message
        case .invalidMissionCount:
            return "Loomey could not create four reading missions for that book."
        case .invalidMissionScore:
            return "Loomey could not score those mission answers."
        case .missingMissionAnswers:
            return "Answer all four mission prompts before scoring."
        }
    }
}

final class ReadingMissionAIService {
    static let shared = ReadingMissionAIService()

    private let baseURL = "https://appapi.voxiverse.ink"

    private init() {}

    func generateMissions(for bookContext: ReadingMissionBookContext) async throws -> [GeneratedReadingMissionTask] {
        guard let url = URL(string: "\(baseURL)/api/lumey/reading-missions/generate") else {
            throw ReadingMissionAIServiceError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ReadingMissionAIRequest(book: bookContext))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadingMissionAIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(ReadingMissionErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"
            throw ReadingMissionAIServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(ReadingMissionAIResponse.self, from: data)
        guard decoded.missions.count == 4 else {
            throw ReadingMissionAIServiceError.invalidMissionCount
        }

        return decoded.missions
    }

    func scoreMission(
        bookContext: ReadingMissionBookContext,
        prompts: [ReadingMissionScorePrompt]
    ) async throws -> ReadingMissionScoreResponse {
        guard prompts.count == 4,
              prompts.allSatisfy({ !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else {
            throw ReadingMissionAIServiceError.missingMissionAnswers
        }

        guard let url = URL(string: "\(baseURL)/api/lumey/reading-missions/score") else {
            throw ReadingMissionAIServiceError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ReadingMissionScoreRequest(book: bookContext, prompts: prompts))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadingMissionAIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(ReadingMissionErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"
            throw ReadingMissionAIServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(ReadingMissionScoreResponse.self, from: data)
        guard decoded.promptScores.count == 4 else {
            throw ReadingMissionAIServiceError.invalidMissionScore
        }

        return decoded
    }
}

enum ReadingMissionGeneratorError: LocalizedError {
    case noEligibleBooks
    case selectedBookUnavailable
    case missingGeneratedTasks

    var errorDescription: String? {
        switch self {
        case .noEligibleBooks:
            return "No books match those mission filters."
        case .selectedBookUnavailable:
            return "Choose a book from your Reading list to create a mission."
        case .missingGeneratedTasks:
            return "Loomey did not receive four usable mission cards."
        }
    }
}

enum ReadingMissionGenerator {
    static func eligibleBooks(from books: [Book], criteria: ReadingMissionFilterCriteria) -> [Book] {
        let activeKinds = criteria.activeKinds
        let isEntireLibrary = activeKinds.contains(.entireLibrary) || activeKinds.isEmpty

        return books
            .filter { !$0.isArchived }
            .filter { book in
                guard !isEntireLibrary else { return true }

                let selectedStatuses = statusFilters(from: activeKinds)
                if !selectedStatuses.isEmpty {
                    let matchesStatus = selectedStatuses.contains(book.status)
                    let matchesUnread = activeKinds.contains(.unreadBooks) && book.status != .finished && book.status != .didNotFinish
                    guard matchesStatus || matchesUnread else { return false }
                }

                let selectedFormats = formatFilters(from: activeKinds)
                if !selectedFormats.isEmpty, !selectedFormats.contains(book.format) {
                    return false
                }

                if activeKinds.contains(.genre), !criteria.genres.isEmpty {
                    guard intersects(book.genres, criteria.genres) else { return false }
                }

                if activeKinds.contains(.author), !criteria.authors.isEmpty {
                    let author = book.displayAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard criteria.authors.contains(where: { $0.localizedCaseInsensitiveCompare(author) == .orderedSame }) else {
                        return false
                    }
                }

                if activeKinds.contains(.tags), !criteria.tags.isEmpty {
                    guard intersects(book.tags, criteria.tags) else { return false }
                }

                if activeKinds.contains(.rating), book.rating < Double(criteria.minimumRating) {
                    return false
                }

                let wantsStandalone = activeKinds.contains(.standaloneBooks)
                let wantsSeries = activeKinds.contains(.seriesBooks)
                if wantsStandalone != wantsSeries {
                    let hasSeries = !book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if wantsStandalone && hasSeries { return false }
                    if wantsSeries && !hasSeries { return false }
                }

                return true
            }
    }

    @MainActor
    static func generateMission(
        from books: [Book],
        criteria: ReadingMissionFilterCriteria,
        userID: String,
        modelContext: ModelContext,
        aiService: ReadingMissionAIService
    ) async throws -> ReadingMission {
        let eligible = eligibleBooks(from: books, criteria: criteria)
        guard let selectedBook = eligible.randomElement() else {
            throw ReadingMissionGeneratorError.noEligibleBooks
        }

        return try await createMission(
            for: selectedBook,
            criteria: criteria,
            userID: userID,
            modelContext: modelContext,
            aiService: aiService
        )
    }

    @MainActor
    static func generateMission(
        for selectedBook: Book,
        userID: String,
        modelContext: ModelContext,
        aiService: ReadingMissionAIService
    ) async throws -> ReadingMission {
        guard !selectedBook.isArchived, selectedBook.status == .reading else {
            throw ReadingMissionGeneratorError.selectedBookUnavailable
        }

        var criteria = ReadingMissionFilterCriteria()
        criteria.activeKinds = [.reading]

        return try await createMission(
            for: selectedBook,
            criteria: criteria,
            userID: userID,
            modelContext: modelContext,
            aiService: aiService
        )
    }

    @MainActor
    private static func createMission(
        for selectedBook: Book,
        criteria: ReadingMissionFilterCriteria,
        userID: String,
        modelContext: ModelContext,
        aiService: ReadingMissionAIService
    ) async throws -> ReadingMission {
        let context = bookContext(for: selectedBook)
        let generatedTasks = try await aiService.generateMissions(for: context)
        guard generatedTasks.count == 4 else {
            throw ReadingMissionGeneratorError.missingGeneratedTasks
        }

        let now = Date()
        let mission = ReadingMission(
            userID: userID,
            bookID: selectedBook.id,
            bookTitle: selectedBook.displayTitle,
            bookAuthor: selectedBook.displayAuthor,
            bookSynopsis: context.synopsis,
            bookGenres: context.genres,
            bookTags: context.tags,
            bookPageCount: context.pageCount,
            bookSeriesName: context.seriesName,
            bookSeriesNumber: context.seriesNumber,
            bookCoverURL: selectedBook.coverURL,
            bookCoverColorHex: selectedBook.coverColorHex,
            bookAccentColorHex: selectedBook.accentColorHex,
            filterCriteria: criteria,
            generatedAt: now
        )
        modelContext.insert(mission)

        for (index, generatedTask) in generatedTasks.enumerated() {
            let category = ReadingMissionTaskCategory.normalized(from: generatedTask.category)
            let task = ReadingMissionTask(
                missionID: mission.id,
                title: sanitized(generatedTask.title, fallback: "Mission \(index + 1)"),
                taskDescription: sanitized(generatedTask.description, fallback: "Spend a few minutes engaging with this book from a new angle."),
                category: category,
                difficulty: sanitized(generatedTask.difficulty, fallback: "Medium"),
                sortIndex: index
            )
            modelContext.insert(task)
        }

        let history = ReadingMissionHistory(
            userID: userID,
            missionID: mission.id,
            bookID: selectedBook.id,
            bookTitle: selectedBook.displayTitle,
            bookAuthor: selectedBook.displayAuthor,
            generatedAt: now
        )
        modelContext.insert(history)

        try modelContext.save()
        return mission
    }

    static func bookContext(for book: Book) -> ReadingMissionBookContext {
        ReadingMissionBookContext(
            title: book.displayTitle,
            author: book.displayAuthor,
            synopsis: book.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            genres: book.genres,
            tags: book.tags,
            pageCount: max(book.totalPages, book.ebookTotalPages, book.currentPage),
            seriesName: book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines),
            seriesNumber: book.seriesNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func statusFilters(from kinds: Set<ReadingMissionFilterKind>) -> Set<BookStatus> {
        var statuses: Set<BookStatus> = []
        if kinds.contains(.finishedBooks) { statuses.insert(.finished) }
        if kinds.contains(.reading) { statuses.insert(.reading) }
        if kinds.contains(.tbr) { statuses.insert(.toBeRead) }
        return statuses
    }

    private static func formatFilters(from kinds: Set<ReadingMissionFilterKind>) -> Set<BookFormat> {
        var formats: Set<BookFormat> = []
        if kinds.contains(.physicalBooks) { formats.insert(.physical) }
        if kinds.contains(.ebooks) { formats.insert(.ebook) }
        if kinds.contains(.audiobooks) { formats.insert(.audiobook) }
        return formats
    }

    private static func intersects(_ lhs: [String], _ rhs: [String]) -> Bool {
        let lhsValues = Set(lhs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })
        return rhs.contains { lhsValues.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
    }

    private static func sanitized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

enum ReadingMissionCompletionService {
    static let completionPoints = 100

    @discardableResult
    static func completeIfNeeded(
        mission: ReadingMission,
        tasks: [ReadingMissionTask],
        modelContext: ModelContext
    ) -> Bool {
        guard !mission.isCompleted,
              tasks.count == 4,
              tasks.allSatisfy(\.isCompleted),
              tasks.allSatisfy({ !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else {
            return false
        }

        let now = Date()
        mission.status = .completed
        mission.completedAt = now
        mission.pointsAwarded = completionPoints
        mission.xpAwarded = ReadingXPService.awardReadingMissionCompletion(mission, modelContext: modelContext)
        mission.updatedAt = now

        let histories = (try? modelContext.fetch(FetchDescriptor<ReadingMissionHistory>())) ?? []
        if let history = histories.first(where: { $0.missionID == mission.id && $0.eventType == .completed }) {
            history.completedAt = now
            history.durationSeconds = now.timeIntervalSince(mission.generatedAt)
            history.isCompleted = true
            history.eventType = .completed
            history.updatedAt = now
        } else {
            modelContext.insert(
                ReadingMissionHistory(
                    userID: mission.userID,
                    missionID: mission.id,
                    bookID: mission.bookID,
                    bookTitle: mission.bookTitle,
                    bookAuthor: mission.bookAuthor,
                    eventType: .completed,
                    generatedAt: mission.generatedAt,
                    completedAt: now,
                    durationSeconds: now.timeIntervalSince(mission.generatedAt),
                    isCompleted: true
                )
            )
        }

        try? modelContext.save()
        return true
    }
}

enum ReadingMissionScoringService {
    @MainActor
    static func scoreMission(
        mission: ReadingMission,
        tasks: [ReadingMissionTask],
        book: Book?,
        modelContext: ModelContext,
        aiService: ReadingMissionAIService
    ) async throws -> ReadingMissionScoreResponse {
        let sortedTasks = tasks.sorted { $0.sortIndex < $1.sortIndex }
        let prompts = sortedTasks.map { task in
            ReadingMissionScorePrompt(
                title: task.title,
                description: task.taskDescription,
                category: task.categoryRawValue,
                difficulty: task.difficulty,
                answer: task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        guard prompts.count == 4,
              prompts.allSatisfy({ !$0.answer.isEmpty })
        else {
            throw ReadingMissionAIServiceError.missingMissionAnswers
        }

        let bookContext: ReadingMissionBookContext
        if let book {
            bookContext = ReadingMissionGenerator.bookContext(for: book)
        } else {
            bookContext = ReadingMissionBookContext(
                title: mission.bookTitle,
                author: mission.bookAuthor,
                synopsis: mission.bookSynopsis,
                genres: mission.bookGenres,
                tags: mission.bookTags,
                pageCount: mission.bookPageCount,
                seriesName: mission.bookSeriesName,
                seriesNumber: mission.bookSeriesNumber
            )
        }

        let score = try await aiService.scoreMission(
            bookContext: bookContext,
            prompts: prompts
        )

        let now = Date()
        mission.score = score.overallScore
        mission.scoreLabel = score.ratingLabel
        mission.scoreSummary = score.summary
        mission.scoreStrengths = score.strengths
        mission.scoreNextStep = score.nextStep
        mission.scoredAt = now
        mission.updatedAt = now

        for (index, task) in sortedTasks.enumerated() {
            let promptScore = score.promptScores[index]
            task.aiScore = promptScore.score
            task.aiFeedback = promptScore.feedback
            task.scoredAt = now
            task.updatedAt = now
        }

        let histories = (try? modelContext.fetch(FetchDescriptor<ReadingMissionHistory>())) ?? []
        if let history = histories.first(where: { $0.missionID == mission.id && $0.eventType == .scored }) {
            history.scoredAt = now
            history.score = score.overallScore
            history.scoreLabel = score.ratingLabel
            history.scoreSummary = score.summary
            history.updatedAt = now
        } else {
            modelContext.insert(
                ReadingMissionHistory(
                    userID: mission.userID,
                    missionID: mission.id,
                    bookID: mission.bookID,
                    bookTitle: mission.bookTitle,
                    bookAuthor: mission.bookAuthor,
                    eventType: .scored,
                    generatedAt: mission.generatedAt,
                    scoredAt: now,
                    score: score.overallScore,
                    scoreLabel: score.ratingLabel,
                    scoreSummary: score.summary
                )
            )
        }

        try modelContext.save()
        return score
    }
}

struct ReadingMissionStatsSummary {
    let missionsGenerated: Int
    let missionsCompleted: Int
    let completionPercentage: Double
    let averageCompletionTimeSeconds: Double
    let favoriteMissionCategory: String
    let currentMissionStreak: Int
    let longestMissionStreak: Int
}

enum ReadingMissionStatsCalculator {
    static func summary(missions: [ReadingMission], tasks: [ReadingMissionTask]) -> ReadingMissionStatsSummary {
        let completedMissions = missions.filter(\.isCompleted)
        let completionPercentage = missions.isEmpty ? 0 : Double(completedMissions.count) / Double(missions.count)

        let durations = completedMissions.compactMap { mission -> Double? in
            guard let completedAt = mission.completedAt else { return nil }
            return max(completedAt.timeIntervalSince(mission.generatedAt), 0)
        }

        let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        let favoriteCategory = favoriteCategory(from: tasks.filter(\.isCompleted))
        let streaks = missionStreaks(from: completedMissions.compactMap(\.completedAt))

        return ReadingMissionStatsSummary(
            missionsGenerated: missions.count,
            missionsCompleted: completedMissions.count,
            completionPercentage: completionPercentage,
            averageCompletionTimeSeconds: averageDuration,
            favoriteMissionCategory: favoriteCategory,
            currentMissionStreak: streaks.current,
            longestMissionStreak: streaks.longest
        )
    }

    static func formattedDuration(seconds: Double) -> String {
        guard seconds > 0 else { return "Not enough data yet" }

        let days = Int(seconds / 86_400)
        if days >= 1 {
            return days == 1 ? "1 day" : "\(days) days"
        }

        let hours = Int(seconds / 3_600)
        if hours >= 1 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }

        let minutes = max(Int(seconds / 60), 1)
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    private static func favoriteCategory(from tasks: [ReadingMissionTask]) -> String {
        guard !tasks.isEmpty else { return "Not enough data yet" }
        let grouped = Dictionary(grouping: tasks) { $0.categoryRawValue }
        return grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.key > rhs.key
            }
            return lhs.value.count < rhs.value.count
        }?.key ?? "Not enough data yet"
    }

    private static func missionStreaks(from dates: [Date]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let uniqueDays = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
        guard !uniqueDays.isEmpty else { return (0, 0) }

        var longest = 1
        var run = 1
        for index in uniqueDays.indices.dropFirst() {
            let previous = uniqueDays[index - 1]
            let current = uniqueDays[index]
            let expected = calendar.date(byAdding: .day, value: 1, to: previous) ?? previous
            if calendar.isDate(current, inSameDayAs: expected) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        guard let last = uniqueDays.last,
              calendar.isDate(last, inSameDayAs: today) || calendar.isDate(last, inSameDayAs: yesterday)
        else {
            return (0, longest)
        }

        var current = 1
        var cursor = last
        while let previous = calendar.date(byAdding: .day, value: -1, to: cursor),
              uniqueDays.contains(where: { calendar.isDate($0, inSameDayAs: previous) }) {
            current += 1
            cursor = previous
        }

        return (current, longest)
    }
}
