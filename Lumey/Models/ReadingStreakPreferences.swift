//
//  ReadingStreakPreferences.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingStreakPreferences {
    var id: UUID = UUID()

    var weekendDay1RawValue: Int = ReadingWeekday.saturday.rawValue
    var weekendDay2RawValue: Int = ReadingWeekday.sunday.rawValue
    var weeklyReadingDayRawValue: Int = ReadingWeekday.monday.rawValue
    var monthlyReadingDay: Int = 1

    var weekendCurrentResetAt: Date?
    var weeklyCurrentResetAt: Date?
    var monthlyCurrentResetAt: Date?

    var preservedLongestWeekendStreak: Int = 0
    var preservedLongestWeeklyStreak: Int = 0
    var preservedLongestMonthlyStreak: Int = 0

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        weekendDay1: ReadingWeekday = .saturday,
        weekendDay2: ReadingWeekday = .sunday,
        weeklyReadingDay: ReadingWeekday = .monday,
        monthlyReadingDay: Int = 1
    ) {
        self.id = UUID()
        self.weekendDay1RawValue = weekendDay1.rawValue
        self.weekendDay2RawValue = weekendDay2.rawValue
        self.weeklyReadingDayRawValue = weeklyReadingDay.rawValue
        self.monthlyReadingDay = min(max(monthlyReadingDay, 1), 31)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension ReadingStreakPreferences {
    static func preferredRecord(from records: [ReadingStreakPreferences]) -> ReadingStreakPreferences? {
        records.max { $0.updatedAt < $1.updatedAt }
    }

    static func fetchOrCreate(in modelContext: ModelContext) -> ReadingStreakPreferences {
        let records = (try? modelContext.fetch(FetchDescriptor<ReadingStreakPreferences>())) ?? []
        if let preferred = preferredRecord(from: records) {
            return preferred
        }

        let preferences = ReadingStreakPreferences()
        modelContext.insert(preferences)
        return preferences
    }

    var configuration: ReadingStreakConfiguration {
        ReadingStreakConfiguration(
            weekendDay1: ReadingWeekday(rawValue: weekendDay1RawValue) ?? .saturday,
            weekendDay2: ReadingWeekday(rawValue: weekendDay2RawValue) ?? .sunday,
            weeklyReadingDay: ReadingWeekday(rawValue: weeklyReadingDayRawValue) ?? .monday,
            monthlyReadingDay: min(max(monthlyReadingDay, 1), 31)
        ).normalized()
    }

    func applyConfiguration(_ configuration: ReadingStreakConfiguration) {
        let normalized = configuration.normalized()
        weekendDay1RawValue = normalized.weekendDay1.rawValue
        weekendDay2RawValue = normalized.weekendDay2.rawValue
        weeklyReadingDayRawValue = normalized.weeklyReadingDay.rawValue
        monthlyReadingDay = normalized.monthlyReadingDay
        updatedAt = Date()
    }
}
