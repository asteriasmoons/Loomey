//
//  ReadingCatchUpService.swift
//  Lumey
//

import Foundation
import SwiftData

struct ReadingCatchUpSessionPlan: Identifiable, Equatable {
    let sequence: Int
    let date: Date
    let startPage: Int
    let endPage: Int
    let pagesRead: Int

    var id: Int { sequence }
}

struct ReadingCatchUpPreview: Equatable {
    let lastLoggedPage: Int
    let currentPage: Int
    let missingPages: Int
    let readingDays: Int
    let sessions: [ReadingCatchUpSessionPlan]
}

enum ReadingCatchUpError: LocalizedError {
    case currentPageRequired
    case readingDaysRequired
    case currentPageNotAhead(lastLoggedPage: Int)
    case currentPageExceedsBook(totalPages: Int)
    case moreDaysThanPages(missingPages: Int)
    case dateGenerationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .currentPageRequired:
            return "Enter your current book page."
        case .readingDaysRequired:
            return "Enter how many days you read."
        case .currentPageNotAhead(let lastLoggedPage):
            return "Current page must be later than your last logged page, \(lastLoggedPage)."
        case .currentPageExceedsBook(let totalPages):
            return "Current page cannot be higher than the book's \(totalPages) pages."
        case .moreDaysThanPages(let missingPages):
            return "Reading days cannot exceed the \(missingPages) missing pages."
        case .dateGenerationFailed:
            return "Lumey could not create the session dates. Try again."
        case .saveFailed:
            return "Lumey could not save the Catch Up sessions. Try again."
        }
    }
}

enum ReadingCatchUpService {
    static func lastLoggedPage(for book: Book, sessions: [ReadingSession]) -> Int {
        let latestBookSession = sessions
            .filter { $0.linkedBookID == book.id }
            .max { $0.date < $1.date }

        if let latestBookSession, latestBookSession.endPage > 0 {
            return latestBookSession.endPage
        }

        return max(book.currentPage, 0)
    }

    static func makePreview(
        lastLoggedPage: Int,
        currentPage: Int?,
        readingDays: Int?,
        bookTotalPages: Int,
        today: Date = Date(),
        calendar: Calendar = .current
    ) throws -> ReadingCatchUpPreview {
        guard let currentPage, currentPage > 0 else {
            throw ReadingCatchUpError.currentPageRequired
        }
        guard let readingDays, readingDays > 0 else {
            throw ReadingCatchUpError.readingDaysRequired
        }
        guard currentPage > lastLoggedPage else {
            throw ReadingCatchUpError.currentPageNotAhead(lastLoggedPage: lastLoggedPage)
        }
        if bookTotalPages > 0, currentPage > bookTotalPages {
            throw ReadingCatchUpError.currentPageExceedsBook(totalPages: bookTotalPages)
        }

        let missingPages = currentPage - lastLoggedPage
        guard readingDays <= missingPages else {
            throw ReadingCatchUpError.moreDaysThanPages(missingPages: missingPages)
        }

        let basePagesPerDay = missingPages / readingDays
        let remainder = missingPages % readingDays
        let todayStart = calendar.startOfDay(for: today)
        var datesNewestFirst: [Date] = []

        for index in 0..<readingDays {
            guard let date = calendar.date(byAdding: .day, value: -index, to: todayStart) else {
                throw ReadingCatchUpError.dateGenerationFailed
            }
            datesNewestFirst.append(date)
        }

        var pageCursor = lastLoggedPage
        var plans: [ReadingCatchUpSessionPlan] = []

        for (index, date) in datesNewestFirst.reversed().enumerated() {
            let receivesRemainderPage = remainder > 0 && index >= readingDays - remainder
            let pagesRead = basePagesPerDay + (receivesRemainderPage ? 1 : 0)
            let endPage = pageCursor + pagesRead
            plans.append(
                ReadingCatchUpSessionPlan(
                    sequence: index,
                    date: date,
                    startPage: pageCursor,
                    endPage: endPage,
                    pagesRead: pagesRead
                )
            )
            pageCursor = endPage
        }

        return ReadingCatchUpPreview(
            lastLoggedPage: lastLoggedPage,
            currentPage: currentPage,
            missingPages: missingPages,
            readingDays: readingDays,
            sessions: plans
        )
    }

    @discardableResult
    static func createSessions(
        for book: Book,
        preview: ReadingCatchUpPreview,
        existingSessions: [ReadingSession],
        modelContext: ModelContext
    ) throws -> [ReadingSession] {
        let recoveredSessions = preview.sessions.map { plan in
            ReadingSession(
                linkedBookID: book.id,
                linkedBookTitle: book.title,
                durationMinutes: 0,
                pagesRead: plan.pagesRead,
                startPage: plan.startPage,
                endPage: plan.endPage,
                isCatchUpSession: true,
                notes: "",
                date: plan.date
            )
        }

        recoveredSessions.forEach(modelContext.insert)
        if book.canConvertEbookPages {
            let ebookPosition = Int(
                round(
                    (Double(preview.currentPage) / Double(book.totalPages))
                    * Double(book.ebookTotalPages)
                )
            )
            book.ebookCurrentPage = min(max(ebookPosition, 0), book.ebookTotalPages)
        }
        book.currentPage = preview.currentPage
        book.lastUpdated = Date()

        refreshStats(using: existingSessions + recoveredSessions, modelContext: modelContext)

        do {
            try modelContext.save()
        } catch {
            throw ReadingCatchUpError.saveFailed
        }

        return recoveredSessions
    }
}

private extension ReadingCatchUpService {
    static func refreshStats(using sessions: [ReadingSession], modelContext: ModelContext) {
        let stats = ReadingStats.fetchOrCreate(in: modelContext)
        let calendar = Calendar.current
        let now = Date()

        stats.totalReadingSessions = sessions.count
        stats.totalMinutesRead = sessions.reduce(0) { $0 + $1.durationMinutes }
        stats.totalPagesRead = sessions.reduce(0) { $0 + $1.pagesRead }
        stats.longestReadingSessionMinutes = sessions.map(\.durationMinutes).max() ?? 0
        stats.lastReadingDate = sessions.map(\.date).max()

        let todaySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        stats.minutesReadToday = todaySessions.reduce(0) { $0 + $1.durationMinutes }
        stats.pagesReadToday = todaySessions.reduce(0) { $0 + $1.pagesRead }

        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let monthSessions = sessions.filter {
            calendar.component(.year, from: $0.date) == currentYear
            && calendar.component(.month, from: $0.date) == currentMonth
        }
        stats.minutesReadThisMonth = monthSessions.reduce(0) { $0 + $1.durationMinutes }
        stats.pagesReadThisMonth = monthSessions.reduce(0) { $0 + $1.pagesRead }

        let yearSessions = sessions.filter { calendar.component(.year, from: $0.date) == currentYear }
        stats.pagesReadThisYear = yearSessions.reduce(0) { $0 + $1.pagesRead }

        let preferences = (try? modelContext.fetch(FetchDescriptor<ReadingStreakPreferences>())) ?? []
        let dailyStreak = ReadingStreakEngine.summary(
            for: .daily,
            sessions: sessions,
            preferences: ReadingStreakPreferences.preferredRecord(from: preferences),
            breakPeriods: stats.breakPeriods,
            today: now,
            calendar: calendar,
            preservedDailyLongest: stats.bestReadingStreak
        )
        stats.currentReadingStreak = dailyStreak.current
        stats.bestReadingStreak = max(stats.bestReadingStreak, dailyStreak.longest)
        stats.updatedAt = now
    }
}
