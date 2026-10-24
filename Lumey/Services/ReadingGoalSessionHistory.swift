import Foundation

enum ReadingGoalSessionHistory {
    static func sessions(
        associatedWith goal: ReadingGoals,
        sessions: [ReadingSession],
        history: [ReadingGoalHistory]
    ) -> [ReadingSession] {
        let sourceSessionIDs = Set(history.lazy
            .filter { $0.goalID == goal.id }
            .compactMap(\.sourceSessionID))

        return sessions.filter {
            $0.allLinkedGoalIDs.contains(goal.id) || sourceSessionIDs.contains($0.id)
        }.sorted { $0.date > $1.date }
    }
}
