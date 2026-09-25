//
//  ProfileView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState
    @Query private var users: [AuthUser]
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var statsRecords: [ReadingStats]

    @Query(sort: \ChallengeUserProfile.username)
    private var challengeProfiles: [ChallengeUserProfile]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var challengeSubmissions: [ChallengeSubmission]

    @Query(sort: \ChallengeEntry.startDate, order: .reverse)
    private var challengeEntries: [ChallengeEntry]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @Query(sort: \ChallengeBookmark.createdAt, order: .reverse)
    private var challengeBookmarks: [ChallengeBookmark]

    @State private var challengeAvatarItem: PhotosPickerItem?
    @State private var showingSignInSheet = false
    @State private var showingBookmarkedChallenges = false
    @State private var editedChallengeUsername = ""
    @State private var isEditingChallengeUsername = false
    @State private var isFollowingChallengeProfile = false
    @State private var selectedConversation: ConversationDTO?
    @State private var isCreatingConversation = false
    @State private var showingMessagesList = false
    @State private var visibleChallengeSubmissionCount = 4
    @State private var completedChallengesRoute: CompletedChallengesRoute?

    let challengeProfile: ChallengeUserProfile?
    let currentChallengeTitle: String?
    let recentChallengeSubmissions: [ChallengeSubmission]?
    let onChallengeSubmissionTapped: ((ChallengeSubmission) -> Void)?
    let showsCloseButton: Bool

    init(
        challengeProfile: ChallengeUserProfile? = nil,
        currentChallengeTitle: String? = nil,
        recentChallengeSubmissions: [ChallengeSubmission]? = nil,
        onChallengeSubmissionTapped: ((ChallengeSubmission) -> Void)? = nil,
        showsCloseButton: Bool = false
    ) {
        self.challengeProfile = challengeProfile
        self.currentChallengeTitle = currentChallengeTitle
        self.recentChallengeSubmissions = recentChallengeSubmissions
        self.onChallengeSubmissionTapped = onChallengeSubmissionTapped
        self.showsCloseButton = showsCloseButton
    }

    private var user: AuthUser? {
        appState.currentUser ?? users.first
    }

    private var isSignedIn: Bool {
        appState.currentUser != nil
    }

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var currentUsername: String {
        let challengeUsername = activeChallengeProfile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !challengeUsername.isEmpty {
            return challengeUsername
        }

        let displayName = appState.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return displayName.isEmpty ? "Reader" : displayName
    }

    private var activeChallengeProfile: ChallengeUserProfile? {
        if let challengeProfile {
            return challengeProfile
        }

        return challengeProfiles.first { $0.userID == currentUserID }
    }

    private var isViewingCurrentChallengeProfile: Bool {
        activeChallengeProfile?.userID == currentUserID
    }

    private var displayedChallengeSubmissions: [ChallengeSubmission] {
        if let recentChallengeSubmissions {
            return recentChallengeSubmissions
        }

        guard let activeChallengeProfile else { return [] }

        return challengeSubmissions.filter {
            $0.userID == activeChallengeProfile.userID
        }
    }

    private var displayedCurrentChallengeTitle: String? {
        let providedTitle = currentChallengeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !providedTitle.isEmpty {
            return providedTitle
        }

        guard let activeChallengeProfile else { return nil }

        let activeEntry = challengeEntries.first {
            $0.userID == activeChallengeProfile.userID && $0.isActive
        }

        guard let challengeID = activeEntry?.challengeID else { return nil }

        return challenges.first { $0.id == challengeID }?.title
    }

    private var activeChallengeBookmarks: [ChallengeBookmark] {
        challengeBookmarks.filter {
            $0.userID == currentUserID && $0.isActive
        }
    }

    private var visibleChallengeSubmissions: [ChallengeSubmission] {
        Array(displayedChallengeSubmissions.prefix(visibleChallengeSubmissionCount))
    }

    private var hasMoreChallengeSubmissions: Bool {
        displayedChallengeSubmissions.count > visibleChallengeSubmissionCount
    }

    private var profileEmail: String {
        let trimmed = user?.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "No email connected" : trimmed
    }

    private var readingDNABooks: [Book] {
        let linkedBookIDs = Set(weeklyReadingSessions.compactMap(\.linkedBookID))
        let linkedTitles = Set(
            weeklyReadingSessions
                .map { normalizedKey($0.linkedBookTitle) }
                .filter { !$0.isEmpty }
        )

        return activeReadingBooks.filter { book in
            linkedBookIDs.contains(book.id)
            || linkedTitles.contains(normalizedKey(book.displayTitle))
            || linkedTitles.contains(normalizedKey(book.title))
            || currentWeekInterval.contains(book.dateAdded)
            || currentWeekInterval.contains(book.lastUpdated)
            || (book.dateStarted.map { currentWeekInterval.contains($0) } ?? false)
            || (book.dateFinished.map { currentWeekInterval.contains($0) } ?? false)
        }
    }

    private var finishedBooks: [Book] {
        readingDNABooks.filter { $0.status == .finished }
    }

    private var activeReadingBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var currentWeekInterval: DateInterval {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: Date())
        ?? DateInterval(start: calendar.startOfDay(for: Date()), duration: 7 * 24 * 60 * 60)
    }

    private var weeklyReadingSessions: [ReadingSession] {
        sessions.filter { currentWeekInterval.contains($0.date) }
    }

    private var mostReadGenre: String {
        mostCommonValue(readingDNABooks.flatMap { $0.genres })
    }

    private var mostReadMood: String {
        mostCommonValue(readingDNABooks.flatMap { $0.moods })
    }

    private var mostReadTrope: String {
        mostCommonValue(readingDNABooks.flatMap { $0.tropes })
    }

    private var mostReadAuthor: String {
        mostCommonValue(
            readingDNABooks
                .map { $0.displayAuthor.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "Unknown Author" }
        )
    }

    private var mostCommonBookLength: String {
        let values = readingDNABooks.compactMap { book -> String? in
            guard book.totalPages > 0 else { return nil }

            switch book.totalPages {
            case 0..<250:
                return "Under 250 pages"
            case 250..<350:
                return "250–349 pages"
            case 350..<500:
                return "350–499 pages"
            case 500..<700:
                return "500–699 pages"
            default:
                return "700+ pages"
            }
        }

        return mostCommonValue(values)
    }

    private var mostCommonRating: String {
        let values = readingDNABooks.compactMap { book -> String? in
            guard book.rating > 0 else { return nil }
            let rounded = (book.rating * 2).rounded() / 2
            return "\(rounded.cleanRating) stars"
        }

        return mostCommonValue(values)
    }

    private var averageDaysToFinish: String {
        let dayCounts = finishedBooks.compactMap { book -> Int? in
            guard let started = book.dateStarted,
                  let finished = book.dateFinished
            else { return nil }

            let days = Calendar.current.dateComponents([.day], from: started, to: finished).day ?? 0
            return max(days, 1)
        }

        guard !dayCounts.isEmpty else { return "Not enough this week" }

        let average = dayCounts.reduce(0, +) / dayCounts.count
        return "\(average) day\(average == 1 ? "" : "s")"
    }

    private var preferredFormat: String {
        mostCommonValue(
            readingDNABooks
                .map { $0.format.rawValue }
                .filter { !$0.isEmpty }
        )
    }

    private var stats: ReadingStats? {
        ReadingStats.preferredRecord(from: statsRecords)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var yearlyBooks: [Book] {
        activeReadingBooks.filter { book in
            guard book.status == .finished else { return false }

            return Calendar.current.component(.year, from: finishedReferenceDate(for: book)) == currentYear
        }
    }

    private var yearlySessions: [ReadingSession] {
        sessions.filter {
            Calendar.current.component(.year, from: $0.date) == currentYear
        }
    }

    private var yearlyBooksRead: String {
        "\(yearlyBooks.count)"
    }

    private var yearlyPagesRead: String {
        let pages = yearlyBooks.reduce(0) { total, book in
            total + finishedPageCount(for: book)
        }
        return "\(pages)"
    }

    private var yearlyHoursRead: String {
        let minutes = yearlySessions.reduce(0) { $0 + $1.durationMinutes }
        let hours = Double(minutes) / 60.0

        if hours == 0 { return "0" }
        if hours < 1 { return "<1" }

        return String(format: "%.1f", hours)
    }

    private var yearlyLongestStreak: String {
        "\(longestReadingStreak(from: yearlySessions)) days"
    }

    private var yearlyHighestRated: String {
        guard let book = yearlyBooks
            .filter({ $0.rating > 0 })
            .max(by: { $0.rating < $1.rating })
        else { return "Not enough data yet" }

        return "\(book.displayTitle) • \(book.rating.cleanRating) stars"
    }

    private var yearlyMostEmotional: String {
        guard let book = yearlyBooks
            .filter({ $0.emotionalRating > 0 })
            .max(by: { $0.emotionalRating < $1.emotionalRating })
        else { return "Not enough data yet" }

        return book.displayTitle
    }

    private var yearlyFavoriteBook: String {
        if let favorite = yearlyBooks.first(where: { $0.isFavorite }) {
            return favorite.displayTitle
        }

        guard let highestRated = yearlyBooks
            .filter({ $0.rating > 0 })
            .max(by: { $0.rating < $1.rating })
        else { return "Not enough data yet" }

        return highestRated.displayTitle
    }

    private var yearlyLongestBook: String {
        guard let book = yearlyBooks
            .filter({ $0.totalPages > 0 })
            .max(by: { $0.totalPages < $1.totalPages })
        else { return "Not enough data yet" }

        return "\(book.displayTitle) • \(book.totalPages) pages"
    }

    private var yearlyFastestFinished: String {
        let finishedWithDays = yearlyBooks.compactMap { book -> (Book, Int)? in
            guard let started = book.dateStarted,
                  let finished = book.dateFinished
            else { return nil }

            let days = Calendar.current.dateComponents([.day], from: started, to: finished).day ?? 0
            return (book, max(days, 1))
        }

        guard let fastest = finishedWithDays.min(by: { $0.1 < $1.1 }) else {
            return "Not enough data yet"
        }

        return "\(fastest.0.displayTitle) • \(fastest.1) day\(fastest.1 == 1 ? "" : "s")"
    }

    private var actualCurrentReadingStreak: Int {
        if let stats, stats.isOnReadingBreak {
            if stats.currentBreakDays > ReadingStats.maxBreakDays { return 0 }
            return stats.readingBreakStreakValue
        }

        let calendar = Calendar.current
        let readingDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        guard !readingDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let breakPeriods = stats?.breakPeriods ?? []

        var anchorDay: Date?
        var checkDay = today
        var graceDaysUsed = 0

        while graceDaysUsed <= 1 {
            if readingDays.contains(checkDay) {
                anchorDay = checkDay
                break
            }

            if ReadingStats.isDateInBreakPeriod(checkDay, periods: breakPeriods),
               let previous = calendar.date(byAdding: .day, value: -1, to: checkDay) {
                checkDay = previous
                continue
            }

            graceDaysUsed += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDay) else {
                break
            }
            checkDay = previous
        }

        guard let anchorDay else { return 0 }

        var streak = 0
        var day = anchorDay

        for _ in 0..<3650 {
            if readingDays.contains(day) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            } else if ReadingStats.isDateInBreakPeriod(day, periods: breakPeriods),
                      let previous = calendar.date(byAdding: .day, value: -1, to: day) {
                day = previous
            } else {
                break
            }
        }

        return streak
    }

    private func finishedPageCount(for book: Book) -> Int {
        max(book.totalPages, book.currentPage, book.ebookTotalPages)
    }

    private func finishedReferenceDate(for book: Book) -> Date {
        book.dateFinished ?? book.lastUpdated
    }

    private func longestReadingStreak(from sessions: [ReadingSession]) -> Int {
        let calendar = Calendar.current
        let sortedDays = Array(Set(sessions.map { calendar.startOfDay(for: $0.date) })).sorted()
        guard !sortedDays.isEmpty else { return 0 }

        let breakPeriods = stats?.breakPeriods ?? []
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
                    if !ReadingStats.isDateInBreakPeriod(gapDay, periods: breakPeriods) {
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

    private var readingDNAObservations: [String] {
        var observations: [String] = []

        if hasReadingDNAValue(mostCommonBookLength) {
            observations.append("You prefer books around \(mostCommonBookLength.lowercased()).")
        }

        if hasReadingDNAValue(mostReadTrope) {
            let tropeCount = readingDNABooks.filter { $0.tropes.contains(where: { $0.localizedCaseInsensitiveCompare(mostReadTrope) == .orderedSame }) }.count
            if !readingDNABooks.isEmpty {
                let percent = Int((Double(tropeCount) / Double(readingDNABooks.count)) * 100)
                observations.append("\(mostReadTrope) appears in \(percent)% of your library.")
            }
        }

        if hasReadingDNAValue(mostReadGenre) {
            let genreBooks = readingDNABooks.filter { $0.genres.contains(where: { $0.localizedCaseInsensitiveCompare(mostReadGenre) == .orderedSame }) }
            let ratedGenreBooks = genreBooks.filter { $0.rating > 0 }
            let ratedBooks = readingDNABooks.filter { $0.rating > 0 }

            if !ratedGenreBooks.isEmpty && !ratedBooks.isEmpty {
                let genreAverage = ratedGenreBooks.reduce(0.0) { $0 + $1.rating } / Double(ratedGenreBooks.count)
                let overallAverage = ratedBooks.reduce(0.0) { $0 + $1.rating } / Double(ratedBooks.count)
                let difference = genreAverage - overallAverage

                if abs(difference) >= 0.3 {
                    let direction = difference > 0 ? "higher" : "lower"
                    observations.append("You rate \(mostReadGenre) \(String(format: "%.1f", abs(difference))) stars \(direction) than your average.")
                }
            }
        }

        return observations.isEmpty ? ["Keep adding books and Lumey will learn your reading patterns."] : Array(observations.prefix(3))
    }

    private func hasReadingDNAValue(_ value: String) -> Bool {
        value != "Not enough data yet" && value != "Not enough this week"
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
                return (lhs.value.first ?? lhs.key) > (rhs.value.first ?? rhs.key)
            }
            return lhs.value.count < rhs.value.count
        }

        return bestGroup?.value.first ?? "Not enough data yet"
    }

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Nav
                HStack(spacing: 12) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)
                    Spacer()

                    if showsCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LColors.accents.contrast)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(LColors.bg)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let activeChallengeProfile {
                            challengeProfileSection(activeChallengeProfile)
                                .padding(.horizontal, 16)
                        }

                        readingDNASection
                            .padding(.horizontal, 16)

                        yearInBooksSection
                            .padding(.horizontal, 16)

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            ensureCurrentChallengeProfileIfNeeded()
            syncChallengeProfileState()
        }
        .onChange(of: activeChallengeProfile?.userID) { _, _ in
            syncChallengeProfileState()
            visibleChallengeSubmissionCount = 4
        }
        .onChange(of: challengeAvatarItem) { _, newItem in
            Task {
                await loadChallengeAvatarImage(from: newItem)
            }
        }
        .adaptivePresentation(isPresented: $showingSignInSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            SignInView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
        }
        .adaptivePresentation(item: $selectedConversation, useFullScreenCover: horizontalSizeClass == .regular) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                otherAvatarURL: activeChallengeProfile?.avatarURL,
                otherAvatarName: activeChallengeProfile?.avatarName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingMessagesList, useFullScreenCover: horizontalSizeClass == .regular) {
            MessagesListView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingBookmarkedChallenges, useFullScreenCover: horizontalSizeClass == .regular) {
            ChallengeBookmarksPage(userID: currentUserID)
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $completedChallengesRoute, useFullScreenCover: horizontalSizeClass == .regular) { route in
            ChallengeCompletedChallengesPage(userID: route.userID, username: route.username)
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Challenge Profile

    private func challengeProfileSection(_ profile: ChallengeUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            challengeProfileHero(profile)

            challengeStatsGrid(profile)

            if let title = displayedCurrentChallengeTitle,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentChallengeCard(title)
            }

            if !challengeBio(for: profile).isEmpty {
                challengeBioCard(profile)
            }

            if isViewingCurrentChallengeProfile {
                bookmarkedChallengesCard
            }

            recentChallengeEntriesSection
        }
    }

    private func challengeProfileHero(_ profile: ChallengeUserProfile) -> some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(spacing: 16) {
                challengeAvatarView(profile)

                VStack(spacing: 10) {
                    if isEditingChallengeUsername && isViewingCurrentChallengeProfile {
                        VStack(spacing: 10) {
                            TextField("Username", text: $editedChallengeUsername)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                )

                            Button {
                                saveChallengeUsername(profile)
                            } label: {
                                Text("Save Username")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(LGradients.completion)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    } else if isViewingCurrentChallengeProfile {
                        Button {
                            editedChallengeUsername = challengeUsername(for: profile)
                            isEditingChallengeUsername = true
                        } label: {
                            challengeUsernameLabel(profile, showsEditIcon: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        challengeUsernameLabel(profile, showsEditIcon: false)
                    }

                    if !challengeFavoriteGenre(for: profile).isEmpty {
                        HStack(spacing: 6) {
                            Image("sparklybook")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(LColors.accents.secondary)

                            Text(challengeFavoriteGenre(for: profile))
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    challengeSocialActions(profile)
                }

                HStack(spacing: 10) {
                    socialMiniStat(
                        title: "Followers",
                        value: "\(profile.followersCount)",
                        tint: theme.palette.primaryAction
                    )
                    socialMiniStat(
                        title: "Following",
                        value: "\(profile.followingCount)",
                        tint: theme.palette.secondaryAccent
                    )
                }

                if isViewingCurrentChallengeProfile {
                    accountConnectionControls
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var accountConnectionControls: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(profileEmail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(isSignedIn ? "Signed in with Apple" : "Sign in to sync your Loomey profile.")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(isSignedIn ? theme.palette.indicators : LColors.textSecondary)
                    .bubblyIconMaterial(tint: theme.palette.indicators, isEnabled: isSignedIn)
                    .multilineTextAlignment(.center)
            }

            Button {
                if isSignedIn {
                    appState.signOut()
                } else {
                    showingSignInSheet = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(isSignedIn ? "xmarkwavy" : "profilewavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)

                    Text(isSignedIn ? "Sign Out" : "Sign In")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background {
                    BubblyTileSurface(
                        tint: theme.palette.indicators,
                        cornerRadius: LSpacing.buttonRadius
                    )
                }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func challengeAvatarView(_ profile: ChallengeUserProfile) -> some View {
        if isViewingCurrentChallengeProfile {
            PhotosPicker(selection: $challengeAvatarItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    challengeAvatarImage(profile)

                    Image("upload")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .bubblyIconMaterial(tint: theme.palette.indicators)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(theme.palette.raisedSurface)
                                .overlay(
                                    Circle()
                                        .strokeBorder(theme.palette.indicators, lineWidth: 1)
                                )
                        )
                }
            }
            .buttonStyle(.plain)
        } else {
            challengeAvatarImage(profile)
        }
    }

    private func challengeAvatarImage(_ profile: ChallengeUserProfile) -> some View {
        UserAvatarView(
            avatarURL: profile.avatarURL,
            avatarName: profile.avatarName,
            size: 104,
            iconSize: 60
        )
        .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 16, y: 8)
    }

    private func challengeUsernameLabel(
        _ profile: ChallengeUserProfile,
        showsEditIcon: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Text(challengeUsername(for: profile))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
                .multilineTextAlignment(.center)

            if showsEditIcon {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .bubblyIconMaterial(tint: theme.palette.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func challengeSocialActions(_ profile: ChallengeUserProfile) -> some View {
        HStack(spacing: 10) {
            if !isViewingCurrentChallengeProfile {
                Button {
                    toggleChallengeFollow(profile)
                } label: {
                    Text(isFollowingChallengeProfile ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isFollowingChallengeProfile ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LColors.accents.special))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await startMessage(with: profile)
                    }
                } label: {
                    Image("sendbutton")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(isCreatingConversation ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LColors.accents.primary))
                                .overlay(
                                    Circle()
                                        .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isCreatingConversation)
            }

            Button {
                showingMessagesList = true
            } label: {
                Image("chatlinesfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func socialMiniStat(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }

    private func challengeStatsGrid(_ profile: ChallengeUserProfile) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            Button {
                completedChallengesRoute = CompletedChallengesRoute(
                    userID: profile.userID,
                    username: challengeUsername(for: profile)
                )
            } label: {
                challengeStatCard(
                    icon: "startrophyhands",
                    title: "Completed",
                    value: "\(profile.challengesCompleted)",
                    subtitle: "Challenges",
                    accentIndex: 0
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Completed challenges")

            challengeStatCard(
                icon: "starfill",
                title: "Points",
                value: "\(profile.challengePoints)",
                subtitle: "Earned",
                accentIndex: 1
            )

            challengeStatCard(
                icon: "loveflame",
                title: "Streak",
                value: "\(displayedReadingStreak(for: profile))",
                subtitle: displayedReadingStreak(for: profile) == 1 ? "Day" : "Days",
                accentIndex: 2
            )

            challengeStatCard(
                icon: "sparkle",
                title: "Entries",
                value: "\(displayedChallengeSubmissions.count)",
                subtitle: "Recent",
                accentIndex: 3
            )
        }
    }

    private func challengeStatCard(
        icon: String,
        title: String,
        value: String,
        subtitle: String,
        accentIndex: Int
    ) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return GlassCard(padding: 0, variant: .secondary, borderColor: tint) {
            ZStack(alignment: .topLeading) {
                BubblyLightWash(colors: [tint], intensity: 0.34, fadeEnd: 0.82)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .bubblyIconMaterial(tint: tint)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Circle()
                                        .strokeBorder(tint, lineWidth: 1)
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        Text(title)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(subtitle)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func displayedReadingStreak(for profile: ChallengeUserProfile) -> Int {
        profile.userID == currentUserID ? actualCurrentReadingStreak : profile.readingStreak
    }

    private func currentChallengeCard(_ title: String) -> some View {
        GlassCard(variant: .primary, borderColor: theme.palette.secondaryAccent) {
            HStack(spacing: 12) {
                Image("stargoal")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Challenge")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
    }

    private var bookmarkedChallengesCard: some View {
        Button {
            showingBookmarkedChallenges = true
        } label: {
            GlassCard(variant: .secondary, borderColor: theme.palette.indicators) {
                HStack(spacing: 12) {
                    Image("starmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .bubblyIconMaterial(tint: theme.palette.indicators)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Circle()
                                        .strokeBorder(theme.palette.indicators, lineWidth: 1)
                                )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bookmarked Challenges")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("\(activeChallengeBookmarks.count) saved challenge\(activeChallengeBookmarks.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .bubblyIconMaterial(tint: theme.palette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func challengeBioCard(_ profile: ChallengeUserProfile) -> some View {
        GlassCard(variant: .tertiary) {
            VStack(alignment: .leading, spacing: 10) {
                profileSectionHeader(icon: "starnote", title: "About")

                Text(challengeBio(for: profile))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recentChallengeEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            profileSectionHeader(icon: "sparkle", title: "Recent Challenge Entries")

            if displayedChallengeSubmissions.isEmpty {
                GlassCard(variant: .elevated) {
                    VStack(spacing: 10) {
                        Image("openbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(LColors.accents.special)

                        Text("No recent entries yet.")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("Challenge submissions will appear here once this reader starts joining events.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(visibleChallengeSubmissions.enumerated()), id: \.element.id) { index, submission in
                        Button {
                            onChallengeSubmissionTapped?(submission)
                        } label: {
                            recentChallengeSubmissionRow(submission, accentIndex: index)
                        }
                        .buttonStyle(.plain)
                    }

                    if hasMoreChallengeSubmissions {
                        loadMoreChallengeEntriesButton
                    }
                }
            }
        }
    }

    private var loadMoreChallengeEntriesButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                visibleChallengeSubmissionCount = min(
                    visibleChallengeSubmissionCount + 4,
                    displayedChallengeSubmissions.count
                )
            }
        } label: {
            HStack(spacing: 8) {
                Text("Load More")
                    .font(.system(size: 13, weight: .black, design: .rounded))

                Image("chevdown")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
            }
            .foregroundStyle(.white)
            .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 999) }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private func recentChallengeSubmissionRow(_ submission: ChallengeSubmission, accentIndex: Int) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return HStack(alignment: .center, spacing: 12) {
            Image(statusIcon(for: submission.validationStatus))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .bubblyIconMaterial(tint: tint)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(tint, lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(submission.validationStatus.displayName)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(submission.submittedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .bubblyIconMaterial(tint: theme.palette.indicators)

                    Text("\(submission.likeCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .bubblyIconMaterial(tint: theme.palette.textSecondary)

                    Text("\(submission.commentCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LColors.surface.nested)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(tint, lineWidth: 1)
                }
        }
    }

    private func profileSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LColors.accents.secondary)

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
    }

    // MARK: - Reading DNA

    private var readingDNASection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reading DNA")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Text("Lumey learns your reading habits automatically.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            GlassCard(variant: .subtle, borderColor: theme.palette.primaryAction) {
                VStack(alignment: .leading, spacing: 12) {
                    ReadingDNARow(iconName: "openbook", title: "Most Read Genre", value: mostReadGenre, accentIndex: 0)
                    ReadingDNARow(iconName: "xsmile", title: "Most Read Mood", value: mostReadMood, accentIndex: 1)
                    ReadingDNARow(iconName: "sparkle", title: "Most Read Trope", value: mostReadTrope, accentIndex: 2)
                    ReadingDNARow(iconName: "profilewavy", title: "Most Read Author", value: mostReadAuthor, accentIndex: 3)
                    ReadingDNARow(iconName: "starwavy", title: "Most Common Book Length", value: mostCommonBookLength, accentIndex: 4)
                    ReadingDNARow(iconName: "starfill", title: "Most Common Rating", value: mostCommonRating, accentIndex: 5)
                    ReadingDNARow(iconName: "clockfill", title: "Average Days To Finish", value: averageDaysToFinish, accentIndex: 6)
                    ReadingDNARow(iconName: "starmark", title: "Preferred Format", value: preferredFormat, accentIndex: 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Observations")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    ForEach(readingDNAObservations, id: \.self) { observation in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(.clear)
                                .frame(width: 9, height: 9)
                                .background {
                                    BubblyIconMaterial(tint: theme.palette.primaryAction)
                                        .clipShape(Circle())
                                }
                                .padding(.top, 5)

                            Text(observation)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Year In Books

    private var yearInBooksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Year In Books")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Text("Your \(currentYear) reading wrapped into one cozy report.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            GlassCard(variant: .primary, borderColor: theme.palette.secondaryAccent) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image("startrophyfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.iconContainer.primary)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(currentYear) Wrapped")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text("The story your reading year tells.")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    ProfileMaterialDottedDivider(tint: theme.palette.secondaryAccent)

                    VStack(alignment: .leading, spacing: 12) {
                        ReadingDNARow(iconName: "openbook", title: "Books Read", value: yearlyBooksRead, accentIndex: 1)
                        ReadingDNARow(iconName: "bulletlovenote", title: "Pages Read", value: yearlyPagesRead, accentIndex: 2)
                        ReadingDNARow(iconName: "clockfill", title: "Hours Read", value: yearlyHoursRead, accentIndex: 3)
                        ReadingDNARow(iconName: "flame", title: "Longest Streak", value: yearlyLongestStreak, accentIndex: 4)
                        ReadingDNARow(iconName: "sparklesstarflag", title: "Highest Rated", value: yearlyHighestRated, accentIndex: 5)
                        ReadingDNARow(iconName: "heartfill", title: "Most Emotional", value: yearlyMostEmotional, accentIndex: 6)
                        ReadingDNARow(iconName: "loveflame", title: "Favorite Book", value: yearlyFavoriteBook, accentIndex: 7)
                        ReadingDNARow(iconName: "flatbook", title: "Longest Book", value: yearlyLongestBook, accentIndex: 8)
                        ReadingDNARow(iconName: "sparkbolt", title: "Fastest Finished", value: yearlyFastestFinished, accentIndex: 9)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Challenge profile actions

    private func ensureCurrentChallengeProfileIfNeeded() {
        guard challengeProfile == nil else { return }
        guard challengeProfiles.first(where: { $0.userID == currentUserID }) == nil else { return }

        let username = appState.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let profile = ChallengeUserProfile(
            userID: currentUserID,
            username: username.isEmpty ? "Reader" : username,
            avatarName: nil,
            bio: nil,
            favoriteGenre: nil
        )

        modelContext.insert(profile)
        try? modelContext.save()
    }

    private func syncChallengeProfileState() {
        guard let activeChallengeProfile else { return }

        editedChallengeUsername = challengeUsername(for: activeChallengeProfile)
        isFollowingChallengeProfile = activeChallengeProfile.isFollowing
    }

    private func challengeUsername(for profile: ChallengeUserProfile) -> String {
        let trimmed = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }

    private func challengeBio(for profile: ChallengeUserProfile) -> String {
        profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func challengeFavoriteGenre(for profile: ChallengeUserProfile) -> String {
        profile.favoriteGenre?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @MainActor
    private func startMessage(with profile: ChallengeUserProfile) async {
        guard !isCreatingConversation else { return }

        isCreatingConversation = true

        do {
            let conversation = try await ChallengeSocialService.shared.createConversation(
                senderUserID: currentUserID,
                senderUsername: currentUsername,
                recipientUserID: profile.userID,
                recipientUsername: challengeUsername(for: profile)
            )

            selectedConversation = conversation
        } catch {
            print("Failed to start conversation:", error)
        }

        isCreatingConversation = false
    }

    private func saveChallengeUsername(_ profile: ChallengeUserProfile) {
        let trimmed = editedChallengeUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        profile.username = trimmed
        isEditingChallengeUsername = false

        try? modelContext.save()

        updateRemoteChallengeProfile(profile)
    }

    private func toggleChallengeFollow(_ profile: ChallengeUserProfile) {
        isFollowingChallengeProfile.toggle()
        profile.isFollowing = isFollowingChallengeProfile

        if isFollowingChallengeProfile {
            profile.followersCount += 1
        } else {
            profile.followersCount = max(0, profile.followersCount - 1)
        }

        try? modelContext.save()

        updateRemoteChallengeProfile(profile)
    }

    @MainActor
    private func loadChallengeAvatarImage(from item: PhotosPickerItem?) async {
        guard let item,
              let activeChallengeProfile,
              isViewingCurrentChallengeProfile
        else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let avatarURL = try await ChallengeSocialService.shared.uploadProfileAvatar(
                    imageData: data
                )

                activeChallengeProfile.avatarURL = avatarURL
                try? modelContext.save()

                updateRemoteChallengeProfile(activeChallengeProfile)
            }
        } catch {
            print("Failed to upload avatar image:", error)
        }
    }

    private func updateRemoteChallengeProfile(_ profile: ChallengeUserProfile) {
        Task {
            try? await ChallengeSocialService.shared.updateProfile(
                userID: profile.userID,
                username: profile.username,
                avatarName: profile.avatarName,
                avatarURL: profile.avatarURL,
                bio: profile.bio,
                favoriteGenre: profile.favoriteGenre,
                readingStreak: profile.readingStreak,
                challengePoints: profile.challengePoints,
                challengesCompleted: profile.challengesCompleted,
                followersCount: profile.followersCount,
                followingCount: profile.followingCount
            )
        }
    }

    private func statusIcon(for status: ChallengeSubmissionStatus) -> String {
        switch status {
        case .approved:
            return "checkwavy"
        case .inProgress:
            return "clockfill"
        case .needsMoreInfo:
            return "questionwavy"
        case .rejected:
            return "xmarkwavy"
        case .validating, .submitted:
            return "sparkle"
        case .joined, .readyToSubmit:
            return "openbook"
        case .expired:
            return "clockfill"
        }
    }

}

struct ReadingDNARow: View {
    @Environment(\.appTheme) private var theme

    let iconName: String
    let title: String
    let value: String
    let accentIndex: Int

    private var tint: Color {
        theme.palette.rotation[accentIndex % theme.palette.rotation.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .bubblyIconMaterial(tint: tint)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    Circle()
                        .strokeBorder(tint, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ProfileMaterialDottedDivider: View {
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<28, id: \.self) { _ in
                Circle()
                    .fill(.clear)
                    .frame(width: 3, height: 3)
                    .background {
                        BubblyIconMaterial(tint: tint)
                            .clipShape(Circle())
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }
}

private struct CompletedChallengesRoute: Identifiable {
    let id = UUID()
    let userID: String
    let username: String
}

private extension Double {
    var cleanRating: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self))"
        } else {
            return String(format: "%.1f", self)
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

    @ViewBuilder
    func adaptivePresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(item: item, content: content)
        } else {
            self.sheet(item: item, content: content)
        }
    }
}
