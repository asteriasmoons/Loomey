//
//  AddEditReadingGoalSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct AddEditReadingGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme
    
    let goal: ReadingGoals?
    
    @State private var title = ""
    @State private var goalDescription = ""
    @State private var goalReason = ""
    @State private var rewardIdea = ""
    
    @State private var type: ReadingGoalType = .books
    @State private var mode: ReadingGoalMode = .recurring
    @State private var cadence: ReadingGoalCadence = .yearly
    @State private var status: ReadingGoalStatus = .active
    @State private var priority: ReadingGoalPriority = .medium
    
    @State private var targetValue = ""
    @State private var currentValue = ""
    @State private var unitLabel = ""
    
    @State private var startDate = Date()
    @State private var targetDate = Date()
    @State private var hasTargetDate = false
    
    @State private var iconName = "achievement"
    @State private var isPinned = false
    
    @State private var linkedBookIDs: [UUID] = []
    @State private var linkedSeriesName: String = ""
    
    @State private var showingIconPicker = false
    @State private var isBookDropdownExpanded = false
    @State private var isSeriesDropdownExpanded = false
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    private var isEditing: Bool {
        goal != nil
    }

    private var startDateYearRange: ClosedRange<Int> {
        yearRange(containing: startDate)
    }

    private var targetDateYearRange: ClosedRange<Int> {
        yearRange(containing: targetDate)
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionCard(title: "Goal Identity", accentIndex: 0) {
                            LumeyTextField(title: "Title", text: $title, borderColor: theme.palette.primaryAction)
                            LumeyTextEditor(
                                title: "Description",
                                text: $goalDescription,
                                minHeight: 80,
                                borderColor: theme.palette.secondaryAccent
                            )
                            LumeyTextEditor(
                                title: "Why This Matters",
                                text: $goalReason,
                                minHeight: 80,
                                borderColor: theme.palette.indicators
                            )
                            LumeyTextField(title: "Reward Idea", text: $rewardIdea, borderColor: theme.palette.primaryAction)
                        }
                        
                        sectionCard(title: "Goal Type", accentIndex: 1) {
                            GoalSheetDropdown(
                                title: "Type",
                                selection: $type,
                                options: Array(ReadingGoalType.allCases),
                                tint: theme.palette.primaryAction,
                                label: { $0.rawValue }
                            )
                            GoalSheetDropdown(
                                title: "Mode",
                                selection: $mode,
                                options: Array(ReadingGoalMode.allCases),
                                tint: theme.palette.secondaryAccent,
                                label: { $0.rawValue }
                            )
                            
                            if mode == .recurring {
                                GoalSheetDropdown(
                                    title: "Cadence",
                                    selection: $cadence,
                                    options: Array(ReadingGoalCadence.allCases),
                                    tint: theme.palette.indicators,
                                    label: { $0.rawValue }
                                )
                            }
                            
                            GoalSheetDropdown(
                                title: "Status",
                                selection: $status,
                                options: Array(ReadingGoalStatus.allCases),
                                tint: theme.palette.primaryAction,
                                label: { $0.rawValue }
                            )
                            GoalSheetDropdown(
                                title: "Priority",
                                selection: $priority,
                                options: Array(ReadingGoalPriority.allCases),
                                tint: theme.palette.secondaryAccent,
                                label: { $0.rawValue }
                            )
                        }
                        
                        sectionCard(title: "Progress", accentIndex: 2) {
                            LumeyTextField(title: "Target Value", text: $targetValue, borderColor: theme.palette.primaryAction)
                                .keyboardType(.decimalPad)
                            
                            LumeyTextField(title: "Current Value", text: $currentValue, borderColor: theme.palette.secondaryAccent)
                                .keyboardType(.decimalPad)
                            
                            LumeyTextField(title: "Unit Label", text: $unitLabel, borderColor: theme.palette.indicators)
                        }
                        
                        sectionCard(title: "Dates", accentIndex: 3) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Start Date")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                LumeyDateDrumPicker(
                                    date: $startDate,
                                    solidTint: theme.palette.primaryAction,
                                    yearRange: startDateYearRange
                                )
                            }

                            LumeyIconToggle(
                                title: "Use Target Date",
                                iconName: "lovecalendar",
                                isOn: $hasTargetDate,
                                tint: theme.palette.secondaryAccent
                            )
                            
                            if hasTargetDate {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Target Date")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)

                                    LumeyDateDrumPicker(
                                        date: $targetDate,
                                        solidTint: theme.palette.indicators,
                                        yearRange: targetDateYearRange
                                    )
                                }
                            }
                        }
                        
                        sectionCard(title: "Display", accentIndex: 4) {
                            GoalIconPickerRow(iconName: $iconName, tint: theme.palette.primaryAction) {
                                showingIconPicker = true
                            }
                            
                            LumeyIconToggle(
                                title: "Pin as Main Goal",
                                iconName: "pin",
                                isOn: $isPinned,
                                tint: theme.palette.secondaryAccent
                            )
                        }
                        
                        sectionCard(title: "Related Content", accentIndex: 5) {
                            bookLinkingSection
                            seriesLinkingSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .task(id: goal?.id) {
            loadGoal()
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
                Text(isEditing ? "Edit Goal" : "Add Goal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                
                Text(isEditing ? "Update your reading goal" : "Create a new Lumey reading goal")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                saveGoal()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background {
                        BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            .clipShape(Capsule(style: .continuous))
                    }
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
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(theme.palette.raisedSurface)
                            .overlay {
                                BubblyIconMaterial(tint: theme.palette.primaryAction)
                                    .mask { Circle().strokeBorder(lineWidth: 1.2) }
                            }
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
    
    private func sectionCard<Content: View>(
        title: String,
        accentIndex: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let accent = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return GlassCard(variant: .featured, borderColor: accent) {
            VStack(alignment: .leading, spacing: 13) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                
                VStack(spacing: 12) {
                    content()
                }
            }
        }
    }

    private func yearRange(containing date: Date) -> ClosedRange<Int> {
        let currentYear = Calendar.current.component(.year, from: Date())
        let selectedYear = Calendar.current.component(.year, from: date)
        return min(currentYear - 20, selectedYear)...max(currentYear + 20, selectedYear)
    }
    
    // MARK: - Book & Series Linking
    
    private var availableBooks: [Book] {
        allBooks.filter { !$0.isArchived }
    }
    
    private var availableSeriesNames: [String] {
        let names = Set(allBooks.compactMap { name in
            let trimmed = name.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        })
        return names.sorted()
    }
    
    private var bookLinkingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Linked Books")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            if !linkedBookIDs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(linkedBookIDs.enumerated()), id: \.element) { index, bookID in
                        if let book = availableBooks.first(where: { $0.id == bookID }) {
                            let accent = theme.palette.rotation[index % theme.palette.rotation.count]

                            HStack(spacing: 10) {
                                Image("books")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(.white)
                                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                        .lineLimit(1)
                                    
                                    Text(book.author)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button {
                                    linkedBookIDs.removeAll { $0 == bookID }
                                } label: {
                                    Image("xmarkwavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(.white)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(theme.palette.raisedSurface))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background { BubblyTileSurface(tint: accent, cornerRadius: 14) }
                            .bubblyTileLift()
                        }
                    }
                }
            }
            
            let unlinkableBooks = availableBooks.filter { !linkedBookIDs.contains($0.id) }
            
            if !unlinkableBooks.isEmpty {
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isBookDropdownExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)

                            Text("Link a Book")
                                .font(.system(size: 13, weight: .black, design: .rounded))

                            Spacer()

                            Image(isBookDropdownExpanded ? "chevup" : "chevdown")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                        .bubblyTileLift()
                    }
                    .buttonStyle(.plain)

                    if isBookDropdownExpanded {
                        ScrollView(.vertical, showsIndicators: unlinkableBooks.count > 4) {
                            LazyVStack(spacing: 7) {
                                ForEach(unlinkableBooks) { book in
                                    Button {
                                        linkedBookIDs.append(book.id)
                                        if unlinkableBooks.count <= 1 {
                                            isBookDropdownExpanded = false
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image("books")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 14, height: 14)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(book.title)
                                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                                    .lineLimit(1)

                                                Text(book.author)
                                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                    .opacity(0.82)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            Image("addwavy")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 12, height: 12)
                                        }
                                        .foregroundStyle(.white)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 9)
                                        .background(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .fill(theme.palette.raisedSurface)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: CGFloat(min(unlinkableBooks.count, 4)) * 54)
                        .padding(10)
                        .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
                        .bubblyTileLift()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    private var seriesLinkingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Linked Series")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            if !linkedSeriesName.isEmpty {
                let accent = theme.palette.rotation[linkedBookIDs.count % theme.palette.rotation.count]

                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    
                    Text(linkedSeriesName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        linkedSeriesName = ""
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.white)
                            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(theme.palette.raisedSurface))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background { BubblyTileSurface(tint: accent, cornerRadius: 14) }
                .bubblyTileLift()
            }
            
            if !availableSeriesNames.isEmpty || !linkedSeriesName.isEmpty {
                VStack(spacing: 8) {
                    Button {
                        guard linkedSeriesName.isEmpty else { return }
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isSeriesDropdownExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)

                            Text("Link a Series")
                                .font(.system(size: 13, weight: .black, design: .rounded))

                            Spacer()

                            Image(isSeriesDropdownExpanded ? "chevup" : "chevdown")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background { BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 16) }
                        .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                    .disabled(!linkedSeriesName.isEmpty)
                    .opacity(linkedSeriesName.isEmpty ? 1 : 0.48)

                    if isSeriesDropdownExpanded && linkedSeriesName.isEmpty {
                        ScrollView(.vertical, showsIndicators: availableSeriesNames.count > 4) {
                            LazyVStack(spacing: 7) {
                                ForEach(availableSeriesNames, id: \.self) { name in
                                    Button {
                                        linkedSeriesName = name
                                        isSeriesDropdownExpanded = false
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image("books")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 14, height: 14)

                                            Text(name)
                                                .font(.system(size: 13, weight: .black, design: .rounded))
                                                .lineLimit(1)

                                            Spacer()

                                            Image("checkwavy")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 12, height: 12)
                                        }
                                        .foregroundStyle(.white)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .fill(theme.palette.raisedSurface)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: CGFloat(min(availableSeriesNames.count, 4)) * 48)
                        .padding(10)
                        .background { BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 18) }
                        .bubblyTileLift()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    private func loadGoal() {
        guard let goal else { return }
        
        title = goal.title
        goalDescription = goal.goalDescription
        goalReason = goal.goalReason
        rewardIdea = goal.rewardIdea
        
        type = goal.type
        mode = goal.mode
        cadence = goal.cadence
        status = goal.status
        priority = goal.priority
        
        targetValue = ReadingGoals.cleanNumber(goal.targetValue)
        currentValue = ReadingGoals.cleanNumber(goal.currentValue)
        unitLabel = goal.unitLabel
        
        startDate = goal.startDate
        
        if let date = goal.targetDate {
            targetDate = date
            hasTargetDate = true
        } else {
            hasTargetDate = false
        }
        
        iconName = goal.iconName
        isPinned = goal.isPinned
        linkedBookIDs = goal.linkedBookIDs
        linkedSeriesName = goal.targetSeriesName
    }
    
    private func saveGoal() {
        let targetGoal = goal ?? ReadingGoals()
        let wasNewGoal = goal == nil
        
        let previousValue = targetGoal.currentValue
        let previousStreak = targetGoal.currentStreak
        let previousBestStreak = targetGoal.bestStreak
        let previousStatus = targetGoal.status
        
        targetGoal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        targetGoal.goalDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        targetGoal.goalReason = goalReason.trimmingCharacters(in: .whitespacesAndNewlines)
        targetGoal.rewardIdea = rewardIdea.trimmingCharacters(in: .whitespacesAndNewlines)
        
        targetGoal.type = type
        targetGoal.mode = mode
        targetGoal.cadence = mode == .recurring ? cadence : .lifetime
        targetGoal.status = status
        targetGoal.priority = priority
        
        targetGoal.targetValue = Double(targetValue) ?? 0
        targetGoal.currentValue = Double(currentValue) ?? 0
        targetGoal.unitLabel = unitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        
        targetGoal.startDate = startDate
        targetGoal.targetDate = hasTargetDate ? targetDate : nil
        
        targetGoal.iconName = iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "achievement" : iconName
        targetGoal.isPinned = isPinned
        targetGoal.linkedBookIDs = linkedBookIDs
        targetGoal.targetSeriesName = linkedSeriesName.trimmingCharacters(in: .whitespacesAndNewlines)
        targetGoal.updatedAt = Date()
        
        if targetGoal.currentValue >= targetGoal.targetValue && targetGoal.targetValue > 0 {
            targetGoal.status = .completed
        }
        
        if wasNewGoal {
            modelContext.insert(targetGoal)
            
            insertGoalHistory(
                for: targetGoal,
                eventType: .created,
                previousValue: 0,
                newValue: targetGoal.currentValue,
                targetValue: targetGoal.targetValue,
                previousStreak: 0,
                newStreak: targetGoal.currentStreak,
                bestStreak: targetGoal.bestStreak,
                note: "Goal created."
            )
        } else {
            if previousValue != targetGoal.currentValue ||
                previousStreak != targetGoal.currentStreak ||
                previousBestStreak != targetGoal.bestStreak {
                
                insertGoalHistory(
                    for: targetGoal,
                    eventType: previousStreak != targetGoal.currentStreak ? .streakUpdated : .progressUpdated,
                    previousValue: previousValue,
                    newValue: targetGoal.currentValue,
                    targetValue: targetGoal.targetValue,
                    previousStreak: previousStreak,
                    newStreak: targetGoal.currentStreak,
                    bestStreak: targetGoal.bestStreak,
                    note: "Goal progress updated."
                )
            }
            
            if previousStatus != .completed && targetGoal.status == .completed {
                insertGoalHistory(
                    for: targetGoal,
                    eventType: .completed,
                    previousValue: previousValue,
                    newValue: targetGoal.currentValue,
                    targetValue: targetGoal.targetValue,
                    previousStreak: previousStreak,
                    newStreak: targetGoal.currentStreak,
                    bestStreak: targetGoal.bestStreak,
                    note: "Goal completed."
                )
            }
        }
        
        try? modelContext.save()
        dismiss()
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
    }
}

private struct GoalSheetDropdown<Value: Identifiable & Hashable>: View {
    @Environment(\.appTheme) private var theme

    let title: String
    @Binding var selection: Value
    let options: [Value]
    let tint: Color
    let label: (Value) -> String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(label(selection))
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .lineLimit(1)

                    Spacer()

                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                }
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.vertical, showsIndicators: options.count > 4) {
                    LazyVStack(spacing: 7) {
                        ForEach(options) { option in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    selection = option
                                    isExpanded = false
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(selection == option ? .white : theme.palette.raisedSurface)
                                        .frame(width: 12, height: 12)
                                        .overlay {
                                            Circle()
                                                .fill(selection == option ? tint : Color.clear)
                                                .frame(width: 4, height: 4)
                                        }

                                    Text(label(option))
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .lineLimit(1)

                                    Spacer()

                                    if selection == option {
                                        Image("checkwavy")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                    }
                                }
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selection == option ? theme.palette.raisedSurface : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: CGFloat(min(options.count, 4)) * 46)
                .padding(9)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 16) }
                .bubblyTileLift()
                .transition(.move(edge: .top).combined(with: .opacity))
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
