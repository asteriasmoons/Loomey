//
//  LumeyApp.swift
//  Lumey
//

import SwiftUI
import SwiftData

@main
struct LumeyApp: App {
    private static let cloudKitContainerIdentifier = "iCloud.im.lystaria.Lumey"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AuthUser.self,
            UserSettings.self,
            Item.self,
            Book.self,
            BookNote.self,
            BookQuote.self,
            BookReview.self,
            ReadingInsight.self,
            ChallengeComment.self,
            ChallengeBookmark.self,
            ChallengeEntry.self,
            ChallengeLike.self,
            ChallengeSubmission.self,
            ChallengeUserProfile.self,
            EPUBBookmark.self,
            EPUBHighlight.self,
            FeedAnnouncement.self,
            ReadingGoals.self,
            ReadingChallenge.self,
            ReadingAchievement.self,
            ReadingDream.self,
            ReadingStats.self,
            ReadingGoalHistory.self,
            ReadingMission.self,
            ReadingMissionTask.self,
            ReadingMissionHistory.self,
            ReadingBingoProgress.self,
            ReadingSession.self,
            ReadingXPProfile.self,
            ReadingXPEvent.self,
            ReadingStreakPreferences.self,
            ReadingLibrarySettings.self,
            ReadingLibraryCustomFilter.self,
            GoalNote.self,
            ReadingList.self,
            ReaderSettings.self,
            EPUBCollection.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let backfillKey = "ReadingSessionGoalBackfillV7"

                    print("🚀 Starting ReadingSessionGoalBackfill")

                    guard !UserDefaults.standard.bool(forKey: backfillKey) else {
                        print("⏭️ Backfill already completed.")
                        return
                    }

                    let context = sharedModelContainer.mainContext

                    let goals = (try? context.fetch(FetchDescriptor<ReadingGoals>())) ?? []
                    let sessions = (try? context.fetch(FetchDescriptor<ReadingSession>())) ?? []
                    print("Goals: \(goals.count)")
                    print("Sessions: \(sessions.count)")

                    var changed = false

                    for session in sessions {

                        print("------------")
                        print("Session: \(session.linkedBookTitle)")
                        print("linkedGoalID = \(String(describing: session.linkedGoalID))")
                        print("linkedBookID = \(String(describing: session.linkedBookID))")

                        guard session.linkedGoalID == nil else {
                            print("⏭️ Already has goal")
                            continue
                        }

                        guard let bookID = session.linkedBookID else {
                            print("❌ No linkedBookID")
                            continue
                        }

                        print("✅ Using bookID: \(bookID)")

                        let goal = goals.first { goal in
                            print("Checking goal: \(goal.displayTitle)")
                            print(goal.linkedBookIDs)
                            return goal.linkedBookIDs.contains(bookID)
                        }

                        guard let goal else {
                            print("❌ No goal matched")
                            continue
                        }

                        print("🎉 MATCHED \(goal.displayTitle)")

                        session.linkedGoalID = goal.id
                        session.linkedGoalTitle = goal.displayTitle
                        changed = true
                    }
                    
                    // MARK: - GOAL BACKFILL
                    for goal in goals {
                        let allHistory = (try? context.fetch(FetchDescriptor<ReadingGoalHistory>())) ?? []

                        let alreadyHasCompletionHistory = allHistory.contains {
                            $0.goalID == goal.id &&
                            $0.eventTypeRawValue == "Completed"
                        }

                        if alreadyHasCompletionHistory {
                            continue
                        }

                        let goalSessions = sessions.filter { session in
                            if session.linkedGoalID == goal.id {
                                return true
                            }

                            if session.linkedGoalTitle == goal.displayTitle {
                                return true
                            }

                            if let bookID = session.linkedBookID,
                               goal.linkedBookIDs.contains(bookID) {
                                return true
                            }

                            if goal.type == .pages && session.pagesRead > 0 {
                                return true
                            }

                            if goal.type == .minutes && session.durationMinutes > 0 {
                                return true
                            }

                            if goal.type == .hours && session.durationMinutes > 0 {
                                return true
                            }

                            return false
                        }

                        guard !goalSessions.isEmpty else {
                            continue
                        }

                        switch goal.type {

                        case .pages:

                            let total = goalSessions.reduce(0) { $0 + $1.pagesRead }

                            if Double(total) > goal.currentValue {
                                goal.currentValue = Double(total)
                                changed = true
                            }

                            if Double(total) >= goal.targetValue {

                                goal.status = .completed

                                if goal.completedDate == nil {
                                    goal.completedDate = goalSessions
                                        .max(by: { $0.date < $1.date })?
                                        .date
                                }

                                goal.lastProgressResetDate = goal.completedDate
                                goal.updatedAt = Date()
                                
                                let history = ReadingGoalHistory(
                                    goalID: goal.id,
                                    goalTitleSnapshot: goal.displayTitle,
                                    eventType: .completed,
                                    previousValue: 0,
                                    newValue: Double(total),
                                    targetValue: goal.targetValue,
                                    previousStreak: 0,
                                    newStreak: goal.currentStreak,
                                    bestStreak: goal.bestStreak,
                                    note: "Backfilled from reading sessions.",
                                    rewardEarned: goal.rewardIdea,
                                    createdAt: goal.completedDate ?? Date()
                                )

                                context.insert(history)

                                changed = true
                            }

                        case .minutes:

                            let total = goalSessions.reduce(0) { $0 + $1.durationMinutes }

                            if Double(total) > goal.currentValue {
                                goal.currentValue = Double(total)
                                changed = true
                            }

                            if Double(total) >= goal.targetValue {

                                goal.status = .completed

                                if goal.completedDate == nil {
                                    goal.completedDate = goalSessions
                                        .max(by: { $0.date < $1.date })?
                                        .date
                                }

                                goal.lastProgressResetDate = goal.completedDate
                                goal.updatedAt = Date()
                                
                                let history = ReadingGoalHistory(
                                    goalID: goal.id,
                                    goalTitleSnapshot: goal.displayTitle,
                                    eventType: .completed,
                                    previousValue: 0,
                                    newValue: Double(total),
                                    targetValue: goal.targetValue,
                                    previousStreak: 0,
                                    newStreak: goal.currentStreak,
                                    bestStreak: goal.bestStreak,
                                    note: "Backfilled from reading sessions.",
                                    rewardEarned: goal.rewardIdea,
                                    createdAt: goal.completedDate ?? Date()
                                )

                                context.insert(history)

                                changed = true
                            }

                        case .hours:

                            let totalMinutes = goalSessions.reduce(0) { $0 + $1.durationMinutes }
                            let totalHours = Double(totalMinutes) / 60

                            if totalHours > goal.currentValue {
                                goal.currentValue = totalHours
                                changed = true
                            }

                            if totalHours >= goal.targetValue {

                                goal.status = .completed

                                if goal.completedDate == nil {
                                    goal.completedDate = goalSessions
                                        .max(by: { $0.date < $1.date })?
                                        .date
                                }

                                goal.lastProgressResetDate = goal.completedDate
                                goal.updatedAt = Date()
                                
                                let history = ReadingGoalHistory(
                                    goalID: goal.id,
                                    goalTitleSnapshot: goal.displayTitle,
                                    eventType: .completed,
                                    previousValue: 0,
                                    newValue: totalHours,
                                    targetValue: goal.targetValue,
                                    previousStreak: 0,
                                    newStreak: goal.currentStreak,
                                    bestStreak: goal.bestStreak,
                                    note: "Backfilled from reading sessions.",
                                    rewardEarned: goal.rewardIdea,
                                    createdAt: goal.completedDate ?? Date()
                                )

                                context.insert(history)

                                changed = true
                            }

                        default:
                            break
                        }
                    }

                    if changed {
                        try? context.save()
                        print("✅ Reading Session Goal Backfill Complete")
                    }

                    UserDefaults.standard.set(true, forKey: backfillKey)
                }
                .task {
                    let breakMigrationKey = "ReadingBreakFieldsMigrationV1"
                    guard !UserDefaults.standard.bool(forKey: breakMigrationKey) else { return }
                    let context = sharedModelContainer.mainContext
                    let allStats = (try? context.fetch(FetchDescriptor<ReadingStats>())) ?? []
                    for stat in allStats {
                        stat.updatedAt = Date()
                    }
                    if !allStats.isEmpty {
                        try? context.save()
                    }
                    UserDefaults.standard.set(true, forKey: breakMigrationKey)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
