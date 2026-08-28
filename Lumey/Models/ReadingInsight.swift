//
//  ReadingInsight.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingInsight {
    var id: UUID = UUID()
    var dateCreated: Date = Date()

    var whatHappened: String = ""
    var whatStoodOut: String = ""
    var howIFeel: String = ""
    var moodTagsData: String = "[]"
    var feelingNote: String = ""
    var predictions: String = ""
    var favoriteMoment: String = ""
    var favoriteQuote: String = ""
    var aiSummary: String = ""

    var book: Book?
    var session: ReadingSession?

    init(
        dateCreated: Date = Date(),
        book: Book? = nil,
        session: ReadingSession? = nil,
        whatHappened: String = "",
        whatStoodOut: String = "",
        howIFeel: String = "",
        moodTags: [String] = [],
        feelingNote: String = "",
        predictions: String = "",
        favoriteMoment: String = "",
        favoriteQuote: String = "",
        aiSummary: String = ""
    ) {
        self.id = UUID()
        self.dateCreated = dateCreated
        self.book = book
        self.session = session
        self.whatHappened = whatHappened
        self.whatStoodOut = whatStoodOut
        self.howIFeel = howIFeel
        self.moodTags = moodTags
        self.feelingNote = feelingNote
        self.predictions = predictions
        self.favoriteMoment = favoriteMoment
        self.favoriteQuote = favoriteQuote
        self.aiSummary = aiSummary
    }
}

extension ReadingInsight {
    var moodTags: [String] {
        get {
            guard let data = moodTagsData.data(using: .utf8),
                  let values = try? JSONDecoder().decode([String].self, from: data)
            else {
                return []
            }

            return values
        }
        set {
            let cleaned = Self.uniqueStrings(
                newValue
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
            guard let data = try? JSONEncoder().encode(cleaned),
                  let encoded = String(data: data, encoding: .utf8)
            else {
                moodTagsData = "[]"
                return
            }

            moodTagsData = encoded
        }
    }

    var displayMoodTags: [String] {
        let stored = moodTags
        if !stored.isEmpty {
            return stored
        }

        let trimmed = howIFeel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let moodPart = trimmed.components(separatedBy: ":").first ?? trimmed
        return Self.uniqueStrings(
            moodPart
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    var displayFeelingNote: String {
        let storedNote = feelingNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !storedNote.isEmpty {
            return storedNote
        }

        let trimmed = howIFeel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separatorRange = trimmed.range(of: ":") else { return "" }
        return trimmed[separatorRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func uniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.lowercased()).inserted }
    }
}
