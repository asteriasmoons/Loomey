//
//  ReadingHomeView.swift
//  Lumey
//

import SwiftUI
import SwiftData

private extension View {
    @ViewBuilder
    func bubblyTextMaterial(tint: Color) -> some View {
        self
            .foregroundStyle(.clear)
            .overlay {
                BubblyIconMaterial(tint: tint)
                    .mask { self }
            }
    }
}

@ViewBuilder
private func readingHomePaletteCard<Content: View>(
    theme: AppTheme,
    color: Color,
    cornerRadius: CGFloat = 24,
    padding: CGFloat = LSpacing.cardPadding,
    @ViewBuilder content: () -> Content
) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    content()
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(theme.palette.surface))
        .overlay(shape.strokeBorder(color, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
}

struct ReadingHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState
    @Environment(\.appTheme) private var theme
    
    @State private var showingSignInSheet = false

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var stats: [ReadingStats]

    @Query(sort: \ReadingGoals.updatedAt, order: .reverse)
    private var goals: [ReadingGoals]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var authUsers: [AuthUser]

    @Query
    private var allNotes: [BookNote]

    @Query
    private var allQuotes: [BookQuote]

    @Query
    private var allReviews: [BookReview]

    private var readingStats: ReadingStats? {
        ReadingStats.preferredRecord(from: stats)
    }

    private var savedAuthUser: AuthUser? {
        authUsers.first
    }

    private var isSignedIn: Bool {
        appState.currentUser != nil || savedAuthUser != nil
    }

    private var activeReadingGoals: [ReadingGoals] {
        goals.filter { $0.status == .active && !$0.isArchived }
    }

    private var currentlyReadingBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var currentStreak: Int {
        if let s = readingStats, s.isOnReadingBreak {
            if s.currentBreakDays > ReadingStats.maxBreakDays { return 0 }
            return s.readingBreakStreakValue
        }

        let calendar = Calendar.current
        let readingDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        guard !readingDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let allBreakPeriods = readingStats?.breakPeriods ?? []

        var anchorDay: Date?
        var checkDay = today
        var graceDaysUsed = 0

        while graceDaysUsed <= 1 {
            if readingDays.contains(checkDay) {
                anchorDay = checkDay
                break
            }
            if ReadingStats.isDateInBreakPeriod(checkDay, periods: allBreakPeriods) {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
                checkDay = prev
                continue
            }
            graceDaysUsed += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }

        guard let anchor = anchorDay else { return 0 }

        var streak = 0
        var day = anchor

        for _ in 0..<3650 {
            if readingDays.contains(day) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else if ReadingStats.isDateInBreakPeriod(day, periods: allBreakPeriods) {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }

        return streak
    }

    private var bestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = Array(Set(sessions.map { calendar.startOfDay(for: $0.date) })).sorted()
        guard !sortedDays.isEmpty else { return 0 }

        let allBreakPeriods = readingStats?.breakPeriods ?? []
        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]
            let dayAfterPrevious = calendar.date(byAdding: .day, value: 1, to: previous) ?? previous

            if calendar.isDate(currentDay, inSameDayAs: dayAfterPrevious) {
                current += 1
            } else {
                var gapDay = dayAfterPrevious
                var gapBridged = true
                while gapDay < currentDay {
                    if !ReadingStats.isDateInBreakPeriod(gapDay, periods: allBreakPeriods) {
                        gapBridged = false
                        break
                    }
                    guard let next = calendar.date(byAdding: .day, value: 1, to: gapDay) else {
                        gapBridged = false
                        break
                    }
                    gapDay = next
                }
                current = gapBridged ? current + 1 : 1
            }
            best = max(best, current)
        }

        return best
    }

    private var todaysSessions: [ReadingSession] {
        sessions.filter {
            Calendar.current.isDateInToday($0.date)
        }
    }

    private var pagesReadToday: Int {
        todaysSessions.reduce(0) { $0 + $1.pagesRead }
    }

    private var minutesReadToday: Int {
        todaysSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        currentlyReadingSection
                        libraryPulseSection
                        writingStatsSection
                        readingMomentumSection
                        goalsSection
                        HomeRecommendationCollectionsSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 90)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                ensureReadingModelsExist()

                restoreSavedUserIfNeeded()
                showingSignInSheet = !isSignedIn
            }
            .adaptivePresentation(isPresented: $showingSignInSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                SignInView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .preferredColorScheme(.dark)
            }
            .onChange(of: authUsers.count) { _, _ in
                restoreSavedUserIfNeeded()
                if isSignedIn {
                    showingSignInSheet = false
                }
            }
        }
    }
}

// MARK: - Header

private extension ReadingHomeView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lumey")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Spacer()

                if !isSignedIn {
                    Button {
                        showingSignInSheet = true
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(LGradients.header)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Your cozy reading space")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Currently Reading

private extension ReadingHomeView {
    var currentlyReadingSection: some View {
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Currently Reading")

            if currentlyReadingBooks.isEmpty {
                emptyCard(
                    title: "No active books yet",
                    message: "Add a book and mark it as Reading to see it here."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(currentlyReadingBooks.prefix(3).enumerated()), id: \.element.id) { index, book in
                        HomeCurrentReadingCard(
                            book: book,
                            accentIndex: index
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Library Pulse

private extension ReadingHomeView {
    var libraryPulseSection: some View {
        let activeReadingRatio = activeBooks.isEmpty ? 0 : Double(currentlyReadingBooks.count) / Double(activeBooks.count)

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Library Pulse")

            readingHomePaletteCard(theme: theme, color: theme.palette.indicators) {
                HStack(spacing: 16) {
                    VStack(spacing: 12) {
                        frostedStatBox(
                            value: "\(activeBooks.count)",
                            label: "Total Books",
                            tint: theme.palette.primaryAction
                        )

                        frostedStatBox(
                            value: "\(currentlyReadingBooks.count)",
                            label: "Currently Reading",
                            tint: theme.palette.secondaryAccent
                        )
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        DottedProgressRing(
                            progress: activeReadingRatio,
                            size: 120,
                            dotCount: 24,
                            dotSize: 6,
                            tint: theme.palette.indicators,
                            track: theme.palette.indicators.opacity(0.22)
                        )

                        Text("Reading Now")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)

                        Text("of active library")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(width: 132)
                }
            }
        }
    }

    func frostedStatBox(value: String, label: String, tint: Color = LColors.accents.primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 14)
        }
        .bubblyTileLift()
    }
}

// MARK: - Writing Stats

private extension ReadingHomeView {
    var writingStatsSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Your Writing")

            LazyVGrid(columns: columns, spacing: 12) {
                writingStatCard(icon: "lovedocument", title: "Notes",   count: allNotes.count,   accentIndex: 0)
                writingStatCard(icon: "starmark",    title: "Quotes",  count: allQuotes.count,  accentIndex: 1)
                writingStatCard(icon: "starcircle",  title: "Reviews", count: allReviews.count, accentIndex: 2)
            }
        }
    }

    /// Distributes accents across adjacent stat cards so three siblings show
    /// three different palette colors instead of one repeated accent.
    func writingStatCard(icon: String, title: String, count: Int, accentIndex: Int) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return VStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .background {
                    BubblyIconMaterial(tint: tint)
                        .mask {
                            Image(icon)
                                .resizable()
                                .scaledToFit()
                        }
                }
                .foregroundStyle(.clear)
                .frame(width: 40, height: 40)

            Text("\(count)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .bubblyTextMaterial(tint: tint)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background {
            ZStack(alignment: .top) {
                shape.fill(theme.palette.surface)

                BubblyLightWash(
                    colors: [tint],
                    intensity: 0.58,
                    fadeEnd: 0.78
                )
                .frame(maxWidth: .infinity)
                .frame(height: 82)
            }
            .clipShape(shape)
        }
        .overlay {
            shape.strokeBorder(tint, lineWidth: 1)
        }
    }
}

// MARK: - Reading Momentum

private extension ReadingHomeView {
    var readingMomentumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Reading Momentum")

            readingHomePaletteCard(theme: theme, color: theme.palette.primaryAction) {
                VStack(spacing: 16) {
                    // Streak row — current in accent, best in contrast
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image("flame")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .background {
                                        BubblyIconMaterial(tint: theme.palette.primaryAction)
                                            .mask {
                                                Image("flame")
                                                    .resizable()
                                                    .scaledToFit()
                                            }
                                    }
                                    .foregroundStyle(.clear)

                                Text("\(currentStreak)")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .bubblyTextMaterial(tint: theme.palette.primaryAction)
                            }

                            Text("day streak")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.text.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(bestStreak)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .bubblyTextMaterial(tint: theme.palette.secondaryAccent)

                            Text("best streak")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.text.tertiary)
                        }
                    }

                    // 7-day activity strip
                    weekActivityStrip

                    // Today's stats pills — pages in secondary, minutes in contrast
                    HStack(spacing: 10) {
                        todayPill(
                            icon: "openbook",
                            value: "\(pagesReadToday)",
                            label: "pages today",
                            tint: theme.palette.secondaryAccent,
                            iconTint: theme.palette.indicators
                        )

                        todayPill(
                            icon: "clockfill",
                            value: "\(minutesReadToday)",
                            label: "min today",
                            tint: theme.palette.indicators,
                            iconTint: theme.palette.secondaryAccent
                        )
                    }
                }
            }
        }
    }

    var weekActivityStrip: some View {
        let calendar = Calendar.current
        let today = Date()
        let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

        // Build last 7 days
        let days: [(label: String, isActive: Bool)] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0
            let label = weekdaySymbols[weekdayIndex]

            let isActive = sessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: date)
            }

            return (label, isActive)
        }

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Text(day.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)

                    Circle()
                        .fill(
                            day.isActive
                            ? AnyShapeStyle(LColors.accents.primary)
                            : AnyShapeStyle(LColors.surface.subtle)
                        )
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    day.isActive
                                    ? AnyShapeStyle(Color.clear)
                                    : AnyShapeStyle(LColors.border.primary.opacity(0.5)),
                                    lineWidth: 1
                                )
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background {
            BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 14)
        }
        .bubblyTileLift()
    }

    func todayPill(icon: String, value: String, label: String, tint: Color, iconTint: Color) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .background {
                    BubblyIconMaterial(tint: iconTint)
                        .mask {
                            Image(icon)
                                .resizable()
                                .scaledToFit()
                        }
                }
                .foregroundStyle(.clear)

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.primary)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 12)
        }
        .bubblyTileLift()
    }
}

// MARK: - Goals

private extension ReadingHomeView {
    var goalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Reading Goals")

            if activeReadingGoals.isEmpty {
                emptyCard(
                    title: "No reading goals yet",
                    message: "Create a reading goal to track your progress here."
                )
            } else {
                readingHomePaletteCard(theme: theme, color: theme.palette.secondaryAccent) {
                    VStack(spacing: 0) {
                        ForEach(Array(activeReadingGoals.prefix(3).enumerated()), id: \.element.id) { index, goal in
                            if index > 0 {
                                Rectangle()
                                    .fill(LColors.border.subtle)
                                    .frame(height: 1)
                                    .padding(.vertical, 10)
                            }

                            CompactGoalRow(goal: goal, accentIndex: index)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension ReadingHomeView {
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(LColors.headingPrimary)
    }

    func emptyCard(title: String, message: String) -> some View {
        GlassCard(variant: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func ensureReadingModelsExist() {
        if stats.isEmpty {
            modelContext.insert(ReadingStats())
        }

        if goals.isEmpty {
            modelContext.insert(ReadingGoals())
        }
    }

    func restoreSavedUserIfNeeded() {
        guard appState.currentUser == nil,
              let savedAuthUser
        else { return }

        appState.setSignedIn(savedAuthUser)
    }
}

// MARK: - Dotted Progress Ring

struct DottedProgressRing: View {
    let progress: Double
    let size: CGFloat
    let dotCount: Int
    let dotSize: CGFloat
    let tint: Color
    let track: Color

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var filledDots: Int {
        Int((clampedProgress * Double(dotCount)).rounded())
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                let angle = (Double(index) / Double(dotCount)) * 360 - 90
                let radians = angle * .pi / 180
                let isFilled = index < filledDots
                let radius = (size - dotSize) / 2

                Circle()
                    .fill(.clear)
                    .frame(width: dotSize, height: dotSize)
                    .background {
                        BubblyIconMaterial(tint: isFilled ? tint : track)
                            .clipShape(Circle())
                    }
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
            }

            Text("\(Int(clampedProgress * 100))%")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Dotted Progress Bar

struct DottedProgressBar: View {
    let value: Double
    let dotCount: Int
    let dotSize: CGFloat
    var tint: Color = LColors.accents.primary
    var track: Color = LColors.surface.subtle
    var usesBubblyMaterial: Bool = false

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var filledDots: Int {
        Int((clampedValue * Double(dotCount)).rounded())
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                let dotTint = index < filledDots ? tint : track

                if usesBubblyMaterial {
                    Circle()
                        .fill(.clear)
                        .frame(width: dotSize, height: dotSize)
                        .background {
                            BubblyIconMaterial(tint: dotTint)
                                .clipShape(Circle())
                        }
                } else {
                    Circle()
                        .fill(dotTint)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
    }
}

// MARK: - Home Current Reading Card

struct HomeCurrentReadingCard: View {
    let book: Book
    var accentIndex: Int = 0
    @Environment(\.appTheme) private var theme

    private var accent: Color {
        theme.palette.rotation[accentIndex % theme.palette.rotation.count]
    }

    private var lastReadLabel: String {
        let date = book.lastUpdated
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Read today"
        } else if calendar.isDateInYesterday(date) {
            return "Read yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            return days <= 30 ? "\(days)d ago" : date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var percentText: String {
        "\(Int(book.calculatedProgress * 100))%"
    }

    private var pagesLeftText: String {
        if book.totalPages > 0 {
            let left = max(book.totalPages - book.currentPage, 0)
            return "\(left) pages left"
        } else if book.totalChapters > 0 {
            let left = max(book.totalChapters - book.currentChapter, 0)
            return "\(left) chapters left"
        } else {
            return "\(Int(100 - book.progressPercent))% remaining"
        }
    }

    var body: some View {
        readingHomePaletteCard(theme: theme, color: accent) {
            HStack(alignment: .top, spacing: 12) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .background {
                        BubblyIconMaterial(tint: accent)
                            .mask {
                                Image("openbook")
                                    .resizable()
                                    .scaledToFit()
                            }
                    }
                    .foregroundStyle(.clear)
                    .frame(width: 42, height: 42)
                    .background(theme.palette.raisedSurface, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(accent, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.displayTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.primary)
                            .lineLimit(2)

                        Text(book.displayAuthor)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 7) {
                        DottedProgressBar(
                            value: book.calculatedProgress,
                            dotCount: 12,
                            dotSize: 6,
                            tint: accent,
                            track: accent.opacity(0.22),
                            usesBubblyMaterial: true
                        )

                        Text(percentText)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .bubblyTextMaterial(tint: accent)
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.progressText)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.primary)

                        Text(lastReadLabel)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.text.tertiary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Compact Goal Row

struct CompactGoalRow: View {
    let goal: ReadingGoals
    var accentIndex: Int = 0
    @Environment(\.appTheme) private var theme

    private var iconAccent: Color {
        accentIndex.isMultiple(of: 2) ? theme.palette.primaryAction : theme.palette.secondaryAccent
    }

    private var isCompletedToday: Bool {
        guard let date = goal.lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(date) && goal.progressValue >= 1
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(goal.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .background {
                    BubblyIconMaterial(tint: iconAccent)
                        .mask {
                            Image(goal.iconName)
                                .resizable()
                                .scaledToFit()
                        }
                }
                .foregroundStyle(.clear)
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(iconAccent, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.displayTitle)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .lineLimit(1)

                if isCompletedToday {
                    HStack(spacing: 5) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.state.completionText)

                        Text("Done today")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.state.completionText)
                    }
                } else {
                    DottedProgressBar(
                        value: goal.progressValue,
                        dotCount: 12,
                        dotSize: 5,
                        tint: theme.palette.indicators,
                        track: theme.palette.indicators.opacity(0.22),
                        usesBubblyMaterial: true
                    )
                }
            }

            Spacer(minLength: 0)

            if goal.type == .streak && goal.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image("flame")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(theme.palette.textPrimary)

                    Text("\(goal.currentStreak)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.textPrimary)
                }
            } else {
                Text("\(goal.progressPercentage)%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
            }
        }
    }
}

// MARK: - Book Cover Thumbnail

struct BookCoverThumbnail: View {
    let book: Book
    var width: CGFloat = 58
    var height: CGFloat = 84
    var accent: Color = LColors.accents.primary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.55),
                            LColors.accents.secondary.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let data = book.coverImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text(book.displayTitle.prefix(1).uppercased())
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var variant: GlassCardVariant = .primary
    var accent: Color = LColors.accents.primary

    var body: some View {
        GlassCard(variant: variant) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)

                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Recent Book Row

struct RecentBookRow: View {
    let book: Book
    var variant: GlassCardVariant = .primary
    var accent: Color = LColors.accents.primary

    var body: some View {
        GlassCard(variant: variant) {
            HStack(spacing: 12) {
                BookCoverThumbnail(book: book, width: 46, height: 66, accent: accent)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.displayTitle)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.primary)
                        .lineLimit(1)

                    Text(book.displayAuthor)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                        .lineLimit(1)

                    Text(book.status.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }

                Spacer()

                if book.rating > 0 {
                    Text(String(format: "%.1f", book.rating))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(LColors.state.completionFill, in: Capsule())
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func adaptivePresentation<Content: View>(
        isPresented: Binding<Bool>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(isPresented: isPresented, content: content)
        } else {
            self.sheet(isPresented: isPresented, content: content)
        }
    }
}

// MARK: - Preview

#Preview {
    ReadingHomeView()
        .modelContainer(for: [
            Book.self,
            BookNote.self,
            BookQuote.self,
            BookReview.self,
            ReadingStats.self,
            ReadingGoals.self,
            ReadingSession.self,
            AuthUser.self,
            ChallengeEntry.self,
            ChallengeSubmission.self
        ], inMemory: true)
}
