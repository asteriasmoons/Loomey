//
//  ReadingChallenge.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingChallenge {
    var id: UUID = UUID()
    var title: String = ""
    var challengeDescription: String = ""
    var iconName: String = "openbook"
    var categoryRawValue: String = ChallengeCategory.readingHabit.rawValue
    var points: Int = 0
    var durationDays: Int = 7
    var requirementText: String = ""
    var validationTypeRawValue: String = ChallengeValidationType.readingSession.rawValue
    var recurrenceRawValue: String = ChallengeRecurrence.oneTime.rawValue
    var cycleAnchorDate: Date?

    // Validation requirements
    var requiredBookCount: Int?
    var requiredPageCount: Int?
    var requiredSessionCount: Int?
    var requiredReviewCount: Int?
    var requiredRating: Int?
    var requiredGenre: String?
    var requiredTagsStorage: String = "[]"
    var requiredThemesStorage: String = "[]"
    var requiresAIValidation: Bool = false

    // Additional validation params
    var requiredSessionMinutes: Int?
    var requiredWordCount: Int?
    var requiredUniqueAuthorCount: Int?
    var requiredSameAuthorCount: Int?
    var requiredMinPages: Int?
    var requiredMaxPages: Int?
    var requiredDaysStreak: Int?

    // Featured / Weekly
    var isFeatured: Bool = false
    var isWeekly: Bool = false
    var featuredStartDate: Date?
    var featuredEndDate: Date?

    // Participation counts (local cache)
    var participantCount: Int = 0
    var completedCount: Int = 0

    // Metadata
    var createdDate: Date = Date()

    init(
        title: String = "",
        challengeDescription: String = "",
        iconName: String = "openbook",
        category: ChallengeCategory = .readingHabit,
        points: Int = 0,
        durationDays: Int = 7,
        requirementText: String = "",
        validationType: ChallengeValidationType = .readingSession,
        requiredBookCount: Int? = nil,
        requiredPageCount: Int? = nil,
        requiredSessionCount: Int? = nil,
        requiredReviewCount: Int? = nil,
        requiredRating: Int? = nil,
        requiredGenre: String? = nil,
        requiredTags: [String] = [],
        requiredThemes: [String] = [],
        requiresAIValidation: Bool = false,
        requiredSessionMinutes: Int? = nil,
        requiredWordCount: Int? = nil,
        requiredUniqueAuthorCount: Int? = nil,
        requiredSameAuthorCount: Int? = nil,
        requiredMinPages: Int? = nil,
        requiredMaxPages: Int? = nil,
        requiredDaysStreak: Int? = nil,
        recurrence: ChallengeRecurrence = .oneTime,
        cycleAnchorDate: Date? = nil,
        isFeatured: Bool = false,
        isWeekly: Bool = false,
        featuredStartDate: Date? = nil,
        featuredEndDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = challengeDescription
        self.iconName = iconName
        self.categoryRawValue = category.rawValue
        self.points = points
        self.durationDays = durationDays
        self.requirementText = requirementText
        self.validationTypeRawValue = validationType.rawValue
        self.requiredBookCount = requiredBookCount
        self.requiredPageCount = requiredPageCount
        self.requiredSessionCount = requiredSessionCount
        self.requiredReviewCount = requiredReviewCount
        self.requiredRating = requiredRating
        self.requiredGenre = requiredGenre
        self.requiredTags = requiredTags
        self.requiredThemes = requiredThemes
        self.requiresAIValidation = requiresAIValidation
        self.requiredSessionMinutes = requiredSessionMinutes
        self.requiredWordCount = requiredWordCount
        self.requiredUniqueAuthorCount = requiredUniqueAuthorCount
        self.requiredSameAuthorCount = requiredSameAuthorCount
        self.requiredMinPages = requiredMinPages
        self.requiredMaxPages = requiredMaxPages
        self.requiredDaysStreak = requiredDaysStreak
        self.recurrenceRawValue = (recurrence == .oneTime && isWeekly) ? ChallengeRecurrence.weekly.rawValue : recurrence.rawValue
        self.cycleAnchorDate = cycleAnchorDate
        self.isFeatured = isFeatured
        self.isWeekly = isWeekly
        self.featuredStartDate = featuredStartDate
        self.featuredEndDate = featuredEndDate
        self.createdDate = Date()
    }
}

// MARK: - Computed Properties

extension ReadingChallenge {
    var category: ChallengeCategory {
        get { ChallengeCategory(rawValue: categoryRawValue) ?? .readingHabit }
        set { categoryRawValue = newValue.rawValue }
    }

    var validationType: ChallengeValidationType {
        get { ChallengeValidationType(rawValue: validationTypeRawValue) ?? .readingSession }
        set { validationTypeRawValue = newValue.rawValue }
    }

    var recurrence: ChallengeRecurrence {
        get {
            let stored = ChallengeRecurrence(rawValue: recurrenceRawValue) ?? .oneTime
            if stored == .oneTime && isWeekly {
                return .weekly
            }
            return stored
        }
        set { recurrenceRawValue = newValue.rawValue }
    }

    var isRecurring: Bool {
        recurrence != .oneTime
    }

    var isPhotoProofChallenge: Bool {
        guard validationType == .experience,
              requiresAIValidation,
              durationDays == 1
        else { return false }

        let normalizedRequirement = requirementText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedRequirement.contains("submit a photo") ||
            normalizedRequirement.contains("submit photo proof") ||
            normalizedRequirement.contains("photo proof")
    }

    var requiredTags: [String] {
        get { Self.decodeStringArray(from: requiredTagsStorage) }
        set { requiredTagsStorage = Self.encodeStringArray(newValue) }
    }

    var requiredThemes: [String] {
        get { Self.decodeStringArray(from: requiredThemesStorage) }
        set { requiredThemesStorage = Self.encodeStringArray(newValue) }
    }

    var displayDuration: String {
        if durationDays == 1 { return "1 Day" }
        if durationDays < 30 { return "\(durationDays) Days" }
        if durationDays == 30 { return "1 Month" }
        if durationDays == 60 { return "2 Months" }
        if durationDays == 90 { return "3 Months" }
        if durationDays == 120 { return "4 Months" }
        if durationDays == 180 { return "6 Months" }
        if durationDays == 365 { return "1 Year" }
        return "\(durationDays) Days"
    }

    var displayPoints: String {
        "\(points) pts"
    }

    func cycle(containing date: Date = Date(), calendar: Calendar = .current) -> ChallengeCycle {
        let anchorDate = cycleAnchorDate ?? featuredStartDate ?? createdDate
        let anchor = calendar.startOfDay(for: anchorDate)

        guard isRecurring else {
            let end = calendar.date(byAdding: .day, value: durationDays, to: anchor) ?? anchor
            return ChallengeCycle(
                id: "\(id.uuidString):one-time",
                startDate: anchor,
                endDate: end
            )
        }

        let targetDate = max(calendar.startOfDay(for: date), anchor)
        var start = anchor
        var end = nextCycleEnd(after: start, calendar: calendar)

        while targetDate >= end {
            start = end
            end = nextCycleEnd(after: start, calendar: calendar)
        }

        return ChallengeCycle(
            id: "\(id.uuidString):\(Self.cycleKey(for: start, calendar: calendar))",
            startDate: start,
            endDate: end
        )
    }

    func cycle(containingEntryStart date: Date, calendar: Calendar = .current) -> ChallengeCycle {
        cycle(containing: date, calendar: calendar)
    }

    static func rotatingFeaturedChallenge(
        from challenges: [ReadingChallenge],
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> ReadingChallenge? {
        let pool = challenges
            .filter { $0.durationDays == 1 && $0.isRecurring }
            .sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category.rawValue.localizedCaseInsensitiveCompare(rhs.category.rawValue) == .orderedAscending
                }

                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

        guard !pool.isEmpty else { return nil }

        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let startIndex = day % pool.count

        return pool[startIndex]
    }

    private func nextCycleEnd(after start: Date, calendar: Calendar) -> Date {
        switch recurrence {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: start) ?? start
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: start) ?? start
        case .custom:
            return calendar.date(byAdding: .day, value: max(durationDays, 1), to: start) ?? start
        case .oneTime:
            return calendar.date(byAdding: .day, value: durationDays, to: start) ?? start
        }
    }

    // MARK: - JSON Helpers

    private static func cycleKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        return "\(year)-\(month)-\(day)"
    }

    private static func decodeStringArray(from storage: String) -> [String] {
        guard let data = storage.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private static func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}

struct ChallengeCycle: Equatable {
    let id: String
    let startDate: Date
    let endDate: Date
}
