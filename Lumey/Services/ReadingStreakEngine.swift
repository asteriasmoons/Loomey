//
//  ReadingStreakEngine.swift
//  Lumey
//

import Foundation

enum ReadingWeekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var nextDay: ReadingWeekday {
        ReadingWeekday(rawValue: rawValue == 7 ? 1 : rawValue + 1) ?? .sunday
    }
}

struct ReadingStreakConfiguration: Equatable {
    var weekendDay1: ReadingWeekday = .saturday
    var weekendDay2: ReadingWeekday = .sunday
    var weeklyReadingDay: ReadingWeekday = .monday
    var monthlyReadingDay: Int = 1

    static let `default` = ReadingStreakConfiguration()

    func normalized() -> ReadingStreakConfiguration {
        var copy = self
        copy.monthlyReadingDay = min(max(monthlyReadingDay, 1), 31)
        if !Self.areConsecutive(day1: copy.weekendDay1, day2: copy.weekendDay2) {
            copy.weekendDay2 = copy.weekendDay1.nextDay
        }
        return copy
    }

    static func areConsecutive(day1: ReadingWeekday, day2: ReadingWeekday) -> Bool {
        day1.nextDay == day2
    }
}

enum ReadingStreakKind: String, CaseIterable, Identifiable {
    case daily
    case weekend
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily Reading Streak"
        case .weekend: return "Weekend Reading Streak"
        case .weekly: return "Weekly Reading Streak"
        case .monthly: return "Monthly Reading Streak"
        }
    }

    var iconName: String {
        switch self {
        case .daily: return "flame"
        case .weekend: return "stargoal"
        case .weekly: return "circledothashtag"
        case .monthly: return "lovegoal"
        }
    }

    var unitName: String {
        switch self {
        case .daily: return "days"
        case .weekend: return "weekends"
        case .weekly: return "weeks"
        case .monthly: return "months"
        }
    }
}

struct ReadingStreakSummary: Identifiable {
    let kind: ReadingStreakKind
    let current: Int
    let longest: Int
    let detail: String

    var id: ReadingStreakKind { kind }
}

enum ReadingActivityDetector {
    static func qualifyingActivityDays(
        from sessions: [ReadingSession],
        after resetAt: Date? = nil,
        calendar: Calendar = .current
    ) -> Set<Date> {
        Set(
            sessions
                .filter { session in
                    guard isQualifyingReadingActivity(session) else { return false }
                    guard let resetAt else { return true }
                    return session.date >= resetAt
                }
                .map { calendar.startOfDay(for: $0.date) }
        )
    }

    static func hasQualifyingActivity(on date: Date, sessions: [ReadingSession], calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return sessions.contains {
            isQualifyingReadingActivity($0) && calendar.isDate($0.date, inSameDayAs: day)
        }
    }

    private static func isQualifyingReadingActivity(_ session: ReadingSession) -> Bool {
        session.durationMinutes > 0
        || session.pagesRead > 0
        || session.notes.localizedCaseInsensitiveContains("goal check-in")
        || session.hasLinkedGoal
    }
}

enum ReadingStreakEngine {
    static func summaries(
        sessions: [ReadingSession],
        preferences: ReadingStreakPreferences?,
        breakPeriods: [ReadingBreakPeriod] = [],
        today: Date = Date(),
        calendar: Calendar = .current,
        preservedDailyLongest: Int = 0
    ) -> [ReadingStreakSummary] {
        let configuration = preferences?.configuration ?? .default
        let activityDays = ReadingActivityDetector.qualifyingActivityDays(from: sessions, calendar: calendar)
        let weekendActivityDays = ReadingActivityDetector.qualifyingActivityDays(
            from: sessions,
            after: preferences?.weekendCurrentResetAt,
            calendar: calendar
        )
        let weeklyActivityDays = ReadingActivityDetector.qualifyingActivityDays(
            from: sessions,
            after: preferences?.weeklyCurrentResetAt,
            calendar: calendar
        )
        let monthlyActivityDays = ReadingActivityDetector.qualifyingActivityDays(
            from: sessions,
            after: preferences?.monthlyCurrentResetAt,
            calendar: calendar
        )

        let daily = dailySummary(
            activityDays: activityDays,
            breakPeriods: breakPeriods,
            today: today,
            calendar: calendar,
            preservedLongest: preservedDailyLongest
        )
        let weekend = weekendSummary(
            activityDays: weekendActivityDays,
            configuration: configuration,
            resetAt: preferences?.weekendCurrentResetAt,
            today: today,
            calendar: calendar,
            preservedLongest: preferences?.preservedLongestWeekendStreak ?? 0
        )
        let weekly = weeklySummary(
            activityDays: weeklyActivityDays,
            configuration: configuration,
            resetAt: preferences?.weeklyCurrentResetAt,
            today: today,
            calendar: calendar,
            preservedLongest: preferences?.preservedLongestWeeklyStreak ?? 0
        )
        let monthly = monthlySummary(
            activityDays: monthlyActivityDays,
            configuration: configuration,
            resetAt: preferences?.monthlyCurrentResetAt,
            today: today,
            calendar: calendar,
            preservedLongest: preferences?.preservedLongestMonthlyStreak ?? 0
        )

        return [daily, weekend, weekly, monthly]
    }

    static func summary(
        for kind: ReadingStreakKind,
        sessions: [ReadingSession],
        preferences: ReadingStreakPreferences?,
        breakPeriods: [ReadingBreakPeriod] = [],
        today: Date = Date(),
        calendar: Calendar = .current,
        preservedDailyLongest: Int = 0
    ) -> ReadingStreakSummary {
        summaries(
            sessions: sessions,
            preferences: preferences,
            breakPeriods: breakPeriods,
            today: today,
            calendar: calendar,
            preservedDailyLongest: preservedDailyLongest
        ).first { $0.kind == kind } ?? ReadingStreakSummary(kind: kind, current: 0, longest: 0, detail: "")
    }
}

private extension ReadingStreakEngine {
    static func dailySummary(
        activityDays: Set<Date>,
        breakPeriods: [ReadingBreakPeriod],
        today: Date,
        calendar: Calendar,
        preservedLongest: Int
    ) -> ReadingStreakSummary {
        let todayStart = calendar.startOfDay(for: today)
        let current = dailyCurrentStreak(
            activityDays: activityDays,
            breakPeriods: breakPeriods,
            today: todayStart,
            calendar: calendar
        )
        let longest = max(
            preservedLongest,
            dailyLongestStreak(
                activityDays: activityDays,
                breakPeriods: breakPeriods,
                calendar: calendar
            )
        )

        return ReadingStreakSummary(
            kind: .daily,
            current: current,
            longest: longest,
            detail: "Any qualifying reading activity keeps this alive."
        )
    }

    static func dailyCurrentStreak(
        activityDays: Set<Date>,
        breakPeriods: [ReadingBreakPeriod],
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard !activityDays.isEmpty else { return 0 }

        var anchorDay: Date?
        var checkDay = today
        var graceDaysUsed = 0

        while graceDaysUsed <= 1 {
            if activityDays.contains(checkDay) {
                anchorDay = checkDay
                break
            }
            if ReadingStats.isDateInBreakPeriod(checkDay, periods: breakPeriods) {
                guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
                checkDay = previous
                continue
            }
            graceDaysUsed += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = previous
        }

        guard let anchorDay else { return 0 }

        var streak = 0
        var day = anchorDay

        for _ in 0..<3650 {
            if activityDays.contains(day) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            } else if ReadingStats.isDateInBreakPeriod(day, periods: breakPeriods) {
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            } else {
                break
            }
        }

        return streak
    }

    static func dailyLongestStreak(
        activityDays: Set<Date>,
        breakPeriods: [ReadingBreakPeriod],
        calendar: Calendar
    ) -> Int {
        let sortedDays = activityDays.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]
            let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: previous) ?? previous

            if calendar.isDate(currentDay, inSameDayAs: expectedNextDay) {
                current += 1
            } else if gapIsCoveredByBreaks(from: expectedNextDay, to: currentDay, breakPeriods: breakPeriods, calendar: calendar) {
                current += 1
            } else {
                current = 1
            }

            best = max(best, current)
        }

        return best
    }

    static func weekendSummary(
        activityDays: Set<Date>,
        configuration: ReadingStreakConfiguration,
        resetAt: Date?,
        today: Date,
        calendar: Calendar,
        preservedLongest: Int
    ) -> ReadingStreakSummary {
        let normalized = configuration.normalized()
        let periods = weekendPeriods(
            activityDays: activityDays,
            day1: normalized.weekendDay1,
            resetAt: resetAt,
            today: today,
            calendar: calendar
        )
        let result = streakResult(periods: periods) { period in
            guard period.targetDates.count == 2 else { return false }
            return activityDays.contains(period.targetDates[0])
            && activityDays.contains(period.targetDates[1])
        }

        return ReadingStreakSummary(
            kind: .weekend,
            current: result.current,
            longest: max(preservedLongest, result.longest),
            detail: "\(normalized.weekendDay1.fullName) + \(normalized.weekendDay2.fullName)"
        )
    }

    static func weeklySummary(
        activityDays: Set<Date>,
        configuration: ReadingStreakConfiguration,
        resetAt: Date?,
        today: Date,
        calendar: Calendar,
        preservedLongest: Int
    ) -> ReadingStreakSummary {
        let normalized = configuration.normalized()
        let periods = weeklyPeriods(
            activityDays: activityDays,
            weekday: normalized.weeklyReadingDay,
            resetAt: resetAt,
            today: today,
            calendar: calendar
        )
        let result = streakResult(periods: periods) { period in
            guard let targetDate = period.targetDates.first else { return false }
            return activityDays.contains(targetDate)
        }

        return ReadingStreakSummary(
            kind: .weekly,
            current: result.current,
            longest: max(preservedLongest, result.longest),
            detail: normalized.weeklyReadingDay.fullName
        )
    }

    static func monthlySummary(
        activityDays: Set<Date>,
        configuration: ReadingStreakConfiguration,
        resetAt: Date?,
        today: Date,
        calendar: Calendar,
        preservedLongest: Int
    ) -> ReadingStreakSummary {
        let normalized = configuration.normalized()
        let periods = monthlyPeriods(
            activityDays: activityDays,
            dayOfMonth: normalized.monthlyReadingDay,
            resetAt: resetAt,
            today: today,
            calendar: calendar
        )
        let result = streakResult(periods: periods) { period in
            guard let targetDate = period.targetDates.first else { return false }
            return activityDays.contains(targetDate)
        }

        return ReadingStreakSummary(
            kind: .monthly,
            current: result.current,
            longest: max(preservedLongest, result.longest),
            detail: "Day \(normalized.monthlyReadingDay)"
        )
    }

    struct Period {
        let targetDates: [Date]
    }

    static func streakResult(periods: [Period], isComplete: (Period) -> Bool) -> (current: Int, longest: Int) {
        guard !periods.isEmpty else { return (0, 0) }

        var longest = 0
        var run = 0

        for period in periods {
            if isComplete(period) {
                run += 1
                longest = max(longest, run)
            } else {
                run = 0
            }
        }

        var current = 0
        for period in periods.reversed() {
            guard isComplete(period) else { break }
            current += 1
        }

        return (current, longest)
    }

    static func weekendPeriods(
        activityDays: Set<Date>,
        day1: ReadingWeekday,
        resetAt: Date?,
        today: Date,
        calendar: Calendar
    ) -> [Period] {
        let todayStart = calendar.startOfDay(for: today)
        let earliest = earliestRelevantDate(activityDays: activityDays, resetAt: resetAt, today: todayStart, calendar: calendar)
        var firstDay = alignedDate(onOrBefore: earliest, weekday: day1, calendar: calendar)
        if let resetAt, firstDay < calendar.startOfDay(for: resetAt) {
            firstDay = nextOrSameWeekday(after: calendar.startOfDay(for: resetAt), weekday: day1, calendar: calendar)
        }

        var periods: [Period] = []
        var day = firstDay

        while let secondDay = calendar.date(byAdding: .day, value: 1, to: day), secondDay <= todayStart {
            periods.append(Period(targetDates: [day, secondDay]))
            guard let next = calendar.date(byAdding: .day, value: 7, to: day) else { break }
            day = next
        }

        return periods
    }

    static func weeklyPeriods(
        activityDays: Set<Date>,
        weekday: ReadingWeekday,
        resetAt: Date?,
        today: Date,
        calendar: Calendar
    ) -> [Period] {
        let todayStart = calendar.startOfDay(for: today)
        let earliest = earliestRelevantDate(activityDays: activityDays, resetAt: resetAt, today: todayStart, calendar: calendar)
        var firstDay = alignedDate(onOrBefore: earliest, weekday: weekday, calendar: calendar)
        if let resetAt, firstDay < calendar.startOfDay(for: resetAt) {
            firstDay = nextOrSameWeekday(after: calendar.startOfDay(for: resetAt), weekday: weekday, calendar: calendar)
        }

        var periods: [Period] = []
        var day = firstDay

        while day <= todayStart {
            periods.append(Period(targetDates: [day]))
            guard let next = calendar.date(byAdding: .day, value: 7, to: day) else { break }
            day = next
        }

        return periods
    }

    static func monthlyPeriods(
        activityDays: Set<Date>,
        dayOfMonth: Int,
        resetAt: Date?,
        today: Date,
        calendar: Calendar
    ) -> [Period] {
        let todayStart = calendar.startOfDay(for: today)
        let earliest = earliestRelevantDate(activityDays: activityDays, resetAt: resetAt, today: todayStart, calendar: calendar)
        let startOfFirstMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliest)) ?? earliest

        var periods: [Period] = []
        var monthStart = startOfFirstMonth

        while monthStart <= todayStart {
            let targetDate = monthlyTargetDate(monthStart: monthStart, dayOfMonth: dayOfMonth, calendar: calendar)
            if targetDate <= todayStart,
               resetAt == nil || targetDate >= calendar.startOfDay(for: resetAt ?? targetDate) {
                periods.append(Period(targetDates: [targetDate]))
            }

            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }
            monthStart = nextMonth
        }

        return periods
    }

    static func earliestRelevantDate(
        activityDays: Set<Date>,
        resetAt: Date?,
        today: Date,
        calendar: Calendar
    ) -> Date {
        if let resetAt {
            return calendar.startOfDay(for: resetAt)
        }

        return activityDays.min() ?? today
    }

    static func alignedDate(onOrBefore date: Date, weekday: ReadingWeekday, calendar: Calendar) -> Date {
        var day = calendar.startOfDay(for: date)
        for _ in 0..<7 {
            if calendar.component(.weekday, from: day) == weekday.rawValue {
                return day
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return calendar.startOfDay(for: date)
    }

    static func nextOrSameWeekday(after date: Date, weekday: ReadingWeekday, calendar: Calendar) -> Date {
        var day = calendar.startOfDay(for: date)
        for _ in 0..<7 {
            if calendar.component(.weekday, from: day) == weekday.rawValue {
                return day
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return calendar.startOfDay(for: date)
    }

    static func monthlyTargetDate(monthStart: Date, dayOfMonth: Int, calendar: Calendar) -> Date {
        let range = calendar.range(of: .day, in: .month, for: monthStart)
        let finalDay = range?.count ?? 28
        var components = calendar.dateComponents([.year, .month], from: monthStart)
        components.day = min(max(dayOfMonth, 1), finalDay)
        return calendar.startOfDay(for: calendar.date(from: components) ?? monthStart)
    }

    static func gapIsCoveredByBreaks(
        from start: Date,
        to end: Date,
        breakPeriods: [ReadingBreakPeriod],
        calendar: Calendar
    ) -> Bool {
        var day = start
        while day < end {
            if !ReadingStats.isDateInBreakPeriod(day, periods: breakPeriods) {
                return false
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return false }
            day = next
        }
        return true
    }
}
