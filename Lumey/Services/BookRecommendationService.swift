//
//  BookRecommendationService.swift
//  Lumey
//

import Foundation

struct LumeyBookRecommendation: Identifiable, Codable {
    let id = UUID()

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

struct LumeyBookRecommendationsResponse: Codable {
    let recs: [LumeyBookRecommendation]
    let meta: LumeyBookRecommendationsMeta?
}

struct LumeyBookRecommendationsMeta: Codable {
    let requestType: String
    let normalizedQuery: String
    let seedResolved: Bool
    let candidateGroups: [LumeyBookRecommendationCandidateGroup]
    let verifiedCandidateCount: Int
}

struct LumeyBookRecommendationCandidateGroup: Codable {
    let strategy: String
    let count: Int
}

struct LumeyBookRecommendationRequest: Codable {
    let query: String
    let desiredCount: Int
    let minVerifiedResults: Int
    let excludeBookKeys: [String]
    let readerContext: LumeyRecommendationReaderContext
}

struct LumeyRecommendationReaderContext: Codable {
    let libraryBookKeys: [String]
    let finishedBookKeys: [String]
    let ratings: [LumeyRecommendationRating]
    let readingSessions: [LumeyRecommendationReadingSession]
    let pagePreferences: LumeyRecommendationPagePreferences?
    let favoriteGenres: [String]
    let favoriteTropes: [String]
    let favoriteMoods: [String]
    let favoriteAuthors: [String]
    let favoriteTags: [String]
    let recentBookKeys: [String]
    let alreadyRecommendedBookKeys: [String]
}

struct LumeyRecommendationRating: Codable {
    let title: String
    let author: String?
    let rating: Double
}

struct LumeyRecommendationReadingSession: Codable {
    let bookKey: String
    let lastReadAt: String?
    let pagesRead: Int?
    let minutesRead: Int?
}

struct LumeyRecommendationPagePreferences: Codable {
    let preferredMinPages: Int?
    let preferredMaxPages: Int?
}

struct LumeyBookRecommendationErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum LumeyBookRecommendationServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The recommendation service URL is invalid."
        case .invalidResponse:
            return "The recommendation service returned an invalid response."
        case .serverError(_, let message):
            return message
        }
    }
}

final class LumeyBookRecommendationService {

    static let shared = LumeyBookRecommendationService()

    private init() {}

    private let baseURL = "https://appapi.voxiverse.ink"

    func fetchRecommendations(
        query: String,
        readerContext: LumeyRecommendationReaderContext,
        excludeBookKeys: [String]
    ) async throws -> LumeyBookRecommendationsResponse {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        print("Book recommendation request started")
        print("Search text:", trimmedQuery)
        print("Base URL:", baseURL)

        guard let url = URL(string: "\(baseURL)/api/books/recs") else {
            throw LumeyBookRecommendationServiceError.badURL
        }

        let body = LumeyBookRecommendationRequest(
            query: trimmedQuery,
            desiredCount: 30,
            minVerifiedResults: 12,
            excludeBookKeys: excludeBookKeys,
            readerContext: readerContext
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let rawString = String(data: data, encoding: .utf8) {
            print("Book recommendation response body:")
            print(rawString)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LumeyBookRecommendationServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(LumeyBookRecommendationErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"

            print("Book recommendation HTTP error:", httpResponse.statusCode)
            print("Book recommendation error message:", message)

            throw LumeyBookRecommendationServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        do {
            let decoded = try JSONDecoder().decode(LumeyBookRecommendationsResponse.self, from: data)
            print("Recommendations loaded:", decoded.recs.count)
            return decoded
        } catch {
            print("Book recommendation JSON decode error:", error)

            if let rawString = String(data: data, encoding: .utf8) {
                print("Failed recommendation JSON:")
                print(rawString)
            }

            throw error
        }
    }
}
