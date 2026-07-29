//
//  BookSearchService.swift
//  Lumey
//

import Foundation

// MARK: - Models

struct BookSearchResult: Codable, Identifiable, Hashable {
    let id = UUID()

    let title: String
    let author: String
    let summary: String

    let coverUrl: String?
    let pages: Int?
    let releaseYear: Int?
    let rating: Double?
    let publisher: String?
    let isbn: String?
    let tags: [String]?

    let source: String

    enum CodingKeys: String, CodingKey {
        case title
        case author
        case summary
        case coverUrl
        case pages
        case releaseYear
        case rating
        case publisher
        case isbn
        case tags
        case source
    }
}

struct BookSearchResponse: Codable {
    let books: [BookSearchResult]
}

// MARK: - Errors

enum BookSearchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case emptyQuery

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"

        case .invalidResponse:
            return "Invalid response"

        case .serverError(let code):
            return "Server returned status code \(code)"

        case .decodingError:
            return "Failed to decode response"

        case .emptyQuery:
            return "Search query is empty"
        }
    }
}

// MARK: - Service

final class BookSearchService {

    static let shared = BookSearchService()

    private init() {}

    private let baseURL = "https://appapi.voxiverse.ink"

    func searchBooks(query: String) async throws -> [BookSearchResult] {

        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            throw BookSearchError.emptyQuery
        }

        guard let url = URL(
            string: "\(baseURL)/api/books/search"
        ) else {
            throw BookSearchError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "query": trimmedQuery
            ]
        )

        print("📚 Book Search Started")
        print("📚 Query: \(trimmedQuery)")
        print("📚 URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookSearchError.invalidResponse
        }

        let rawBody = String(
            data: data,
            encoding: .utf8
        ) ?? "Unable to decode body"

        print("📚 Search Response:")
        print(rawBody)

        guard (200...299).contains(httpResponse.statusCode) else {

            print("❌ HTTP Error: \(httpResponse.statusCode)")
            print(rawBody)

            throw BookSearchError.serverError(
                httpResponse.statusCode
            )
        }

        do {

            let decoded = try JSONDecoder().decode(
                BookSearchResponse.self,
                from: data
            )

            print("✅ Books Found: \(decoded.books.count)")

            return decoded.books

        } catch {

            print("❌ Decoding Error")
            print(error)

            throw BookSearchError.decodingError
        }
    }
}
