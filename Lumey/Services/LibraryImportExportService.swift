//
//  LibraryImportExportService.swift
//  Lumey
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var lumeyCSV: UTType {
        UTType(filenameExtension: "csv") ?? .plainText
    }
}

enum LibraryImportSource {
    static let goodreads = "Goodreads"
}

struct BookDuplicateMatch: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let reason: String
}

struct GoodreadsBookDraft: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let publisher: String
    let publicationYear: String
    let isbn: String
    let rating: Double
    let status: BookStatus
    let format: BookFormat
    let totalPages: Int
    let review: String
    let privateNotes: String
    let tags: [String]
    let dateAdded: Date
    let dateFinished: Date?
    let isFavorite: Bool
    let isReread: Bool

    func makeBook(batchID: String, importedAt: Date) -> Book {
        Book(
            title: title,
            author: author,
            publisher: publisher,
            publicationYear: publicationYear,
            isbn: isbn,
            rating: rating,
            status: status,
            format: format,
            ownership: .unknown,
            totalPages: totalPages,
            tags: tags,
            dateAdded: dateAdded,
            dateFinished: status == .finished ? dateFinished : nil,
            importSource: LibraryImportSource.goodreads,
            importBatchID: batchID,
            importedAt: importedAt,
            isFavorite: isFavorite,
            isReread: isReread
        )
    }
}

struct GoodreadsImportCandidate: Identifiable {
    let id = UUID()
    let rowNumber: Int
    let draft: GoodreadsBookDraft
    let duplicateMatches: [BookDuplicateMatch]

    var isLikelyDuplicate: Bool {
        !duplicateMatches.isEmpty
    }
}

struct GoodreadsImportPreview: Identifiable {
    let id: String
    let importedAt: Date
    let candidates: [GoodreadsImportCandidate]
    let skippedInvalidRows: Int

    var defaultSelectedIDs: Set<UUID> {
        Set(candidates.filter { !$0.isLikelyDuplicate }.map(\.id))
    }

    var duplicateCount: Int {
        candidates.filter(\.isLikelyDuplicate).count
    }
}

enum LibraryImportExportError: LocalizedError {
    case unreadableFile
    case missingTitleColumn
    case emptyExport

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Loomey couldn't read that file."
        case .missingTitleColumn:
            return "That CSV does not look like a Goodreads library export."
        case .emptyExport:
            return "There are no books to export yet."
        }
    }
}

enum LibraryImportExportService {
    static func previewGoodreadsImport(from url: URL, existingBooks: [Book]) throws -> GoodreadsImportPreview {
        let csv = try readCSVString(from: url)
        let rows = parseCSV(csv)

        guard let header = rows.first else {
            throw LibraryImportExportError.unreadableFile
        }

        let headerIndex = indexHeaders(header)
        guard headerIndex["title"] != nil else {
            throw LibraryImportExportError.missingTitleColumn
        }

        var candidates: [GoodreadsImportCandidate] = []
        var previousDrafts: [GoodreadsBookDraft] = []
        var skippedInvalidRows = 0

        for (offset, row) in rows.dropFirst().enumerated() {
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                continue
            }

            guard let draft = goodreadsDraft(from: row, headerIndex: headerIndex) else {
                skippedInvalidRows += 1
                continue
            }

            let matches = duplicateMatches(for: draft, existingBooks: existingBooks, previousDrafts: previousDrafts)
            candidates.append(
                GoodreadsImportCandidate(
                    rowNumber: offset + 2,
                    draft: draft,
                    duplicateMatches: matches
                )
            )
            previousDrafts.append(draft)
        }

        return GoodreadsImportPreview(
            id: UUID().uuidString,
            importedAt: Date(),
            candidates: candidates,
            skippedInvalidRows: skippedInvalidRows
        )
    }

    static func likelyLegacyGoodreadsImportedBooks(from books: [Book], now: Date = Date()) -> [Book] {
        books
            .filter { book in
                guard book.deletedAt == nil,
                      book.importSource.isEmpty,
                      book.importBatchID.isEmpty else {
                    return false
                }

                var score = 0
                let recentImportWindow = now.addingTimeInterval(-72 * 60 * 60)

                if book.lastUpdated >= recentImportWindow {
                    score += 3
                }

                if book.ownership == .unknown {
                    score += 2
                }

                if book.notes.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Imported from Goodreads.") {
                    score += 4
                }

                if !book.tags.isEmpty {
                    score += 1
                }

                if !book.review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    score += 1
                }

                if book.dateFinished != nil || book.totalPages > 0 {
                    score += 1
                }

                return score >= 5
            }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }

    static func lumeyExportCSV(from books: [Book]) throws -> String {
        let exportBooks = books
            .filter { $0.deletedAt == nil }
            .sorted {
                $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }

        guard !exportBooks.isEmpty else {
            throw LibraryImportExportError.emptyExport
        }

        let headers = [
            "Title",
            "Author",
            "Subtitle",
            "Series Name",
            "Series Number",
            "Publisher",
            "Publication Year",
            "ISBN",
            "Rating",
            "Status",
            "Format",
            "Ownership",
            "Current Page",
            "Total Pages",
            "Current Chapter",
            "Total Chapters",
            "Progress Percent",
            "Genres",
            "Moods",
            "Topics",
            "Tags",
            "Tropes",
            "Review",
            "Favorite Quote",
            "Notes",
            "Cover URL",
            "Date Added",
            "Date Started",
            "Date Finished",
            "Import Source",
            "Import Batch ID",
            "Imported At",
            "Is Favorite",
            "Is Archived",
            "Is DNF",
            "Is Reread"
        ]

        var lines = [csvLine(headers)]

        for book in exportBooks {
            lines.append(csvLine([
                book.title,
                book.author,
                book.subtitle,
                book.seriesName,
                book.seriesNumber,
                book.publisher,
                book.publicationYear,
                book.isbn,
                decimalString(book.rating),
                book.status.rawValue,
                book.format.rawValue,
                book.ownership.rawValue,
                String(book.currentPage),
                String(book.totalPages),
                String(book.currentChapter),
                String(book.totalChapters),
                decimalString(book.progressPercent),
                book.genres.joined(separator: ", "),
                book.moods.joined(separator: ", "),
                book.topics.joined(separator: ", "),
                book.tags.joined(separator: ", "),
                book.tropes.joined(separator: ", "),
                book.review,
                book.favoriteQuote,
                book.notes,
                book.coverURL,
                exportDateFormatter.string(from: book.dateAdded),
                book.dateStarted.map(exportDateFormatter.string(from:)) ?? "",
                book.dateFinished.map(exportDateFormatter.string(from:)) ?? "",
                book.importSource,
                book.importBatchID,
                book.importedAt.map(exportDateFormatter.string(from:)) ?? "",
                book.isFavorite ? "true" : "false",
                book.isArchived ? "true" : "false",
                book.isDNF ? "true" : "false",
                book.isReread ? "true" : "false"
            ]))
        }

        return lines.joined(separator: "\n")
    }

    private static func readCSVString(from url: URL) throws -> String {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)

        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }

        throw LibraryImportExportError.unreadableFile
    }

    private static func goodreadsDraft(from row: [String], headerIndex: [String: Int]) -> GoodreadsBookDraft? {
        let title = value(["title"], in: row, headerIndex: headerIndex)
        guard !title.isEmpty else { return nil }

        let isbn13 = cleanedISBN(value(["isbn13"], in: row, headerIndex: headerIndex))
        let isbn = isbn13.isEmpty ? cleanedISBN(value(["isbn"], in: row, headerIndex: headerIndex)) : isbn13
        let exclusiveShelf = value(["exclusive shelf"], in: row, headerIndex: headerIndex)
        let shelves = shelfValues(from: value(["bookshelves"], in: row, headerIndex: headerIndex))
        let tags = shelves.filter { !isStatusShelf($0) }
        let readCount = intValue(value(["read count"], in: row, headerIndex: headerIndex))

        return GoodreadsBookDraft(
            title: title,
            author: value(["author", "author l f"], in: row, headerIndex: headerIndex),
            publisher: value(["publisher"], in: row, headerIndex: headerIndex),
            publicationYear: value(["year published", "original publication year"], in: row, headerIndex: headerIndex),
            isbn: isbn,
            rating: ratingValue(value(["my rating"], in: row, headerIndex: headerIndex)),
            status: statusFromGoodreadsShelf(exclusiveShelf),
            format: formatFromBinding(value(["binding"], in: row, headerIndex: headerIndex)),
            totalPages: intValue(value(["number of pages"], in: row, headerIndex: headerIndex)),
            review: value(["my review"], in: row, headerIndex: headerIndex),
            privateNotes: value(["private notes"], in: row, headerIndex: headerIndex),
            tags: tags,
            dateAdded: dateValue(value(["date added"], in: row, headerIndex: headerIndex)) ?? Date(),
            dateFinished: dateValue(value(["date read"], in: row, headerIndex: headerIndex)),
            isFavorite: tags.contains { $0.localizedCaseInsensitiveContains("favorite") },
            isReread: readCount > 1
        )
    }

    private static func duplicateMatches(
        for draft: GoodreadsBookDraft,
        existingBooks: [Book],
        previousDrafts: [GoodreadsBookDraft]
    ) -> [BookDuplicateMatch] {
        let draftIdentity = BookIdentity(draft)
        var matches: [BookDuplicateMatch] = []

        for book in existingBooks where book.deletedAt == nil {
            let identity = BookIdentity(book)

            if let reason = duplicateReason(candidate: draftIdentity, existing: identity) {
                matches.append(
                    BookDuplicateMatch(
                        title: book.displayTitle,
                        author: book.displayAuthor,
                        reason: reason
                    )
                )
            }
        }

        for previousDraft in previousDrafts {
            let identity = BookIdentity(previousDraft)

            if let reason = duplicateReason(candidate: draftIdentity, existing: identity) {
                matches.append(
                    BookDuplicateMatch(
                        title: previousDraft.title,
                        author: previousDraft.author.isEmpty ? "Unknown Author" : previousDraft.author,
                        reason: "Duplicate row in this CSV: \(reason)"
                    )
                )
            }
        }

        return matches
    }

    private static func duplicateReason(candidate: BookIdentity, existing: BookIdentity) -> String? {
        if !candidate.isbns.isDisjoint(with: existing.isbns) {
            return "Matching ISBN"
        }

        guard !candidate.titleBase.isEmpty, !existing.titleBase.isEmpty else {
            return nil
        }

        let authorsMatch = !candidate.author.isEmpty && candidate.author == existing.author
        let authorsLooseMatch = !candidate.authorLoose.isEmpty && candidate.authorLoose == existing.authorLoose

        if authorsMatch && candidate.titleFull == existing.titleFull {
            return "Matching title and author"
        }

        if authorsMatch && candidate.titleBase == existing.titleBase {
            return "Matching base title and author"
        }

        if authorsLooseMatch && candidate.titleBase == existing.titleBase {
            return "Matching base title and author name"
        }

        if authorsLooseMatch && titleSimilarity(candidate.titleBase, existing.titleBase) >= 0.90 {
            return "Very similar title and matching author"
        }

        if candidate.titleBase == existing.titleBase,
           candidate.author.isEmpty || existing.author.isEmpty {
            return "Matching title"
        }

        return nil
    }

    static func existingBookMatching(
        title: String,
        author: String,
        isbn: String = "",
        in existingBooks: [Book]
    ) -> Book? {
        let candidateIdentity = BookIdentity(title: title, author: author, isbn: isbn)

        return existingBooks.first { book in
            guard book.deletedAt == nil, !book.isArchived else { return false }
            return duplicateReason(candidate: candidateIdentity, existing: BookIdentity(book)) != nil
        }
    }

    private static func indexHeaders(_ header: [String]) -> [String: Int] {
        var index: [String: Int] = [:]

        for (offset, rawHeader) in header.enumerated() {
            let key = normalizedHeader(rawHeader)
            if !key.isEmpty {
                index[key] = offset
            }
        }

        return index
    }

    private static func normalizedHeader(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{feff}", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func value(_ keys: [String], in row: [String], headerIndex: [String: Int]) -> String {
        for key in keys {
            guard let index = headerIndex[normalizedHeader(key)], index < row.count else { continue }
            let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                return value
            }
        }

        return ""
    }

    private static func parseCSV(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let characters = Array(csv)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                if inQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if character == ",", !inQuotes {
                row.append(field)
                field = ""
            } else if (character == "\n" || character == "\r"), !inQuotes {
                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }

                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }

            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func cleanedISBN(_ value: String) -> String {
        value
            .uppercased()
            .filter { $0.isNumber || $0 == "X" }
    }

    private static func shelfValues(from value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func isStatusShelf(_ value: String) -> Bool {
        let shelf = value.lowercased()
        return shelf == "read" || shelf == "currently-reading" || shelf == "currently reading" || shelf == "to-read" || shelf == "to read"
    }

    private static func statusFromGoodreadsShelf(_ value: String) -> BookStatus {
        let shelf = value.lowercased()

        if shelf == "read" {
            return .finished
        }

        if shelf == "currently-reading" || shelf == "currently reading" {
            return .reading
        }

        return .toBeRead
    }

    private static func formatFromBinding(_ value: String) -> BookFormat {
        let binding = value.lowercased()

        if binding.contains("kindle") || binding.contains("ebook") || binding.contains("nook") {
            return .ebook
        }

        if binding.contains("audio") {
            return .audiobook
        }

        if binding.contains("library") {
            return .library
        }

        if binding.contains("hardcover") || binding.contains("paperback") || binding.contains("mass market") {
            return .physical
        }

        return .other
    }

    private static func intValue(_ value: String) -> Int {
        Int(value.filter { $0.isNumber }) ?? 0
    }

    private static func ratingValue(_ value: String) -> Double {
        guard let rating = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return 0
        }

        return min(max(rating, 0), 5)
    }

    private static func dateValue(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for formatter in importDateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    private static func isbnVariants(_ value: String) -> Set<String> {
        let isbn = cleanedISBN(value)
        guard !isbn.isEmpty else { return [] }

        var variants: Set<String> = [isbn]

        if isbn.count == 13,
           isbn.hasPrefix("978"),
           let isbn10 = convertISBN13ToISBN10(isbn) {
            variants.insert(isbn10)
        }

        if isbn.count == 10,
           let isbn13 = convertISBN10ToISBN13(isbn) {
            variants.insert(isbn13)
        }

        return variants
    }

    private static func convertISBN13ToISBN10(_ isbn13: String) -> String? {
        guard isbn13.count == 13, isbn13.hasPrefix("978") else { return nil }
        let bodyStart = isbn13.index(isbn13.startIndex, offsetBy: 3)
        let bodyEnd = isbn13.index(isbn13.startIndex, offsetBy: 12)
        let body = String(isbn13[bodyStart..<bodyEnd])
        guard body.allSatisfy(\.isNumber) else { return nil }

        var sum = 0
        for (index, character) in body.enumerated() {
            guard let digit = character.wholeNumberValue else { return nil }
            sum += (10 - index) * digit
        }

        let remainder = 11 - (sum % 11)
        let check: String

        if remainder == 10 {
            check = "X"
        } else if remainder == 11 {
            check = "0"
        } else {
            check = String(remainder)
        }

        return body + check
    }

    private static func convertISBN10ToISBN13(_ isbn10: String) -> String? {
        guard isbn10.count == 10 else { return nil }
        let body = "978" + isbn10.prefix(9)
        guard body.allSatisfy(\.isNumber) else { return nil }

        var sum = 0
        for (index, character) in body.enumerated() {
            guard let digit = character.wholeNumberValue else { return nil }
            sum += index.isMultiple(of: 2) ? digit : digit * 3
        }

        let check = (10 - (sum % 10)) % 10
        return body + String(check)
    }

    private static func normalizedTitle(_ value: String, stripSubtitle: Bool) -> String {
        var result = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        result = removeBracketedText(from: result)

        if stripSubtitle {
            for separator in [":", " - ", " -- ", " / "] {
                if let range = result.range(of: separator) {
                    result = String(result[..<range.lowerBound])
                }
            }
        }

        result = normalizedWordString(result)

        for article in ["the ", "a ", "an "] where result.hasPrefix(article) {
            result = String(result.dropFirst(article.count))
        }

        return result
    }

    private static func normalizedAuthor(_ value: String) -> String {
        var author = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if author.contains(",") {
            let parts = author
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            if parts.count >= 2 {
                author = parts.dropFirst().joined(separator: " ") + " " + parts[0]
            }
        }

        return normalizedWordString(author)
    }

    private static func looseAuthor(_ value: String) -> String {
        normalizedAuthor(value)
            .split(separator: " ")
            .filter { !$0.isEmpty && $0.count > 1 }
            .joined(separator: " ")
    }

    private static func removeBracketedText(from value: String) -> String {
        var result = ""
        var depth = 0

        for character in value {
            if character == "(" || character == "[" || character == "{" {
                depth += 1
                continue
            }

            if character == ")" || character == "]" || character == "}" {
                depth = max(0, depth - 1)
                continue
            }

            if depth == 0 {
                result.append(character)
            }
        }

        return result
    }

    private static func normalizedWordString(_ value: String) -> String {
        let scalars = value.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }

        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func titleSimilarity(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        if lhs == rhs { return 1 }

        let lhsTokens = Set(lhs.split(separator: " ").map(String.init))
        let rhsTokens = Set(rhs.split(separator: " ").map(String.init))
        let intersection = lhsTokens.intersection(rhsTokens).count
        let union = lhsTokens.union(rhsTokens).count
        let tokenSimilarity = union == 0 ? 0 : Double(intersection) / Double(union)
        let editSimilarity = levenshteinSimilarity(lhs, rhs)

        return max(tokenSimilarity, editSimilarity)
    }

    private static func levenshteinSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        guard !lhsChars.isEmpty, !rhsChars.isEmpty else { return 0 }

        var previous = Array(0...rhsChars.count)

        for (lhsIndex, lhsChar) in lhsChars.enumerated() {
            var current = [lhsIndex + 1]

            for (rhsIndex, rhsChar) in rhsChars.enumerated() {
                let insert = current[rhsIndex] + 1
                let delete = previous[rhsIndex + 1] + 1
                let replace = previous[rhsIndex] + (lhsChar == rhsChar ? 0 : 1)
                current.append(min(insert, delete, replace))
            }

            previous = current
        }

        let distance = previous[rhsChars.count]
        let maxLength = max(lhsChars.count, rhsChars.count)
        return 1 - (Double(distance) / Double(maxLength))
    }

    private static func csvLine(_ fields: [String]) -> String {
        fields.map(csvEscape).joined(separator: ",")
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")

        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r") {
            return "\"\(escaped)\""
        }

        return escaped
    }

    private static func decimalString(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static var importDateFormatters: [DateFormatter] {
        [
            dateFormatter("yyyy/MM/dd"),
            dateFormatter("yyyy-MM-dd"),
            dateFormatter("MM/dd/yyyy"),
            dateFormatter("M/d/yyyy"),
            dateFormatter("MMM d, yyyy"),
            dateFormatter("MMMM d, yyyy")
        ]
    }

    private static var exportDateFormatter: DateFormatter {
        dateFormatter("yyyy-MM-dd")
    }

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

private struct BookIdentity {
    let isbns: Set<String>
    let titleFull: String
    let titleBase: String
    let author: String
    let authorLoose: String

    init(_ book: Book) {
        self.isbns = LibraryImportExportService.isbnVariantsForIdentity(book.isbn)
        self.titleFull = LibraryImportExportService.normalizedTitleForIdentity(book.title, stripSubtitle: false)
        self.titleBase = LibraryImportExportService.normalizedTitleForIdentity(book.title, stripSubtitle: true)
        self.author = LibraryImportExportService.normalizedAuthorForIdentity(book.author)
        self.authorLoose = LibraryImportExportService.looseAuthorForIdentity(book.author)
    }

    init(_ draft: GoodreadsBookDraft) {
        self.isbns = LibraryImportExportService.isbnVariantsForIdentity(draft.isbn)
        self.titleFull = LibraryImportExportService.normalizedTitleForIdentity(draft.title, stripSubtitle: false)
        self.titleBase = LibraryImportExportService.normalizedTitleForIdentity(draft.title, stripSubtitle: true)
        self.author = LibraryImportExportService.normalizedAuthorForIdentity(draft.author)
        self.authorLoose = LibraryImportExportService.looseAuthorForIdentity(draft.author)
    }

    init(title: String, author: String, isbn: String) {
        self.isbns = LibraryImportExportService.isbnVariantsForIdentity(isbn)
        self.titleFull = LibraryImportExportService.normalizedTitleForIdentity(title, stripSubtitle: false)
        self.titleBase = LibraryImportExportService.normalizedTitleForIdentity(title, stripSubtitle: true)
        self.author = LibraryImportExportService.normalizedAuthorForIdentity(author)
        self.authorLoose = LibraryImportExportService.looseAuthorForIdentity(author)
    }
}

extension LibraryImportExportService {
    static func isbnVariantsForIdentity(_ value: String) -> Set<String> {
        isbnVariants(value)
    }

    static func normalizedTitleForIdentity(_ value: String, stripSubtitle: Bool) -> String {
        normalizedTitle(value, stripSubtitle: stripSubtitle)
    }

    static func normalizedAuthorForIdentity(_ value: String) -> String {
        normalizedAuthor(value)
    }

    static func looseAuthorForIdentity(_ value: String) -> String {
        looseAuthor(value)
    }
}
