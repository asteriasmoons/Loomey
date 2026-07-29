//
//  RecommendationBookDetailService.swift
//  Lumey
//

import Foundation

struct RecommendationBookDetailRequest: Codable {
    let title: String
    let author: String
    let summary: String?
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
    let strategyLabel: String?
    let rationale: String?
}

struct RecommendationBookDetail: Codable, Identifiable {
    var id: String {
        "\(title.lowercased())-\(author.lowercased())"
    }

    let title: String
    let author: String
    let subtitle: String?
    let publisher: String?
    let publicationYear: Int?
    let isbn: String?
    let summary: String
    let coverUrl: String?
    let pages: Int?
    let rating: Double?
    let genres: [String]
    let subgenres: [String]
    let moods: [String]
    let tags: [String]
    let tropes: [String]
    let themes: [String]
    let tone: String?
    let pacing: String?
    let audience: String?
    let romanceLevel: String?
    let darknessLevel: String?
    let source: String
}

struct RecommendationBookDetailErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum RecommendationBookDetailServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The recommendation book detail service URL is invalid."
        case .invalidResponse:
            return "The recommendation book detail service returned an invalid response."
        case .serverError(_, let message):
            return message
        }
    }
}

final class RecommendationBookDetailService {
    static let shared = RecommendationBookDetailService()

    private init() {}

    private let baseURL = "https://appapi.voxiverse.ink"

    func fetchDetail(for book: LumeyRecommendationCollectionBook) async throws -> RecommendationBookDetail {
        guard let url = URL(string: "\(baseURL)/api/books/recommendation-book-detail") else {
            throw RecommendationBookDetailServiceError.badURL
        }

        let body = RecommendationBookDetailRequest(
            title: book.title,
            author: book.author,
            summary: book.summary,
            coverUrl: book.coverUrl,
            pages: book.pages,
            releaseYear: book.releaseYear,
            rating: book.rating,
            tags: book.tags,
            genres: book.genres,
            moods: book.moods,
            tropes: book.tropes,
            themes: book.themes,
            source: book.source,
            strategyLabel: book.strategyLabel,
            rationale: book.rationale
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecommendationBookDetailServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(RecommendationBookDetailErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"

            throw RecommendationBookDetailServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(RecommendationBookDetail.self, from: data)
    }
}
