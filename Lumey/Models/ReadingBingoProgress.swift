//
//  ReadingBingoProgress.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingBingoProgress {
    var id: UUID = UUID()
    var boardID: String = ""
    var squareStatesStorage: String = "[]"
    var earnedLinesStorage: String = "[]"
    var firstBingoEarnedAt: Date?
    var blackoutCompletedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        boardID: String = "",
        squareStates: [ReadingBingoSquareStateRecord] = [],
        earnedLines: [ReadingBingoEarnedLineRecord] = [],
        firstBingoEarnedAt: Date? = nil,
        blackoutCompletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.boardID = boardID
        self.firstBingoEarnedAt = firstBingoEarnedAt
        self.blackoutCompletedAt = blackoutCompletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.squareStates = squareStates
        self.earnedLines = earnedLines
    }
}

struct ReadingBingoSquareStateRecord: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var squareID: String
    var linkedBookID: UUID?
    var linkedBookTitle: String
    var completedAt: Date

    init(
        squareID: String,
        linkedBookID: UUID? = nil,
        linkedBookTitle: String = "",
        completedAt: Date = Date()
    ) {
        self.id = UUID()
        self.squareID = squareID
        self.linkedBookID = linkedBookID
        self.linkedBookTitle = linkedBookTitle
        self.completedAt = completedAt
    }
}

struct ReadingBingoEarnedLineRecord: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var lineID: String
    var completedAt: Date

    init(lineID: String, completedAt: Date = Date()) {
        self.id = UUID()
        self.lineID = lineID
        self.completedAt = completedAt
    }
}

enum ReadingBingoBoardState: String, Codable {
    case new
    case inProgress
    case bingo
    case multipleBingos
    case blackout

    var title: String {
        switch self {
        case .new:
            return "New"
        case .inProgress:
            return "In Progress"
        case .bingo:
            return "Bingo Earned"
        case .multipleBingos:
            return "Multiple Bingos"
        case .blackout:
            return "Blackout Complete"
        }
    }
}

extension ReadingBingoProgress {
    static func preferredRecord(for boardID: String, from records: [ReadingBingoProgress]) -> ReadingBingoProgress? {
        records
            .filter { $0.boardID == boardID }
            .max { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.updatedAt < rhs.updatedAt
            }
    }

    var squareStates: [ReadingBingoSquareStateRecord] {
        get {
            Self.decodeArray(from: squareStatesStorage)
        }
        set {
            squareStatesStorage = Self.encodeArray(newValue)
        }
    }

    var earnedLines: [ReadingBingoEarnedLineRecord] {
        get {
            Self.decodeArray(from: earnedLinesStorage)
        }
        set {
            earnedLinesStorage = Self.encodeArray(newValue)
        }
    }

    private static func decodeArray<T: Decodable>(from storage: String) -> T where T: RangeReplaceableCollection {
        guard
            let data = storage.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(T.self, from: data)
        else {
            return T()
        }

        return decoded
    }

    private static func encodeArray<T: Encodable>(_ value: T) -> String {
        guard
            let data = try? JSONEncoder().encode(value),
            let encoded = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return encoded
    }
}
