//
//  RegularRecBookSummaryService.swift
//  Lumey
//
//  On-demand "Get Details" summary for a single regular recommendation.
//  Calls the Cerebras-backed /api/books/recs-book-summary endpoint.
//

import Foundation

struct RegularRecBookSummaryRequest: Codable {
    let title: String
    let author: String
    let summary: String?
    let rationale: String?
    let strategyLabel: String?
    let genres: [String]?
    let moods: [String]?
    let tropes: [String]?
    let themes: [String]?
    let tags: [String]?
    let pages: Int?
    let releaseYear: Int?
    let rating: Double?
    let source: String?
}

struct RegularRecBookSummaryResponse: Codable {
    let summary: String
}

struct RegularRecBookSummaryErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum RegularRecBookSummaryServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The book summary service URL is invalid."
        case .invalidResponse:
            return "The book summary service returned an invalid response."
        case .serverError(_, let message):
            return message
        }
    }
}

final class RegularRecBookSummaryService {
    static let shared = RegularRecBookSummaryService()

    private init() {}

    private let baseURL = "https://appapi.voxiverse.ink"

    func fetchSummary(for book: LumeyBookRecommendation) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/books/recs-book-summary") else {
            throw RegularRecBookSummaryServiceError.badURL
        }

        let trimmedSummary = book.summary.trimmingCharacters(in: .whitespacesAndNewlines)

        let body = RegularRecBookSummaryRequest(
            title: book.title,
            author: book.author,
            summary: trimmedSummary.isEmpty ? nil : book.summary,
            rationale: book.rationale,
            strategyLabel: book.strategyLabel,
            genres: book.genres,
            moods: book.moods,
            tropes: book.tropes,
            themes: book.themes,
            tags: book.tags,
            pages: book.pages,
            releaseYear: book.releaseYear,
            rating: book.rating,
            source: book.source
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegularRecBookSummaryServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(RegularRecBookSummaryErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"

            throw RegularRecBookSummaryServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(RegularRecBookSummaryResponse.self, from: data).summary
    }
}
