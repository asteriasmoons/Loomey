import Foundation

struct RemoteLibraryBookCover: Decodable, Identifiable {
    let id: String
    let title: String
    let author: String
    let isbns: [String]
    let edition: String?
    let imagePath: String

    var imageURL: URL? {
        URL(string: "https://appapi.voxiverse.ink\(imagePath)")
    }
}

private struct RemoteLibraryBookCoverSearchResponse: Decodable {
    let covers: [RemoteLibraryBookCover]
}

enum BookCoverLibraryError: LocalizedError {
    case invalidRequest
    case unavailable
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "Enter an ISBN or a book title and author."
        case .unavailable: return "The cover library is unavailable right now."
        case .invalidImage: return "The selected cover could not be downloaded."
        }
    }
}

final class BookCoverLibraryService {
    static let shared = BookCoverLibraryService()
    private let baseURL = "https://appapi.voxiverse.ink"
    private init() {}

    func search(isbn: String, title: String, author: String) async throws -> [RemoteLibraryBookCover] {
        let cleanISBN = isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanISBN.isEmpty || (!cleanTitle.isEmpty && !cleanAuthor.isEmpty) else {
            throw BookCoverLibraryError.invalidRequest
        }
        guard var components = URLComponents(string: "\(baseURL)/api/books/covers") else {
            throw BookCoverLibraryError.invalidRequest
        }
        components.queryItems = [
            URLQueryItem(name: "isbn", value: cleanISBN),
            URLQueryItem(name: "title", value: cleanTitle),
            URLQueryItem(name: "author", value: cleanAuthor)
        ].filter { !($0.value ?? "").isEmpty }
        guard let url = components.url else { throw BookCoverLibraryError.invalidRequest }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            throw BookCoverLibraryError.unavailable
        }
        return try JSONDecoder().decode(RemoteLibraryBookCoverSearchResponse.self, from: data).covers
    }

    func imageData(for cover: RemoteLibraryBookCover) async throws -> Data {
        guard let url = cover.imageURL else { throw BookCoverLibraryError.invalidImage }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              !data.isEmpty else { throw BookCoverLibraryError.invalidImage }
        return data
    }
}
