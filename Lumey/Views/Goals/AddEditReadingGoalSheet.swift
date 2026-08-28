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
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    private var isEditing: Bool {
        goal != nil
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionCard(title: "Goal Identity") {
                            LumeyTextField(title: "Title", text: $title)
                            LumeyTextEditor(title: "Description", text: $goalDescription, minHeight: 80)
                            LumeyTextEditor(title: "Why This Matters", text: $goalReason, minHeight: 80)
                            LumeyTextField(title: "Reward Idea", text: $rewardIdea)
                        }
                        
                        sectionCard(title: "Goal Type") {
                            LumeyEnumPicker(title: "Type", selection: $type, options: ReadingGoalType.allCases)
                            LumeyEnumPicker(title: "Mode", selection: $mode, options: ReadingGoalMode.allCases)
                            
                            if mode == .recurring {
                                LumeyEnumPicker(title: "Cadence", selection: $cadence, options: ReadingGoalCadence.allCases)
                            }
                            
                            LumeyEnumPicker(title: "Status", selection: $status, options: ReadingGoalStatus.allCases)
                            LumeyEnumPicker(title: "Priority", selection: $priority, options: ReadingGoalPriority.allCases)
                        }
                        
                        sectionCard(title: "Progress") {
                            LumeyTextField(title: "Target Value", text: $targetValue)
                                .keyboardType(.decimalPad)
                            
                            LumeyTextField(title: "Current Value", text: $currentValue)
                                .keyboardType(.decimalPad)
                            
                            LumeyTextField(title: "Unit Label", text: $unitLabel)
                        }
                        
                        sectionCard(title: "Dates") {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .tint(LColors.accent)
                            
                            Toggle("Use Target Date", isOn: $hasTargetDate)
                                .tint(LColors.accent)
                            
                            if hasTargetDate {
                                DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                                    .tint(LColors.accent)
                            }
                        }
                        
                        sectionCard(title: "Display") {
                            GoalIconPickerRow(iconName: $iconName) {
                                showingIconPicker = true
                            }
                            
                            Toggle("Pin as Main Goal", isOn: $isPinned)
                                .tint(LColors.accent)
                        }
                        
                        sectionCard(title: "Related Content") {
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
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LGradients.completion)
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
                    .foregroundStyle(LColors.accents.primary)
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
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard(variant: .featured) {
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
                    ForEach(linkedBookIDs, id: \.self) { bookID in
                        if let book = availableBooks.first(where: { $0.id == bookID }) {
                            HStack(spacing: 10) {
                                Image("books")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(LColors.accents.contrast)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                        .lineLimit(1)
                                    
                                    Text(book.author)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
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
                                        .foregroundStyle(LColors.textSecondary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(LColors.iconContainer.primary))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
                }
            }
            
            let unlinkableBooks = availableBooks.filter { !linkedBookIDs.contains($0.id) }
            
            if !unlinkableBooks.isEmpty {
                Menu {
                    ForEach(unlinkableBooks) { book in
                        Button {
                            linkedBookIDs.append(book.id)
                        } label: {
                            Text("\(book.title) — \(book.author)")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(LColors.accents.secondary)
                        
                        Text("Link a Book")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Spacer()
                        
                        Image("chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var seriesLinkingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Linked Series")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            if !linkedSeriesName.isEmpty {
                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.accents.special)
                    
                    Text(linkedSeriesName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
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
                            .foregroundStyle(LColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(LColors.iconContainer.primary))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LColors.surface.nested)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LColors.border.nested, lineWidth: 1)
                )
            }
            
            if linkedSeriesName.isEmpty && !availableSeriesNames.isEmpty {
                Menu {
                    ForEach(availableSeriesNames, id: \.self) { name in
                        Button(name) {
                            linkedSeriesName = name
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(LColors.accents.primary)
                        
                        Text("Link a Series")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Spacer()
                        
                        Image("chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                }
                .buttonStyle(.plain)
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
