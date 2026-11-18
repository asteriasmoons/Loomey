//
//  ReadingGoalCatchUpService.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Catch Up Goal Impact (preview model)

/// Describes how a recovered Catch Up batch will contribute to a single reading goal.
///
/// The same evaluation drives both the Catch Up preview and the actual save, so the
/// numbers a user sees before creating sessions always match what is applied.
struct ReadingGoalCatchUpImpact: Identifiable, Equatable {
    enum Metric: Equatable {
        /// Pages added to the goal's current-period progress.
        case pages(Int)
        /// Unique historical reading days contributed toward a streak goal.
        case readingDays(Int)
    }

    let goalID: UUID
    let goalTitle: String
    let goalType: ReadingGoalType
    let metric: Metric

    var id: UUID { goalID }

    /// Short "+N unit" label shown in the preview, matching the goal's measurement type.
    var contributionText: String {
        switch metric {
        case .pages(let pages):
            return "+\(pages) \(pages == 1 ? "page" : "pages")"
        case .readingDays(let days):
            return "+\(days) \(days == 1 ? "day" : "days")"
        }
    }
}

// MARK: - Reading Goal Catch Up Service

/// Shared logic that decides which existing reading goals a set of recovered Catch Up
/// sessions legitimately contributes to, and applies that progress using the project's
/// existing goal mutators and history records.
///
/// Recovered sessions always carry `durationMinutes == 0`, so only the goal types that can
/// be established from real page/day data receive automatic progress:
/// - `.pages`  — from the session's actual pages read.
/// - `.streak` — from the session's historical reading date, via the existing streak rules.
///
/// All other goal types remain manually managed, exactly as they are for ordinary reading
/// sessions (whose `sessionProgressIncrement(minutes:pages:)` also returns `0` for them).
enum ReadingGoalCatchUpService {

    // MARK: Eligibility

    /// Whether a recovered session for `bookID` on `date` can legitimately contribute to `goal`.
    ///
    /// Eligibility is evaluated individually for every session and goal: a goal never receives
    /// progress simply because it exists. A session qualifies only when the goal is an active,
    /// automatically-measurable type, the book matches the goal's linked books (when any), and
    /// the historical reading date falls inside the goal's applicable date window.
    static func goalQualifies(
        _ goal: ReadingGoals,
        bookID: UUID?,
        on date: Date,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        // Status: mirror the ordinary flow, which only offers active, non-archived goals, and
        // whose progress mutators guard on `status == .active`.
        guard goal.status == .active, !goal.isArchived else { return false }

        // Only goal types a recovered (page-based, zero-duration) session can legitimately move.
        guard goal.type == .pages || goal.type == .streak else { return false }

        // Linked books: a goal scoped to specific books only accepts those books; a goal with no
        // linked books is general and accepts any book.
        let linkedBookIDs = goal.linkedBookIDs
        if !linkedBookIDs.isEmpty {
            guard let bookID, linkedBookIDs.contains(bookID) else { return false }
        }

        let day = calendar.startOfDay(for: date)

        // Never count reading before the goal was applicable.
        guard day >= applicabilityFloor(for: goal, calendar: calendar) else { return false }

        // Respect the goal's target date when present.
        if let targetDate = goal.targetDate {
            guard day <= calendar.startOfDay(for: targetDate) else { return false }
        }

        // Never count reading in the future relative to when Catch Up runs.
        guard day <= calendar.startOfDay(for: today) else { return false }

        return true
    }

    /// The earliest day a session may count toward the goal.
    ///
    /// For recurring goals this is the start of the period that contains the goal's start date, so
    /// reading recovered earlier in the current period still counts even if the goal was created a
    /// few days into that period. For non-recurring goals it is simply the goal's start day.
    private static func applicabilityFloor(for goal: ReadingGoals, calendar: Calendar) -> Date {
        if goal.isRecurringGoal,
           let periodStart = goal.cycleDateInterval(containing: goal.startDate, calendar: calendar)?.start {
            return calendar.startOfDay(for: periodStart)
        }
        return calendar.startOfDay(for: goal.startDate)
    }

    /// Whether a qualifying session's date belongs to the goal's current progress period.
    ///
    /// Non-recurring goals accumulate across all time, so every qualifying date is "current".
    /// Recurring goals only advance `currentValue` for dates in the same cycle as `today`; dates
    /// from earlier cycles are preserved in history without inflating the current period.
    static func isCurrentPeriod(
        _ goal: ReadingGoals,
        date: Date,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard goal.isRecurringGoal else { return true }
        let sessionCycle = goal.cycleDateInterval(containing: date, calendar: calendar)
        let currentCycle = goal.cycleDateInterval(containing: today, calendar: calendar)
        return sessionCycle?.start == currentCycle?.start
    }

    // MARK: Preview

    /// Builds the list of goal impacts shown in the Catch Up preview.
    ///
    /// Only goals with a genuine, non-zero contribution are returned, and each headline reflects
    /// exactly what the save will apply: current-period pages for page goals, and the count of
    /// qualifying unique reading days for streak goals.
    static func previewImpacts(
        book: Book,
        plans: [ReadingCatchUpSessionPlan],
        goals: [ReadingGoals],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> [ReadingGoalCatchUpImpact] {
        var impacts: [ReadingGoalCatchUpImpact] = []

        for goal in goals {
            let qualifyingPlans = plans.filter {
                goalQualifies(goal, bookID: book.id, on: $0.date, today: today, calendar: calendar)
            }
            guard !qualifyingPlans.isEmpty else { continue }

            switch goal.type {
            case .pages:
                // Headline the pages that will actually move the visible (current-period) progress.
                let currentPeriodPages = qualifyingPlans
                    .filter { isCurrentPeriod(goal, date: $0.date, today: today, calendar: calendar) }
                    .reduce(0) { $0 + $1.pagesRead }

                guard currentPeriodPages > 0 else { continue }
                impacts.append(
                    ReadingGoalCatchUpImpact(
                        goalID: goal.id,
                        goalTitle: goal.displayTitle,
                        goalType: .pages,
                        metric: .pages(currentPeriodPages)
                    )
                )

            case .streak:
                let uniqueDays = Set(qualifyingPlans.map { calendar.startOfDay(for: $0.date) }).count
                guard uniqueDays > 0 else { continue }
                impacts.append(
                    ReadingGoalCatchUpImpact(
                        goalID: goal.id,
                        goalTitle: goal.displayTitle,
                        goalType: .streak,
                        metric: .readingDays(uniqueDays)
                    )
                )

            default:
                continue
            }
        }

        return impacts
    }

    // MARK: Apply (save)

    /// Applies recovered-session progress to every qualifying goal and records goal history.
    ///
    /// This mutates goals and inserts `ReadingGoalHistory` into `modelContext` but does not save;
    /// the caller commits the whole Catch Up batch atomically. Goal-completion XP is deferred to
    /// the returned set so it is only awarded once the batch is successfully persisted.
    ///
    /// - Returns: the goals that transitioned to completed as a result of these contributions.
    @discardableResult
    static func applyContributions(
        recoveredSessions: [ReadingSession],
        goals: [ReadingGoals],
        stats: ReadingStats,
        existingHistory: [ReadingGoalHistory],
        today: Date = Date(),
        calendar: Calendar = .current,
        modelContext: ModelContext
    ) -> [ReadingGoals] {
        // Apply oldest-first so streak continuity and bridging follow the real reading order.
        let orderedSessions = recoveredSessions.sorted { $0.date < $1.date }
        var completedGoals: [ReadingGoals] = []

        for goal in goals {
            for session in orderedSessions {
                guard goalQualifies(goal, bookID: session.linkedBookID, on: session.date, today: today, calendar: calendar) else {
                    continue
                }

                // Guard against re-applying a contribution that already exists for this
                // (goal, session) pair, so a retried operation never double-counts.
                let alreadyApplied = existingHistory.contains {
                    $0.goalID == goal.id && $0.sourceSessionID == session.id
                }
                guard !alreadyApplied else { continue }

                // Associate the recovered session with the goal using the existing model fields.
                associate(session: session, with: goal)

                switch goal.type {
                case .pages:
                    applyPagesContribution(
                        goal: goal,
                        session: session,
                        today: today,
                        calendar: calendar,
                        completedGoals: &completedGoals,
                        modelContext: modelContext
                    )
                case .streak:
                    applyStreakContribution(
                        goal: goal,
                        session: session,
                        stats: stats,
                        completedGoals: &completedGoals,
                        modelContext: modelContext
                    )
                default:
                    break
                }
            }
        }

        return completedGoals
    }

    // MARK: Backfill

    /// One-time backfill for Catch Up batches that were created before Catch Up integrated with
    /// reading goals. Credits each recovered session's page/streak contribution to its eligible
    /// goals, scoped to sessions created on or after `createdOnOrAfter`.
    ///
    /// It is **goal-only**: statistics and book progress are left untouched because the original
    /// Catch Up already updated them. It is **idempotent**: `applyContributions` skips any session
    /// that already has goal history for a goal, so running it again never double-counts.
    ///
    /// Mutations and history are staged into `modelContext` but not saved; the caller commits and
    /// then awards completion XP for the returned goals, so a failed save can be retried safely.
    ///
    /// - Returns: the goals that transitioned to completed as a result of the backfill.
    @discardableResult
    static func backfillCatchUpContributions(
        createdOnOrAfter cutoff: Date,
        today: Date = Date(),
        calendar: Calendar = .current,
        modelContext: ModelContext
    ) -> [ReadingGoals] {
        let goals = (try? modelContext.fetch(FetchDescriptor<ReadingGoals>())) ?? []
        guard !goals.isEmpty else { return [] }

        let allSessions = (try? modelContext.fetch(FetchDescriptor<ReadingSession>())) ?? []
        let catchUpSessions = allSessions.filter {
            $0.isCatchUpSession && $0.createdAt >= cutoff
        }
        guard !catchUpSessions.isEmpty else { return [] }

        let existingHistory = (try? modelContext.fetch(FetchDescriptor<ReadingGoalHistory>())) ?? []
        let stats = ReadingStats.fetchOrCreate(in: modelContext)

        return applyContributions(
            recoveredSessions: catchUpSessions,
            goals: goals,
            stats: stats,
            existingHistory: existingHistory,
            today: today,
            calendar: calendar,
            modelContext: modelContext
        )
    }

    // MARK: Contribution helpers

    private static func applyPagesContribution(
        goal: ReadingGoals,
        session: ReadingSession,
        today: Date,
        calendar: Calendar,
        completedGoals: inout [ReadingGoals],
        modelContext: ModelContext
    ) {
        let pages = session.pagesRead
        guard pages > 0 else { return }

        let previousValue = goal.currentValue
        let previousStatus = goal.status

        if isCurrentPeriod(goal, date: session.date, today: today, calendar: calendar) {
            // Current period: advance the goal's visible progress, mirroring an ordinary session.
            goal.incrementProgress(by: Double(pages))

            insertHistory(
                for: goal,
                eventType: .progressUpdated,
                previousValue: previousValue,
                newValue: goal.currentValue,
                previousStreak: goal.currentStreak,
                newStreak: goal.currentStreak,
                sessionProgressDelta: Double(pages),
                contributionCycleStart: goal.cycleDateInterval(
                    containing: goal.lastProgressResetDate ?? session.date,
                    calendar: calendar
                )?.start,
                note: "Catch Up session added \(pages) \(pages == 1 ? "page" : "pages") to goal progress.",
                sourceSession: session,
                modelContext: modelContext
            )

            if previousStatus != .completed, goal.status == .completed {
                insertHistory(
                    for: goal,
                    eventType: .completed,
                    previousValue: previousValue,
                    newValue: goal.currentValue,
                    previousStreak: goal.currentStreak,
                    newStreak: goal.currentStreak,
                    sessionProgressDelta: Double(pages),
                    contributionCycleStart: goal.cycleDateInterval(
                        containing: goal.lastProgressResetDate ?? session.date,
                        calendar: calendar
                    )?.start,
                    note: "Goal completed from recovered Catch Up reading.",
                    sourceSession: session,
                    modelContext: modelContext
                )
                completedGoals.append(goal)
            }
        } else {
            // Earlier recurring period: preserve the contribution in history for its own period
            // without inflating the current period's progress.
            let cycleStart = goal.cycleDateInterval(containing: session.date, calendar: calendar)?.start
            insertHistory(
                for: goal,
                eventType: .progressUpdated,
                previousValue: goal.currentValue,
                newValue: goal.currentValue,
                previousStreak: goal.currentStreak,
                newStreak: goal.currentStreak,
                sessionProgressDelta: Double(pages),
                contributionCycleStart: cycleStart,
                note: "Catch Up recovered \(pages) \(pages == 1 ? "page" : "pages") from an earlier period.",
                sourceSession: session,
                modelContext: modelContext
            )
        }
    }

    private static func applyStreakContribution(
        goal: ReadingGoals,
        session: ReadingSession,
        stats: ReadingStats,
        completedGoals: inout [ReadingGoals],
        modelContext: ModelContext
    ) {
        let previousValue = goal.currentValue
        let previousStreak = goal.currentStreak
        let previousBestStreak = goal.bestStreak
        let previousStatus = goal.status

        // Reuse the existing streak rules, including break-period bridging, exactly as an ordinary
        // session does. Same-day repeats are ignored inside `updateStreak`.
        let shouldBridge: Bool = {
            guard let last = goal.lastCompletedDate else { return false }
            return stats.shouldBridgeStreakGap(from: last, to: session.date)
        }()
        goal.updateStreak(completedOn: session.date, bridgeBreakGap: shouldBridge)

        if previousStreak != goal.currentStreak || previousBestStreak != goal.bestStreak {
            insertHistory(
                for: goal,
                eventType: .streakUpdated,
                previousValue: previousValue,
                newValue: goal.currentValue,
                previousStreak: previousStreak,
                newStreak: goal.currentStreak,
                sessionProgressDelta: goal.currentValue - previousValue,
                contributionCycleStart: goal.cycleDateInterval(
                    containing: goal.lastProgressResetDate ?? session.date
                )?.start,
                note: "Reading streak updated from a recovered Catch Up day.",
                sourceSession: session,
                modelContext: modelContext
            )
        }

        if previousStatus != .completed, goal.status == .completed {
            insertHistory(
                for: goal,
                eventType: .completed,
                previousValue: previousValue,
                newValue: goal.currentValue,
                previousStreak: previousStreak,
                newStreak: goal.currentStreak,
                sessionProgressDelta: goal.currentValue - previousValue,
                contributionCycleStart: goal.cycleDateInterval(
                    containing: goal.lastProgressResetDate ?? session.date
                )?.start,
                note: "Streak goal completed from recovered Catch Up reading.",
                sourceSession: session,
                modelContext: modelContext
            )
            completedGoals.append(goal)
        }
    }

    // MARK: Associations & history

    private static func associate(session: ReadingSession, with goal: ReadingGoals) {
        var ids = session.linkedGoalIDs
        guard !ids.contains(goal.id) else { return }
        ids.append(goal.id)
        session.linkedGoalIDs = ids

        var titles = session.linkedGoalTitles
        titles.append(goal.displayTitle)
        session.linkedGoalTitles = titles
    }

    /// Inserts a goal-history record for a recovered contribution. Does not save; the caller
    /// commits the Catch Up batch atomically. XP for completions is handled by the caller after
    /// the save succeeds, so no completion reward is granted here.
    private static func insertHistory(
        for goal: ReadingGoals,
        eventType: ReadingGoalHistoryType,
        previousValue: Double,
        newValue: Double,
        previousStreak: Int,
        newStreak: Int,
        sessionProgressDelta: Double,
        contributionCycleStart: Date?,
        note: String,
        sourceSession: ReadingSession,
        modelContext: ModelContext
    ) {
        let history = ReadingGoalHistory(
            goalID: goal.id,
            goalTitleSnapshot: goal.displayTitle,
            eventType: eventType,
            previousValue: previousValue,
            newValue: newValue,
            targetValue: goal.targetValue,
            previousStreak: previousStreak,
            newStreak: newStreak,
            bestStreak: goal.bestStreak,
            note: note,
            createdAt: Date(),
            sourceSessionID: sourceSession.id,
            sessionProgressDelta: sessionProgressDelta,
            contributionCycleStart: contributionCycleStart
        )

        modelContext.insert(history)
    }
}
