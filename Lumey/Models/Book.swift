//
//  Book.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Book Model

@Model
final class Book {
    var id: UUID = UUID()
    
    // Basic Info
    var title: String = ""
    var author: String = ""
    var subtitle: String = ""
    var seriesName: String = ""
    var seriesNumber: String = ""
    var publisher: String = ""
    var publicationYear: String = ""
    var isbn: String = ""
    var summary: String = ""
    var rating: Double = 0
    
    // Reading Status
    var statusRawValue: String = BookStatus.toBeRead.rawValue
    var formatRawValue: String = BookFormat.physical.rawValue
    var ownershipRawValue: String = BookOwnership.owned.rawValue
    
    // Progress
    var currentPage: Int = 0
    var totalPages: Int = 0
    var currentChapter: Int = 0
    var totalChapters: Int = 0
    var progressPercent: Double = 0
    var ebookTotalPages: Int = 0
    var ebookCurrentPage: Int = 0
    
    // EPUB Reader
    @Attribute(.externalStorage)
    var epubBookmarkData: Data?

    @Attribute(.externalStorage)
    var epubFileData: Data?

    var epubOriginalFileName: String = ""
    var epubReaderLocation: String = ""
    var epubLastOpenedAt: Date?
    
    // Ratings & Review
    var spiceRating: Double = 0
    var emotionalRating: Double = 0
    var review: String = ""
    var favoriteQuote: String = ""
    
    // Notes & Metadata
    var notes: String = ""
    var genresStorage: String = "[]"
    var moodsStorage: String = "[]"
    var tagsStorage: String = "[]"
    var tropesStorage: String = "[]"
    var topicsStorage: String = "[]"
    var customFilterIDsStorage: String = "[]"
    
    // Cover / Visuals
    @Attribute(.externalStorage)
    var coverImageData: Data?

    var coverURL: String = ""
    var coverColorHex: String = "#03DBFC"
    var accentColorHex: String = "#7D19F7"
    
    // Tracking
    var dateAdded: Date = Date()
    var dateStarted: Date?
    var dateFinished: Date?
    var updatedAt: Date = Date()
    var deletedAt: Date?
    var lastUpdated: Date = Date()
    var importSource: String = ""
    var importBatchID: String = ""
    var importedAt: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \BookNote.book)
    var bookNotes: [BookNote]? = []

    @Relationship(deleteRule: .cascade, inverse: \BookQuote.book)
    var bookQuotes: [BookQuote]? = []

    @Relationship(deleteRule: .cascade, inverse: \BookReview.book)
    var bookReviews: [BookReview]? = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingInsight.book)
    var insights: [ReadingInsight]? = []

    // Flags
    var isFavorite: Bool = false
    var isArchived: Bool = false
    var isDNF: Bool = false
    var isReread: Bool = false
    
    init(
        title: String = "",
        author: String = "",
        subtitle: String = "",
        seriesName: String = "",
        seriesNumber: String = "",
        publisher: String = "",
        publicationYear: String = "",
        isbn: String = "",
        summary: String = "",
        rating: Double = 0,
        status: BookStatus = .toBeRead,
        format: BookFormat = .physical,
        ownership: BookOwnership = .owned,
        currentPage: Int = 0,
        totalPages: Int = 0,
        currentChapter: Int = 0,
        totalChapters: Int = 0,
        progressPercent: Double = 0,
        ebookTotalPages: Int = 0,
        ebookCurrentPage: Int = 0,
        epubBookmarkData: Data? = nil,
        epubOriginalFileName: String = "",
        epubReaderLocation: String = "",
        epubLastOpenedAt: Date? = nil,
        spiceRating: Double = 0,
        emotionalRating: Double = 0,
        review: String = "",
        favoriteQuote: String = "",
        notes: String = "",
        genres: [String] = [],
        moods: [String] = [],
        tags: [String] = [],
        tropes: [String] = [],
        topics: [String] = [],
        customFilterIDs: [UUID] = [],
        coverImageData: Data? = nil,
        coverURL: String = "",
        coverColorHex: String = "#03DBFC",
        accentColorHex: String = "#7D19F7",
        dateAdded: Date = Date(),
        dateStarted: Date? = nil,
        dateFinished: Date? = nil,
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        importSource: String = "",
        importBatchID: String = "",
        importedAt: Date? = nil,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        isDNF: Bool = false,
        isReread: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.subtitle = subtitle
        self.seriesName = seriesName
        self.seriesNumber = seriesNumber
        self.publisher = publisher
        self.publicationYear = publicationYear
        self.isbn = isbn
        self.summary = summary
        self.rating = rating
        
        self.statusRawValue = status.rawValue
        self.formatRawValue = format.rawValue
        self.ownershipRawValue = ownership.rawValue
        
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.currentChapter = currentChapter
        self.totalChapters = totalChapters
        self.progressPercent = progressPercent
        self.ebookTotalPages = ebookTotalPages
        self.ebookCurrentPage = ebookCurrentPage
        self.epubBookmarkData = epubBookmarkData
        self.epubOriginalFileName = epubOriginalFileName
        self.epubReaderLocation = epubReaderLocation
        self.epubLastOpenedAt = epubLastOpenedAt
        self.spiceRating = spiceRating
        self.emotionalRating = emotionalRating
        self.review = review
        self.favoriteQuote = favoriteQuote
        
        self.notes = notes
        self.genres = genres
        self.moods = moods
        self.tags = tags
        self.tropes = tropes
        self.topics = topics
        self.customFilterIDs = customFilterIDs
        
        self.coverImageData = coverImageData
        self.coverURL = coverURL
        self.coverColorHex = coverColorHex
        self.accentColorHex = accentColorHex
        
        self.dateAdded = dateAdded
        self.dateStarted = dateStarted
        self.dateFinished = dateFinished
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.lastUpdated = Date()
        self.importSource = importSource
        self.importBatchID = importBatchID
        self.importedAt = importedAt
        
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.isDNF = isDNF
        self.isReread = isReread
    }
}

// MARK: - Computed Properties

extension Book {
    var status: BookStatus {
        get { BookStatus(rawValue: statusRawValue) ?? .toBeRead }
        set {
            statusRawValue = newValue.rawValue
            lastUpdated = Date()
        }
    }
    
    var format: BookFormat {
        get { BookFormat(rawValue: formatRawValue) ?? .physical }
        set {
            formatRawValue = newValue.rawValue
            lastUpdated = Date()
        }
    }
    
    var ownership: BookOwnership {
        get { BookOwnership(rawValue: ownershipRawValue) ?? .owned }
        set {
            ownershipRawValue = newValue.rawValue
            lastUpdated = Date()
        }
    }
    
    var genres: [String] {
        get { decodeStringArray(from: genresStorage) }
        set {
            genresStorage = encodeStringArray(newValue)
            lastUpdated = Date()
        }
    }

    var moods: [String] {
        get { decodeStringArray(from: moodsStorage) }
        set {
            moodsStorage = encodeStringArray(newValue)
            lastUpdated = Date()
        }
    }
    
    var tags: [String] {
        get { decodeStringArray(from: tagsStorage) }
        set {
            tagsStorage = encodeStringArray(newValue)
            lastUpdated = Date()
        }
    }
    
    var tropes: [String] {
        get { decodeStringArray(from: tropesStorage) }
        set {
            tropesStorage = encodeStringArray(newValue)
            lastUpdated = Date()
        }
    }

    var topics: [String] {
        get { decodeStringArray(from: topicsStorage) }
        set {
            topicsStorage = encodeStringArray(newValue)
            lastUpdated = Date()
        }
    }

    var customFilterIDs: [UUID] {
        get { decodeUUIDArray(from: customFilterIDsStorage) }
        set {
            customFilterIDsStorage = encodeUUIDArray(newValue)
            lastUpdated = Date()
        }
    }
    
    var displayTitle: String {
        title.isEmpty ? "Untitled Book" : title
    }
    
    var displayAuthor: String {
        author.isEmpty ? "Unknown Author" : author
    }
    
    var progressText: String {
        if canConvertEbookPages {
            let physicalEquiv = convertedPhysicalPage(from: ebookCurrentPage)
            return "\(physicalEquiv) / \(totalPages) pages (ebook pg \(ebookCurrentPage))"
        } else if totalPages > 0 {
            return "\(currentPage) / \(totalPages) pages"
        } else if totalChapters > 0 {
            return "\(currentChapter) / \(totalChapters) chapters"
        } else {
            return "\(Int(progressPercent))%"
        }
    }
    
    var calculatedProgress: Double {
        if canConvertEbookPages {
            return min(Double(ebookCurrentPage) / Double(ebookTotalPages), 1)
        } else if totalPages > 0 {
            return min(Double(currentPage) / Double(totalPages), 1)
        } else if totalChapters > 0 {
            return min(Double(currentChapter) / Double(totalChapters), 1)
        } else {
            return min(progressPercent / 100, 1)
        }
    }
    
    var isCompleted: Bool {
        status == .finished
    }

    /// Whether the ebook-to-physical page conversion is available
    var canConvertEbookPages: Bool {
        format == .ebook && ebookTotalPages > 0 && totalPages > 0
    }

    /// Converts an ebook page number to its physical equivalent
    func convertedPhysicalPage(from ebookPage: Int) -> Int {
        guard ebookTotalPages > 0, totalPages > 0 else { return ebookPage }
        let ratio = Double(ebookPage) / Double(ebookTotalPages)
        return min(Int(round(ratio * Double(totalPages))), totalPages)
    }

    var hasEPUB: Bool {
        epubFileData != nil || epubBookmarkData != nil
    }
}

// MARK: - Helpers

extension Book {
    func updateProgress(currentPage: Int? = nil, currentChapter: Int? = nil, progressPercent: Double? = nil, ebookCurrentPage: Int? = nil) {
        if let ebookCurrentPage {
            self.ebookCurrentPage = max(0, ebookCurrentPage)
            if canConvertEbookPages {
                self.currentPage = convertedPhysicalPage(from: self.ebookCurrentPage)
            }
        }

        if let currentPage {
            self.currentPage = max(0, currentPage)
        }
        
        if let currentChapter {
            self.currentChapter = max(0, currentChapter)
        }
        
        if let progressPercent {
            self.progressPercent = min(max(progressPercent, 0), 100)
        }
        
        if status == .toBeRead {
            markStarted()
        }
        
        if calculatedProgress >= 1 {
            markFinished()
        }
        
        lastUpdated = Date()
    }

    func updateStatus(to newStatus: BookStatus) {
        switch newStatus {
        case .toBeRead:
            status = .toBeRead
            isDNF = false
            dateFinished = nil
            touch()
        case .reading:
            markStarted()
        case .finished:
            markFinished()
        case .paused:
            markPaused()
        case .didNotFinish:
            markDNF()
        }
    }
    
    func markStarted() {
        status = .reading
        if dateStarted == nil {
            dateStarted = Date()
        }
        dateFinished = nil
        isDNF = false
        touch()
    }

    func markPaused() {
        status = .paused
        if dateStarted == nil {
            dateStarted = Date()
        }
        dateFinished = nil
        isDNF = false
        touch()
    }
    
    func markFinished() {
        status = .finished
        dateFinished = Date()
        isDNF = false
        progressPercent = 100
        
        if totalPages > 0 {
            currentPage = totalPages
        }
        
        if totalChapters > 0 {
            currentChapter = totalChapters
        }

        if ebookTotalPages > 0 {
            ebookCurrentPage = ebookTotalPages
        }
        
        touch()
    }
    
    func markDNF() {
        status = .didNotFinish
        isDNF = true
        dateFinished = nil
        touch()
    }

    private func touch() {
        let now = Date()
        updatedAt = now
        lastUpdated = now
    }
    
    private func decodeStringArray(from storage: String) -> [String] {
        guard let data = storage.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
    
    private func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        
        return string
    }

    private func decodeUUIDArray(from storage: String) -> [UUID] {
        guard let data = storage.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
    }

    private func encodeUUIDArray(_ values: [UUID]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return string
    }
}

// MARK: - Book Status

enum BookStatus: String, Codable, CaseIterable, Identifiable {
    case toBeRead = "To Be Read"
    case reading = "Reading"
    case finished = "Finished"
    case paused = "Paused"
    case didNotFinish = "Did Not Finish"
    
    var id: String { rawValue }
}

// MARK: - Book Format

enum BookFormat: String, Codable, CaseIterable, Identifiable {
    case physical = "Physical"
    case ebook = "Ebook"
    case audiobook = "Audiobook"
    case library = "Library"
    case other = "Other"
    
    var id: String { rawValue }
}

// MARK: - Book Ownership

enum BookOwnership: String, Codable, CaseIterable, Identifiable {
    case owned = "Owned"
    case borrowed = "Borrowed"
    case library = "Library"
    case wishlist = "Wishlist"
    case preorder = "Preorder"
    case unknown = "Unknown"
    
    var id: String { rawValue }
}
