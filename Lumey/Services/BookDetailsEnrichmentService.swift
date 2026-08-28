//
//  BookDetailsEnrichmentService.swift
//  Lumey
//

import Foundation

struct BookDetailsEnrichmentRequest: Codable {
    let title: String
    let author: String
}

struct BookDetailsEnrichmentResponse: Codable {
    let subtitle: String?
    let seriesName: String?
    let seriesNumber: String?
    let publisher: String?
    let publicationYear: String?
    let isbn: String?
    let summary: String?
    let totalPages: Int?
    let ebookTotalPages: Int?
    let totalChapters: Int?
    let genres: [String]
    let moods: [String]
    let topics: [String]
    let tags: [String]
    let tropes: [String]
    let classification: String
    let source: String
}

private struct BookDetailsEnrichmentErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum BookDetailsEnrichmentError: LocalizedError {
    case badURL
    case missingIdentity
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The book details service URL is invalid."
        case .missingIdentity:
            return "Enter a title and author before getting details."
        case .invalidResponse:
            return "Lumey received an invalid book details response."
        case .serverError(_, let message):
            return message
        case .decodingError:
            return "Lumey could not read the book details response."
        }
    }
}

final class BookDetailsEnrichmentService {
    static let shared = BookDetailsEnrichmentService()

    private let baseURL = "https://appapi.voxiverse.ink"

    private init() {}

    func enrich(title: String, author: String) async throws -> BookDetailsEnrichmentResponse {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedAuthor.isEmpty else {
            throw BookDetailsEnrichmentError.missingIdentity
        }

        guard let url = URL(string: "\(baseURL)/api/books/enrich-details") else {
            throw BookDetailsEnrichmentError.badURL
        }

        print("[BookDetailsEnrichmentService] sending request", [
            "title": trimmedTitle,
            "author": trimmedAuthor
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            BookDetailsEnrichmentRequest(title: trimmedTitle, author: trimmedAuthor)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookDetailsEnrichmentError.invalidResponse
        }

        print("[BookDetailsEnrichmentService] response status", httpResponse.statusCode)
        if let bodyText = String(data: data, encoding: .utf8) {
            print("[BookDetailsEnrichmentService] response body", bodyText)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(
                BookDetailsEnrichmentErrorResponse.self,
                from: data
            )
            let message = backendError?.detail
                ?? backendError?.error
                ?? "Lumey could not find confident details for that book."
            throw BookDetailsEnrichmentError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        do {
            return try JSONDecoder().decode(BookDetailsEnrichmentResponse.self, from: data)
        } catch {
            throw BookDetailsEnrichmentError.decodingError
        }
    }
}
