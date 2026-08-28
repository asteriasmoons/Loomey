//
//  ReadingBingoEngine.swift
//  Lumey
//

import Foundation
import SwiftData

struct ReadingBingoPosition: Hashable {
    let row: Int
    let column: Int
}

struct ReadingBingoLineDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let positions: [ReadingBingoPosition]
}

struct ReadingBingoSquareSnapshot: Identifiable, Hashable {
    let id: String
    let definition: ReadingBingoSquareDefinition
    let completionRecord: ReadingBingoSquareStateRecord?
    let isCompleted: Bool
    let linkedBookTitle: String
    let completedAt: Date?
    let lineIDs: [String]
    let isHighlighted: Bool

    var row: Int { definition.row }
    var column: Int { definition.column }
    var title: String { definition.title }
    var description: String { definition.description }
    var isFreeSpace: Bool { definition.isFreeSpace }
}

struct ReadingBingoBoardSnapshot: Identifiable {
    let id: String
    let definition: ReadingBingoBoardDefinition
    let progressRecord: ReadingBingoProgress?
    let squares: [ReadingBingoSquareSnapshot]
    let lineDefinitions: [ReadingBingoLineDefinition]
    let earnedLineIDs: [String]
    let completedChallengeCount: Int
    let totalChallengeCount: Int
    let bingoCount: Int
    let state: ReadingBingoBoardState
    let firstBingoEarnedAt: Date?
    let blackoutCompletedAt: Date?

    var title: String { definition.title }
    var description: String { definition.description }
    var iconName: String { definition.iconName }
    var accent: ReadingBingoAccentIdentity { definition.accent }
    var remainingChallengeCount: Int { max(totalChallengeCount - completedChallengeCount, 0) }
    var progress: Double {
        guard totalChallengeCount > 0 else { return 0 }
        return Double(completedChallengeCount) / Double(totalChallengeCount)
    }

    var statusText: String {
        switch state {
        case .new:
            return "\(remainingChallengeCount) challenges waiting"
        case .inProgress:
            return "\(completedChallengeCount) squares complete"
        case .bingo:
            return "BINGO! Your first line is complete."
        case .multipleBingos:
            return "\(bingoCount) Bingos earned"
        case .blackout:
            return "Board complete"
        }
    }
}

struct ReadingBingoHubSummary {
    let totalCompletedChallengeSquares: Int
    let totalBingoLines: Int
    let totalBlackoutBoards: Int
    let boardsInProgress: Int
    let overallProgress: Double
}

struct ReadingBingoMutationResult {
    let snapshot: ReadingBingoBoardSnapshot
    let newlyEarnedLineIDs: [String]
    let removedLineIDs: [String]
    let completedSquare: Bool
    let clearedSquare: Bool
    let didEarnFirstBingo: Bool
    let didEarnBlackout: Bool
}

enum ReadingBingoEngine {
    static let allLineDefinitions: [ReadingBingoLineDefinition] = makeLineDefinitions()

    static func hubSummary(progressRecords: [ReadingBingoProgress]) -> ReadingBingoHubSummary {
        let snapshots = ReadingBingoCatalog.allBoards.map { board in
            snapshot(
                for: board,
                progressRecord: ReadingBingoProgress.preferredRecord(for: board.id, from: progressRecords)
            )
        }

        let totalCompleted = snapshots.reduce(0) { $0 + $1.completedChallengeCount }
        let totalLines = snapshots.reduce(0) { $0 + $1.bingoCount }
        let totalBlackouts = snapshots.filter { $0.state == .blackout }.count
        let inProgressCount = snapshots.filter { $0.state != .new && $0.state != .blackout }.count
        let totalChallenges = snapshots.reduce(0) { $0 + $1.totalChallengeCount }
        let progress = totalChallenges == 0 ? 0 : Double(totalCompleted) / Double(totalChallenges)

        return ReadingBingoHubSummary(
            totalCompletedChallengeSquares: totalCompleted,
            totalBingoLines: totalLines,
            totalBlackoutBoards: totalBlackouts,
            boardsInProgress: inProgressCount,
            overallProgress: progress
        )
    }

    static func snapshot(
        for definition: ReadingBingoBoardDefinition,
        progressRecord: ReadingBingoProgress?
    ) -> ReadingBingoBoardSnapshot {
        let completionByID = Dictionary(
            uniqueKeysWithValues: (progressRecord?.squareStates ?? []).map { ($0.squareID, $0) }
        )
        let earnedLinesByID = Dictionary(
            uniqueKeysWithValues: (progressRecord?.earnedLines ?? []).map { ($0.lineID, $0) }
        )
        let validEarnedLineIDs = completedLineIDs(for: definition, completedSquareIDs: Set(completionByID.keys))
        let lineIDsByPosition = makeLineIDsByPosition(earnedLineIDs: validEarnedLineIDs)

        let squareSnapshots = definition.squares
            .sorted { lhs, rhs in
                if lhs.row == rhs.row {
                    return lhs.column < rhs.column
                }
                return lhs.row < rhs.row
            }
            .map { square -> ReadingBingoSquareSnapshot in
                let record = completionByID[square.id]
                let isCompleted = square.isFreeSpace || record != nil
                let position = ReadingBingoPosition(row: square.row, column: square.column)
                let lineIDs = lineIDsByPosition[position] ?? []

                return ReadingBingoSquareSnapshot(
                    id: square.id,
                    definition: square,
                    completionRecord: record,
                    isCompleted: isCompleted,
                    linkedBookTitle: record?.linkedBookTitle ?? "",
                    completedAt: record?.completedAt,
                    lineIDs: lineIDs,
                    isHighlighted: !lineIDs.isEmpty
                )
            }

        let completedChallengeCount = squareSnapshots.filter { !$0.isFreeSpace && $0.isCompleted }.count
        let state = boardState(
            completedChallengeCount: completedChallengeCount,
            totalChallengeCount: definition.squares.filter { !$0.isFreeSpace }.count,
            bingoCount: validEarnedLineIDs.count
        )

        let lineCompletionDates = validEarnedLineIDs.compactMap { earnedLinesByID[$0]?.completedAt }
        let firstBingoDate = lineCompletionDates.min() ?? progressRecord?.firstBingoEarnedAt
        let blackoutDate = state == .blackout ? progressRecord?.blackoutCompletedAt : nil

        return ReadingBingoBoardSnapshot(
            id: definition.id,
            definition: definition,
            progressRecord: progressRecord,
            squares: squareSnapshots,
            lineDefinitions: allLineDefinitions,
            earnedLineIDs: validEarnedLineIDs,
            completedChallengeCount: completedChallengeCount,
            totalChallengeCount: definition.squares.filter { !$0.isFreeSpace }.count,
            bingoCount: validEarnedLineIDs.count,
            state: state,
            firstBingoEarnedAt: firstBingoDate,
            blackoutCompletedAt: blackoutDate
        )
    }

    @discardableResult
    static func completeSquare(
        boardID: String,
        squareID: String,
        linkedBookID: UUID?,
        linkedBookTitle: String,
        in modelContext: ModelContext
    ) throws -> ReadingBingoMutationResult {
        guard let definition = ReadingBingoCatalog.definition(for: boardID) else {
            throw ReadingBingoEngineError.boardNotFound
        }

        guard let square = definition.squares.first(where: { $0.id == squareID }), !square.isFreeSpace else {
            throw ReadingBingoEngineError.squareNotFound
        }

        let record = fetchOrCreateProgress(boardID: boardID, in: modelContext)
        let previousLineIDs = Set(record.earnedLines.map(\.lineID))
        var squareStates = record.squareStates

        if let existingIndex = squareStates.firstIndex(where: { $0.squareID == squareID }) {
            squareStates[existingIndex].linkedBookID = linkedBookID
            squareStates[existingIndex].linkedBookTitle = linkedBookTitle
            squareStates[existingIndex].completedAt = Date()
        } else {
            squareStates.append(
                ReadingBingoSquareStateRecord(
                    squareID: squareID,
                    linkedBookID: linkedBookID,
                    linkedBookTitle: linkedBookTitle,
                    completedAt: Date()
                )
            )
        }

        record.squareStates = normalizedSquareStates(squareStates)
        let mutation = synchronizeBoardProgress(definition: definition, record: record)
        try modelContext.save()
        return mutation(previousLineIDs, true, false)
    }

    @discardableResult
    static func undoSquare(
        boardID: String,
        squareID: String,
        in modelContext: ModelContext
    ) throws -> ReadingBingoMutationResult {
        guard let definition = ReadingBingoCatalog.definition(for: boardID) else {
            throw ReadingBingoEngineError.boardNotFound
        }

        let record = fetchOrCreateProgress(boardID: boardID, in: modelContext)
        let previousLineIDs = Set(record.earnedLines.map(\.lineID))
        record.squareStates.removeAll { $0.squareID == squareID }
        let mutation = synchronizeBoardProgress(definition: definition, record: record)
        try modelContext.save()
        return mutation(previousLineIDs, false, true)
    }

    private static func synchronizeBoardProgress(
        definition: ReadingBingoBoardDefinition,
        record: ReadingBingoProgress
    ) -> (_ previousLineIDs: Set<String>, _ completedSquare: Bool, _ clearedSquare: Bool) -> ReadingBingoMutationResult {
        { previousLineIDs, completedSquare, clearedSquare in
            let completedSquareIDs = Set(record.squareStates.map(\.squareID))
            let lineIDs = completedLineIDs(for: definition, completedSquareIDs: completedSquareIDs)
            let existingLinesByID = Dictionary(uniqueKeysWithValues: record.earnedLines.map { ($0.lineID, $0) })
            let now = Date()

            record.earnedLines = lineIDs.map { lineID in
                existingLinesByID[lineID] ?? ReadingBingoEarnedLineRecord(lineID: lineID, completedAt: now)
            }
            .sorted { $0.completedAt < $1.completedAt }

            record.firstBingoEarnedAt = record.earnedLines.map(\.completedAt).min()

            let totalChallengeCount = definition.squares.filter { !$0.isFreeSpace }.count
            let completedChallengeCount = record.squareStates.count
            let isBlackout = completedChallengeCount >= totalChallengeCount
            if isBlackout {
                record.blackoutCompletedAt = record.blackoutCompletedAt ?? now
            } else {
                record.blackoutCompletedAt = nil
            }

            record.updatedAt = now
            let snapshotValue = snapshot(for: definition, progressRecord: record)
            let newLineIDs = Set(lineIDs)
            let newlyEarnedLineIDs = Array(newLineIDs.subtracting(previousLineIDs)).sorted()
            let removedLineIDs = Array(previousLineIDs.subtracting(newLineIDs)).sorted()

            return ReadingBingoMutationResult(
                snapshot: snapshotValue,
                newlyEarnedLineIDs: newlyEarnedLineIDs,
                removedLineIDs: removedLineIDs,
                completedSquare: completedSquare,
                clearedSquare: clearedSquare,
                didEarnFirstBingo: previousLineIDs.isEmpty && !newlyEarnedLineIDs.isEmpty,
                didEarnBlackout: record.blackoutCompletedAt == now
            )
        }
    }

    private static func fetchOrCreateProgress(boardID: String, in modelContext: ModelContext) -> ReadingBingoProgress {
        let descriptor = FetchDescriptor<ReadingBingoProgress>()
        let records = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = ReadingBingoProgress.preferredRecord(for: boardID, from: records) {
            return existing
        }

        let progress = ReadingBingoProgress(boardID: boardID)
        modelContext.insert(progress)
        return progress
    }

    static func completedLineIDs(
        for definition: ReadingBingoBoardDefinition,
        completedSquareIDs: Set<String>
    ) -> [String] {
        let completedPositions = Set(
            definition.squares.compactMap { square -> ReadingBingoPosition? in
                if square.isFreeSpace || completedSquareIDs.contains(square.id) {
                    return ReadingBingoPosition(row: square.row, column: square.column)
                }
                return nil
            }
        )

        return allLineDefinitions
            .filter { line in
                line.positions.allSatisfy { completedPositions.contains($0) }
            }
            .map(\.id)
            .sorted()
    }

    static func boardState(
        completedChallengeCount: Int,
        totalChallengeCount: Int,
        bingoCount: Int
    ) -> ReadingBingoBoardState {
        if completedChallengeCount <= 0 {
            return .new
        }

        if completedChallengeCount >= totalChallengeCount {
            return .blackout
        }

        if bingoCount > 1 {
            return .multipleBingos
        }

        if bingoCount == 1 {
            return .bingo
        }

        return .inProgress
    }

    private static func makeLineDefinitions() -> [ReadingBingoLineDefinition] {
        var lines: [ReadingBingoLineDefinition] = []

        for row in 0..<ReadingBingoCatalog.boardSize {
            lines.append(
                ReadingBingoLineDefinition(
                    id: "row-\(row)",
                    title: "Row \(row + 1)",
                    positions: (0..<ReadingBingoCatalog.boardSize).map { ReadingBingoPosition(row: row, column: $0) }
                )
            )
        }

        for column in 0..<ReadingBingoCatalog.boardSize {
            lines.append(
                ReadingBingoLineDefinition(
                    id: "column-\(column)",
                    title: "Column \(column + 1)",
                    positions: (0..<ReadingBingoCatalog.boardSize).map { ReadingBingoPosition(row: $0, column: column) }
                )
            )
        }

        lines.append(
            ReadingBingoLineDefinition(
                id: "diagonal-main",
                title: "Main Diagonal",
                positions: (0..<ReadingBingoCatalog.boardSize).map { ReadingBingoPosition(row: $0, column: $0) }
            )
        )

        lines.append(
            ReadingBingoLineDefinition(
                id: "diagonal-opposite",
                title: "Opposite Diagonal",
                positions: (0..<ReadingBingoCatalog.boardSize).map {
                    ReadingBingoPosition(row: $0, column: (ReadingBingoCatalog.boardSize - 1) - $0)
                }
            )
        )

        return lines
    }

    private static func makeLineIDsByPosition(earnedLineIDs: [String]) -> [ReadingBingoPosition: [String]] {
        var mapping: [ReadingBingoPosition: [String]] = [:]
        let earnedLineSet = Set(earnedLineIDs)

        for line in allLineDefinitions where earnedLineSet.contains(line.id) {
            for position in line.positions {
                mapping[position, default: []].append(line.id)
            }
        }

        return mapping
    }

    private static func normalizedSquareStates(_ states: [ReadingBingoSquareStateRecord]) -> [ReadingBingoSquareStateRecord] {
        let deduped = Dictionary(uniqueKeysWithValues: states.map { ($0.squareID, $0) })
        return deduped.values.sorted { $0.completedAt < $1.completedAt }
    }
}

enum ReadingBingoEngineError: Error {
    case boardNotFound
    case squareNotFound
}
