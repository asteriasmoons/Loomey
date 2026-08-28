//
//  ReadingStatsView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingStatsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var statsRecords: [ReadingStats]

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var allNotes: [BookNote]

    @Query
    private var allQuotes: [BookQuote]

    @Query
    private var allReviews: [BookReview]

    @Query(sort: \ReadingXPProfile.updatedAt, order: .reverse)
    private var xpProfiles: [ReadingXPProfile]

    @Query(sort: \ReadingStreakPreferences.updatedAt, order: .reverse)
    private var streakPreferenceRecords: [ReadingStreakPreferences]

    @Query(sort: \ReadingMission.generatedAt, order: .reverse)
    private var readingMissions: [ReadingMission]

    @Query(sort: \ReadingMissionTask.sortIndex)
    private var readingMissionTasks: [ReadingMissionTask]

    @State private var showingBreakSheet = false
    @State private var visibleRecentSessionCount = 4
    @State private var editingRecentSession: ReadingSession?

    private var stats: ReadingStats? {
        ReadingStats.preferredRecord(from: statsRecords)
    }

    private var xpProfile: ReadingXPProfile? {
        ReadingXPService.preferredProfile(from: xpProfiles)
    }

    private var xpSummary: ReadingXPLevelSummary {
        ReadingXPService.levelSummary(totalXP: xpProfile?.totalXP ?? 0)
    }

    private var streakPreferences: ReadingStreakPreferences? {
        ReadingStreakPreferences.preferredRecord(from: streakPreferenceRecords)
    }

    private var streakSummaries: [ReadingStreakSummary] {
        ReadingStreakEngine.summaries(
            sessions: sessions,
            preferences: streakPreferences,
            breakPeriods: stats?.breakPeriods ?? [],
            preservedDailyLongest: stats?.bestReadingStreak ?? 0
        )
    }

    private var dailyStreakSummary: ReadingStreakSummary {
        streakSummaries.first { $0.kind == .daily }
        ?? ReadingStreakSummary(kind: .daily, current: 0, longest: 0, detail: "")
    }

    private var missionStats: ReadingMissionStatsSummary {
        ReadingMissionStatsCalculator.summary(missions: readingMissions, tasks: readingMissionTasks)
    }

    // MARK: - Derived aggregates

    private var totalPoints: Int {
        sessions.reduce(0) { $0 + $1.pointsEarned } + readingMissions.reduce(0) { $0 + $1.pointsAwarded }
    }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalPages: Int {
        sessions.reduce(0) { $0 + $1.pagesRead }
    }

    private var finishedBooksForMilestones: [Book] {
        books.filter {
            !$0.isArchived &&
            $0.status == .finished
        }
    }

    private var totalFinishedBookPages: Int {
        finishedBooksForMilestones.reduce(0) { total, book in
            total + finishedPageCount(for: book)
        }
    }

    private var totalSessions: Int {
        sessions.count
    }
    
    private var totalBooksFinished: Int {
        finishedBooksForMilestones.count
    }

    private var hasWrittenReview: Bool {
        allReviews.contains {
            !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func finishedPageCount(for book: Book) -> Int {
        max(book.totalPages, book.currentPage, book.ebookTotalPages)
    }

    private var averageSessionMinutes: Int {
        guard totalSessions > 0 else { return 0 }
        return totalMinutes / totalSessions
    }

    private var longestSession: ReadingSession? {
        sessions.max(by: { $0.durationMinutes < $1.durationMinutes })
    }

    private var recentSessions: [ReadingSession] {
        Array(sessions.prefix(20))
    }

    private var visibleRecentSessions: [ReadingSession] {
        Array(recentSessions.prefix(visibleRecentSessionCount))
    }

    private var hasMoreRecentSessions: Bool {
        recentSessions.count > visibleRecentSessionCount
    }

    private var isShowingExpandedRecentSessions: Bool {
        visibleRecentSessionCount > 4
    }

    private var heatmapDays: [ReadingHeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }

        return (0..<84).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let daySessions = sessionsByDay[date] ?? []
            let pages = daySessions.reduce(0) { $0 + $1.pagesRead }
            let minutes = daySessions.reduce(0) { $0 + $1.durationMinutes }

            return ReadingHeatmapDay(
                date: date,
                sessions: daySessions.count,
                pages: pages,
                minutes: minutes
            )
        }
    }

    private var currentStreak: Int {
        if let s = stats, s.isOnReadingBreak {
            if s.currentBreakDays > ReadingStats.maxBreakDays {
                return 0
            }
            return s.readingBreakStreakValue
        }

        return dailyStreakSummary.current
    }

    private var bestStreak: Int {
        dailyStreakSummary.longest
    }

    private var readingMilestones: [ReadingMilestone] {
        [
            ReadingMilestone(
                title: "First Book Finished",
                subtitle: "Finish your first book in Lumey.",
                iconName: "startrophy",
                isUnlocked: totalBooksFinished >= 1
            ),
            ReadingMilestone(
                title: "First Review Written",
                subtitle: "Write your first book review.",
                iconName: "starnote",
                isUnlocked: hasWrittenReview
            ),
            ReadingMilestone(
                title: "100 Pages Read",
                subtitle: "Read 100 pages from finished books.",
                iconName: "openbook",
                isUnlocked: totalFinishedBookPages >= 100
            ),
            ReadingMilestone(
                title: "1,000 Pages Read",
                subtitle: "Read 1,000 pages from finished books.",
                iconName: "books",
                isUnlocked: totalFinishedBookPages >= 1_000
            ),
            ReadingMilestone(
                title: "10 Books Finished",
                subtitle: "Finish 10 books total.",
                iconName: "bookstack",
                isUnlocked: totalBooksFinished >= 10
            )
        ]
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var currentWeekInterval: DateInterval {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: Date())
        ?? DateInterval(start: calendar.startOfDay(for: Date()), duration: 7 * 24 * 60 * 60)
    }

    private var weeklySessions: [ReadingSession] {
        sessions.filter { currentWeekInterval.contains($0.date) }
    }

    private var weeklyQuotes: [BookQuote] {
        allQuotes.filter {
            currentWeekInterval.contains($0.dateCreated)
            || currentWeekInterval.contains($0.lastUpdated)
        }
    }

    private var weeklyReviews: [BookReview] {
        allReviews.filter {
            currentWeekInterval.contains($0.dateCreated)
            || currentWeekInterval.contains($0.lastUpdated)
        }
    }

    private var weeklyBooks: [Book] {
        let linkedBookIDs = Set(weeklySessions.compactMap(\.linkedBookID))
        let linkedTitles = Set(
            weeklySessions
                .map { normalizedKey($0.linkedBookTitle) }
                .filter { !$0.isEmpty }
        )

        return activeBooks.filter { book in
            linkedBookIDs.contains(book.id)
            || linkedTitles.contains(normalizedKey(book.displayTitle))
            || currentWeekInterval.contains(book.dateAdded)
            || currentWeekInterval.contains(book.lastUpdated)
            || (book.dateStarted.map { currentWeekInterval.contains($0) } ?? false)
            || (book.dateFinished.map { currentWeekInterval.contains($0) } ?? false)
        }
    }

    private var mostReadAuthor: String {
        mostCommonValue(
            weeklyBooks
                .map { $0.displayAuthor.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    private var favoriteGenre: String {
        mostCommonValue(weeklyBooks.flatMap { $0.genres })
    }

    private var favoriteMood: String {
        mostCommonValue(weeklyBooks.flatMap { $0.moods })
    }

    private var favoriteTrope: String {
        mostCommonValue(weeklyBooks.flatMap { $0.tropes })
    }

    private var mostCommonTag: String {
        mostCommonValue(weeklyBooks.flatMap { $0.tags })
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .split(separator: " ")
            .joined(separator: " ")
    }

    private func mostCommonValue(_ values: [String]) -> String {
        let cleanedValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedValues.isEmpty else { return "Not enough this week" }

        let grouped = Dictionary(grouping: cleanedValues) { $0.lowercased() }

        let bestGroup = grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.value.first ?? lhs.key > rhs.value.first ?? rhs.key
            }
            return lhs.value.count < rhs.value.count
        }

        return bestGroup?.value.first ?? "Not enough data yet"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        personalityCard

                        pointsHeroCard

                        readingMissionStatsSection

                        readingMilestonesSection

                        favoriteThingsSection

                        readingHeatmapSection

                        streakSection

                        recentSessionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                stats?.checkAndExpireBreak()
                try? modelContext.save()
            }
            .sheet(isPresented: $showingBreakSheet) {
                ReadingBreakSettingsSheet(stats: stats, currentStreak: currentStreak)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(
                isPresented: Binding(
                    get: { editingRecentSession != nil },
                    set: { isPresented in
                        if !isPresented {
                            editingRecentSession = nil
                        }
                    }
                )
            ) {
                if let editingRecentSession {
                    EditReadingSessionSheet(
                        session: editingRecentSession,
                        allSessions: sessions,
                        stats: stats
                    )
                }
            }
        }
    }
}

struct ReadingMilestone: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let isUnlocked: Bool
}

struct ReadingHeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: Int
    let pages: Int
    let minutes: Int

    var intensity: Int {
        if pages >= 75 || minutes >= 90 { return 4 }
        if pages >= 40 || minutes >= 45 { return 3 }
        if pages >= 15 || minutes >= 20 { return 2 }
        if sessions > 0 { return 1 }
        return 0
    }
}

// MARK: - Header

private extension ReadingStatsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Text("Your reading sessions, points, and momentum at a glance.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            readingBreakButton
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var readingBreakButton: some View {
        Button {
            showingBreakSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(stats?.isOnReadingBreak == true ? "playwavy" : "pausewavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)

                Text(stats?.isOnReadingBreak == true ? "Resume" : "Break")
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(LGradients.header)
            )
            .shadow(color: LColors.gradientPurple.opacity(0.30), radius: 10, y: 4)
        }
    }
}

// MARK: - Reading Personality

enum ReadingPersonality: String {
    case fantasyExplorer = "Fantasy Explorer"
    case nightReader = "Night Reader"
    case quoteCollector = "Quote Collector"
    case reviewWriter = "Review Writer"
    case seriesBinger = "Series Binger"
    case moodReader = "Mood Reader"
    case steadyReader = "Steady Reader"

    var description: String {
        switch self {
        case .fantasyExplorer:
            return "You keep reaching for magic, danger, romance, and impossible worlds."
        case .nightReader:
            return "Your reading rhythm comes alive later in the day."
        case .quoteCollector:
            return "You notice lines worth keeping and build meaning through saved passages."
        case .reviewWriter:
            return "You turn finished books into opinions, reflections, and reader insight."
        case .seriesBinger:
            return "You like staying inside one world long enough to watch it unfold."
        case .moodReader:
            return "You seem drawn to books by atmosphere, emotion, and feeling."
        case .steadyReader:
            return "You\u{2019}re building a consistent reading life one session at a time."
        }
    }

    var iconName: String {
        switch self {
        case .fantasyExplorer: return "sparkle"
        case .nightReader:    return "moonzs"
        case .quoteCollector: return "starmark"
        case .reviewWriter:   return "starcircle"
        case .seriesBinger:   return "bookstack"
        case .moodReader:     return "xsmile"
        case .steadyReader:   return "achievement"
        }
    }

    static func calculate(
        books: [Book],
        sessions: [ReadingSession],
        quotes: [BookQuote],
        reviews: [BookReview],
        cadence: ReadingPersonalityCadence = .lifetime
    ) -> ReadingPersonality {
        let activeBooks = books.filter { !$0.isArchived }
        let thresholds = cadence.thresholds

        // Quote collector
        if quotes.count >= thresholds.quoteCollector {
            return .quoteCollector
        }

        // Review writer
        if reviews.count >= thresholds.reviewWriter {
            return .reviewWriter
        }

        // Night reader
        let nightSessions = sessions.filter {
            Calendar.current.component(.hour, from: $0.date) >= 20
        }.count
        if nightSessions >= thresholds.nightReader {
            return .nightReader
        }

        // Series binger
        let seriesCounts = Dictionary(
            grouping: activeBooks.filter { !$0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            by: { $0.seriesName }
        )
        let maxSeriesCount = seriesCounts.values.map(\.count).max() ?? 0
        if maxSeriesCount >= thresholds.seriesBinger {
            return .seriesBinger
        }

        // Fantasy explorer
        let fantasyCount = activeBooks.filter {
            $0.genres.contains { $0.localizedCaseInsensitiveContains("fantasy") }
        }.count
        if fantasyCount >= max(thresholds.fantasyExplorerMinimum, activeBooks.count / 2) {
            return .fantasyExplorer
        }

        // Mood reader
        let totalMoods = activeBooks.reduce(0) { $0 + $1.moods.count }
        if totalMoods >= thresholds.moodReader {
            return .moodReader
        }

        return .steadyReader
    }
}

enum ReadingPersonalityCadence {
    case lifetime
    case weekly

    var thresholds: ReadingPersonalityThresholds {
        switch self {
        case .lifetime:
            return ReadingPersonalityThresholds(
                quoteCollector: 10,
                reviewWriter: 5,
                nightReader: 5,
                seriesBinger: 3,
                fantasyExplorerMinimum: 2,
                moodReader: 8
            )
        case .weekly:
            return ReadingPersonalityThresholds(
                quoteCollector: 3,
                reviewWriter: 2,
                nightReader: 3,
                seriesBinger: 2,
                fantasyExplorerMinimum: 1,
                moodReader: 4
            )
        }
    }
}

struct ReadingPersonalityThresholds {
    let quoteCollector: Int
    let reviewWriter: Int
    let nightReader: Int
    let seriesBinger: Int
    let fantasyExplorerMinimum: Int
    let moodReader: Int
}

// MARK: - Personality Card

private extension ReadingStatsView {
    var personality: ReadingPersonality {
        ReadingPersonality.calculate(
            books: weeklyBooks,
            sessions: weeklySessions,
            quotes: weeklyQuotes,
            reviews: weeklyReviews,
            cadence: .weekly
        )
    }

    var personalityCard: some View {
        GlassCard(variant: .featured) {
            HStack(spacing: 16) {
                Image(personality.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(LColors.iconContainer.primary)
                            .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading Personality")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.tertiary)

                    Text(personality.rawValue)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)

                    Text(personality.description)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Points Hero

private extension ReadingStatsView {
    var pointsHeroCard: some View {
        let summary = xpSummary
        let title = xpProfile?.selectedTitle.isEmpty == false ? xpProfile?.selectedTitle ?? summary.title : summary.title

        return GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("levelup")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(LColors.accents.primary)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(LColors.iconContainer.tertiary))
                        .overlay(Circle().strokeBorder(LColors.accents.primary, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading Level")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Level \(summary.level)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)

                    VStack(alignment: .leading, spacing: 7) {
                        GradientProgressBar(value: summary.progress)
                            .frame(height: 10)

                        HStack {
                            Text("\(summary.totalXP) XP")
                            Spacer()
                            Text("\(summary.xpNeededForNextLevel) XP to Level \(summary.level + 1)")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                    }
                }

                DottedDivider()

                HStack(spacing: 10) {
                    statCapsule(title: "Points",   value: "\(totalPoints)",   tint: LColors.accents.primary)
                    statCapsule(title: "Sessions", value: "\(totalSessions)", tint: LColors.accents.contrast)
                    statCapsule(title: "Pages",    value: "\(totalPages)",    tint: LColors.accents.secondary)
                }
            }
        }
    }

    func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.primary)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
        }
    }

    func statCapsule(title: String, value: String, tint: Color = LColors.accents.primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.32), lineWidth: 1)
        )
    }
}

// MARK: - Reading Missions

private extension ReadingStatsView {
    var readingMissionStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Reading Missions")

            GlassCard(variant: .secondary) {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        missionStat(value: "\(missionStats.missionsGenerated)", label: "Joined", icon: "wand", accentIndex: 0)
                        missionStat(value: "\(missionStats.missionsCompleted)", label: "Completed", icon: "checkwavy", accentIndex: 1)
                        missionStat(value: "\(Int((missionStats.completionPercentage * 100).rounded()))%", label: "Completion", icon: "sparkletrophy", accentIndex: 2)
                        missionStat(value: ReadingMissionStatsCalculator.formattedDuration(seconds: missionStats.averageCompletionTimeSeconds), label: "Average Time", icon: "timebook", accentIndex: 3)
                        missionStat(value: missionStats.favoriteMissionCategory, label: "Favorite Category", icon: "starmark", accentIndex: 4)
                        missionStat(value: "\(missionStats.currentMissionStreak) / \(missionStats.longestMissionStreak)", label: "Current / Longest", icon: "starcal", accentIndex: 5)
                    }
                }
            }
        }
    }

    func missionStat(value: String, label: String, icon: String, accentIndex: Int) -> some View {
        let tint: Color = {
            switch accentIndex % 4 {
            case 0:  return LColors.accents.primary
            case 1:  return LColors.accents.contrast
            case 2:  return LColors.accents.secondary
            default: return LColors.accents.special
            }
        }()

        return HStack(spacing: 10) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(tint.opacity(0.55), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.30), lineWidth: 1)
        )
    }
}


// MARK: - Reading Milestones

private extension ReadingStatsView {
    var readingMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Reading Milestones")

            GlassCard(variant: .tertiary) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(readingMilestones.enumerated()), id: \.element.id) { index, milestone in
                        ReadingMilestoneRow(milestone: milestone, accentIndex: index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ReadingMilestoneRow: View {
    let milestone: ReadingMilestone
    var accentIndex: Int = 0

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(milestone.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(milestone.isUnlocked ? accent : LColors.text.muted)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(milestone.isUnlocked ? accent.opacity(0.16) : LColors.surface.subtle.opacity(0.5))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            milestone.isUnlocked ? accent : LColors.border.subtle,
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(milestone.isUnlocked ? LColors.text.primary : LColors.text.tertiary)

                Text(milestone.subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(milestone.isUnlocked ? LColors.text.secondary : LColors.text.muted)
            }

            Spacer(minLength: 0)

            Text(milestone.isUnlocked ? "Unlocked" : "Locked")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(milestone.isUnlocked ? LColors.appBackground : LColors.text.muted)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            milestone.isUnlocked
                            ? AnyShapeStyle(accent)
                            : AnyShapeStyle(LColors.surface.subtle.opacity(0.5))
                        )
                )
        }
    }
}

// MARK: - Favorite Things

private extension ReadingStatsView {
    var favoriteThingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Favorite Things")

            GlassCard(variant: .featured) {
                VStack(alignment: .leading, spacing: 12) {
                    FavoriteThingRow(iconName: "openbook", title: "Most Read Author", value: mostReadAuthor, accentIndex: 0)
                    FavoriteThingRow(iconName: "loveflame", title: "Favorite Genre",    value: favoriteGenre,  accentIndex: 1)
                    FavoriteThingRow(iconName: "xsmile",    title: "Favorite Mood",     value: favoriteMood,   accentIndex: 2)
                    FavoriteThingRow(iconName: "starmark",  title: "Favorite Trope",    value: favoriteTrope,  accentIndex: 3)
                    FavoriteThingRow(iconName: "tagsparkle",title: "Most Common Tag",   value: mostCommonTag,  accentIndex: 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct FavoriteThingRow: View {
    let iconName: String
    let title: String
    let value: String
    var accentIndex: Int = 0

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(accent, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)

                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }
}


// MARK: - Reading Heatmap

private extension ReadingStatsView {
    var readingHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Reading Heatmap")

            GlassCard(variant: .featured) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Last 12 weeks")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text("Tiny calendar of your reading days.")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 4) {
                            Text("Less")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.75))

                            ForEach(0..<5, id: \.self) { intensity in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(heatmapColor(for: intensity))
                                    .frame(width: 9, height: 9)
                            }

                            Text("More")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.75))
                        }
                    }

                    HStack(alignment: .top, spacing: 5) {
                        ForEach(0..<12, id: \.self) { week in
                            VStack(spacing: 5) {
                                ForEach(0..<7, id: \.self) { day in
                                    let index = (week * 7) + day
                                    if heatmapDays.indices.contains(index) {
                                        ReadingHeatmapCell(day: heatmapDays[index])
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Heatmap intensity — solid palette color per level, no gradients.
    func heatmapColor(for intensity: Int) -> Color {
        switch intensity {
        case 4:  return LColors.accents.contrast
        case 3:  return LColors.accents.primary
        case 2:  return LColors.accents.secondary
        case 1:  return LColors.accents.tertiary.opacity(0.60)
        default: return LColors.surface.nestedSoft
        }
    }
}

struct ReadingHeatmapCell: View {
    let day: ReadingHeatmapDay

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(cellGradient)
            .frame(width: 17, height: 17)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(day.intensity == 0 ? LColors.border.subtle.opacity(0.45) : LColors.accents.contrast.opacity(0.28), lineWidth: 0.7)
            )
            .accessibilityLabel(accessibilityText)
    }

    /// Heatmap cell fill — solid palette color per intensity, no gradients.
    private var cellGradient: Color {
        switch day.intensity {
        case 4:  return LColors.accents.contrast
        case 3:  return LColors.accents.primary
        case 2:  return LColors.accents.secondary
        case 1:  return LColors.accents.tertiary.opacity(0.55)
        default: return LColors.surface.nestedSoft
        }
    }

    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: day.date)): \(day.sessions) sessions, \(day.pages) pages, \(day.minutes) minutes"
    }
}

struct DottedDivider: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<28, id: \.self) { _ in
                Circle()
                    .fill(LColors.border.subtle)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }
}


private extension ReadingStatsView {
    var streakSection: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Streaks")

                GlassCard(variant: .primary) {
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(Array(streakSummaries.enumerated()), id: \.element.id) { index, summary in
                            ReadingStreakSummaryRow(
                                summary: adjustedSummary(summary),
                                isPaused: summary.kind == .daily && stats?.isOnReadingBreak == true
                            )

                            if index < streakSummaries.count - 1 {
                                DottedDivider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                readingBreakInfoCard
            }
        }

    func adjustedSummary(_ summary: ReadingStreakSummary) -> ReadingStreakSummary {
        guard summary.kind == .daily else { return summary }

        return ReadingStreakSummary(
            kind: summary.kind,
            current: currentStreak,
            longest: bestStreak,
            detail: summary.detail
        )
    }

    var readingBreakInfoCard: some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image("pausewavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LColors.accents.contrast)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(LColors.iconContainer.primary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.accents.primary, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Reading Break")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        if stats?.isOnReadingBreak == true {
                            let days = stats?.currentBreakDays ?? 0
                            let remaining = max(0, ReadingStats.maxBreakDays - days)
                            Text("Day \(days) of \(ReadingStats.maxBreakDays) · \(remaining) days remaining")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        } else {
                            Text("No active break")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)
                }

                if stats?.isOnReadingBreak == true || (stats?.totalReadingBreakDays ?? 0) > 0 {
                    HStack(spacing: 10) {
                        if stats?.isOnReadingBreak == true {
                            statCapsule(title: "Current", value: "\(stats?.currentBreakDays ?? 0)")
                        }
                        statCapsule(title: "Total Break Days", value: "\((stats?.totalReadingBreakDays ?? 0) + (stats?.isOnReadingBreak == true ? (stats?.currentBreakDays ?? 0) : 0))")
                    }
                }
            }
        }
    }
}

struct ReadingStreakSummaryRow: View {
    let summary: ReadingStreakSummary
    let isPaused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                Image(summary.kind.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.secondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(summary.kind.title)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        if isPaused {
                            Text("Paused")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LColors.gradientPurple.opacity(0.40)
                                        )
                                )
                        }
                    }

                    Text(summary.detail)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                streakValueCard(title: "Current", value: summary.current, unit: summary.kind.unitName)
                streakValueCard(title: "Longest", value: summary.longest, unit: summary.kind.unitName)
            }
        }
    }

    private func streakValueCard(title: String, value: Int, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.accents.special)

            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Text(unit)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LColors.border.nested, lineWidth: 1)
        )
    }
}

// MARK: - Recent Sessions

private extension ReadingStatsView {
    var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Recent Sessions")
                Spacer()
                Text("\(totalSessions)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }

            GlassCard(variant: .tertiary) {
                if recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sessions yet")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        Text("Log a reading session from the Goals tab to start earning points.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(visibleRecentSessions.enumerated()), id: \.element.id) { index, session in
                            CompactReadingSessionRow(session: session) {
                                editingRecentSession = session
                            }

                            if index < visibleRecentSessions.count - 1 {
                                RecentSessionFullDottedDivider()
                            }
                        }

                        if recentSessions.count > 4 {
                            HStack(spacing: 10) {
                                if isShowingExpandedRecentSessions {
                                    Button {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                            visibleRecentSessionCount = 4
                                        }
                                    } label: {
                                        recentSessionsButtonLabel("Load Less")
                                    }
                                    .buttonStyle(.plain)
                                }

                                if hasMoreRecentSessions {
                                    Button {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                            visibleRecentSessionCount += 4
                                        }
                                    } label: {
                                        recentSessionsButtonLabel("Load More")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func recentSessionsButtonLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(LColors.iconContainer.primary)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Session Row

struct CompactReadingSessionRow: View {
    let session: ReadingSession
    let onEdit: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("clockfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(LColors.accents.primary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    Circle()
                        .strokeBorder(LColors.accents.special, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 7) {
                Text(session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(1)

                HStack(spacing: 7) {
                    if session.durationMinutes > 0 {
                        ReadingGoalPill(text: "\(session.durationMinutes) min")
                    }
                    if session.pagesRead > 0 {
                        ReadingGoalPill(text: "\(session.pagesRead) pages")
                    }
                    ReadingGoalPill(text: "+\(session.pointsEarned) pts", usePurpleStyle: true)
                }

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Text(formattedDate)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }

            Spacer(minLength: 0)

            Button(action: onEdit) {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.border.subtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RecentSessionFullDottedDivider: View {
    var body: some View {
        GeometryReader { proxy in
            let dotCount = max(Int(proxy.size.width / 8), 1)

            HStack(spacing: 4) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .fill(LColors.border.nestedStrong)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditReadingSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: ReadingSession
    let allSessions: [ReadingSession]
    let stats: ReadingStats?

    @State private var title: String = ""
    @State private var minutes: String = ""
    @State private var pages: String = ""
    @State private var notes: String = ""
    @State private var sessionDate: Date = Date()
    @State private var saveError: String?

    private var parsedMinutes: Int {
        max(Int(minutes.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, 0)
    }

    private var parsedPages: Int {
        max(Int(pages.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, 0)
    }

    private var previewPoints: Int {
        ReadingSession.calculatePoints(minutes: parsedMinutes, pages: parsedPages)
    }

    private var canSave: Bool {
        parsedMinutes > 0 || parsedPages > 0
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(LColors.border.primary.opacity(0.75))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        GlassCard(variant: .elevated) {
                            VStack(alignment: .leading, spacing: 14) {
                                LumeyTextField(title: "Session Title", text: $title)
                                LumeyNumberField(title: "Minutes", text: $minutes)
                                LumeyNumberField(title: "Pages", text: $pages)
                                LumeyTextEditor(title: "Notes", text: $notes, minHeight: 92)
                            }
                        }

                        GlassCard(variant: .subtle) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Date & Time")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)

                                LumeyGradientDateTimeDrumPicker(date: $sessionDate)
                            }
                        }

                        GlassCard(variant: .featured) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Updated Points")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)

                                    Text("+\(previewPoints) pts")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.accents.secondary)
                                }

                                Spacer()

                                Image("levelup")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(LColors.accents.special)
                            }
                        }

                        if !canSave {
                            Text("Add minutes or pages to save this session.")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.gradientPink)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let saveError {
                            Text(saveError)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.gradientPink)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 42)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .lumeyDismissKeyboardOnTap()
        .onAppear(perform: loadSession)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image("pencil")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(LColors.accents.primary)
                .frame(width: 50, height: 50)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(LColors.accents.primary, lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text("Edit Session")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Update the session details and saved points.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LColors.iconContainer.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(LColors.border.subtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                saveSession()
            } label: {
                Text("Save Changes")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? AnyShapeStyle(LColors.accents.primary) : AnyShapeStyle(LColors.border.nestedStrong))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
    }

    private func loadSession() {
        title = session.linkedBookTitle
        minutes = session.durationMinutes > 0 ? "\(session.durationMinutes)" : ""
        pages = session.pagesRead > 0 ? "\(session.pagesRead)" : ""
        notes = session.notes
        sessionDate = session.date
    }

    private func saveSession() {
        guard canSave else { return }

        saveError = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        session.linkedBookTitle = trimmedTitle
        session.durationMinutes = parsedMinutes
        session.pagesRead = parsedPages
        session.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        session.date = sessionDate
        session.pointsEarned = previewPoints

        refreshStatsRecord()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Could not save this session. Try again."
        }
    }

    private func refreshStatsRecord() {
        guard let stats else { return }

        let calendar = Calendar.current
        let now = Date()
        let sessions = allSessions

        stats.totalReadingSessions = sessions.count
        stats.totalMinutesRead = sessions.reduce(0) { $0 + $1.durationMinutes }
        stats.totalPagesRead = sessions.reduce(0) { $0 + $1.pagesRead }
        stats.longestReadingSessionMinutes = sessions.map(\.durationMinutes).max() ?? 0
        stats.lastReadingDate = sessions.map(\.date).max()

        let todaySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        stats.minutesReadToday = todaySessions.reduce(0) { $0 + $1.durationMinutes }
        stats.pagesReadToday = todaySessions.reduce(0) { $0 + $1.pagesRead }

        let monthSessions = sessions.filter {
            calendar.component(.year, from: $0.date) == calendar.component(.year, from: now)
            && calendar.component(.month, from: $0.date) == calendar.component(.month, from: now)
        }
        stats.minutesReadThisMonth = monthSessions.reduce(0) { $0 + $1.durationMinutes }
        stats.pagesReadThisMonth = monthSessions.reduce(0) { $0 + $1.pagesRead }

        let yearSessions = sessions.filter {
            calendar.component(.year, from: $0.date) == calendar.component(.year, from: now)
        }
        stats.pagesReadThisYear = yearSessions.reduce(0) { $0 + $1.pagesRead }
        stats.updatedAt = now
    }
}

// MARK: - Helpers

private extension ReadingStatsView {
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(LColors.headingPrimary)
    }
}

// MARK: - Reading Break Settings Sheet

struct ReadingBreakSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let stats: ReadingStats?
    let currentStreak: Int

    @State private var showingConfirm = false

    private var isOnBreak: Bool {
        stats?.isOnReadingBreak == true
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(LColors.border.primary.opacity(0.75))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack(spacing: 14) {
                            Image(isOnBreak ? "playwavy" : "pausewavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .foregroundStyle(LColors.accents.secondary)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(
                                            LColors.gradientBlue.opacity(0.18)
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isOnBreak ? "Resume Reading" : "Reading Break")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.headingPrimary)

                                Text(isOnBreak ? "Pick up your streak where you left off." : "Take a break without losing your streak.")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }

                        if isOnBreak {
                            activeBreakContent
                        } else {
                            startBreakContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Start Break Content

    private var startBreakContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(variant: .primary) {
                VStack(alignment: .leading, spacing: 14) {
                    breakInfoRow(
                        icon: "flame",
                        title: "Streak Protected",
                        subtitle: "Your \(currentStreak)-day streak will be frozen and safe."
                    )
                    breakInfoRow(
                        icon: "clockwavy",
                        title: "Up to \(ReadingStats.maxBreakDays) Days",
                        subtitle: "Breaks last a maximum of \(ReadingStats.maxBreakDays) days before auto-expiring."
                    )
                    breakInfoRow(
                        icon: "flatbook",
                        title: "Resume Anytime",
                        subtitle: "Log a session after resuming to continue your streak."
                    )
                }
            }

            Button {
                startBreak()
            } label: {
                HStack(spacing: 8) {
                    Image("pausewavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text("Start Reading Break")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LGradients.header)
                )
                .shadow(color: LColors.gradientPurple.opacity(0.30), radius: 12, y: 6)
            }
        }
    }

    // MARK: - Active Break Content

    private var activeBreakContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard(variant: .secondary) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Duration")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)

                            Text("\(stats?.currentBreakDays ?? 0) days")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.accents.special)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Frozen Streak")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)

                            Text("\(stats?.readingBreakStreakValue ?? 0) days")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.headingPrimary)
                        }
                    }

                    // Progress bar showing days used
                    let days = stats?.currentBreakDays ?? 0
                    let progress = min(Double(days) / Double(ReadingStats.maxBreakDays), 1.0)

                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(LColors.iconContainer.primary)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(LGradients.header)
                                    .frame(width: max(0, geo.size.width * progress), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(max(0, ReadingStats.maxBreakDays - days)) days remaining")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    if let startDate = stats?.readingBreakStartDate {
                        DottedDivider()

                        HStack(spacing: 6) {
                            Text("Started")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)

                            Text(startDate, style: .date)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }
                    }
                }
            }

            Button {
                resumeReading()
            } label: {
                HStack(spacing: 8) {
                    Image("playwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text("Resume Reading")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LGradients.header)
                )
                .shadow(color: LColors.gradientPurple.opacity(0.30), radius: 12, y: 6)
            }
        }
    }

    // MARK: - Helpers

    private func breakInfoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.accents.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    Circle()
                        .strokeBorder(LColors.accents.special, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    private func startBreak() {
        let targetStats = stats ?? ReadingStats.fetchOrCreate(in: modelContext)
        targetStats.startBreak(currentStreak: currentStreak)
        try? modelContext.save()
        dismiss()
    }

    private func resumeReading() {
        let targetStats = stats ?? ReadingStats.fetchOrCreate(in: modelContext)
        targetStats.endBreak()
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ReadingStatsView()
}
