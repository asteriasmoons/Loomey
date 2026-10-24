import Foundation

struct AutomaticCatalogLibraryBook: Codable, Equatable {
    let id: String
    let title: String
    let author: String
    let isbn: String
    let genres: [String]
    let subjects: [String]
    let rating: Double
    let favorite: Bool
    let status: String
    let activity: Int
    var providerBookID: String? = nil
    var seriesName: String? = nil
    var seriesNumber: String? = nil
    var subtitle: String? = nil
}

struct AutomaticCatalogRequest: Codable {
    let books: [AutomaticCatalogLibraryBook]
    var progressive = true
    var forceRefresh = false
    var categories: [String]? = nil
    var preferences: ReadingPreferencesConfiguration? = nil
}

enum AutomaticCatalogIdentity {
    static func normalize(_ value: String) -> String {
        value.decomposedStringWithCompatibilityMapping.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func cleanTitle(_ value: String) -> String {
        var title = value.replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
        for (entity, replacement) in ["&amp;": "&", "&quot;": "\"", "&apos;": "'", "&#39;": "'", "&nbsp;": " ", "&lt;": "<", "&gt;": ">"] {
            title = title.replacingOccurrences(of: entity, with: replacement)
        }
        title = title.replacingOccurrences(of: #"[\x00-\x1f\x7f\x{200b}-\x{200d}\x{feff}]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        let edition = #"(?:paperback|hardback|hardcover|softcover|mass.market paperback|kindle edition|ebook edition|e.book|large print|unabridged|abridged|illustrated edition|annotated edition|revised edition|updated edition|(?:\d+(?:st|nd|rd|th)|first|second|third) (?:edition|ed\.?))"#
        let annotation = "(?i)\\s*(?:\\(\(edition)\\)|\\[\(edition)\\]|(?:\\s[-:|]\\s)\(edition))\\s*$"
        for _ in 0..<3 {
            let next = title.replacingOccurrences(of: annotation, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)\s*[:|]\s*(?:a novel|a memoir)\s*$"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            if next.isEmpty || next == title { break }
            title = next
        }
        return title
    }

    static func authorKeys(_ value: String) -> Set<String> {
        func key(_ value: String) -> String { normalize(value).replacingOccurrences(of: #"\b([a-z])\s+(?=[a-z]\b)"#, with: "$1", options: .regularExpression) }
        var keys: Set<String> = [key(value)]
        let parts = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2 { keys.insert(key(parts[1] + " " + parts[0])) }
        keys.remove("")
        return keys
    }

    static func tokens(title: String, author: String, isbn value: String?, variants: [String] = [], isbns: [String] = [], authors: [String] = [], workID: String? = nil) -> Set<String> {
        var result = Set(([value ?? ""] + isbns).compactMap { isbn($0) }.map { "isbn:" + $0 })
        if let workID, !workID.isEmpty { result.insert("work:" + workID) }
        let authorValues = ([author] + authors).reduce(into: Set<String>()) { $0.formUnion(authorKeys($1)) }
        for name in [title] + variants {
            let name = normalize(cleanTitle(name))
            if !name.isEmpty { for writer in authorValues { result.insert("title:\(name)|\(writer)") } }
        }
        return result
    }

    static func tokens(_ book: AutomaticCatalogBook) -> Set<String> {
        var result = tokens(title: book.title, author: book.author, isbn: book.isbn, variants: book.titleVariants ?? [], isbns: book.isbns ?? [], authors: book.authorNames ?? [], workID: book.id)
        for (provider, ids) in book.providerIDs ?? [:] {
            for id in ids {
                result.insert("provider:\(provider):\(id)")
                if provider == "bookdatabase.io" { result.insert("work:" + id) }
            }
        }
        return result
    }

    static func tokens(_ book: AutomaticCatalogLibraryBook) -> Set<String> {
        tokens(title: book.title, author: book.author, isbn: book.isbn, workID: book.providerBookID)
    }

    static func isbn(_ value: String) -> String? {
        let normalized = value.replacingOccurrences(of: #"(?i)^\s*ISBN(?:[ -]?1[03])?:?\s*"#, with: "", options: .regularExpression).uppercased().filter { "0123456789X".contains($0) }
        if normalized.count == 13, normalized.allSatisfy(\.isNumber) {
            let sum = normalized.enumerated().reduce(0) { $0 + ($1.element.wholeNumberValue ?? 0) * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
            return sum.isMultiple(of: 10) ? normalized : nil
        }
        guard normalized.count == 10, normalized.dropLast().allSatisfy(\.isNumber) else { return nil }
        let checksum = normalized.enumerated().reduce(0) { $0 + ($1.element == "X" ? 10 : ($1.element.wholeNumberValue ?? 0)) * (10 - $1.offset) }
        guard checksum.isMultiple(of: 11) else { return nil }
        let prefix = "978" + normalized.prefix(9)
        let sum = prefix.enumerated().reduce(0) { $0 + ($1.element.wholeNumberValue ?? 0) * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return prefix + String((10 - sum % 10) % 10)
    }
}

struct AutomaticCatalogResponse: Codable {
    var catalogs: [AutomaticBookCatalog]
    let generatedAt: String
    var expiresAt: String
    var partial: Bool
    var state: String? = nil
    var errorCode: String? = nil
    var retryAfter: Int? = nil
    var traceID: String? = nil
    var refreshAfter: String? = nil
    var categoryStates: [String: AutomaticCatalogCategoryState]? = nil
    var engineVersion: String? = nil
    var disabledSources: [String]? = nil

    var expirationDate: Date {
        Self.date(expiresAt)
    }

    var refreshDate: Date { Self.date(refreshAfter ?? expiresAt) }

    static func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value) ?? .distantPast
    }

    func validated(for library: [AutomaticCatalogLibraryBook], now: Date = Date(), preferences: ReadingPreferencesConfiguration? = nil) -> AutomaticCatalogResponse {
        var result = self
        let limit = now.addingTimeInterval(engineVersion == "loomey-1" ? 7 * 86400 : 86400)
        let owned = library.reduce(into: Set<String>()) { $0.formUnion(AutomaticCatalogIdentity.tokens($1)) }
        var seen = Set<String>()
        result.catalogs = catalogs.compactMap { section in
            guard Self.date(section.expiresAt ?? expiresAt) > now else { return nil }
            var section = section
            section.expiresAt = ISO8601DateFormatter().string(from: min(Self.date(section.expiresAt ?? expiresAt), limit))
            section.books = section.books.compactMap { candidate in
                var book = candidate
                book.title = AutomaticCatalogIdentity.cleanTitle(book.title)
                book.author = book.author.trimmingCharacters(in: .whitespacesAndNewlines)
                let identity = AutomaticCatalogIdentity.tokens(book)
                guard !book.title.isEmpty, !book.author.isEmpty, book.language == "eng", !book.id.isEmpty,
                      preferences?.allows(genres: book.genres, subjects: book.subjects) ?? true,
                      book.metadataExpiresAt.map({ Self.date($0) > now }) ?? true,
                      !(disabledSources ?? []).contains(where: { book.source.contains($0) }),
                      CatalogNetworkPolicy.safeURL(book.coverUrl) != nil || (book.coverUrls ?? []).contains(where: { CatalogNetworkPolicy.safeURL($0) != nil }) || !(book.imageID ?? "").isEmpty,
                      owned.isDisjoint(with: identity), seen.isDisjoint(with: identity) else { return nil }
                seen.formUnion(identity)
                return book
            }
            return section.books.isEmpty ? nil : section
        }
        result.expiresAt = ISO8601DateFormatter().string(from: min(limit, result.catalogs.compactMap { $0.expiresAt.map { Self.date($0) } }.max() ?? expirationDate))
        return result
    }
}

struct AutomaticCatalogCategoryState: Codable {
    var state: String
    var generatedAt: String
    var refreshAfter: String
    var expiresAt: String
    var errorCode: String?
}

struct AutomaticBookCatalog: Identifiable, Codable {
    let id: String
    let title: String
    var books: [AutomaticCatalogBook]
    var generatedAt: String? = nil
    var refreshAfter: String? = nil
    var expiresAt: String? = nil
    var state: String? = nil
}

struct AutomaticCatalogBook: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var author: String
    let summary: String
    let subtitle: String?
    let isbn: String?
    let pages: Int?
    let publisher: String?
    let releaseYear: Int?
    let coverUrl: String?
    let imageID: String?
    let genres: [String]
    let subjects: [String]
    let source: String
    var language: String? = nil
    var editionID: String? = nil
    var isbns: [String]? = nil
    var titleVariants: [String]? = nil
    var authorNames: [String]? = nil
    var providerIDs: [String: [String]]? = nil
    var coverUrls: [String]? = nil
    var metadataExpiresAt: String? = nil

    var recommendationBook: LumeyRecommendationCollectionBook {
        LumeyRecommendationCollectionBook(
            title: title, author: author, summary: summary, coverUrl: coverUrl,
            pages: pages, releaseYear: releaseYear, rating: nil, tags: nil,
            genres: genres, moods: nil, tropes: nil, themes: subjects, source: source,
            strategy: nil, strategyLabel: nil, rationale: nil,
            matchScore: nil, metadataScore: nil, finalScore: nil
        )
    }

    var recommendationDetail: RecommendationBookDetail {
        RecommendationBookDetail(
            title: title, author: author, subtitle: subtitle, publisher: publisher,
            publicationYear: releaseYear, isbn: isbn, summary: summary,
            coverUrl: coverUrl, pages: pages, rating: nil, genres: genres,
            subgenres: [], moods: [], tags: [], tropes: [], themes: subjects,
            tone: nil, pacing: nil, audience: nil, romanceLevel: nil,
            darknessLevel: nil, source: source
        )
    }
}
