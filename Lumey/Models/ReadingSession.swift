//
//  ReadingSession.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Reading Session

@Model
final class ReadingSession {
    var id: UUID = UUID()

    // Linked book (optional)
    var linkedBookID: UUID?
    var linkedBookTitle: String = ""
    
    // Linked goal (optional)
    var linkedGoalID: UUID?
    var linkedGoalTitle: String = ""
    var linkedGoalIDsData: String = "[]"
    var linkedGoalTitlesData: String = "[]"

    // Session data
    var durationMinutes: Int = 0
    var pagesRead: Int = 0
    var startPage: Int = 0
    var endPage: Int = 0
    var isCatchUpSession: Bool = false
    var notes: String = ""
    var date: Date = Date()

    // Points
    var pointsEarned: Int = 0

    // Metadata
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ReadingInsight.session)
    var insights: [ReadingInsight]? = []

    init(
        linkedBookID: UUID? = nil,
        linkedBookTitle: String = "",
        linkedGoalID: UUID? = nil,
        linkedGoalTitle: String = "",
        linkedGoalIDs: [UUID] = [],
        linkedGoalTitles: [String] = [],
        durationMinutes: Int = 0,
        pagesRead: Int = 0,
        startPage: Int = 0,
        endPage: Int = 0,
        isCatchUpSession: Bool = false,
        notes: String = "",
        date: Date = Date()
    ) {
        self.id = UUID()
        self.linkedBookID = linkedBookID
        self.linkedBookTitle = linkedBookTitle
        self.linkedGoalID = linkedGoalID
        self.linkedGoalTitle = linkedGoalTitle
        let storedGoalIDs = linkedGoalIDs.isEmpty ? linkedGoalID.map { [$0] } ?? [] : linkedGoalIDs
        let storedGoalTitles = linkedGoalTitles.isEmpty && !linkedGoalTitle.isEmpty ? [linkedGoalTitle] : linkedGoalTitles
        self.linkedGoalIDs = storedGoalIDs
        self.linkedGoalTitles = storedGoalTitles
        self.durationMinutes = durationMinutes
        self.pagesRead = pagesRead
        self.startPage = startPage
        self.endPage = endPage
        self.isCatchUpSession = isCatchUpSession
        self.notes = notes
        self.date = date
        self.pointsEarned = Self.calculatePoints(minutes: durationMinutes, pages: pagesRead)
        self.createdAt = Date()
    }

    static func calculatePoints(minutes: Int, pages: Int) -> Int {
        // 1 pt per minute, 2 pts per page, minimum 5 pts for any logged session
        let raw = minutes + (pages * 2)
        return max(raw, minutes > 0 || pages > 0 ? 5 : 0)
    }
}

extension ReadingSession {
    var linkedGoalIDs: [UUID] {
        get {
            Self.decodeStringArray(linkedGoalIDsData)
                .compactMap { UUID(uuidString: $0) }
        }
        set {
            linkedGoalIDsData = Self.encodeStringArray(Self.uniqueUUIDs(newValue).map(\.uuidString))
        }
    }

    var linkedGoalTitles: [String] {
        get {
            Self.decodeStringArray(linkedGoalTitlesData)
        }
        set {
            linkedGoalTitlesData = Self.encodeStringArray(
                Self.uniqueStrings(
                    newValue
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            )
        }
    }

    var allLinkedGoalIDs: [UUID] {
        var ids = linkedGoalIDs
        if let linkedGoalID, !ids.contains(linkedGoalID) {
            ids.append(linkedGoalID)
        }
        return Self.uniqueUUIDs(ids)
    }

    var allLinkedGoalTitles: [String] {
        var titles = linkedGoalTitles
        let trimmedLegacyTitle = linkedGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLegacyTitle.isEmpty && !titles.contains(where: { $0.caseInsensitiveCompare(trimmedLegacyTitle) == .orderedSame }) {
            titles.append(trimmedLegacyTitle)
        }
        return Self.uniqueStrings(titles)
    }

    var hasLinkedGoal: Bool {
        !allLinkedGoalIDs.isEmpty || !allLinkedGoalTitles.isEmpty
    }

    private static func decodeStringArray(_ data: String) -> [String] {
        guard let rawData = data.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: rawData)
        else {
            return []
        }

        return values
    }

    private static func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let encoded = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return encoded
    }

    private static func uniqueUUIDs(_ values: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func uniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.lowercased()).inserted }
    }
}
