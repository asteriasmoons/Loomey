//
//  ReadingMissionSheet.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct ReadingMissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingMission.generatedAt, order: .reverse)
    private var missions: [ReadingMission]

    @Query(sort: \ReadingMissionTask.sortIndex)
    private var tasks: [ReadingMissionTask]

    @State private var criteria = ReadingMissionFilterCriteria.entireLibrary
    @State private var selectedMissionID: UUID?
    @State private var isGenerating = false
    @State private var isShowingReadingBookPicker = false
    @State private var loadingMessageIndex = 0
    @State private var errorMessage: String?
    @State private var showCompletionBurst = false
    @State private var isScoringMission = false
    @State private var missionScoreMessage: String?
    @State private var missionScoreError: String?

    private let loadingMessages = [
        "Searching your library...",
        "Choosing your next adventure...",
        "Learning about your book...",
        "Creating personalized reading missions...",
        "Almost ready...",
        "Mission Complete!"
    ]

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var readingBooks: [Book] {
        activeBooks
            .filter { $0.status == .reading }
            .sorted { lhs, rhs in
                lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
            }
    }

    private var eligibleBooks: [Book] {
        ReadingMissionGenerator.eligibleBooks(from: books, criteria: criteria)
    }

    private var selectedMission: ReadingMission? {
        guard let selectedMissionID else { return nil }
        return missions.first { $0.id == selectedMissionID }
    }

    private var selectedMissionTasks: [ReadingMissionTask] {
        guard let selectedMissionID else { return [] }
        return tasks
            .filter { $0.missionID == selectedMissionID }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var missionStats: ReadingMissionStatsSummary {
        ReadingMissionStatsCalculator.summary(missions: missions, tasks: tasks)
    }

    private var availableGenres: [String] {
        uniqueValues(activeBooks.flatMap(\.genres))
    }

    private var availableAuthors: [String] {
        uniqueValues(activeBooks.map(\.displayAuthor))
    }

    private var availableTags: [String] {
        uniqueValues(activeBooks.flatMap(\.tags))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        if isGenerating {
                            loadingState
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        } else if let selectedMission {
                            missionReveal(mission: selectedMission, missionTasks: selectedMissionTasks)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            setupContent
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 44)
                }
                .scrollDismissesKeyboard(.interactively)

                if showCompletionBurst {
                    completionBurst
                        .transition(.opacity.combined(with: .scale(scale: 0.88)))
                }
            }
            .navigationBarHidden(true)
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: isGenerating)
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selectedMissionID)
        }
        .lumeyDismissKeyboardOnTap()
    }
}

// MARK: - Header

private extension ReadingMissionSheet {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Reading Mission")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Loomey will randomly choose a book from your library and create four personalized missions for that exact read.")
                    .font(.callout)
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.primary)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(theme.palette.raisedSurface))
                    .overlay {
                        BubblyIconMaterial(tint: theme.palette.primaryAction)
                            .mask { Circle().strokeBorder(lineWidth: 1.2) }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }
}

// MARK: - Setup

private extension ReadingMissionSheet {
    var setupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            missionIntroCard
            filtersCard
            missionStatsCard
            missionHistorySection
        }
    }

    var missionIntroCard: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.rotation[0]) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image("wand")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(theme.palette.secondaryAccent)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                .mask { Circle().strokeBorder(lineWidth: 1) }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mission Setup")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("\(eligibleBooks.count) eligible \(eligibleBooks.count == 1 ? "book" : "books")")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                Button {
                    Task { await generateMission() }
                } label: {
                    Text(isGenerating ? "Creating Mission..." : "Get Reading Mission")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(theme.palette.textPrimary)
                        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                        .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)
                .disabled(isGenerating || eligibleBooks.isEmpty)
                .opacity(eligibleBooks.isEmpty ? 0.55 : 1)

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        isShowingReadingBookPicker.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image("openbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)

                        Text(readingBooks.isEmpty ? "No Reading Books Available" : "Pick Reading Book")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Spacer(minLength: 0)

                        Text("\(readingBooks.count)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(readingBooks.isEmpty ? LColors.textSecondary : .white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule(style: .continuous).fill(LColors.border.nested))

                        Image(isShowingReadingBookPicker ? "chevup" : "chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                    }
                    .foregroundStyle(readingBooks.isEmpty ? theme.palette.textSecondary : theme.palette.textPrimary)
                    .shadow(
                        color: readingBooks.isEmpty ? .clear : theme.palette.background.opacity(0.55),
                        radius: 1,
                        y: 2
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background {
                        if readingBooks.isEmpty {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(theme.palette.raisedSurface)
                        } else {
                            BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 18)
                        }
                    }
                    .bubblyTileLift(isEnabled: !readingBooks.isEmpty)
                }
                .buttonStyle(.plain)
                .disabled(isGenerating || readingBooks.isEmpty)
                .opacity(readingBooks.isEmpty ? 0.55 : 1)

                if isShowingReadingBookPicker, !readingBooks.isEmpty {
                    readingBookPicker
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.gradientPink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    var readingBookPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose from Reading")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.secondary)

            VStack(spacing: 8) {
                ForEach(Array(readingBooks.enumerated()), id: \.element.id) { index, book in
                    let accent = theme.palette.rotation[index % theme.palette.rotation.count]
                    Button {
                        Task { await generateMission(for: book) }
                    } label: {
                        HStack(spacing: 11) {
                            ReadingMissionBookPickerCover(book: book, width: 42, height: 62)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(book.displayTitle)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .lineLimit(2)

                                Text(book.displayAuthor)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .lineLimit(1)

                                Text(book.progressText)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.text.muted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            Image("wand")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(theme.palette.secondaryAccent)
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(theme.palette.raisedSurface))
                                .overlay {
                                    BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                        .mask { Circle().strokeBorder(lineWidth: 1) }
                                }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LColors.surface.nested)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(accent, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isGenerating)
                }
            }
        }
    }

    var filtersCard: some View {
        GlassCard(variant: .primary, borderColor: theme.palette.rotation[1]) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(
                    title: "Randomization Filters",
                    icon: "sparklesearch",
                    tint: theme.palette.indicators
                )

                FlowLayout(spacing: 8) {
                    ForEach(Array(ReadingMissionFilterKind.allCases.enumerated()), id: \.element.id) { index, filter in
                        filterChip(
                            filter,
                            tint: theme.palette.rotation[index % theme.palette.rotation.count]
                        )
                    }
                }

                if criteria.activeKinds.contains(.genre), !availableGenres.isEmpty {
                    valueFilterSection(title: "Genres", values: availableGenres, selectedValues: criteria.genres) { value in
                        toggleValue(value, keyPath: \.genres)
                    }
                }

                if criteria.activeKinds.contains(.author), !availableAuthors.isEmpty {
                    valueFilterSection(title: "Authors", values: availableAuthors, selectedValues: criteria.authors) { value in
                        toggleValue(value, keyPath: \.authors)
                    }
                }

                if criteria.activeKinds.contains(.tags), !availableTags.isEmpty {
                    valueFilterSection(title: "Tags", values: availableTags, selectedValues: criteria.tags) { value in
                        toggleValue(value, keyPath: \.tags)
                    }
                }

                if criteria.activeKinds.contains(.rating) {
                    ratingFilterSection
                }
            }
        }
    }

    func filterChip(_ filter: ReadingMissionFilterKind, tint: Color) -> some View {
        let isSelected = criteria.activeKinds.contains(filter)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                toggleFilter(filter)
            }
        } label: {
            HStack(spacing: 7) {
                Image(filter.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(theme.palette.textPrimary)
                    .bubblyIconMaterial(tint: theme.palette.textPrimary)

                Text(filter.rawValue)
                    .lineLimit(1)
                    .foregroundStyle(theme.palette.textPrimary)
                    .bubblyIconMaterial(tint: theme.palette.textPrimary)
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(theme.palette.textPrimary)
            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
            .overlay {
                if isSelected {
                    Capsule().strokeBorder(theme.palette.textPrimary.opacity(0.72), lineWidth: 1.25)
                }
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }

    func valueFilterSection(
        title: String,
        values: [String],
        selectedValues: [String],
        toggle: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.secondary)

            FlowLayout(spacing: 8) {
                ForEach(Array(values.prefix(36).enumerated()), id: \.element) { index, value in
                    let isSelected = selectedValues.contains(where: { $0.localizedCaseInsensitiveCompare(value) == .orderedSame })
                    let tint = theme.palette.rotation[index % theme.palette.rotation.count]
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                            toggle(value)
                        }
                    } label: {
                        Text(value)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(theme.palette.textPrimary)
                            .bubblyIconMaterial(tint: theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
                            .overlay {
                                if isSelected {
                                    Capsule().strokeBorder(theme.palette.textPrimary.opacity(0.72), lineWidth: 1.25)
                                }
                            }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var ratingFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Minimum Rating")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.text.secondary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    let tint = theme.palette.rotation[(rating - 1) % theme.palette.rotation.count]
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                            criteria.minimumRating = rating
                        }
                    } label: {
                        Text("\(rating)+")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .bubblyIconMaterial(tint: theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
                            .overlay {
                                if criteria.minimumRating == rating {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(theme.palette.textPrimary.opacity(0.72), lineWidth: 1.25)
                                }
                            }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var missionStatsCard: some View {
        GlassCard(variant: .secondary, borderColor: theme.palette.rotation[2]) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    title: "Mission Stats",
                    icon: "sparkletrophy",
                    tint: theme.palette.primaryAction
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    missionStat(value: "\(missionStats.missionsGenerated)", label: "Joined", tint: theme.palette.rotation[0])
                    missionStat(value: "\(missionStats.missionsCompleted)", label: "Completed", tint: theme.palette.rotation[1])
                    missionStat(value: "\(Int((missionStats.completionPercentage * 100).rounded()))%", label: "Completion", tint: theme.palette.rotation[2])
                    missionStat(value: ReadingMissionStatsCalculator.formattedDuration(seconds: missionStats.averageCompletionTimeSeconds), label: "Average Time", tint: theme.palette.rotation[0])
                    missionStat(value: missionStats.favoriteMissionCategory, label: "Favorite Category", tint: theme.palette.rotation[1])
                    missionStat(value: "\(missionStats.currentMissionStreak) / \(missionStats.longestMissionStreak)", label: "Current / Longest", tint: theme.palette.rotation[2])
                }
            }
        }
    }

    func missionStat(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82, alignment: .leading)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }

    var missionHistorySection: some View {
        Group {
            if !missions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(
                        title: "Mission History",
                        icon: "timebook",
                        tint: theme.palette.secondaryAccent
                    )

                    VStack(spacing: 10) {
                        ForEach(Array(missions.prefix(8).enumerated()), id: \.element.id) { index, mission in
                            Button {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                    selectedMissionID = mission.id
                                    errorMessage = nil
                                }
                            } label: {
                                missionHistoryCard(
                                    mission,
                                    tint: theme.palette.rotation[index % theme.palette.rotation.count]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    func missionHistoryCard(_ mission: ReadingMission, tint: Color) -> some View {
        GlassCard(cornerRadius: 18, padding: 14, variant: .featured, borderColor: tint) {
            HStack(spacing: 12) {
                ReadingMissionCover(book: localBook(for: mission), mission: mission, width: 42, height: 62)

                VStack(alignment: .leading, spacing: 5) {
                    Text(mission.bookTitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .lineLimit(2)

                    Text(mission.bookAuthor)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(1)

                    Text(mission.generatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.muted)
                }

                Spacer(minLength: 8)

                Text(mission.isCompleted ? "Complete" : "\(completedTaskCount(for: mission)) / 4")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
                    .bubblyIconMaterial(
                        tint: theme.palette.textPrimary,
                        isEnabled: mission.isCompleted
                    )
                    .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background {
                        if mission.isCompleted {
                            BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 999)
                        } else {
                            Capsule().fill(theme.palette.raisedSurface)
                        }
                    }
            }
        }
    }
}

// MARK: - Loading

private extension ReadingMissionSheet {
    var loadingState: some View {
        GlassCard(variant: .tertiary, borderColor: theme.palette.rotation[0]) {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(LColors.iconContainer.primary)
                        .frame(width: 116, height: 116)
                        .overlay(Circle().strokeBorder(LColors.accents.secondary, lineWidth: 1))

                    LumeyDottedGradientSpinner(size: 76)

                    Image("wand")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(LColors.accents.special)
                }

                VStack(spacing: 8) {
                    Text(loadingMessages[min(loadingMessageIndex, loadingMessages.count - 1)])
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)
                        .multilineTextAlignment(.center)
                        .id(loadingMessageIndex)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Text("Your mission reveal is being prepared.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 360)
        }
    }
}

// MARK: - Reveal

private extension ReadingMissionSheet {
    func missionReveal(mission: ReadingMission, missionTasks: [ReadingMissionTask]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                    selectedMissionID = nil
                    showCompletionBurst = false
                }
            } label: {
                HStack(spacing: 7) {
                    Image("chevleft")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(theme.palette.textPrimary)

                    Text("Mission Setup")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)

            missionHero(mission: mission, missionTasks: missionTasks)

            VStack(spacing: 12) {
                ForEach(Array(missionTasks.enumerated()), id: \.element.id) { index, task in
                    ReadingMissionTaskCard(
                        task: task,
                        borderColor: theme.palette.rotation[(index + 1) % theme.palette.rotation.count]
                    ) {
                        toggleTask(task, mission: mission)
                    } onNotesChanged: { notes in
                        task.notes = notes
                        task.updatedAt = Date()
                        try? modelContext.save()
                    }
                }
            }

            missionScoringSection(
                mission: mission,
                missionTasks: missionTasks,
                borderColor: theme.palette.rotation[(missionTasks.count + 1) % theme.palette.rotation.count]
            )

            if mission.isCompleted {
                completedMissionCard(
                    mission: mission,
                    borderColor: theme.palette.rotation[(missionTasks.count + 2) % theme.palette.rotation.count]
                )
            }

            HStack(spacing: 10) {
                Button {
                    beginReading(mission)
                } label: {
                    Text("Begin Reading")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(theme.palette.textPrimary)
                        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                        .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
                        .bubblyTileLift()
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Dismiss")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(theme.palette.textPrimary)
                        .background(theme.palette.raisedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    func missionHero(mission: ReadingMission, missionTasks: [ReadingMissionTask]) -> some View {
        let completeCount = missionTasks.filter(\.isCompleted).count
        let progress = missionTasks.isEmpty ? 0 : Double(completeCount) / Double(missionTasks.count)

        return GlassCard(variant: .elevated, borderColor: theme.palette.rotation[0]) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 15) {
                    ReadingMissionCover(book: localBook(for: mission), mission: mission, width: 82, height: 122)

                    VStack(alignment: .leading, spacing: 11) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(mission.bookTitle)
                                    .font(.system(size: 21, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.headingPrimary)
                                    .lineLimit(3)

                                Text(mission.bookAuthor)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 8)

                            ReadingMissionProgressRing(progress: progress, completeCount: completeCount)
                        }

                        Text("\(completeCount) / 4 Missions Complete")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.secondaryAccent)
                            .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            .contentTransition(.numericText())

                        Text(mission.isCompleted ? "Mission Status: Complete" : "Mission Status: Active")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.text.tertiary)
                    }
                }

                if mission.hasScore {
                    missionScoreSummaryTile(mission)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func missionScoreSummaryTile(_ mission: ReadingMission) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(mission.score)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.indicators)
                    .bubblyIconMaterial(tint: theme.palette.indicators)

                Text("/ 100")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.muted)

                Spacer(minLength: 0)

                Text(mission.scoreLabel.isEmpty ? "Scored" : mission.scoreLabel)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule(style: .continuous).fill(LColors.border.nested))
                    .overlay(Capsule(style: .continuous).strokeBorder(LColors.border.subtle, lineWidth: 1))
            }

            if !mission.scoreSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(mission.scoreSummary)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LColors.surface.nestedSoft))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(LColors.accents.primary, lineWidth: 1))
    }

    func missionScoringSection(
        mission: ReadingMission,
        missionTasks: [ReadingMissionTask],
        borderColor: Color
    ) -> some View {
        let canScore = hasAllRequiredAnswers(missionTasks)

        return GlassCard(
            cornerRadius: 18,
            padding: 16,
            variant: .primary,
            borderColor: borderColor
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image("sparkletrophy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(theme.palette.primaryAction)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: theme.palette.primaryAction)
                                .mask { Circle().strokeBorder(lineWidth: 1) }
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Score Answers")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(canScore ? "All four answers are ready." : "Answer all four prompts before scoring.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(canScore ? AnyShapeStyle(LColors.accents.secondary) : AnyShapeStyle(LColors.text.tertiary))
                            .bubblyIconMaterial(
                                tint: theme.palette.secondaryAccent,
                                isEnabled: canScore
                            )
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    Task { await scoreMission(mission: mission, missionTasks: missionTasks) }
                } label: {
                    HStack(spacing: 10) {
                        if isScoringMission {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.82)
                        } else {
                            Image("sparklesearch")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                                .foregroundStyle(theme.palette.textPrimary)
                                .bubblyIconMaterial(tint: theme.palette.textPrimary)
                        }

                        Text(isScoringMission ? "Scoring Answers..." : "Get Score")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background { BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 16) }
                    .bubblyTileLift()
                }
                .buttonStyle(.plain)
                .disabled(isScoringMission)

                if let missionScoreMessage {
                    Text(missionScoreMessage)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let missionScoreError {
                    Text(missionScoreError)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.gradientPink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    func completedMissionCard(mission: ReadingMission, borderColor: Color) -> some View {
        GlassCard(variant: .subtle, borderColor: borderColor) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(
                    title: "Mission Complete",
                    icon: "startrophy",
                    tint: theme.palette.secondaryAccent
                )

                if let completedAt = mission.completedAt {
                    Text("Date Completed: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                }

                Text("Book: \(mission.bookTitle)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)

                Text("Time to Complete: \(ReadingMissionStatsCalculator.formattedDuration(seconds: max((mission.completedAt ?? Date()).timeIntervalSince(mission.generatedAt), 0)))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)

                HStack(spacing: 8) {
                    LibraryStatusPill(text: "+\(mission.pointsAwarded) pts", usePurpleStyle: true)
                    LibraryStatusPill(text: "+\(mission.xpAwarded) XP", usePurpleStyle: true)
                }
            }
        }
    }

    var completionBurst: some View {
        VStack(spacing: 14) {
            Image("sparkletrophy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .foregroundStyle(LColors.accents.contrast)

            Text("Mission Complete")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LColors.bg.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(LColors.accents.contrast, lineWidth: 1.2))
                .shadow(color: LColors.gradientPurple.opacity(0.28), radius: 30, y: 14)
        )
    }
}

// MARK: - Actions

private extension ReadingMissionSheet {
    @MainActor
    func generateMission() async {
        await generateMission(selectedBook: nil)
    }

    @MainActor
    func generateMission(for book: Book) async {
        await generateMission(selectedBook: book)
    }

    @MainActor
    private func generateMission(selectedBook book: Book?) async {
        guard !isGenerating else { return }

        isGenerating = true
        selectedMissionID = nil
        errorMessage = nil
        loadingMessageIndex = 0

        let messageTask = Task {
            for index in loadingMessages.indices {
                try Task.checkCancellation()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        loadingMessageIndex = index
                    }
                }
                try await Task.sleep(nanoseconds: 900_000_000)
            }
        }

        do {
            let mission: ReadingMission
            if let book {
                mission = try await ReadingMissionGenerator.generateMission(
                    for: book,
                    userID: currentUserID,
                    modelContext: modelContext,
                    aiService: .shared
                )
            } else {
                mission = try await ReadingMissionGenerator.generateMission(
                    from: books,
                    criteria: criteria,
                    userID: currentUserID,
                    modelContext: modelContext,
                    aiService: .shared
                )
            }

            while loadingMessageIndex < loadingMessages.count - 1 {
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)

            messageTask.cancel()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedMissionID = mission.id
                isGenerating = false
                isShowingReadingBookPicker = false
            }
        } catch {
            messageTask.cancel()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                isGenerating = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTask(_ task: ReadingMissionTask, mission: ReadingMission) {
        if !task.isCompleted && task.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missionScoreMessage = nil
            missionScoreError = "Type an answer for this prompt before marking it complete."
            return
        }

        missionScoreError = nil

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            task.setCompleted(!task.isCompleted)
        }

        let didCompleteMission = ReadingMissionCompletionService.completeIfNeeded(
            mission: mission,
            tasks: selectedMissionTasks,
            modelContext: modelContext
        )
        try? modelContext.save()

        if didCompleteMission {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                showCompletionBurst = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.28)) {
                        showCompletionBurst = false
                    }
                }
            }
        }
    }

    func hasAllRequiredAnswers(_ missionTasks: [ReadingMissionTask]) -> Bool {
        missionTasks.count == 4 && missionTasks.allSatisfy {
            !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    @MainActor
    func scoreMission(mission: ReadingMission, missionTasks: [ReadingMissionTask]) async {
        guard !isScoringMission else { return }
        guard hasAllRequiredAnswers(missionTasks) else {
            missionScoreMessage = nil
            missionScoreError = "Answer all four mission prompts before getting a score."
            return
        }

        isScoringMission = true
        missionScoreMessage = nil
        missionScoreError = nil

        do {
            let result = try await ReadingMissionScoringService.scoreMission(
                mission: mission,
                tasks: missionTasks,
                book: localBook(for: mission),
                modelContext: modelContext,
                aiService: .shared
            )
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                missionScoreMessage = "Score saved: \(result.overallScore)/100"
                missionScoreError = nil
            }
        } catch {
            missionScoreMessage = nil
            missionScoreError = error.localizedDescription
        }

        isScoringMission = false
    }

    func beginReading(_ mission: ReadingMission) {
        guard let book = localBook(for: mission), book.status != .finished else {
            dismiss()
            return
        }

        let previousStatus = book.status
        book.markStarted()
        ReadingXPService.awardBookStatusChange(
            book: book,
            previousStatus: previousStatus,
            newStatus: book.status,
            modelContext: modelContext
        )
        try? modelContext.save()
        dismiss()
    }

    func toggleFilter(_ filter: ReadingMissionFilterKind) {
        if filter == .entireLibrary {
            criteria = .entireLibrary
            return
        }

        var kinds = criteria.activeKinds
        kinds.remove(.entireLibrary)

        if kinds.contains(filter) {
            kinds.remove(filter)
        } else {
            kinds.insert(filter)
        }

        if kinds.isEmpty {
            kinds.insert(.entireLibrary)
        }

        criteria.activeKinds = kinds

        if !kinds.contains(.genre) { criteria.genres = [] }
        if !kinds.contains(.author) { criteria.authors = [] }
        if !kinds.contains(.tags) { criteria.tags = [] }
    }

    func toggleValue(_ value: String, keyPath: WritableKeyPath<ReadingMissionFilterCriteria, [String]>) {
        var values = criteria[keyPath: keyPath]
        if let index = values.firstIndex(where: { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }) {
            values.remove(at: index)
        } else {
            values.append(value)
        }
        criteria[keyPath: keyPath] = values.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func localBook(for mission: ReadingMission) -> Book? {
        guard let bookID = mission.bookID else { return nil }
        return books.first { $0.id == bookID }
    }

    func completedTaskCount(for mission: ReadingMission) -> Int {
        tasks.filter { $0.missionID == mission.id && $0.isCompleted }.count
    }

    func uniqueValues(_ values: [String]) -> [String] {
        Array(
            Set(
                values
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func sectionHeader(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(tint)
                .bubblyIconMaterial(tint: tint)

            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
        }
    }
}

private struct ReadingMissionProgressRing: View {
    @Environment(\.appTheme) private var theme

    let progress: Double
    let completeCount: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.palette.raisedSurface, lineWidth: 7)

            BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 999)
                .mask {
                    Circle()
                        .trim(from: 0, to: min(max(progress, 0), 1))
                        .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round))
                }
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: progress)

            Text("\(completeCount)")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                .contentTransition(.numericText())
        }
        .frame(width: 54, height: 54)
    }
}

private struct ReadingMissionCover: View {
    let book: Book?
    let mission: ReadingMission
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(lumeyHex: mission.bookCoverColorHex).opacity(0.62),
                            Color(lumeyHex: mission.bookAccentColorHex).opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let data = book?.coverImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if let url = URL(string: mission.bookCoverURL), !mission.bookCoverURL.isEmpty {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(mission.bookTitle.prefix(1).uppercased())
                            .font(.system(size: width * 0.42, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text(mission.bookTitle.prefix(1).uppercased())
                    .font(.system(size: width * 0.42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }
}

private struct ReadingMissionBookPickerCover: View {
    let book: Book
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(lumeyHex: book.coverColorHex).opacity(0.62),
                            Color(lumeyHex: book.accentColorHex).opacity(0.78)
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
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if let url = URL(string: book.coverURL), !book.coverURL.isEmpty {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(book.displayTitle.prefix(1).uppercased())
                            .font(.system(size: width * 0.42, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text(book.displayTitle.prefix(1).uppercased())
                    .font(.system(size: width * 0.42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }
}

private struct ReadingMissionTaskCard: View {
    @Environment(\.appTheme) private var theme

    let task: ReadingMissionTask
    let borderColor: Color
    let onToggle: () -> Void
    let onNotesChanged: (String) -> Void

    @State private var draftNotes = ""
    @FocusState private var isNotesFocused: Bool

    private var hasAnswer: Bool {
        draftNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        GlassCard(
            cornerRadius: 18,
            padding: 16,
            variant: .secondary,
            borderColor: borderColor
        ) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Image(task.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(theme.palette.primaryAction)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: theme.palette.primaryAction)
                                .mask { Circle().strokeBorder(lineWidth: 1) }
                        }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(task.categoryRawValue)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(theme.palette.indicators)
                                .bubblyIconMaterial(tint: theme.palette.indicators)

                            Text(task.difficulty)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.text.muted)
                        }

                        Text(task.title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button(action: onToggle) {
                        Image(task.isCompleted ? "checkwavy" : "staroutline")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .foregroundStyle(theme.palette.secondaryAccent)
                            .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(theme.palette.raisedSurface))
                            .overlay {
                                BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                    .mask { Circle().strokeBorder(lineWidth: 1) }
                            }
                    }
                    .buttonStyle(.plain)
                }

                Text(task.taskDescription)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Answer")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.tertiary)

                    TextEditor(text: Binding(
                        get: { draftNotes },
                        set: { newValue in
                            draftNotes = newValue
                            onNotesChanged(newValue)
                        }
                    ))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .focused($isNotesFocused)
                    .frame(minHeight: 72)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.surface.nestedSoft))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(theme.palette.primaryAction, lineWidth: isNotesFocused ? 1.4 : 1)
                    }

                    if !task.isCompleted && !hasAnswer {
                        Text("Answer required")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.gradientPink)
                    }
                }

                if task.aiScore > 0 || !task.aiFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Image("sparkletrophy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)
                                .foregroundStyle(theme.palette.textPrimary)
                                .bubblyIconMaterial(tint: theme.palette.textPrimary)

                            Text("\(task.aiScore)/100")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(theme.palette.textPrimary)
                                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                            Text("AI Score")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(theme.palette.textPrimary)
                                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                            Spacer(minLength: 0)
                        }

                        if !task.aiFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(task.aiFeedback)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.palette.textPrimary)
                                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(11)
                    .background {
                        BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 14)
                    }
                    .bubblyTileLift()
                }

                if let completedAt = task.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.indicators)
                        .bubblyIconMaterial(tint: theme.palette.indicators)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            draftNotes = task.notes
        }
        .onChange(of: task.notes) { _, newValue in
            if draftNotes != newValue {
                draftNotes = newValue
            }
        }
    }
}
