//
//  ReadingGoalHistoryView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingGoalHistoryView: View {
    
    @Query(sort: \ReadingGoalHistory.createdAt, order: .reverse)
    private var historyItems: [ReadingGoalHistory]

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

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    topBar

                    dateRow
                    
                    if historyItems.isEmpty && completedDreams.isEmpty {
                        emptyState
                    } else {
                        if !completedDreams.isEmpty {
                            completedDreamsSection
                        }

                        if filteredHistory.isEmpty {
                            dayEmptyState
                        } else {
                            goalHistorySection
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
                .foregroundStyle(.white)

            Text("A soft timeline of your reading goal progress, completed goals, streak changes, and milestones.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LGradients.header)
                    .frame(width: 32, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Day bubbles
            ForEach(weekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isTodayBubble = calendar.isDateInToday(day)

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
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [LColors.gradientBlue, LColors.gradientPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(LColors.glassSurface2)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected
                                ? Color.clear
                                : (isTodayBubble ? Color.white.opacity(0.18) : Color.white.opacity(0.08)),
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LGradients.header)
                    .frame(width: 32, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty States
    
    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(.white)
                    .opacity(0.9)
                
                Text("No reading history yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("When you update or complete reading goals, your progress will appear here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }

    private var dayEmptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image("sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(LGradients.header)

                Text(dayEmptyTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(dayEmptyMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
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
                    .foregroundStyle(.white)

                Spacer()

                Text("\(completedDreams.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(completedDreams.enumerated()), id: \.element.id) { index, dream in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.vertical, 10)
                        }

                        CompletedDreamRow(dream: dream)
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
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(filteredHistory.enumerated()), id: \.element.id) { index, item in
                    TimelineRow(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == filteredHistory.count - 1
                    )
                }
            }
        }
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {

    let item: ReadingGoalHistory
    let isFirst: Bool
    let isLast: Bool

    private let nodeSize: CGFloat = 42

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline spine with icon node
            VStack(spacing: 0) {
                // Line above icon
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.white.opacity(0.12))
                    .frame(width: 1.5)
                    .frame(height: 10)

                // Icon node
                timelineIcon

                // Line below icon
                Rectangle()
                    .fill(isLast ? Color.clear : Color.white.opacity(0.12))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: nodeSize)

            // Card (no icon inside)
            ReadingGoalHistoryCard(item: item)
                .padding(.bottom, isLast ? 0 : 10)
        }
    }

    private var timelineIcon: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(iconForeground)
            .frame(width: nodeSize, height: nodeSize)
            .background(
                Circle()
                    .fill(LColors.glassSurface2)
            )
            .overlay(
                Circle()
                    .strokeBorder(iconBorder, lineWidth: 1)
            )
    }

    private var iconForeground: some ShapeStyle {
        switch item.eventType {
        case .completed:
            return AnyShapeStyle(LGradients.header)
        default:
            return AnyShapeStyle(Color.white.opacity(0.7))
        }
    }

    private var iconBorder: some ShapeStyle {
        switch item.eventType {
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [LColors.gradientBlue.opacity(0.6), LColors.gradientPurple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        default:
            return AnyShapeStyle(Color.white.opacity(0.10))
        }
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

    var body: some View {
        GlassCard(cornerRadius: 18, padding: 16) {
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
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text("Goal created.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
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
                    .foregroundStyle(.white.opacity(0.55))

                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LGradients.header)

                Text(formattedNumber(item.newValue))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if item.targetValue > 0 {
                    Spacer()
                    Text("/ \(formattedNumber(item.targetValue))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Progress bar
            if item.targetValue > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(LGradients.header)
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
                    .foregroundStyle(.white.opacity(0.6))
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
                    .foregroundStyle(LGradients.header)

                Text(goalTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))

                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }

            if item.targetValue > 0 {
                HStack(spacing: 4) {
                    Text(formattedNumber(item.newValue))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("/ \(formattedNumber(item.targetValue))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Text("Goal completed!")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(LGradients.header)

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
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
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 5) {
                        Text("\(item.previousStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(LGradients.header)

                        Text("\(item.newStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                if item.bestStreak > 0 {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Best")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("\(item.bestStreak)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
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
                        .foregroundStyle(LGradients.header)

                    Text(item.rewardEarned)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
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
                    .foregroundStyle(.white.opacity(0.72))
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
                .foregroundStyle(.white.opacity(0.5))
                .italic()

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Shared Header (Text Only — No Icon)

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.eventType.rawValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(goalTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(2)

            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
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

    var body: some View {
        HStack(spacing: 12) {
            Image(dream.iconName.isEmpty ? "sparklybook" : dream.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LGradients.header)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .strokeBorder(LGradients.header, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(dream.title.isEmpty ? "Untitled Dream" : dream.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
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
                .foregroundStyle(LGradients.header)
        }
    }
}
