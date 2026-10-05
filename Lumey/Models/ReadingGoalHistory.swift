//
//  ReadingGoalHistory.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingGoalHistory {
    
    var id: UUID = UUID()
    
    // MARK: - Goal Reference
    
    var goalID: UUID = UUID()
    var goalTitleSnapshot: String = ""
    
    // MARK: - History Type
    
    var eventTypeRawValue: String = ReadingGoalHistoryType.progressUpdated.rawValue
    
    // MARK: - Progress Snapshot
    
    var previousValue: Double = 0
    var newValue: Double = 0
    var targetValue: Double = 0
    
    // MARK: - Streak Snapshot
    
    var previousStreak: Int = 0
    var newStreak: Int = 0
    var bestStreak: Int = 0
    
    // MARK: - Optional Context
    
    var note: String = ""
    var rewardEarned: String = ""
    
    // MARK: - Metadata
    
    var createdAt: Date = Date()
    
    init(
        goalID: UUID = UUID(),
        goalTitleSnapshot: String = "",
        eventType: ReadingGoalHistoryType = .progressUpdated,
        previousValue: Double = 0,
        newValue: Double = 0,
        targetValue: Double = 0,
        previousStreak: Int = 0,
        newStreak: Int = 0,
        bestStreak: Int = 0,
        note: String = "",
        rewardEarned: String = "",
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.goalID = goalID
        self.goalTitleSnapshot = goalTitleSnapshot
        self.eventTypeRawValue = eventType.rawValue
        self.previousValue = previousValue
        self.newValue = newValue
        self.targetValue = targetValue
        self.previousStreak = previousStreak
        self.newStreak = newStreak
        self.bestStreak = bestStreak
        self.note = note
        self.rewardEarned = rewardEarned
        self.createdAt = createdAt
    }
}

// MARK: - Event Types

enum ReadingGoalHistoryType: String, Codable, CaseIterable, Identifiable {
    
    case created = "Created"
    case progressUpdated = "Progress Updated"
    case streakUpdated = "Streak Updated"
    case completed = "Completed"
    case reset = "Reset"
    case paused = "Paused"
    case resumed = "Resumed"
    case ended = "Ended"
    case archived = "Archived"
    case rewardClaimed = "Reward Claimed"
    case noteAdded = "Note Added"
    
    var id: String { rawValue }
}

// MARK: - Computed Properties

extension ReadingGoalHistory {
    
    var eventType: ReadingGoalHistoryType {
        get {
            ReadingGoalHistoryType(rawValue: eventTypeRawValue) ?? .progressUpdated
        }
        set {
            eventTypeRawValue = newValue.rawValue
        }
    }
    
    var progressDelta: Double {
        newValue - previousValue
    }
    
    var streakDelta: Int {
        newStreak - previousStreak
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(max(newValue / targetValue, 0), 1)
    }
}
