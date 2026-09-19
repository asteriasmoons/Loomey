//
//  ReadingGoalsView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var timer = ReadingTimerManager.shared
    
    @Query(sort: \ReadingGoals.updatedAt, order: .reverse)
    private var goals: [ReadingGoals]
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query(
        sort: \ReadingAchievement.sortOrder
    )
    private var achievements: [ReadingAchievement]

    @Query(sort: \ReadingDream.updatedAt, order: .reverse)
    private var dreams: [ReadingDream]
    
    @State private var showingAddGoalSheet = false
    @State private var showingLogSession = false
    @State private var showingCatchUp = false
    @State private var showingReadingTimer = false
    @State private var showingAddDreamSheet = false
    @State private var showingCheckIn = false
    
    private var activeGoals: [ReadingGoals] {
        goals.filter { $0.status == .active && !$0.isArchived }
    }
    
    private var pinnedGoals: [ReadingGoals] {
        activeGoals.filter { $0.isPinned }
    }
    
    private var completedGoals: [ReadingGoals] {
        goals.filter { $0.status == .completed && !$0.isArchived }
    }
    
    private var pausedGoals: [ReadingGoals] {
        goals.filter { $0.status == .paused && !$0.isArchived }
    }
    
    private var heroGoal: ReadingGoals? {
        pinnedGoals.first ?? activeGoals.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    LumeyBackground()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            header

                            readingGoalsHeroSummaryCard

                            readingMilestonesSection

                            readingDreamsSection

                            miniTimerSection

                            heroGoalSection
                            
                            goalTypeShelf
                            
                            activeGoalsSection
                            
                            completedGoalsSection
                        }
                        .frame(width: geo.size.width - 40, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 140)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .adaptivePresentation(isPresented: $showingAddGoalSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                AddEditReadingGoalSheet(goal: nil)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingLogSession, useFullScreenCover: horizontalSizeClass == .regular) {
                LogSessionSheet(goals: goals, books: books)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showingCatchUp) {
                CatchUpSheet(books: books, sessions: sessions)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingReadingTimer, useFullScreenCover: horizontalSizeClass == .regular) {
                ReadingTimerSheet(
                    goals: goals,
                    books: books
                )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingAddDreamSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                AddEditReadingDreamSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingCheckIn, useFullScreenCover: horizontalSizeClass == .regular) {
                GoalCheckInSheet(goals: activeGoals, books: books)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .onAppear {
                resetRecurringGoalsIfNeeded()
                ReadingAchievementManager.updateAchievements(modelContext: modelContext)
            }
            .onChange(of: books.map(\.lastUpdated)) {
                ReadingAchievementManager.updateAchievements(modelContext: modelContext)
            }
            .onChange(of: sessions.map(\.date)) {
                ReadingAchievementManager.updateAchievements(modelContext: modelContext)
            }
        }
    }
    
    private func resetRecurringGoalsIfNeeded() {
        goals.forEach { goal in
            let previousValue = goal.currentValue
            let previousStatus = goal.status

            goal.resetProgressIfNeededForCurrentPeriod()

            if goal.cadence == .daily,
               previousStatus == .completed,
               previousValue != goal.currentValue {
                goal.status = .active
                goal.updatedAt = Date()
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Header

private extension ReadingGoalsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Goals")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                
                Spacer()
                
                addGoalButton
            }
            
            Text("Track your reading momentum, rituals, themes, and long-term reader identity.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            HStack(spacing: 10) {
                Button {
                    showingLogSession = true
                } label: {
                    HStack(spacing: 7) {
                        Image("clockfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                        Text("Log Session")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LColors.accents.primary
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingReadingTimer = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .bold))
                        Text("Timer")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(timer.isActive ? LColors.gradientBlue : LColors.textSecondary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface)
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        timer.isActive
                                        ? LColors.accents.primary
                                        : LColors.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingCheckIn = true
                } label: {
                    HStack(spacing: 7) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text("Check-In")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(LColors.textSecondary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface)
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        LColors.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                showingCatchUp = true
            } label: {
                HStack(spacing: 7) {
                    Image("clockwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)

                    Text("Catch Up")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundStyle(LColors.cardTitle)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(LColors.glassSurface)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var addGoalButton: some View {
        Button {
            showingAddGoalSheet = true
        } label: {
            Image("addwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(
                    LColors.accents.primary
                )
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LColors.accents.primary,
                                    lineWidth: 1.35
                                )
                        )
                        .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reading Goals Hero Summary

private extension ReadingGoalsView {
    var readingGoalsHeroSummaryCard: some View {
        ReadingGoalsHeroSummaryCard(
            activeCount: activeGoals.count,
            completedCount: completedGoals.count,
            totalBooksCount: books.filter { !$0.isArchived }.count,
            totalSessionsCount: sessions.count,
            onAddGoal: {
                showingAddGoalSheet = true
            }
        )
    }
}

struct ReadingGoalsHeroSummaryCard: View {
    let activeCount: Int
    let completedCount: Int
    let totalBooksCount: Int
    let totalSessionsCount: Int
    let onAddGoal: () -> Void

    var body: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    Image("achievement")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(LColors.accents.contrast)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1.15))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Goals in Motion")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.primary)

                        Text("Track daily, weekly, monthly, and yearly reading targets.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    ReadingGoalsHeroMiniStat(title: "Active",    value: "\(activeCount)",        tint: LColors.accents.primary)
                    ReadingGoalsHeroMiniStat(title: "Completed", value: "\(completedCount)",     tint: LColors.accents.contrast)
                    ReadingGoalsHeroMiniStat(title: "Books",     value: "\(totalBooksCount)",    tint: LColors.accents.secondary)
                    ReadingGoalsHeroMiniStat(title: "Sessions",  value: "\(totalSessionsCount)", tint: LColors.accents.special)
                }
                
                Button(action: onAddGoal) {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                        
                        Text("Add Reading Goal")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LGradients.header)
                    )
                    .shadow(color: LColors.gradientBlue.opacity(0.22), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ReadingGoalsHeroMiniStat: View {
    let title: String
    let value: String
    var tint: Color = LColors.accents.primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
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

// MARK: - Reading Achievements

private extension ReadingGoalsView {
    var readingMilestonesSection: some View {
        let unlockedAchievements = achievements.filter { $0.isUnlocked }
        let inProgressAchievements = achievements.filter { !$0.isUnlocked }
        let displayAchievements = Array(unlockedAchievements.prefix(3)) + Array(inProgressAchievements.prefix(5))

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Reading Achievements")

                Spacer()

                Text("\(unlockedAchievements.count)/\(achievements.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }

            if achievements.isEmpty {
                EmptyGoalCard(
                    title: "Achievements are loading",
                    message: "Lumey creates built-in reading achievements automatically from your reading progress."
                )
            } else {
                GlassCard(variant: .tertiary) {
                    VStack(spacing: 0) {
                        ForEach(Array(displayAchievements.enumerated()), id: \.element.id) { index, achievement in
                            if index > 0 {
                                Rectangle()
                                    .fill(LColors.border.subtle)
                                    .frame(height: 1)
                                    .padding(.vertical, 10)
                            }

                            CompactAchievementRow(achievement: achievement, accentIndex: index)
                        }
                    }
                }
            }
        }
    }
}

struct CompactAchievementRow: View {
    let achievement: ReadingAchievement
    var accentIndex: Int = 0

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    private var progress: Double {
        guard achievement.targetValue > 0 else { return 0 }
        return min(Double(achievement.currentValue) / Double(achievement.targetValue), 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(achievement.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(achievement.isUnlocked ? accent : LColors.text.muted)
                .frame(width: 38, height: 38)
                .background(Circle().fill(achievement.isUnlocked ? accent.opacity(0.15) : LColors.iconContainer.primary))
                .overlay(
                    Circle().strokeBorder(
                        achievement.isUnlocked ? accent : LColors.border.nested,
                        lineWidth: 1
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(achievement.isUnlocked ? LColors.text.primary : LColors.text.tertiary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if achievement.isUnlocked {
                        Image("startrophy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(accent)
                    } else {
                        Text("\(min(achievement.currentValue, achievement.targetValue))/\(achievement.targetValue)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.tertiary)
                    }
                }

                DottedGoalProgressBar(value: progress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Reading Dreams

private extension ReadingGoalsView {
    var readingDreamsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Reading Dreams")

                Spacer()

                Button {
                    showingAddDreamSheet = true
                } label: {
                    Image("addwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.accents.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(LColors.iconContainer.primary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.accents.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            let activeDreams = dreams.filter { !$0.isArchived && !$0.isCompleted }

            if activeDreams.isEmpty {
                EmptyGoalCard(
                    title: "No reading dreams yet",
                    message: "Add big-picture aspirations like finishing a series, building a fantasy library, or reading more classics."
                )
            } else {
                GlassCard(variant: .secondary) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(activeDreams.prefix(6).enumerated()), id: \.element.id) { index, dream in
                            ReadingDreamBulletRow(dream: dream, accentIndex: index) {
                                dream.isCompleted = true
                                dream.completedDate = Date()
                                dream.updatedAt = Date()
                                try? modelContext.save()
                            }

                            if index < min(activeDreams.count, 6) - 1 {
                                Rectangle()
                                    .fill(LColors.border.subtle)
                                    .frame(height: 1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ReadingDreamBulletRow: View {
    let dream: ReadingDream
    var accentIndex: Int = 0
    let onComplete: () -> Void

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(dream.iconName.isEmpty ? "sparklybook" : dream.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(accent, lineWidth: 1))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(dream.title.isEmpty ? "Untitled Dream" : dream.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(2)

                if !dream.notes.isEmpty {
                    Text(dream.notes)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 0)

            Button(action: onComplete) {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(LColors.iconContainer.primary)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(LColors.border.nested, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AddEditReadingDreamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var title = ""
    @State private var notes = ""
    @State private var iconName = "sparklybook"
    @State private var showingIconPicker = false

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 13) {
                                Text("Dream")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.text.primary)

                                LumeyTextField(title: "Title", text: $title)
                                LumeyTextEditor(title: "Notes", text: $notes, minHeight: 100)
                            }
                        }

                        GlassCard(variant: .secondary) {
                            GoalIconPickerRow(iconName: $iconName) {
                                showingIconPicker = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .adaptivePresentation(isPresented: $showingIconPicker, useFullScreenCover: horizontalSizeClass == .regular) {
            IconPickerView(selectedIcon: $iconName)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Dream")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Create a big-picture reading aspiration")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                saveDream()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LGradients.header)
                    )
            }
            .buttonStyle(.plain)

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
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LColors.border.nested)
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private func saveDream() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let dream = ReadingDream(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "sparklybook" : iconName
        )

        modelContext.insert(dream)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Mini Timer

private extension ReadingGoalsView {
    @ViewBuilder
    var miniTimerSection: some View {
        if timer.isActive {
            MiniReadingTimerCard(timer: timer) {
                showingReadingTimer = true
            }
        }
    }
}

// MARK: - Hero Goal

private extension ReadingGoalsView {
    var heroGoalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Main Goal")
            
            if let heroGoal {
                NavigationLink {
                    ReadingGoalDetailView(goal: heroGoal)
                } label: {
                    ReadingHeroGoalCard(goal: heroGoal)
                }
                .buttonStyle(.plain)
            } else {
                EmptyGoalCard(
                    title: "No active goal yet",
                    message: "Create a yearly book goal, daily reading ritual, genre challenge, streak goal, or custom Lumey goal."
                )
            }
        }
    }
}

// MARK: - Goal Type Shelf

private extension ReadingGoalsView {
    var goalTypeShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Goal Types")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ReadingGoalType.allCases) { type in
                        ReadingGoalTypeCard(type: type)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 10)
            }
            .scrollClipDisabled(false)
        }
    }
}

// MARK: - Active Goals

private extension ReadingGoalsView {
    var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Active Goals")
                
                Spacer()
                
                Text("\(activeGoals.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }
            
            if activeGoals.isEmpty {
                EmptyGoalCard(
                    title: "Nothing active yet",
                    message: "Your active reading goals will appear here."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activeGoals) { goal in
                        NavigationLink {
                            ReadingGoalDetailView(goal: goal)
                        } label: {
                            ReadingGoalRow(
                                goal: goal,
                                onDelete: {
                                    modelContext.delete(goal)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Completed Goals

private extension ReadingGoalsView {
    var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Completed Goals")
                
                Spacer()
                
                Text("\(completedGoals.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }
            
            if completedGoals.isEmpty {
                EmptyGoalCard(
                    title: "No completed goals yet",
                    message: "Completed goals will become part of your reading journey."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(completedGoals) { goal in
                        NavigationLink {
                            ReadingGoalDetailView(goal: goal)
                        } label: {
                            ReadingGoalRow(
                                goal: goal,
                                onDelete: {
                                    modelContext.delete(goal)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension ReadingGoalsView {
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(LColors.headingPrimary)
    }
}

// MARK: - Mini Reading Timer Card

struct MiniReadingTimerCard: View {
    @ObservedObject var timer: ReadingTimerManager
    var onTap: () -> Void
    
    private var formattedElapsed: String {
        let total = timer.elapsedSeconds
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Button(action: onTap) {
            GlassCard(variant: .featured) {
                HStack(spacing: 12) {
                    Image("clockfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(
                            LColors.accents.primary
                        )
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(LColors.iconContainer.primary))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timer.isPaused ? "Reading Paused" : "Reading Timer")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Text(timer.bookTitle.isEmpty ? "Session in progress" : timer.bookTitle)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(formattedElapsed)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero Goal Card

struct ReadingHeroGoalCard: View {
    let goal: ReadingGoals
    
    var body: some View {
        GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(goal.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(
                            LColors.accents.primary
                        )
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.accents.secondary, lineWidth: 1.15)
                        )
                    
                    Text(goal.displayTitle)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(goal.goalDescription.isEmpty ? goal.type.rawValue : goal.goalDescription)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(3)
                    
                    FlowLayout(spacing: 8) {
                        ReadingGoalPill(text: goal.type.rawValue)
                        ReadingGoalPill(text: goal.cadence.rawValue)
                        ReadingGoalPill(text: goal.priority.rawValue)
                        
                        if goal.isPinned {
                            ReadingGoalPill(text: "Pinned", usePurpleStyle: true)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DottedGoalProgressBar(value: goal.progressValue)
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
                    
                    if !goal.goalReason.isEmpty {
                        ReadingGoalTextBlock(label: "Why this matters", value: goal.goalReason)
                    }
                    
                    if let days = goal.daysRemaining {
                        Text(days >= 0 ? "\(days) days remaining" : "Past target date")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(days >= 0 ? LColors.textSecondary : LColors.danger)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Goal Row

struct ReadingGoalRow: View {
    let goal: ReadingGoals
    var onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(goal.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            LColors.accents.primary
                        )
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LColors.accents.primary,
                                    lineWidth: 1
                                )
                        )
                    
                    Text(goal.displayTitle)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image("trash")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundStyle(
                                LColors.accents.primary
                            )
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(LColors.iconContainer.primary))
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    if !goal.goalDescription.isEmpty {
                        Text(goal.goalDescription)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(3)
                    }
                    
                    FlowLayout(spacing: 8) {
                        ReadingGoalPill(text: goal.type.rawValue)
                        ReadingGoalPill(text: goal.cadence.rawValue)
                        ReadingGoalPill(text: goal.status.rawValue)
                    }
                    
                    VStack(alignment: .leading, spacing: 7) {
                        DottedGoalProgressBar(value: goal.progressValue)
                            .frame(height: 12)
                        
                        HStack {
                            Text(goal.progressText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(goal.progressPercentage)%")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .alert("Delete Goal?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This goal will be removed from your Goals page.")
        }
    }
}

// MARK: - Dotted Goal Progress Bar

struct DottedGoalProgressBar: View {
    let value: Double
    private let dotCount = 25
    
    private var clampedValue: Double {
        min(max(value, 0), 1)
    }
    
    private var filledDots: Int {
        Int((clampedValue * Double(dotCount)).rounded(.up))
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(dotFill(for: index))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .strokeBorder(index < filledDots ? LColors.accents.primary.opacity(0.35) : LColors.border.subtle.opacity(0.5), lineWidth: 0.6)
                    )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func dotFill(for index: Int) -> LinearGradient {
        if index < filledDots {
            return LumeyProgressStyle.fill
        }
        
        return LinearGradient(
            colors: [
                LumeyProgressStyle.idleDot.opacity(0.92),
                LumeyProgressStyle.idleDot.opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Type Card

struct ReadingGoalTypeCard: View {
    let type: ReadingGoalType
    
    var body: some View {
        GlassCard(variant: .tertiary) {
            VStack(alignment: .leading, spacing: 10) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(
                        LColors.accents.primary
                    )
                
                Text(shortTitle)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 96, alignment: .topLeading)
        }
        .frame(width: 132)
    }

    private var shortTitle: String {
        switch type {
        case .finishBook:      return "Finish Book"
        case .finishSeries:    return "Finish Series"
        case .seasonalTheme:   return "Seasonal"
        case .emotionalGoal:   return "Emotion"
        case .readingRitual:   return "Ritual"
        default:               return type.rawValue
        }
    }
    
    private var iconName: String {
        switch type {
        case .books, .finishBook, .finishSeries, .tbr:
            return "books"
        case .pages:
            return "openbook"
        case .minutes, .hours:
            return "clockfill"
        case .streak:
            return "levelup"
        case .genre, .subgenre:
            return "sparkle"
        case .author:
            return "pencil"
        case .format:
            return "starnote"
        case .habit, .readingRitual:
            return "achievement"
        case .seasonalTheme:
            return "starfill"
        case .emotionalGoal:
            return "heartfill"
        case .custom:
            return "achievement"
        }
    }
}

// MARK: - Stat Card

struct ReadingGoalStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        GlassCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.accents.special)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Empty Goal Card

struct EmptyGoalCard: View {
    let title: String
    let message: String
    
    var body: some View {
        GlassCard(variant: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Goal Pill

struct ReadingGoalPill: View {
    let text: String
    var usePurpleStyle: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: usePurpleStyle
                            ? [
                                LColors.gradientPurple.opacity(0.30),
                                LColors.gradientPurple.opacity(0.18)
                            ]
                            : [
                                LColors.gradientBlue.opacity(0.20),
                                LColors.gradientPurple.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: usePurpleStyle
                            ? [
                                LColors.gradientPurple,
                                LColors.gradientPurple.opacity(0.7)
                            ]
                            : [
                                LColors.gradientBlue.opacity(0.7),
                                LColors.gradientPurple.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

// MARK: - Text Block

struct ReadingGoalTextBlock: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
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
    ReadingGoalsView()
}

// MARK: - Log Session Sheet

struct LogSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let goals: [ReadingGoals]
    let books: [Book]

    @State private var selectedGoalIDs: Set<UUID> = []
    @State private var selectedBook: Book? = nil
    @State private var manualMinutes = ""
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var ebookStartPage = ""
    @State private var ebookEndPage = ""
    @State private var sessionDate = Date()
    @State private var showingInsightSheet = false
    @State private var insightDraft = ReadingInsightDraft()

    private var readingBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    private var activeGoals: [ReadingGoals] {
        goals.filter { $0.status == .active && !$0.isArchived }
    }

    private var selectedGoals: [ReadingGoals] {
        activeGoals.filter { selectedGoalIDs.contains($0.id) }
    }

    private var isEbookMode: Bool {
        let ebStart = Int(ebookStartPage) ?? 0
        let ebEnd = Int(ebookEndPage) ?? 0
        return ebEnd > ebStart
    }
    
    private var bookCanConvert: Bool {
        guard let book = selectedBook else { return false }
        return book.ebookTotalPages > 0 && book.totalPages > 0
    }
    
    private var calculatedPagesRead: Int {
        if isEbookMode, bookCanConvert, let book = selectedBook {
            let ebStart = Int(ebookStartPage) ?? 0
            let ebEnd = Int(ebookEndPage) ?? 0
            let physStart = book.convertedPhysicalPage(from: ebStart)
            let physEnd = book.convertedPhysicalPage(from: ebEnd)
            return max(physEnd - physStart, 0)
        } else {
            let start = Int(startPage) ?? 0
            let end = Int(endPage) ?? 0
            return max(end - start, 0)
        }
    }

    private var enteredEndPage: Int {
        if isEbookMode, bookCanConvert, let book = selectedBook {
            return book.convertedPhysicalPage(from: Int(ebookEndPage) ?? 0)
        }
        return Int(endPage) ?? 0
    }
    
    private var enteredEbookEndPage: Int {
        Int(ebookEndPage) ?? 0
    }

    private var previewPoints: Int {
        ReadingSession.calculatePoints(minutes: Int(manualMinutes) ?? 0, pages: calculatedPagesRead)
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Book link
                        if !readingBooks.isEmpty {
                            GlassCard(variant: .featured) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Book")
                                        .font(.system(size: 17, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                    
                                    Menu {
                                        Button("No Book") {
                                            selectedBook = nil
                                        }
                                        
                                        ForEach(readingBooks) { book in
                                            Button(book.title) {
                                                selectedBook = book
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(selectedBook?.title ?? "Select Reading Book")
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                                .foregroundStyle(selectedBook == nil ? LColors.textSecondary : .white)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Image("chevdown")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 13, height: 13)
                                                .foregroundStyle(LColors.textSecondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(LColors.glassSurface2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .onChange(of: selectedBook?.id) { _, _ in syncEbookToPhysical() }
                                }
                            }
                        }

                        // Duration
                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                LumeyTextField(title: "Minutes read", text: $manualMinutes)
                                    .keyboardType(.numberPad)
                            }
                        }

                        // Pages
                        GlassCard(variant: .secondary) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pages")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)

                                LumeyTextField(title: "Start Page", text: $startPage)
                                    .keyboardType(.numberPad)

                                LumeyTextField(title: "End Page", text: $endPage)
                                    .keyboardType(.numberPad)

                                HStack {
                                    Text("Pages Read")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)

                                    Spacer()

                                    Text("\(calculatedPagesRead)")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                }
                                .padding(.top, 2)
                            }
                        }
                        
                        // Ebook Pages (always visible, optional)
                        GlassCard(variant: .tertiary) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ebook Pages")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                
                                Text("If reading an ebook, enter ebook page numbers here to auto-convert to physical pages.")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                LumeyTextField(title: "Ebook Start Page", text: $ebookStartPage)
                                    .keyboardType(.numberPad)
                                    .onChange(of: ebookStartPage) { _, _ in syncEbookToPhysical() }

                                LumeyTextField(title: "Ebook End Page", text: $ebookEndPage)
                                    .keyboardType(.numberPad)
                                    .onChange(of: ebookEndPage) { _, _ in syncEbookToPhysical() }
                                
                                ebookSessionConversionPreview
                            }
                        }

                        // Goal link
                        if !activeGoals.isEmpty {
                            GlassCard(variant: .elevated) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Link to Goals")
                                        .font(.system(size: 17, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(activeGoals) { goal in
                                                let isSelected = selectedGoalIDs.contains(goal.id)
                                                Button {
                                                    toggleGoalSelection(goal)
                                                } label: {
                                                    Text(goal.displayTitle)
                                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                                        .foregroundStyle(LColors.cardTitle)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Capsule().fill(
                                                                isSelected
                                                                ? LColors.accents.primary
                                                                : LColors.glassSurface2
                                                            )
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }

                                    if !selectedGoalIDs.isEmpty {
                                        Text("Session progress will be added to \(selectedGoals.count) selected \(selectedGoals.count == 1 ? "goal" : "goals") when the goal type matches minutes, hours, pages, or streaks.")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                    }
                                }
                            }
                        }

                        // Date & time
                        GlassCard(variant: .subtle) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Date & Time")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)

                                LumeyGradientDateTimeDrumPicker(date: $sessionDate)
                            }
                        }

                        insightButton

                        // Points preview
                        GlassCard(variant: .featured) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Points Preview")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                    Text("+\(previewPoints) pts")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.accents.primary)
                                }
                                Spacer()
                                Image("levelup")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(
                                        LColors.accents.primary
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .lumeyDismissKeyboardOnTap()
        .adaptivePresentation(isPresented: $showingInsightSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            ReadingInsightCaptureSheet(
                draft: $insightDraft,
                bookTitle: selectedBook?.displayTitle ?? "Reading Session"
            )
        }
    }

    private var insightButton: some View {
        Button {
            showingInsightSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(insightDraft.hasContent ? "pencil" : "crystalball")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(insightDraft.hasContent ? "Edit Insight" : "Insights")
                    .font(.system(size: 15, weight: .black, design: .rounded))

                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedBook == nil ? AnyShapeStyle(LColors.surface.subtle.opacity(0.6)) : AnyShapeStyle(LColors.accents.primary))
                    .shadow(color: selectedBook == nil ? .clear : LColors.gradientBlue.opacity(0.18), radius: 14, y: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selectedBook == nil ? AnyShapeStyle(LColors.glassBorder) : AnyShapeStyle(LColors.border.subtle), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedBook == nil)
        .opacity(selectedBook == nil ? 0.55 : 1)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Log Session")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                Text("Manually record a reading session")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button { saveSession() } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.accents.primary)
                    )
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Image("xmarkwavy")
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
                                    .strokeBorder(LColors.accents.special, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle().fill(LColors.border.nested).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Ebook Sync
    
    private func syncEbookToPhysical() {
        guard let book = selectedBook, book.ebookTotalPages > 0, book.totalPages > 0 else { return }
        let ebStart = Int(ebookStartPage) ?? 0
        let ebEnd = Int(ebookEndPage) ?? 0
        
        if ebStart > 0 {
            startPage = String(book.convertedPhysicalPage(from: ebStart))
        }
        if ebEnd > 0 {
            endPage = String(book.convertedPhysicalPage(from: ebEnd))
        }
    }

    private func toggleGoalSelection(_ goal: ReadingGoals) {
        if selectedGoalIDs.contains(goal.id) {
            selectedGoalIDs.remove(goal.id)
        } else {
            selectedGoalIDs.insert(goal.id)
        }
    }
    
    // MARK: - Ebook Conversion Preview
    
    @ViewBuilder
    private var ebookSessionConversionPreview: some View {
        let ebStart = Int(ebookStartPage) ?? 0
        let ebEnd = Int(ebookEndPage) ?? 0
        
        if ebEnd > 0 {
            if let book = selectedBook, book.ebookTotalPages > 0, book.totalPages > 0 {
                let physTotal = book.totalPages
                let physStart = book.convertedPhysicalPage(from: ebStart)
                let physEnd = book.convertedPhysicalPage(from: ebEnd)
                let physPages = max(physEnd - physStart, 0)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image("sparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.accents.secondary)
                        
                        Text("Ebook pg \(ebStart)\u{2013}\(ebEnd) \u{2248} Physical pg \(physStart)\u{2013}\(physEnd)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    
                    DottedGoalProgressBar(value: min(Double(physEnd) / Double(physTotal), 1.0))
                        .frame(height: 8)
                    
                    Text("\(physPages) physical pages \u{2022} \(physEnd) / \(physTotal) total")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LColors.gradientBlue.opacity(0.08)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LColors.gradientBlue.opacity(0.5),
                            lineWidth: 1
                        )
                )
            } else {
                Text("Selected book needs ebook total pages and total pages set to enable conversion.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }
        }
    }
    
    // MARK: - Save

    private func saveSession() {
        let mins = Int(manualMinutes) ?? 0
        let pages = calculatedPagesRead
        guard mins > 0 || pages > 0 else { dismiss(); return }
        let linkedGoals = selectedGoals

        let session = ReadingSession(
            linkedBookID: selectedBook?.id,
            linkedBookTitle: selectedBook?.title ?? "",
            linkedGoalID: linkedGoals.first?.id,
            linkedGoalTitle: linkedGoals.first?.displayTitle ?? "",
            linkedGoalIDs: linkedGoals.map(\.id),
            linkedGoalTitles: linkedGoals.map(\.displayTitle),
            durationMinutes: mins,
            pagesRead: pages,
            startPage: Int(startPage) ?? 0,
            endPage: enteredEndPage,
            notes: "",
            date: sessionDate
        )
        modelContext.insert(session)
        insertInsightIfNeeded(for: session)
        updateSelectedBookProgress(to: enteredEndPage, ebookPage: isEbookMode && bookCanConvert ? enteredEbookEndPage : nil)

        let stats = ReadingStats.fetchOrCreate(in: modelContext)

        for goal in linkedGoals {
            let previousValue = goal.currentValue
            let previousStreak = goal.currentStreak
            let previousBestStreak = goal.bestStreak
            let previousStatus = goal.status

            let increment: Double
            switch goal.type {
            case .minutes: increment = Double(mins)
            case .hours:   increment = Double(mins) / 60.0
            case .pages:   increment = Double(pages)
            default:       increment = 0
            }

            if increment > 0 {
                goal.incrementProgress(by: increment)
                insertGoalHistory(
                    for: goal,
                    eventType: .progressUpdated,
                    previousValue: previousValue,
                    newValue: goal.currentValue,
                    targetValue: goal.targetValue,
                    previousStreak: previousStreak,
                    newStreak: goal.currentStreak,
                    bestStreak: goal.bestStreak,
                    note: "Reading session added to goal progress."
                )
            } else if goal.type != .streak {
                insertGoalHistory(
                    for: goal,
                    eventType: .noteAdded,
                    previousValue: previousValue,
                    newValue: goal.currentValue,
                    targetValue: goal.targetValue,
                    previousStreak: previousStreak,
                    newStreak: goal.currentStreak,
                    bestStreak: goal.bestStreak,
                    note: sessionHistoryNote(minutes: mins, pages: pages)
                )
            }

            if goal.type == .streak {
                let shouldBridge: Bool = {
                    guard let last = goal.lastCompletedDate else { return false }
                    return stats.shouldBridgeStreakGap(from: last, to: sessionDate)
                }()
                goal.updateStreak(completedOn: sessionDate, bridgeBreakGap: shouldBridge)

                if previousStreak != goal.currentStreak || previousBestStreak != goal.bestStreak {
                    insertGoalHistory(
                        for: goal,
                        eventType: .streakUpdated,
                        previousValue: previousValue,
                        newValue: goal.currentValue,
                        targetValue: goal.targetValue,
                        previousStreak: previousStreak,
                        newStreak: goal.currentStreak,
                        bestStreak: goal.bestStreak,
                        note: "Reading streak updated from logged session."
                    )
                }
            }

            if previousStatus != .completed && goal.status == .completed {
                insertGoalHistory(
                    for: goal,
                    eventType: .completed,
                    previousValue: previousValue,
                    newValue: goal.currentValue,
                    targetValue: goal.targetValue,
                    previousStreak: previousStreak,
                    newStreak: goal.currentStreak,
                    bestStreak: goal.bestStreak,
                    note: "Goal completed from logged reading progress."
                )
            }
        }

        stats.totalMinutesRead += mins
        stats.totalPagesRead += pages
        stats.totalReadingSessions += 1
        if mins > stats.longestReadingSessionMinutes { stats.longestReadingSessionMinutes = mins }
        stats.minutesReadToday += mins
        stats.pagesReadToday += pages
        stats.minutesReadThisMonth += mins
        stats.pagesReadThisMonth += pages

        let cal = Calendar.current
        if let last = stats.lastReadingDate, cal.isDateInYesterday(last) || cal.isDateInToday(last) {
            if !cal.isDateInToday(last) { stats.currentReadingStreak += 1 }
        } else if let last = stats.lastReadingDate,
                  stats.readingBreakStreakValue > 0,
                  stats.shouldBridgeStreakGap(from: last, to: sessionDate) {
            stats.currentReadingStreak = stats.readingBreakStreakValue + 1
        } else {
            stats.currentReadingStreak = 1
        }
        stats.bestReadingStreak = max(stats.bestReadingStreak, stats.currentReadingStreak)
        stats.lastReadingDate = sessionDate
        stats.updatedAt = Date()

        ReadingXPService.awardReadingSession(session, stats: stats, modelContext: modelContext)

        dismiss()
    }

    private func insertInsightIfNeeded(for session: ReadingSession) {
        guard let selectedBook, insightDraft.hasContent else { return }

        let insight = ReadingInsight(
            book: selectedBook,
            session: session,
            whatHappened: insightDraft.whatHappened.trimmingCharacters(in: .whitespacesAndNewlines),
            whatStoodOut: insightDraft.whatStoodOut.trimmingCharacters(in: .whitespacesAndNewlines),
            howIFeel: insightDraft.howIFeel,
            moodTags: insightDraft.selectedMoods,
            feelingNote: insightDraft.feelingNote.trimmingCharacters(in: .whitespacesAndNewlines),
            predictions: insightDraft.predictions.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteMoment: insightDraft.notesAndThoughts.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(insight)
    }

    private func updateSelectedBookProgress(to endPage: Int, ebookPage: Int? = nil) {
        guard let selectedBook, endPage > 0 else { return }

        if let ebookPage, selectedBook.ebookTotalPages > 0, selectedBook.totalPages > 0 {
            selectedBook.updateProgress(ebookCurrentPage: ebookPage)
        } else if selectedBook.totalPages > 0 {
            selectedBook.currentPage = min(endPage, selectedBook.totalPages)
        } else {
            selectedBook.currentPage = endPage
        }

        selectedBook.lastUpdated = Date()
    }

    private func sessionHistoryNote(minutes: Int, pages: Int) -> String {
        var parts: [String] = []

        if minutes > 0 {
            parts.append("\(minutes) min")
        }

        if pages > 0 {
            parts.append("\(pages) pages")
        }

        let summary = parts.isEmpty ? "Reading session" : parts.joined(separator: " • ")
        return "Reading session logged: \(summary)."
    }

    private func insertGoalHistory(
        for goal: ReadingGoals,
        eventType: ReadingGoalHistoryType,
        previousValue: Double,
        newValue: Double,
        targetValue: Double,
        previousStreak: Int,
        newStreak: Int,
        bestStreak: Int,
        note: String
    ) {
        let history = ReadingGoalHistory(
            goalID: goal.id,
            goalTitleSnapshot: goal.displayTitle,
            eventType: eventType,
            previousValue: previousValue,
            newValue: newValue,
            targetValue: targetValue,
            previousStreak: previousStreak,
            newStreak: newStreak,
            bestStreak: bestStreak,
            note: note,
            createdAt: Date()
        )
        
        modelContext.insert(history)
        if eventType == .completed {
            ReadingXPService.awardGoalCompletion(goal: goal, modelContext: modelContext)
        }
        try? modelContext.save()
    }
}

// MARK: - Goal Check-In Sheet

struct GoalCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let goals: [ReadingGoals]
    let books: [Book]
    
    @State private var selectedGoal: ReadingGoals? = nil
    @State private var updatedProgress = ""
    @State private var selectedBook: Book? = nil
    @State private var checkInDate = Date()
    @State private var checkInTime = Date()
    
    private var availableBooks: [Book] {
        books.filter { !$0.isArchived }
    }
    
    private var currentProgress: String {
        guard let goal = selectedGoal else { return "—" }
        return goal.progressText
    }
    
    private var currentPercentage: String {
        guard let goal = selectedGoal else { return "—" }
        return "\(goal.progressPercentage)%"
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Pick a Goal
                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Goal")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                
                                if goals.isEmpty {
                                    Text("No active goals")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                } else {
                                    Menu {
                                        ForEach(goals) { goal in
                                            Button {
                                                selectedGoal = goal
                                                updatedProgress = String(format: "%.0f", goal.currentValue)
                                            } label: {
                                                Text(goal.displayTitle)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedGoal?.displayTitle ?? "Pick a Goal")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(selectedGoal != nil ? .white : LColors.textSecondary)
                                            
                                            Spacer()
                                            
                                            Image("chevdown")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(LColors.textSecondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(LColors.glassSurface2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Current Progress
                        if let goal = selectedGoal {
                            GlassCard(variant: .secondary) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Current Progress")
                                        .font(.system(size: 17, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                    
                                    DottedGoalProgressBar(value: goal.progressValue)
                                        .frame(height: 10)
                                    
                                    HStack {
                                        Text(currentProgress)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text(currentPercentage)
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(LColors.cardTitle)
                                    }
                                }
                            }
                        }
                        
                        // Updated Progress
                        GlassCard(variant: .tertiary) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Updated Progress")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                
                                LumeyTextField(title: "New Value", text: $updatedProgress)
                                    .keyboardType(.decimalPad)
                                
                                if let goal = selectedGoal {
                                    let newVal = Double(updatedProgress) ?? goal.currentValue
                                    let newProgress = goal.targetValue > 0 ? min(newVal / goal.targetValue, 1.0) : 0
                                    let newPercent = Int((newProgress * 100).rounded())
                                    
                                    HStack {
                                        Text("Will be")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text("\(newPercent)%")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(LColors.accents.special)
                                    }
                                }
                            }
                        }
                        
                        // Book (Optional)
                        GlassCard(variant: .elevated) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Book")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                
                                Text("Optional")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                
                                Menu {
                                    Button("None") {
                                        selectedBook = nil
                                    }
                                    
                                    ForEach(availableBooks) { book in
                                        Button {
                                            selectedBook = book
                                        } label: {
                                            Text("\(book.title) — \(book.author)")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedBook?.title ?? "Pick a Book")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(selectedBook != nil ? .white : LColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Image("chevdown")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                            .foregroundStyle(LColors.textSecondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(LColors.glassSurface2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Date & Time
                        GlassCard(variant: .subtle) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Date & Time")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                
                                DatePicker("Date", selection: $checkInDate, displayedComponents: .date)
                                    .tint(LColors.accent)
                                
                                DatePicker("Time", selection: $checkInTime, displayedComponents: .hourAndMinute)
                                    .tint(LColors.accent)
                            }
                        }
                        
                        // Complete Check-In
                        Button {
                            completeCheckIn()
                        } label: {
                            HStack(spacing: 8) {
                                Image("checkwavy")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                
                                Text("Complete Check-In")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(LGradients.header)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text("Goal Check-In")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            
            Spacer()
            
            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(LColors.glassSurface2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle().fill(LColors.border.nested).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }
    
    // MARK: - Complete Check-In
    
    private func completeCheckIn() {
        guard let goal = selectedGoal else { return }

        let previousValue = goal.currentValue
        let previousStreak = goal.currentStreak
        let previousBestStreak = goal.bestStreak
        let previousStatus = goal.status
        let newValue = Double(updatedProgress) ?? goal.currentValue

        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: checkInDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: checkInTime)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        let eventDate = calendar.date(from: combined) ?? Date()

        // Reset recurring goals if new period
        if goal.isRecurringGoal {
            goal.resetProgressIfNeededForCurrentPeriod()
        }
        let sessionProgressBaseline = goal.currentValue

        // Fetch stats early for break-bridge logic
        let stats = ReadingStats.fetchOrCreate(in: modelContext)

        // Use the model's built-in methods
        if goal.type == .streak {
            let shouldBridge: Bool = {
                guard let last = goal.lastCompletedDate else { return false }
                return stats.shouldBridgeStreakGap(from: last, to: eventDate)
            }()
            goal.updateStreak(completedOn: eventDate, bridgeBreakGap: shouldBridge)
        } else {
            goal.updateProgress(to: newValue)
        }

        let progressIncrease = max(goal.currentValue - sessionProgressBaseline, 0)

        let minutes: Int
        let pages: Int

        switch goal.type {
        case .minutes:
            minutes = Int(progressIncrease.rounded())
            pages = 0
        case .hours:
            minutes = Int((progressIncrease * 60).rounded())
            pages = 0
        case .pages:
            minutes = 0
            pages = Int(progressIncrease.rounded())
        default:
            minutes = 0
            pages = 0
        }

        // Determine event type
        let eventType: ReadingGoalHistoryType
        if previousStatus != .completed && goal.status == .completed {
            eventType = .completed
        } else if goal.isRecurringGoal && newValue >= goal.targetValue {
            eventType = .completed
        } else if goal.type == .streak && (previousStreak != goal.currentStreak || previousBestStreak != goal.bestStreak) {
            eventType = .streakUpdated
        } else {
            eventType = .progressUpdated
        }

        let history = ReadingGoalHistory(
            goalID: goal.id,
            goalTitleSnapshot: goal.displayTitle,
            eventType: eventType,
            previousValue: previousValue,
            newValue: goal.currentValue,
            targetValue: goal.targetValue,
            previousStreak: previousStreak,
            newStreak: goal.currentStreak,
            bestStreak: goal.bestStreak,
            note: selectedBook != nil ? "Check-in with \(selectedBook!.title)" : "Goal check-in",
            createdAt: eventDate
        )

        modelContext.insert(history)
        if eventType == .completed {
            ReadingXPService.awardGoalCompletion(goal: goal, occurredAt: eventDate, modelContext: modelContext)
        }

        let didUpdateStreak = goal.type == .streak && (
            previousStreak != goal.currentStreak || previousBestStreak != goal.bestStreak
        )
        var checkInSession: ReadingSession?
        if minutes > 0 || pages > 0 || didUpdateStreak {
            let session = ReadingSession(
                linkedBookID: selectedBook?.id,
                linkedBookTitle: selectedBook?.title ?? "",
                linkedGoalID: goal.id,
                linkedGoalTitle: goal.displayTitle,
                durationMinutes: minutes,
                pagesRead: pages,
                notes: "Goal Check-In",
                date: eventDate
            )
            if didUpdateStreak && session.pointsEarned == 0 {
                session.pointsEarned = 5
            }

            checkInSession = session
            modelContext.insert(session)
        }

        if minutes > 0 || pages > 0 || didUpdateStreak {
            stats.totalMinutesRead += minutes
            stats.totalPagesRead += pages
            stats.totalReadingSessions += 1

            if minutes > stats.longestReadingSessionMinutes {
                stats.longestReadingSessionMinutes = minutes
            }

            if calendar.isDateInToday(eventDate) {
                stats.minutesReadToday += minutes
                stats.pagesReadToday += pages
            }

            if calendar.isDate(eventDate, equalTo: Date(), toGranularity: .month) {
                stats.minutesReadThisMonth += minutes
                stats.pagesReadThisMonth += pages
            }

            if let last = stats.lastReadingDate, calendar.isDateInYesterday(last) || calendar.isDateInToday(last) {
                if !calendar.isDateInToday(last) {
                    stats.currentReadingStreak += 1
                }
            } else if let last = stats.lastReadingDate,
                      stats.readingBreakStreakValue > 0,
                      stats.shouldBridgeStreakGap(from: last, to: eventDate) {
                stats.currentReadingStreak = stats.readingBreakStreakValue + 1
            } else {
                stats.currentReadingStreak = 1
            }

            stats.bestReadingStreak = max(stats.bestReadingStreak, stats.currentReadingStreak)
            stats.lastReadingDate = eventDate
            stats.updatedAt = Date()

            if let checkInSession {
                if minutes > 0 || pages > 0 {
                    ReadingXPService.awardReadingSession(checkInSession, stats: stats, modelContext: modelContext)
                } else {
                    ReadingXPService.awardStreakCheckIn(checkInSession, stats: stats, modelContext: modelContext)
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
