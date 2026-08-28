//
//  ReadingMission.swift
//  Lumey
//

import Foundation
import SwiftData

enum ReadingMissionStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case completed = "Completed"

    var id: String { rawValue }
}

enum ReadingMissionHistoryType: String, Codable, CaseIterable, Identifiable {
    case generated = "Generated"
    case scored = "Scored"
    case completed = "Completed"

    var id: String { rawValue }
}

enum ReadingMissionTaskCategory: String, Codable, CaseIterable, Identifiable {
    case reflection = "Reflection"
    case prediction = "Prediction"
    case observation = "Observation"
    case characterAnalysis = "Character Analysis"
    case themeExploration = "Theme Exploration"
    case symbolism = "Symbolism"
    case quotes = "Quotes"
    case creativity = "Creativity"
    case discussion = "Discussion"
    case emotionalReflection = "Emotional Reflection"
    case worldbuilding = "Worldbuilding"
    case curiosity = "Curiosity"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .reflection:
            return "pagepencil"
        case .prediction:
            return "sparkletimeglass"
        case .observation:
            return "searchsparkle"
        case .characterAnalysis:
            return "bookchat"
        case .themeExploration:
            return "sparklybook"
        case .symbolism:
            return "wand"
        case .quotes:
            return "quote"
        case .creativity:
            return "sparklebrush"
        case .discussion:
            return "chatsparkle"
        case .emotionalReflection:
            return "heartfill"
        case .worldbuilding:
            return "galaxysparkle"
        case .curiosity:
            return "sparklesearch"
        }
    }

    static func normalized(from value: String) -> ReadingMissionTaskCategory {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCases.first {
            $0.rawValue.lowercased() == cleaned ||
            $0.rawValue.replacingOccurrences(of: " ", with: "").lowercased() == cleaned.replacingOccurrences(of: " ", with: "")
        } ?? .reflection
    }
}

enum ReadingMissionFilterKind: String, Codable, CaseIterable, Identifiable {
    case entireLibrary = "Entire Library"
    case unreadBooks = "Unread Books"
    case finishedBooks = "Finished Books"
    case reading = "Reading"
    case tbr = "TBR"
    case physicalBooks = "Physical Books"
    case ebooks = "Ebooks"
    case audiobooks = "Audiobooks"
    case genre = "Genre"
    case author = "Author"
    case tags = "Tags"
    case rating = "Rating"
    case standaloneBooks = "Standalone Books"
    case seriesBooks = "Series Books"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .entireLibrary:
            return "books"
        case .unreadBooks:
            return "blankpages"
        case .finishedBooks:
            return "checkwavy"
        case .reading:
            return "openbook"
        case .tbr:
            return "bookstack"
        case .physicalBooks:
            return "flatbook"
        case .ebooks:
            return "linedpages"
        case .audiobooks:
            return "bookchat"
        case .genre:
            return "sparklybook"
        case .author:
            return "starmark"
        case .tags:
            return "tagsparkle"
        case .rating:
            return "starfill"
        case .standaloneBooks:
            return "starbook"
        case .seriesBooks:
            return "bookstack"
        }
    }
}

struct ReadingMissionFilterCriteria: Codable, Equatable {
    var kindRawValues: [String] = [ReadingMissionFilterKind.entireLibrary.rawValue]
    var genres: [String] = []
    var authors: [String] = []
    var tags: [String] = []
    var minimumRating: Int = 4

    var activeKinds: Set<ReadingMissionFilterKind> {
        get {
            let values = kindRawValues.compactMap(ReadingMissionFilterKind.init(rawValue:))
            return Set(values.isEmpty ? [.entireLibrary] : values)
        }
        set {
            let ordered = ReadingMissionFilterKind.allCases.filter { newValue.contains($0) }
            kindRawValues = ordered.map(\.rawValue)
        }
    }

    static let entireLibrary = ReadingMissionFilterCriteria()
}

@Model
final class ReadingMission {
    var id: UUID = UUID()
    var userID: String = "local-user"
    var bookID: UUID?
    var bookTitle: String = ""
    var bookAuthor: String = ""
    var bookSynopsis: String = ""
    var bookGenresJSON: String = "[]"
    var bookTagsJSON: String = "[]"
    var bookPageCount: Int = 0
    var bookSeriesName: String = ""
    var bookSeriesNumber: String = ""
    var bookCoverURL: String = ""
    var bookCoverColorHex: String = "#03DBFC"
    var bookAccentColorHex: String = "#7D19F7"
    var statusRawValue: String = ReadingMissionStatus.active.rawValue
    var filterCriteriaJSON: String = "{}"
    var generatedAt: Date = Date()
    var completedAt: Date?
    var scoredAt: Date?
    var score: Int = 0
    var scoreLabel: String = ""
    var scoreSummary: String = ""
    var scoreStrengthsJSON: String = "[]"
    var scoreNextStep: String = ""
    var pointsAwarded: Int = 0
    var xpAwarded: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        userID: String = "local-user",
        bookID: UUID? = nil,
        bookTitle: String = "",
        bookAuthor: String = "",
        bookSynopsis: String = "",
        bookGenres: [String] = [],
        bookTags: [String] = [],
        bookPageCount: Int = 0,
        bookSeriesName: String = "",
        bookSeriesNumber: String = "",
        bookCoverURL: String = "",
        bookCoverColorHex: String = "#03DBFC",
        bookAccentColorHex: String = "#7D19F7",
        status: ReadingMissionStatus = .active,
        filterCriteria: ReadingMissionFilterCriteria = .entireLibrary,
        generatedAt: Date = Date(),
        completedAt: Date? = nil,
        pointsAwarded: Int = 0,
        xpAwarded: Int = 0
    ) {
        self.id = UUID()
        self.userID = userID
        self.bookID = bookID
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.bookSynopsis = bookSynopsis
        self.bookGenres = bookGenres
        self.bookTags = bookTags
        self.bookPageCount = bookPageCount
        self.bookSeriesName = bookSeriesName
        self.bookSeriesNumber = bookSeriesNumber
        self.bookCoverURL = bookCoverURL
        self.bookCoverColorHex = bookCoverColorHex
        self.bookAccentColorHex = bookAccentColorHex
        self.statusRawValue = status.rawValue
        self.filterCriteria = filterCriteria
        self.generatedAt = generatedAt
        self.completedAt = completedAt
        self.pointsAwarded = pointsAwarded
        self.xpAwarded = xpAwarded
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension ReadingMission {
    var status: ReadingMissionStatus {
        get { ReadingMissionStatus(rawValue: statusRawValue) ?? .active }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var filterCriteria: ReadingMissionFilterCriteria {
        get {
            guard let data = filterCriteriaJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(ReadingMissionFilterCriteria.self, from: data)
            else {
                return .entireLibrary
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let string = String(data: data, encoding: .utf8)
            else {
                filterCriteriaJSON = "{}"
                return
            }
            filterCriteriaJSON = string
            updatedAt = Date()
        }
    }

    var isCompleted: Bool {
        status == .completed || completedAt != nil
    }

    var bookGenres: [String] {
        get {
            guard let data = bookGenresJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else {
                return []
            }
            return decoded
        }
        set {
            bookGenresJSON = Self.encodeStringArray(newValue)
            updatedAt = Date()
        }
    }

    var bookTags: [String] {
        get {
            guard let data = bookTagsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else {
                return []
            }
            return decoded
        }
        set {
            bookTagsJSON = Self.encodeStringArray(newValue)
            updatedAt = Date()
        }
    }

    var hasScore: Bool {
        score > 0 || scoredAt != nil
    }

    var scoreStrengths: [String] {
        get {
            guard let data = scoreStrengthsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else {
                return []
            }
            return decoded
        }
        set {
            let cleaned = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard let data = try? JSONEncoder().encode(cleaned),
                  let string = String(data: data, encoding: .utf8)
            else {
                scoreStrengthsJSON = "[]"
                return
            }
            scoreStrengthsJSON = string
            updatedAt = Date()
        }
    }

    private static func encodeStringArray(_ values: [String]) -> String {
        let cleaned = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let data = try? JSONEncoder().encode(cleaned),
              let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }
}

@Model
final class ReadingMissionTask {
    var id: UUID = UUID()
    var missionID: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    var categoryRawValue: String = ReadingMissionTaskCategory.reflection.rawValue
    var difficulty: String = "Medium"
    var iconName: String = ReadingMissionTaskCategory.reflection.iconName
    var sortIndex: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var notes: String = ""
    var aiScore: Int = 0
    var aiFeedback: String = ""
    var scoredAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        missionID: UUID = UUID(),
        title: String = "",
        taskDescription: String = "",
        category: ReadingMissionTaskCategory = .reflection,
        difficulty: String = "Medium",
        iconName: String? = nil,
        sortIndex: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String = "",
        aiScore: Int = 0,
        aiFeedback: String = "",
        scoredAt: Date? = nil
    ) {
        self.id = UUID()
        self.missionID = missionID
        self.title = title
        self.taskDescription = taskDescription
        self.categoryRawValue = category.rawValue
        self.difficulty = difficulty
        self.iconName = iconName ?? category.iconName
        self.sortIndex = sortIndex
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
        self.aiScore = aiScore
        self.aiFeedback = aiFeedback
        self.scoredAt = scoredAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension ReadingMissionTask {
    var category: ReadingMissionTaskCategory {
        get { ReadingMissionTaskCategory(rawValue: categoryRawValue) ?? .reflection }
        set {
            categoryRawValue = newValue.rawValue
            iconName = newValue.iconName
            updatedAt = Date()
        }
    }

    func setCompleted(_ completed: Bool, at date: Date = Date()) {
        isCompleted = completed
        completedAt = completed ? date : nil
        updatedAt = date
    }
}

@Model
final class ReadingMissionHistory {
    var id: UUID = UUID()
    var userID: String = "local-user"
    var missionID: UUID = UUID()
    var bookID: UUID?
    var bookTitle: String = ""
    var bookAuthor: String = ""
    var eventTypeRawValue: String = ReadingMissionHistoryType.generated.rawValue
    var generatedAt: Date = Date()
    var completedAt: Date?
    var scoredAt: Date?
    var score: Int = 0
    var scoreLabel: String = ""
    var scoreSummary: String = ""
    var durationSeconds: Double = 0
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        userID: String = "local-user",
        missionID: UUID = UUID(),
        bookID: UUID? = nil,
        bookTitle: String = "",
        bookAuthor: String = "",
        eventType: ReadingMissionHistoryType = .generated,
        generatedAt: Date = Date(),
        completedAt: Date? = nil,
        scoredAt: Date? = nil,
        score: Int = 0,
        scoreLabel: String = "",
        scoreSummary: String = "",
        durationSeconds: Double = 0,
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.userID = userID
        self.missionID = missionID
        self.bookID = bookID
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.eventTypeRawValue = eventType.rawValue
        self.generatedAt = generatedAt
        self.completedAt = completedAt
        self.scoredAt = scoredAt
        self.score = score
        self.scoreLabel = scoreLabel
        self.scoreSummary = scoreSummary
        self.durationSeconds = durationSeconds
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension ReadingMissionHistory {
    var eventType: ReadingMissionHistoryType {
        get {
            if let type = ReadingMissionHistoryType(rawValue: eventTypeRawValue), type != .generated {
                return type
            }
            if isCompleted { return .completed }
            if score > 0 || scoredAt != nil { return .scored }
            return .generated
        }
        set {
            eventTypeRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var eventDate: Date {
        switch eventType {
        case .generated:
            return generatedAt
        case .scored:
            return scoredAt ?? createdAt
        case .completed:
            return completedAt ?? createdAt
        }
    }
}
