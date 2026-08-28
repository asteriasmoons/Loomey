//
//  ReadingInsightReviewService.swift
//  Lumey
//

import Foundation

struct ReadingInsightGeneratedReviewResponse: Codable {
    let title: String
    let content: String
}

private struct ReadingInsightReviewRequest: Codable {
    let book: ReadingInsightReviewBookContext
    let insights: [ReadingInsightReviewInsightContext]
}

private struct ReadingInsightReviewBookContext: Codable {
    let title: String
    let author: String
    let subtitle: String?
    let genres: [String]
    let moods: [String]
    let topics: [String]
    let tags: [String]
    let tropes: [String]
    let rating: Double?
}

private struct ReadingInsightReviewInsightContext: Codable {
    let dateCreated: String
    let sessionDate: String?
    let sessionMinutes: Int?
    let sessionPages: Int?
    let whatHappened: String
    let whatStoodOut: String
    let howIFeel: String
    let predictions: String
    let favoriteMoment: String
    let favoriteQuote: String
    let aiSummary: String
}

private struct ReadingInsightReviewErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum ReadingInsightReviewServiceError: LocalizedError {
    case badURL
    case noInsights
    case invalidResponse
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The reading insights service URL is invalid."
        case .noInsights:
            return "Add at least one insight before creating a review."
        case .invalidResponse:
            return "Lumey received an invalid review response."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Lumey could not read the generated review."
        }
    }
}

final class ReadingInsightReviewService {
    static let shared = ReadingInsightReviewService()

    private let baseURL = "https://appapi.voxiverse.ink"
    private let isoFormatter = ISO8601DateFormatter()

    private init() {}

    func generateReview(book: Book, insights: [ReadingInsight]) async throws -> ReadingInsightGeneratedReviewResponse {
        let sortedInsights = insights.sorted { $0.dateCreated < $1.dateCreated }
        guard !sortedInsights.isEmpty else {
            throw ReadingInsightReviewServiceError.noInsights
        }

        guard let url = URL(string: "\(baseURL)/api/lumey/reading-insights/generate-review") else {
            throw ReadingInsightReviewServiceError.badURL
        }

        let payload = ReadingInsightReviewRequest(
            book: ReadingInsightReviewBookContext(
                title: book.title,
                author: book.author,
                subtitle: emptyToNil(book.subtitle),
                genres: book.genres,
                moods: book.moods,
                topics: book.topics,
                tags: book.tags,
                tropes: book.tropes,
                rating: book.rating > 0 ? book.rating : nil
            ),
            insights: sortedInsights.map { insight in
                ReadingInsightReviewInsightContext(
                    dateCreated: isoFormatter.string(from: insight.dateCreated),
                    sessionDate: insight.session.map { isoFormatter.string(from: $0.date) },
                    sessionMinutes: insight.session?.durationMinutes,
                    sessionPages: insight.session?.pagesRead,
                    whatHappened: insight.whatHappened,
                    whatStoodOut: insight.whatStoodOut,
                    howIFeel: insight.howIFeel,
                    predictions: insight.predictions,
                    favoriteMoment: insight.favoriteMoment,
                    favoriteQuote: insight.favoriteQuote,
                    aiSummary: insight.aiSummary
                )
            }
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadingInsightReviewServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(ReadingInsightReviewErrorResponse.self, from: data)
            throw ReadingInsightReviewServiceError.serverError(
                backendError?.detail
                    ?? backendError?.error
                    ?? "Lumey could not create a review from those insights."
            )
        }

        do {
            return try JSONDecoder().decode(ReadingInsightGeneratedReviewResponse.self, from: data)
        } catch {
            throw ReadingInsightReviewServiceError.decodingError
        }
    }

    private func emptyToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
