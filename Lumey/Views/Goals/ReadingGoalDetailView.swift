//
//  ReadingGoalDetailView.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct ReadingGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Bindable var goal: ReadingGoals

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]

    @Query(sort: \GoalNote.createdAt, order: .reverse)
    private var allGoalNotes: [GoalNote]
    
    @Query(sort: \ReadingSession.date, order: .reverse)
    private var allReadingSessions: [ReadingSession]
    
    @Query(sort: \ReadingGoalHistory.createdAt, order: .reverse)
    private var allGoalHistory: [ReadingGoalHistory]

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirm = false
    @State private var visibleSessionCount = 4
    @State private var showingGoalCompletionHistory = false

    private var goalNotes: [GoalNote] {
        allGoalNotes.filter { $0.goalID == goal.id }
    }

    private var linkedBooks: [Book] {
        let ids = goal.linkedBookIDs
        return allBooks.filter { ids.contains($0.id) }
    }
    
    private var linkedSessions: [ReadingSession] {
        allReadingSessions
            .filter { session in
                if session.allLinkedGoalIDs.contains(goal.id) {
                    return true
                }

                if session.allLinkedGoalTitles.contains(where: { $0.caseInsensitiveCompare(goal.displayTitle) == .orderedSame }) {
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
            .sorted { $0.date > $1.date }
    }

    private var visibleLinkedSessions: [ReadingSession] {
        Array(linkedSessions.prefix(visibleSessionCount))
    }

    private var hasMoreLinkedSessions: Bool {
        linkedSessions.count > visibleSessionCount
    }

    private var isShowingExpandedSessions: Bool {
        visibleSessionCount > 4
    }

    private var linkedSeriesName: String {
        goal.targetSeriesName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var seriesBooks: [Book] {
        guard !linkedSeriesName.isEmpty else { return [] }
        return allBooks.filter {
            $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == linkedSeriesName.lowercased()
        }
    }
    
    private var goalCompletionHistory: [ReadingGoalHistory] {
        allGoalHistory
            .filter {
                $0.goalID == goal.id &&
                $0.eventTypeRawValue == "Completed"
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                        overviewCard

                        if !goal.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            detailCard(title: "Description") {
                                Text(goal.goalDescription)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.text.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if !goal.goalReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            detailCard(title: "Why This Matters") {
                                Text(goal.goalReason)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.text.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if !goal.rewardIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            detailCard(title: "Reward") {
                                HStack(spacing: 10) {
                                    Image("starpopgift")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(LColors.accents.primary)

                                    Text(goal.rewardIdea)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(LColors.border.nestedStrong)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(LColors.border.subtle, lineWidth: 1)
                                        )
                                    )
                                }
                            }

                        notesCard

                        relatedContentSection

                        if !linkedSessions.isEmpty {
                            sessionHistoryCard
                        }

                        milestonesCard
                    }
                    .frame(width: geo.size.width - 40, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(isPresented: $showingEditSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            AddEditReadingGoalSheet(goal: goal)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingGoalCompletionHistory, useFullScreenCover: horizontalSizeClass == .regular) {
            GoalCompletionHistorySheet(
                goalTitle: goal.displayTitle,
                entries: goalCompletionHistory
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .alert("Delete Goal?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(goal)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This goal will be permanently removed.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(goal.displayTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showingEditSheet = true
                } label: {
                    Image("pencil")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(LColors.accents.contrast)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(LColors.bg)
                                .overlay(
                                    Circle()
                                        .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .fixedSize()

                Button {
                    dismiss()
                } label: {
                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(LColors.accents.secondary)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(LColors.bg)
                                .overlay(
                                    Circle()
                                        .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .fixedSize()
            }

            FlowLayout(spacing: 8) {
                ReadingGoalPill(text: goal.type.rawValue)
                ReadingGoalPill(text: goal.status.rawValue)
                ReadingGoalPill(text: goal.cadence.rawValue)

                if goal.isPinned {
                    ReadingGoalPill(text: "Pinned", usePurpleStyle: true)
                }
            }
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    Image(goal.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(LColors.accents.special)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(LColors.accents.secondary, lineWidth: 1.15))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(goal.displayTitle)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(2)

                        Text(goal.mode.rawValue + " • " + goal.cadence.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    DottedGoalProgressBar(value: goal.progressValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 12)

                    HStack {
                        Text(goal.progressText)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)

                        Spacer()

                        Text("\(goal.progressPercentage)%")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                    }
                }

                if let days = goal.daysRemaining {
                    HStack(spacing: 6) {
                        Image("clockfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(days >= 0 ? LColors.textSecondary : LColors.danger)

                        Text(days >= 0 ? "\(days) days remaining" : "Past target date")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(days >= 0 ? LColors.textSecondary : LColors.danger)
                    }
                }

                miniStatsGrid
            }
        }
    }

    @ViewBuilder
    private var miniStatsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
            spacing: 10
        ) {
            GoalDetailMiniStat(
                title: "Started",
                value: goal.startDate.formatted(date: .abbreviated, time: .omitted)
            )

            Button {
                showingGoalCompletionHistory = true
            } label: {
                GoalDetailMiniStat(
                    title: "Completion History",
                    value: "\(goalCompletionHistory.count)"
                )
            }
            .buttonStyle(.plain)

            if let targetDate = goal.targetDate {
                GoalDetailMiniStat(
                    title: "Due",
                    value: targetDate.formatted(date: .abbreviated, time: .omitted)
                )
            }

            if goal.type == .streak {
                GoalDetailMiniStat(title: "Streak", value: "\(goal.currentStreak)")
                GoalDetailMiniStat(title: "Best", value: "\(goal.bestStreak)")
            }
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        NavigationLink {
            GoalNotesTimelinePage(goal: goal)
        } label: {
            GlassCard(variant: .primary) {
                HStack(spacing: 12) {
                    Image("lovepage")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(LColors.accents.primary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(LColors.accents.special, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        if goalNotes.isEmpty {
                            Text("No notes yet")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        } else {
                            Text("\(goalNotes.count) Notes • Last Updated \(lastNoteRelativeDate)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.text.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var lastNoteRelativeDate: String {
        guard let latest = goalNotes.first else { return "" }
        let diff = Calendar.current.dateComponents([.day], from: latest.createdAt, to: Date())
        let days = diff.day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) Days Ago"
    }

    // MARK: - Related Content

    @ViewBuilder
    private var relatedContentSection: some View {
        if !linkedBooks.isEmpty || !linkedSeriesName.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if !linkedBooks.isEmpty {
                    detailCard(title: "Related Books") {
                        VStack(spacing: 10) {
                            ForEach(linkedBooks) { book in
                                HStack(spacing: 10) {
                                    Image("books")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                        .foregroundStyle(LColors.accents.contrast)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.title)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.cardTitle)
                                            .lineLimit(1)

                                        Text(book.author)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(book.status.rawValue)
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(LColors.iconContainer.primary))
                                }
                            }
                        }
                    }
                }

                if !linkedSeriesName.isEmpty {
                    detailCard(title: "Related Series") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(linkedSeriesName)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            if !seriesBooks.isEmpty {
                                Text("\(seriesBooks.count) books in library")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Session History

    private var sessionHistoryCard: some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session History")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                VStack(spacing: 0) {
                    ForEach(Array(visibleLinkedSessions.enumerated()), id: \.element.id) { index, session in
                        sessionHistoryRow(session)

                        if index < visibleLinkedSessions.count - 1 {
                            dottedDivider
                                .padding(.vertical, 10)
                        }
                    }
                }

                if linkedSessions.count > 4 {
                    HStack(spacing: 10) {
                        if isShowingExpandedSessions {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                    visibleSessionCount = 4
                                }
                            } label: {
                                sessionHistoryButtonLabel("Load Less")
                            }
                            .buttonStyle(.plain)
                        }

                        if hasMoreLinkedSessions {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                    visibleSessionCount += 4
                                }
                            } label: {
                                sessionHistoryButtonLabel("Load More")
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

    private func sessionHistoryRow(_ session: ReadingSession) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image("openbook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.accents.secondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(LColors.accents.primary, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(1)

                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("\(session.pagesRead) pages • \(session.durationMinutes) min • \(session.pointsEarned) pts")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    private func sessionHistoryButtonLabel(_ text: String) -> some View {
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
                            .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                    )
            )
    }

    private var dottedDivider: some View {
        HStack(spacing: 4) {
            ForEach(0..<51, id: \.self) { _ in
                Circle()
                    .fill(LColors.border.subtle)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    // MARK: - Milestones Card

    private var milestonesCard: some View {
        let milestones: [(label: String, threshold: Double)] = [
            ("25%", 0.25),
            ("50%", 0.50),
            ("75%", 0.75),
            ("100%", 1.0),
        ]

        return VStack(alignment: .leading, spacing: 14) {
            Text("Milestones")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            VStack(spacing: 10) {
                ForEach(milestones, id: \.label) { milestone in
                    let reached = goal.progressValue >= milestone.threshold
                    let noteCount = goalNotes.filter { $0.progressSnapshot >= milestone.threshold - 0.01 && $0.progressSnapshot <= milestone.threshold + 0.12 }.count

                    HStack(spacing: 12) {
                        Image(reached ? "checkwavy" : "sparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(reached ? AnyShapeStyle(LColors.accents.primary) : AnyShapeStyle(LColors.text.muted))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(lumeyHex: "#1a1a1e")))
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        reached
                                            ? AnyShapeStyle(LColors.accents.contrast)
                                            : AnyShapeStyle(LColors.border.subtle),
                                        lineWidth: 1
                                    )
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.label + " Milestone")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(reached ? .white : .white.opacity(0.45))

                            Text(reached ? (noteCount > 0 ? "\(noteCount) note\(noteCount == 1 ? "" : "s")" : "Reached") : "Not yet reached")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(lumeyHex: "#111114"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                reached
                                    ? AnyShapeStyle(
                                        LColors.accents.special
                                    )
                                    : AnyShapeStyle(LColors.border.nested),
                                lineWidth: reached ? 1.2 : 0.8
                            )
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func detailCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard(variant: .tertiary) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - GOAL COMPLETION HISTORY SHEET
private struct GoalCompletionHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let goalTitle: String
    let entries: [ReadingGoalHistory]

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if entries.isEmpty {
                            emptyHistoryCard
                        } else {
                            ForEach(entries, id: \.id) { entry in
                                historyCard(entry)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Completion History")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(goalTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.special)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.secondary, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .safeAreaPadding(.top)
    }

    private var emptyHistoryCard: some View {
        GlassCard(variant: .elevated) {
            VStack(spacing: 10) {
                Image("startrophyfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(LColors.accents.primary)

                Text("No Completion History Yet")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text("Completed weekly goals will show here.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func historyCard(_ entry: ReadingGoalHistory) -> some View {
        GlassCard(variant: .subtle) {
            HStack(alignment: .top, spacing: 12) {
                Image("startrophyfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.accents.special, lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Completed")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("\(ReadingGoals.cleanNumber(entry.newValue)) / \(ReadingGoals.cleanNumber(entry.targetValue))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    if !entry.rewardEarned.isEmpty {
                        Text(entry.rewardEarned)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                    }

                    Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.8))
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Mini Stat

struct GoalDetailMiniStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
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
