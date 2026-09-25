//
//  ReadingGoalHistoryView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingGoalHistoryView: View {
    @Environment(\.appTheme) private var theme
    
    @Query(sort: \ReadingGoalHistory.createdAt, order: .reverse)
    private var historyItems: [ReadingGoalHistory]

    @Query(sort: \ReadingMissionHistory.createdAt, order: .reverse)
    private var missionHistoryItems: [ReadingMissionHistory]

    @Query(sort: \ReadingDream.updatedAt, order: .reverse)
    private var allDreams: [ReadingDream]

    private var completedDreams: [ReadingDream] {
        allDreams.filter { $0.isCompleted }
    }

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var weekOffset: Int = 0

    private var calendar: Calendar { Calendar.current }

    /// The 7 days of the currently visible week
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Start on Saturday (weekday 7) to match the screenshot layout
        let saturdayOffset = -(weekday % 7)
        guard let saturday = calendar.date(byAdding: .day, value: saturdayOffset + (weekOffset * 7), to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: saturday) }
    }

    /// History items filtered to the selected date
    private var filteredHistory: [ReadingGoalHistory] {
        let start = selectedDate
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return historyItems.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    private var filteredMissionHistory: [ReadingMissionHistory] {
        let start = selectedDate
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return missionHistoryItems
            .filter { item in
                let eventDate = item.eventDate
                return eventDate >= start && eventDate < end
            }
            .sorted { $0.eventDate > $1.eventDate }
    }

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    private func dayAccent(for date: Date) -> Color {
        let day = calendar.component(.day, from: date)
        let index = ((day - 19) % theme.palette.rotation.count + theme.palette.rotation.count) % theme.palette.rotation.count
        return theme.palette.rotation[index]
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    topBar

                    dateRow

                    monthHeader
                    
                    if historyItems.isEmpty && missionHistoryItems.isEmpty && completedDreams.isEmpty {
                        emptyState
                    } else {
                        if !completedDreams.isEmpty {
                            completedDreamsSection
                        }

                        if filteredHistory.isEmpty && filteredMissionHistory.isEmpty {
                            dayEmptyState
                        } else {
                            if !filteredMissionHistory.isEmpty {
                                missionHistorySection
                            }

                            if !filteredHistory.isEmpty {
                                goalHistorySection
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
    }
    
    // MARK: - Top Bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading History")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Text("A soft timeline of your reading goal progress, completed goals, streak changes, and milestones.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Date Row

    private var dateRow: some View {
        HStack(spacing: 8) {
            // Chevron left
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    weekOffset -= 1
                    // Select last day of new week if selected date leaves view
                    if let first = weekDays.first {
                        selectedDate = first
                    }
                }
            } label: {
                Image("chevleft")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Day bubbles
            ForEach(weekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isTodayBubble = calendar.isDateInToday(day)
                let accent = dayAccent(for: day)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = calendar.startOfDay(for: day)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)).prefix(3))
                            .font(.system(size: 11, weight: .bold, design: .rounded))

                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(isTodayBubble ? 0.8 : 0.5))
                    .shadow(
                        color: isSelected ? theme.palette.background.opacity(0.72) : .clear,
                        radius: 1,
                        y: 1
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        if isSelected {
                            BubblyIconMaterial(tint: accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LColors.glassSurface2)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected
                                ? Color.clear
                                : (isTodayBubble ? LColors.border.nestedStrong : LColors.border.nested),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // Chevron right
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    weekOffset += 1
                    if let first = weekDays.first {
                        selectedDate = first
                    }
                }
            } label: {
                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty States

    private var monthHeader: some View {
        Text(selectedDate.formatted(.dateTime.month(.wide)))
            .font(.system(size: 22, weight: .black, design: .rounded))
            .bubblyIconMaterial(tint: theme.palette.primaryAction)
    }
    
    private var emptyState: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(spacing: 14) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                
                Text("No reading history yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                
                Text("When you update or complete reading goals, your progress will appear here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }

    private var dayEmptyState: some View {
        GlassCard(variant: .primary, borderColor: theme.palette.primaryAction) {
            VStack(spacing: 14) {
                Image("sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

                Text(dayEmptyTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(dayEmptyMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 6)
    }

    private var dayEmptyTitle: String {
        if isToday {
            return "Nothing yet today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "A quiet yesterday"
        } else {
            return "A quiet day"
        }
    }

    private var dayEmptyMessage: String {
        let messages = [
            "Every page you turn is a step forward. Your next chapter is waiting.",
            "Rest days are part of the story too. You\u{2019}ll pick it back up.",
            "Some days are for living what you\u{2019}ve read. That counts too.",
            "The best reading journeys have pauses. Yours is no different.",
            "No entries here, but your progress hasn\u{2019}t gone anywhere."
        ]
        // Stable selection based on the date so the message doesn't flicker
        let dayIndex = calendar.ordinality(of: .day, in: .era, for: selectedDate) ?? 0
        return messages[dayIndex % messages.count]
    }

    // MARK: - Completed Dreams

    private var completedDreamsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Completed Dreams")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Spacer()

                Text("\(completedDreams.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }

            GlassCard(variant: .secondary) {
                VStack(spacing: 0) {
                    ForEach(Array(completedDreams.enumerated()), id: \.element.id) { index, dream in
                        if index > 0 {
                            Rectangle()
                                .fill(LColors.iconContainer.primary)
                                .frame(height: 1)
                                .padding(.vertical, 10)
                        }

                        CompletedDreamRow(
                            dream: dream,
                            accent: theme.palette.rotation[index % theme.palette.rotation.count]
                        )
                    }
                }
            }
        }
    }

    // MARK: - Goal History (Timeline)

    private var goalHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Goal History")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            VStack(spacing: 0) {
                ForEach(Array(filteredHistory.enumerated()), id: \.element.id) { index, item in
                    TimelineRow(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == filteredHistory.count - 1,
                        accent: theme.palette.rotation[index % theme.palette.rotation.count]
                    )
                }
            }
        }
    }

    private var missionHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reading Missions")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            VStack(spacing: 0) {
                ForEach(Array(filteredMissionHistory.enumerated()), id: \.element.id) { index, item in
                    MissionTimelineRow(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == filteredMissionHistory.count - 1,
                        accent: theme.palette.rotation[index % theme.palette.rotation.count]
                    )
                }
            }
        }
    }
}

private struct MissionTimelineRow: View {
    let item: ReadingMissionHistory
    let isFirst: Bool
    let isLast: Bool
    let accent: Color

    private let nodeSize: CGFloat = 42

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : LColors.border.subtle)
                    .frame(width: 1.5)
                    .frame(height: 10)

                Image(timelineIconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .bubblyIconMaterial(tint: accent)
                    .frame(width: nodeSize, height: nodeSize)
                    .background(Circle().fill(LColors.glassSurface2))
                    .overlay(Circle().strokeBorder(accent, lineWidth: 1))

                Rectangle()
                    .fill(isLast ? Color.clear : LColors.border.subtle)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: nodeSize)

            ReadingMissionHistoryCard(item: item, accent: accent)
                .padding(.bottom, isLast ? 0 : 10)
        }
    }

    private var timelineIconName: String {
        switch item.eventType {
        case .generated:
            return "wand"
        case .scored:
            return "sparklesearch"
        case .completed:
            return "sparkletrophy"
        }
    }
}

private struct ReadingMissionHistoryCard: View {
    let item: ReadingMissionHistory
    let accent: Color

    var body: some View {
        GlassCard(cornerRadius: 18, padding: 16, variant: .tertiary, borderColor: accent) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    if item.eventType == .generated {
                        Text(title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Text(title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .bubblyIconMaterial(tint: accent)
                    }

                    Text(item.bookTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)

                    Text(item.bookAuthor)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                HStack(spacing: 8) {
                    ReadingGoalPill(
                        text: pillText,
                        usePurpleStyle: item.eventType != .generated,
                        tint: accent
                    )

                    if item.eventType == .scored {
                        ReadingGoalPill(
                            text: "\(item.score)/100",
                            usePurpleStyle: false,
                            tint: accent
                        )
                    } else {
                        ReadingGoalPill(
                            text: ReadingMissionStatsCalculator.formattedDuration(seconds: item.durationSeconds),
                            usePurpleStyle: false,
                            tint: accent
                        )
                    }
                }

                if item.eventType == .scored, !item.scoreSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.scoreSummary)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(item.eventDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: String {
        switch item.eventType {
        case .generated:
            return "Mission Generated"
        case .scored:
            return "Mission Scored"
        case .completed:
            return "Mission Complete"
        }
    }

    private var pillText: String {
        switch item.eventType {
        case .generated:
            return "Active"
        case .scored:
            return item.scoreLabel.isEmpty ? "Scored" : item.scoreLabel
        case .completed:
            return "Completed"
        }
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {

    let item: ReadingGoalHistory
    let isFirst: Bool
    let isLast: Bool
    let accent: Color

    private let nodeSize: CGFloat = 42

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline spine with icon node
            VStack(spacing: 0) {
                // Line above icon
                Rectangle()
                    .fill(isFirst ? Color.clear : LColors.border.subtle)
                    .frame(width: 1.5)
                    .frame(height: 10)

                // Icon node
                timelineIcon

                // Line below icon
                Rectangle()
                    .fill(isLast ? Color.clear : LColors.border.subtle)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: nodeSize)

            // Card (no icon inside)
            ReadingGoalHistoryCard(item: item, accent: accent)
                .padding(.bottom, isLast ? 0 : 10)
        }
    }

    private var timelineIcon: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .bubblyIconMaterial(tint: accent)
            .frame(width: nodeSize, height: nodeSize)
            .background(
                Circle()
                    .fill(LColors.glassSurface2)
            )
            .overlay(
                Circle()
                    .strokeBorder(accent, lineWidth: 1)
            )
    }

    private var iconName: String {
        switch item.eventType {
        case .created:       return "addwavy"
        case .progressUpdated: return "openbook"
        case .streakUpdated: return "sparkle"
        case .completed:     return "checkwavy"
        case .reset:         return "reset"
        case .archived:      return "archivefill"
        case .rewardClaimed: return "starpopgift"
        case .noteAdded:     return "lovepage"
        }
    }
}

// MARK: - History Card (Event-Specific, No Icon)

private struct ReadingGoalHistoryCard: View {
    let item: ReadingGoalHistory
    let accent: Color

    var body: some View {
        GlassCard(cornerRadius: 18, padding: 16, variant: .elevated, borderColor: accent) {
            cardContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch item.eventType {
        case .created:
            createdCard
        case .progressUpdated:
            progressUpdatedCard
        case .completed:
            completedCard
        case .streakUpdated:
            streakUpdatedCard
        case .reset:
            simpleEventCard(description: "Goal reset.")
        case .archived:
            simpleEventCard(description: "Goal archived.")
        case .rewardClaimed:
            rewardCard
        case .noteAdded:
            noteCard
        }
    }

    // MARK: - Created

    private var createdCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            if item.targetValue > 0 {
                Text("Target: \(formattedNumber(item.targetValue))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.tertiary)
            }

            Text("Goal created.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.text.tertiary)
                .italic()
        }
    }

    // MARK: - Progress Updated

    private var progressUpdatedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader

            // Delta display
            HStack(spacing: 6) {
                Text(formattedNumber(item.previousValue))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.tertiary)

                Image("arrowrightwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .bubblyIconMaterial(tint: accent)

                Text(formattedNumber(item.newValue))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                if item.targetValue > 0 {
                    Spacer()
                    Text("/ \(formattedNumber(item.targetValue))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.muted)
                }
            }

            // Progress bar
            if item.targetValue > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LColors.border.nested)
                            .frame(height: 6)

                        BubblyTileSurface(tint: accent, cornerRadius: 3)
                            .frame(
                                width: max(0, geo.size.width * item.progressPercentage),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Completed

    private var completedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Completed")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .bubblyIconMaterial(tint: accent)

                Text(goalTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)

                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.muted)
            }

            if item.targetValue > 0 {
                HStack(spacing: 4) {
                    Text(formattedNumber(item.newValue))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)

                    Text("/ \(formattedNumber(item.targetValue))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.muted)
                }
            }

            Text("Goal completed!")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .bubblyIconMaterial(tint: accent)

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Streak Updated

    private var streakUpdatedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Streak")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.muted)

                    HStack(spacing: 5) {
                        Text("\(item.previousStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.text.tertiary)

                        Image("arrowrightwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .bubblyIconMaterial(tint: accent)

                        Text("\(item.newStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                    }
                }

                if item.bestStreak > 0 {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Best")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.text.muted)

                        Text("\(item.bestStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                    }
                }
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Reward Claimed

    private var rewardCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            if !item.rewardEarned.isEmpty {
                HStack(spacing: 8) {
                    Image("starpopgift")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .bubblyIconMaterial(tint: accent)

                    Text(item.rewardEarned)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.text.primary)
                }
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Note Added

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Simple Event (Reset / Archived)

    private func simpleEventCard(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            Text(description)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.text.tertiary)
                .italic()

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Shared Header (Text Only — No Icon)

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.eventType.rawValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Text(goalTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
                .lineLimit(2)

            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.text.muted)
        }
    }

    // MARK: - Helpers

    private var goalTitle: String {
        item.goalTitleSnapshot.isEmpty ? "Reading Goal" : item.goalTitleSnapshot
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Completed Dream Row

struct CompletedDreamRow: View {
    let dream: ReadingDream
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(dream.iconName.isEmpty ? "sparklybook" : dream.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .bubblyIconMaterial(tint: accent)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    Circle()
                        .strokeBorder(accent, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(dream.title.isEmpty ? "Untitled Dream" : dream.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(2)

                if !dream.notes.isEmpty {
                    Text(dream.notes)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                if let date = dream.completedDate {
                    Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Image("checkwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .bubblyIconMaterial(tint: accent)
        }
    }
}
