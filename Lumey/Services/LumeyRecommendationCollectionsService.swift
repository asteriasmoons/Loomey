//
//  LumeyRecommendationCollectionsService.swift
//  Lumey
//

import Foundation

struct LumeyRecommendationCollectionsResponse: Codable {
    let collections: [LumeyRecommendationCollection]
}

struct LumeyRecommendationCollection: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let reason: String
    let bookCount: Int?
    let books: [LumeyRecommendationCollectionBook]
    let previewCoverUrls: [String]
}

struct LumeyRecommendationCollectionBook: Identifiable, Codable {
    var id: String {
        "\(title.lowercased())-\(author.lowercased())"
    }

    let title: String
    let author: String
    let summary: String
    let coverUrl: String?
    let pages: Int?
    let releaseYear: Int?
    let rating: Double?
    let tags: [String]?
    let genres: [String]?
    let moods: [String]?
    let tropes: [String]?
    let themes: [String]?
    let source: String?
    let strategy: String?
    let strategyLabel: String?
    let rationale: String?
    let matchScore: Int?
    let metadataScore: Int?
    let finalScore: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case author
        case summary
        case coverUrl
        case pages
        case releaseYear
        case rating
        case tags
        case genres
        case moods
        case tropes
        case themes
        case source
        case strategy
        case strategyLabel
        case rationale
        case matchScore
        case metadataScore
        case finalScore
    }
}

struct LumeyRecommendationCollectionsRequest: Codable {
    let userId: String?
    let collectionId: String?
    let desiredCollections: Int
    let booksPerCollection: Int
    let excludeBookKeys: [String]
    let readerContext: LumeyRecommendationCollectionReaderContext
}

struct LumeyRecommendationCollectionReaderContext: Codable {
    let libraryBookKeys: [String]
    let finishedBookKeys: [String]
    let currentlyReadingBookKeys: [String]
    let ratings: [LumeyRecommendationCollectionRating]
    let highestRatedBooks: [LumeyRecommendationCollectionBookSignal]
    let readingSessions: [LumeyRecommendationCollectionReadingSession]
    let pagePreferences: LumeyRecommendationCollectionPagePreferences?
    let favoriteGenres: [String]
    let favoriteSubgenres: [String]
    let favoriteTropes: [String]
    let favoriteMoods: [String]
    let favoriteThemes: [String]
    let favoriteAuthors: [String]
    let favoriteTags: [String]
    let recentBookKeys: [String]
    let alreadyRecommendedBookKeys: [String]
    let readingGoals: [LumeyRecommendationCollectionGoalSignal]
    let readingStats: LumeyRecommendationCollectionStatsSignal?
    let challengeParticipation: LumeyRecommendationCollectionChallengeSignal?
}

struct LumeyRecommendationCollectionRating: Codable {
    let title: String
    let author: String?
    let rating: Double
}

struct LumeyRecommendationCollectionBookSignal: Codable {
    let title: String
    let author: String?
    let rating: Double?
    let genres: [String]
    let moods: [String]
    let tropes: [String]
    let tags: [String]
    let seriesName: String?
}

struct LumeyRecommendationCollectionReadingSession: Codable {
    let bookKey: String
    let lastReadAt: String?
    let pagesRead: Int?
    let minutesRead: Int?
}

struct LumeyRecommendationCollectionPagePreferences: Codable {
    let preferredMinPages: Int?
    let preferredMaxPages: Int?
}

struct LumeyRecommendationCollectionGoalSignal: Codable {
    let title: String
    let type: String
    let cadence: String?
    let progressPercent: Double?
    let targetGenre: String?
    let targetSubgenre: String?
    let targetAuthorName: String?
    let linkedGenres: [String]
    let linkedTags: [String]
}

struct LumeyRecommendationCollectionStatsSignal: Codable {
    let currentReadingStreak: Int?
    let bestReadingStreak: Int?
    let totalBooksFinished: Int?
    let totalPagesRead: Int?
    let totalMinutesRead: Int?
    let booksFinishedThisYear: Int?
    let pagesReadThisYear: Int?
    let averagePagesPerSession: Double?
    let averageMinutesPerSession: Double?
    let favoriteGenre: String?
    let favoriteAuthor: String?
}

struct LumeyRecommendationCollectionChallengeSignal: Codable {
    let activeCount: Int?
    let completedCount: Int?
    let recentChallengeTitles: [String]
    let preferredChallengeThemes: [String]
}

struct LumeyRecommendationCollectionErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum LumeyRecommendationCollectionsServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The recommendation collections service URL is invalid."
        case .invalidResponse:
            return "The recommendation collections service returned an invalid response."
        case .serverError(_, let message):
            return message
        }
    }
}

final class LumeyRecommendationCollectionsService {

    static let shared = LumeyRecommendationCollectionsService()

    private init() {}

    private let baseURL = "https://appapi.voxiverse.ink"

    func fetchRecommendationCollectionSummaries(
        userID: String?,
        readerContext: LumeyRecommendationCollectionReaderContext,
        excludeBookKeys: [String]
    ) async throws -> LumeyRecommendationCollectionsResponse {
        try await fetchRecommendationCollections(
            userID: userID,
            collectionID: nil,
            readerContext: readerContext,
            excludeBookKeys: excludeBookKeys
        )
    }

    func fetchRecommendationCollection(
        id collectionID: String,
        userID: String?,
        readerContext: LumeyRecommendationCollectionReaderContext,
        excludeBookKeys: [String]
    ) async throws -> LumeyRecommendationCollection? {
        let response = try await fetchRecommendationCollections(
            userID: userID,
            collectionID: collectionID,
            readerContext: readerContext,
            excludeBookKeys: excludeBookKeys
        )

        return response.collections.first
    }

    private func fetchRecommendationCollections(
        userID: String?,
        collectionID: String?,
        readerContext: LumeyRecommendationCollectionReaderContext,
        excludeBookKeys: [String]
    ) async throws -> LumeyRecommendationCollectionsResponse {
        guard let url = URL(string: "\(baseURL)/api/books/recommendation-collections") else {
            throw LumeyRecommendationCollectionsServiceError.badURL
        }

        let body = LumeyRecommendationCollectionsRequest(
            userId: userID,
            collectionId: collectionID,
            desiredCollections: 5,
            booksPerCollection: 15,
            excludeBookKeys: excludeBookKeys,
            readerContext: readerContext
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LumeyRecommendationCollectionsServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(LumeyRecommendationCollectionErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"

            throw LumeyRecommendationCollectionsServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(LumeyRecommendationCollectionsResponse.self, from: data)
    }
}
