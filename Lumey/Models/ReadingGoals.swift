//
//  ReadingGoals.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Reading Goal Type

enum ReadingGoalType: String, Codable, CaseIterable, Identifiable {
    case books = "Books"
    case pages = "Pages"
    case minutes = "Minutes"
    case hours = "Hours"
    case streak = "Streak"
    case finishBook = "Finish Book"
    case finishSeries = "Finish Series"
    case tbr = "TBR"
    case genre = "Genre"
    case subgenre = "Subgenre"
    case author = "Author"
    case format = "Format"
    case habit = "Habit"
    case seasonalTheme = "Seasonal Theme"
    case readingRitual = "Reading Ritual"
    case emotionalGoal = "Emotional Goal"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Reading Goal Cadence

enum ReadingGoalCadence: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case seasonal = "Seasonal"
    case yearly = "Yearly"
    case lifetime = "Lifetime"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Reading Goal Mode

enum ReadingGoalMode: String, Codable, CaseIterable, Identifiable {
    case recurring = "Recurring"
    case oneTime = "One-Time"
    
    var id: String { rawValue }
}

// MARK: - Reading Goal Status

enum ReadingGoalStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case paused = "Paused"
    case ended = "Ended"
    case completed = "Completed"
    case archived = "Archived"
    
    var id: String { rawValue }
}

// MARK: - Reading Goal Priority

enum ReadingGoalPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
}

// MARK: - Reading Goals

@Model
final class ReadingGoals {
    var id: UUID = UUID()
    
    // Identity
    var title: String = ""
    var goalDescription: String = ""
    var goalReason: String = ""
    var rewardIdea: String = ""
    
    // Type / Category
    var typeRawValue: String = ReadingGoalType.books.rawValue
    var modeRawValue: String = ReadingGoalMode.recurring.rawValue
    var cadenceRawValue: String = ReadingGoalCadence.yearly.rawValue
    var statusRawValue: String = ReadingGoalStatus.active.rawValue
    var priorityRawValue: String = ReadingGoalPriority.medium.rawValue
    
    // Progress
    var targetValue: Double = 0
    var currentValue: Double = 0
    var unitLabel: String = ""
    
    // Optional Target Metadata
    var targetBookTitle: String = ""
    var targetBookAuthor: String = ""
    var targetSeriesName: String = ""
    var targetAuthorName: String = ""
    var targetGenre: String = ""
    var targetSubgenre: String = ""
    var targetFormatRawValue: String = BookFormat.physical.rawValue
    var targetStatusRawValue: String = BookStatus.toBeRead.rawValue
    var targetThemeName: String = ""
    var targetRitualName: String = ""
    var targetEmotionalFocus: String = ""
    
    // Habit / Ritual Support
    var desiredDaysPerWeek: Int = 0
    var desiredSessionsPerDay: Int = 0
    var preferredTimeOfDay: String = ""
    var habitPrompt: String = ""
    
    // Streak Support
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var targetStreak: Int = 0
    var lastCompletedDate: Date?
    var lastProgressResetDate: Date?
    
    // Date Range
    var startDate: Date = Date()
    var targetDate: Date?
    var completedDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Display
    var iconName: String = "achievement"
    var colorHex: String = "#7D19F7"
    var isPinned: Bool = false
    var isArchived: Bool = false
    
    // Flexible Organization
    var linkedBookIDsStorage: String = "[]"
    var linkedGenresStorage: String = "[]"
    var linkedSubgenresStorage: String = "[]"
    var linkedTagsStorage: String = "[]"
    var notesStorage: String = ""
    
    init(
        title: String = "",
        goalDescription: String = "",
        goalReason: String = "",
        rewardIdea: String = "",
        type: ReadingGoalType = .books,
        mode: ReadingGoalMode = .recurring,
        cadence: ReadingGoalCadence = .yearly,
        status: ReadingGoalStatus = .active,
        priority: ReadingGoalPriority = .medium,
        targetValue: Double = 0,
        currentValue: Double = 0,
        unitLabel: String = "",
        targetBookTitle: String = "",
        targetBookAuthor: String = "",
        targetSeriesName: String = "",
        targetAuthorName: String = "",
        targetGenre: String = "",
        targetSubgenre: String = "",
        targetFormat: BookFormat = .physical,
        targetStatus: BookStatus = .toBeRead,
        targetThemeName: String = "",
        targetRitualName: String = "",
        targetEmotionalFocus: String = "",
        desiredDaysPerWeek: Int = 0,
        desiredSessionsPerDay: Int = 0,
        preferredTimeOfDay: String = "",
        habitPrompt: String = "",
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        targetStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        lastProgressResetDate: Date? = nil,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        completedDate: Date? = nil,
        iconName: String = "achievement",
        colorHex: String = "#7D19F7",
        isPinned: Bool = false,
        isArchived: Bool = false,
        linkedBookIDs: [UUID] = [],
        linkedGenres: [String] = [],
        linkedSubgenres: [String] = [],
        linkedTags: [String] = [],
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = goalDescription
        self.goalReason = goalReason
        self.rewardIdea = rewardIdea
        self.typeRawValue = type.rawValue
        self.modeRawValue = mode.rawValue
        self.cadenceRawValue = cadence.rawValue
        self.statusRawValue = status.rawValue
        self.priorityRawValue = priority.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unitLabel = unitLabel
        self.targetBookTitle = targetBookTitle
        self.targetBookAuthor = targetBookAuthor
        self.targetSeriesName = targetSeriesName
        self.targetAuthorName = targetAuthorName
        self.targetGenre = targetGenre
        self.targetSubgenre = targetSubgenre
        self.targetFormatRawValue = targetFormat.rawValue
        self.targetStatusRawValue = targetStatus.rawValue
        self.targetThemeName = targetThemeName
        self.targetRitualName = targetRitualName
        self.targetEmotionalFocus = targetEmotionalFocus
        self.desiredDaysPerWeek = desiredDaysPerWeek
        self.desiredSessionsPerDay = desiredSessionsPerDay
        self.preferredTimeOfDay = preferredTimeOfDay
        self.habitPrompt = habitPrompt
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.targetStreak = targetStreak
        self.lastCompletedDate = lastCompletedDate
        self.lastProgressResetDate = lastProgressResetDate
        self.startDate = startDate
        self.targetDate = targetDate
        self.completedDate = completedDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.iconName = iconName
        self.colorHex = colorHex
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.linkedBookIDs = linkedBookIDs
        self.linkedGenres = linkedGenres
        self.linkedSubgenres = linkedSubgenres
        self.linkedTags = linkedTags
        self.notes = notes
    }
}

// MARK: - Computed Properties

extension ReadingGoals {
    var isRecurringGoal: Bool {
        guard mode == .recurring else { return false }
        
        switch cadence {
        case .daily, .weekly, .monthly, .seasonal:
            return true
        case .yearly, .lifetime, .custom:
            return false
        }
    }
    
    var isOneTimeGoal: Bool {
        mode == .oneTime
    }
    var shouldResetForCurrentPeriod: Bool {
        guard isRecurringGoal else { return false }
        guard status == .active || status == .completed else { return false }
        guard currentValue > 0 || status == .completed else { return false }

        let comparisonDate = lastProgressResetDate ?? completedDate ?? updatedAt
        return isOutsideCurrentPeriod(comparisonDate)
    }
    var type: ReadingGoalType {
        get { ReadingGoalType(rawValue: typeRawValue) ?? .books }
        set {
            typeRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }

    var mode: ReadingGoalMode {
        get { ReadingGoalMode(rawValue: modeRawValue) ?? .recurring }
        set {
            modeRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var cadence: ReadingGoalCadence {
        get { ReadingGoalCadence(rawValue: cadenceRawValue) ?? .yearly }
        set {
            cadenceRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var status: ReadingGoalStatus {
        get { ReadingGoalStatus(rawValue: statusRawValue) ?? .active }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
            
            if newValue == .completed, completedDate == nil {
                completedDate = Date()
            }
        }
    }
    
    var priority: ReadingGoalPriority {
        get { ReadingGoalPriority(rawValue: priorityRawValue) ?? .medium }
        set {
            priorityRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var targetFormat: BookFormat {
        get { BookFormat(rawValue: targetFormatRawValue) ?? .physical }
        set {
            targetFormatRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var targetStatus: BookStatus {
        get { BookStatus(rawValue: targetStatusRawValue) ?? .toBeRead }
        set {
            targetStatusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var linkedBookIDs: [UUID] {
        get { Self.decodeUUIDArray(linkedBookIDsStorage) }
        set {
            linkedBookIDsStorage = Self.encodeUUIDArray(newValue)
            updatedAt = Date()
        }
    }
    
    var linkedGenres: [String] {
        get { Self.decodeStringArray(linkedGenresStorage) }
        set {
            linkedGenresStorage = Self.encodeStringArray(newValue)
            updatedAt = Date()
        }
    }
    
    var linkedSubgenres: [String] {
        get { Self.decodeStringArray(linkedSubgenresStorage) }
        set {
            linkedSubgenresStorage = Self.encodeStringArray(newValue)
            updatedAt = Date()
        }
    }
    
    var linkedTags: [String] {
        get { Self.decodeStringArray(linkedTagsStorage) }
        set {
            linkedTagsStorage = Self.encodeStringArray(newValue)
            updatedAt = Date()
        }
    }
    
    var notes: String {
        get { notesStorage }
        set {
            notesStorage = newValue
            updatedAt = Date()
        }
    }
    
    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? type.rawValue : title
    }
    
    var displayUnit: String {
        if !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return unitLabel
        }
        
        switch type {
        case .books, .finishBook, .finishSeries, .tbr:
            return "books"
        case .pages:
            return "pages"
        case .minutes:
            return "minutes"
        case .hours:
            return "hours"
        case .streak:
            return "days"
        case .genre, .subgenre, .author, .format:
            return "books"
        case .habit, .readingRitual:
            return "sessions"
        case .seasonalTheme, .emotionalGoal, .custom:
            return "progress"
        }
    }
    
    var progressValue: Double {
        guard targetValue > 0 else { return 0 }
        return min(max(currentValue / targetValue, 0), 1)
    }
    
    var progressPercentage: Int {
        Int((progressValue * 100).rounded())
    }
    
    var progressText: String {
        if targetValue <= 0 {
            return "No target set"
        }
        
        let current = Self.cleanNumber(currentValue)
        let target = Self.cleanNumber(targetValue)
        return "\(current) / \(target) \(displayUnit)"
    }
    
    var isComplete: Bool {
        status == .completed || progressValue >= 1
    }
    
    var daysRemaining: Int? {
        guard let targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
    }

    func cycleDateInterval(
        containing date: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval? {
        guard isRecurringGoal else { return nil }

        switch cadence {
        case .daily:
            return calendar.dateInterval(of: .day, for: date)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: date)
        case .monthly:
            return calendar.dateInterval(of: .month, for: date)
        case .seasonal:
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { return nil }

            let startYear: Int
            let startMonth: Int
            switch month {
            case 3...5:
                startYear = year
                startMonth = 3
            case 6...8:
                startYear = year
                startMonth = 6
            case 9...11:
                startYear = year
                startMonth = 9
            case 12:
                startYear = year
                startMonth = 12
            default:
                startYear = year - 1
                startMonth = 12
            }

            guard let start = calendar.date(
                from: DateComponents(year: startYear, month: startMonth, day: 1)
            ), let end = calendar.date(byAdding: .month, value: 3, to: start) else {
                return nil
            }
            return DateInterval(start: start, end: end)
        case .yearly, .lifetime, .custom:
            return nil
        }
    }
}

// MARK: - Helpers

extension ReadingGoals {
    func touch() {
        updatedAt = Date()
    }
    
    func updateProgress(to value: Double) {
        guard status == .active else { return }

        currentValue = max(0, value)
        if currentValue > 0 {
            lastProgressResetDate = Date()
        }
        updatedAt = Date()
        
        if targetValue > 0,
           currentValue >= targetValue {
            status = .completed
            completedDate = Date()
            lastProgressResetDate = Date()
        } else if status == .completed {
            status = .active
            completedDate = nil
        }
    }
    
    func incrementProgress(by amount: Double = 1) {
        updateProgress(to: currentValue + amount)
    }
    
    func resetProgress() {
        currentValue = 0
        completedDate = nil
        status = .active
        lastProgressResetDate = Date()
        updatedAt = Date()
    }
    
    func resetProgressIfNeededForCurrentPeriod() {
        guard shouldResetForCurrentPeriod else { return }
        resetProgress()
    }
    
    func markCompleted() {
        guard status == .active else { return }

        let now = Date()

        if targetValue > 0 {
            currentValue = targetValue
        }

        status = .completed
        completedDate = now
        lastProgressResetDate = now
        updatedAt = now
    }
    
    func updateStreak(completedOn date: Date = Date(), bridgeBreakGap: Bool = false) {
        guard status == .active else { return }

        let calendar = Calendar.current

        if let lastCompletedDate {
            if calendar.isDate(lastCompletedDate, inSameDayAs: date) {
                return
            }

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastCompletedDate)),
               calendar.isDate(nextDay, inSameDayAs: date) {
                currentStreak += 1
            } else if bridgeBreakGap {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        
        bestStreak = max(bestStreak, currentStreak)
        self.lastCompletedDate = date
        lastProgressResetDate = date
        
        if targetStreak > 0 {
            currentValue = Double(currentStreak)
            targetValue = Double(targetStreak)
            if currentStreak >= targetStreak,
               !isRecurringGoal {
                status = .completed
            }
        }
        
        updatedAt = Date()
    }

    func pauseGoal() {
        guard status == .active || (status == .completed && isRecurringGoal) else { return }
        status = .paused
    }

    func resumeGoal() {
        guard status == .paused else { return }

        let comparisonDate = lastProgressResetDate ?? completedDate ?? updatedAt
        let needsCurrentCycleReset = isRecurringGoal &&
            currentValue > 0 &&
            isOutsideCurrentPeriod(comparisonDate)

        if needsCurrentCycleReset {
            status = .active
            resetProgress()
        } else if targetValue > 0 && currentValue >= targetValue {
            status = .completed
        } else {
            status = .active
        }
    }

    func endGoal() {
        guard status == .active || status == .paused || (status == .completed && isRecurringGoal) else { return }
        status = .ended
        isPinned = false
        updatedAt = Date()
    }

    private func isOutsideCurrentPeriod(_ comparisonDate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch cadence {
        case .daily:
            return !calendar.isDate(comparisonDate, inSameDayAs: now)
        case .weekly:
            return !calendar.isDate(comparisonDate, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return !calendar.isDate(comparisonDate, equalTo: now, toGranularity: .month)
        case .seasonal:
            return seasonalIndex(for: comparisonDate) != seasonalIndex(for: now)
        case .yearly, .lifetime, .custom:
            return false
        }
    }

    private func seasonalIndex(for date: Date) -> Int {
        let month = Calendar.current.component(.month, from: date)
        
        switch month {
        case 3...5:
            return 0
        case 6...8:
            return 1
        case 9...11:
            return 2
        default:
            return 3
        }
    }
    
    static func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        
        return string
    }
    
    static func decodeStringArray(_ string: String) -> [String] {
        guard let data = string.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return values
    }
    
    static func encodeUUIDArray(_ values: [UUID]) -> String {
        let strings = values.map { $0.uuidString }
        return encodeStringArray(strings)
    }
    
    static func decodeUUIDArray(_ string: String) -> [UUID] {
        decodeStringArray(string).compactMap { UUID(uuidString: $0) }
    }
    
    static func cleanNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        
        return String(format: "%.1f", value)
    }
}
