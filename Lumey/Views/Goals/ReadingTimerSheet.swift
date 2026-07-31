//
//  ReadingTimerSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var timer = ReadingTimerManager.shared

    let goals: [ReadingGoals]
    let books: [Book]

    // Book title to attach to the session / live activity
    @State private var bookTitle = ""
    @State private var selectedBook: Book? = nil
    @State private var selectedGoal: ReadingGoals? = nil
    @State private var showingSaveSheet = false
    @State private var finishedMinutes = 0

    private var formattedElapsed: String {
        let m = timer.elapsedSeconds / 60
        let s = timer.elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var readingBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        // Book / goal picker
                        if !timer.isActive {
                            setupCard
                        }

                        // Timer face
                        timerCard

                        // Controls
                        controlCard

                        if timer.isActive {
                            infoCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 60)
                }
            }
        }
        .adaptivePresentation(isPresented: $showingSaveSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            SaveSessionSheet(
                goals: goals,
                books: books,
                prefillMinutes: finishedMinutes,
                prefillBookTitle: selectedBook?.title ?? bookTitle,
                prefillBook: selectedBook,
                prefillGoal: selectedGoal
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Setup Card

    private var setupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Before You Start")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if !readingBooks.isEmpty {
                    Menu {
                        Button("No Book") {
                            selectedBook = nil
                        }
                        
                        ForEach(readingBooks) { book in
                            Button(book.title) {
                                selectedBook = book
                                bookTitle = book.title
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
                }
                
                LumeyTextField(title: "Book or session title (optional)", text: $bookTitle)

                if !goals.filter({ $0.status == .active && !$0.isArchived }).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link to Goal")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(goals.filter { $0.status == .active && !$0.isArchived }) { goal in
                                    let isSelected = selectedGoal?.id == goal.id
                                    Button {
                                        selectedGoal = isSelected ? nil : goal
                                    } label: {
                                        Text(goal.displayTitle)
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule().fill(
                                                    isSelected
                                                    ? LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                    : LinearGradient(colors: [LColors.glassSurface2, LColors.glassSurface2], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timer Face

    private var timerCard: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Elapsed
                Text(formattedElapsed)
                    .font(.system(size: 72, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        timer.isPaused
                        ? LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .leading, endPoint: .trailing)
                    )
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.2), value: timer.elapsedSeconds)

                // Status pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusLabel)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(statusColor.opacity(0.12)))
            }
        }
    }

    // MARK: - Controls

    private var controlCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                if !timer.isActive {
                    // Start
                    primaryButton(label: "Start", icon: "play.fill") {
                        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        timer.start(bookTitle: selectedBook?.title ?? (title.isEmpty ? (selectedGoal?.displayTitle ?? "") : title))
                    }
                } else if timer.isRunning {
                    // Pause
                    primaryButton(label: "Pause", icon: "pause.fill") {
                        timer.pause()
                    }
                    // Stop
                    stopButton
                } else if timer.isPaused {
                    // Resume
                    primaryButton(label: "Resume", icon: "play.fill") {
                        timer.resume()
                    }
                    // Stop
                    stopButton
                }
            }
        }
    }

    private var stopButton: some View {
        Button {
            let result = timer.stop()
            finishedMinutes = result.minutes
            showingSaveSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Finish")
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundStyle(LColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [LColors.gradientBlue, LColors.gradientPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info card (while running)

    private var infoCard: some View {
        GlassCard {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LColors.gradientBlue)
                Text("A Live Activity is showing your timer on the Dynamic Island and lock screen. You can dismiss this sheet — the timer keeps running.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading Timer")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Dismiss anytime — timer lives in the Dynamic Island")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
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
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Helpers

    private var statusLabel: String {
        if timer.isRunning { return "Running" }
        if timer.isPaused { return "Paused" }
        return "Ready"
    }

    private var statusColor: Color {
        if timer.isRunning { return LColors.gradientBlue }
        if timer.isPaused { return LColors.textSecondary }
        return LColors.gradientPurple
    }
}

// MARK: - Save Session Sheet (post-timer)

/// Shown after finishing the timer. Pre-fills duration, lets user add pages/notes/date.
struct SaveSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let goals: [ReadingGoals]
    let books: [Book]
    let prefillMinutes: Int
    let prefillBookTitle: String
    let prefillBook: Book?
    let prefillGoal: ReadingGoals?

    @State private var selectedBook: Book? = nil
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var sessionNotes = ""
    @State private var sessionDate = Date()
    @State private var selectedGoal: ReadingGoals?

    private var readingBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    private var calculatedPagesRead: Int {
        let start = Int(startPage) ?? 0
        let end = Int(endPage) ?? 0
        return max(end - start, 0)
    }

    private var enteredEndPage: Int {
        Int(endPage) ?? 0
    }

    private var previewPoints: Int {
        ReadingSession.calculatePoints(minutes: prefillMinutes, pages: calculatedPagesRead)
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                saveHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary
                        GlassCard {
                            HStack(spacing: 14) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Session complete")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("\(prefillMinutes) minutes read")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                }
                                Spacer()
                            }
                        }

                        // Book link
                        if !readingBooks.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Book")
                                        .font(.system(size: 17, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    
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
                                }
                            }
                        }

                        // Pages
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pages")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                
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
                                        .foregroundStyle(.white)
                                }
                                .padding(.top, 2)
                            }
                        }

                        // Goal link
                        if !goals.filter({ $0.status == .active && !$0.isArchived }).isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Link to Goal")
                                        .font(.system(size: 17, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(goals.filter { $0.status == .active && !$0.isArchived }) { goal in
                                                let isSelected = selectedGoal?.id == goal.id
                                                Button {
                                                    selectedGoal = isSelected ? nil : goal
                                                } label: {
                                                    Text(goal.displayTitle)
                                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Capsule().fill(
                                                                isSelected
                                                                ? LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                                : LinearGradient(colors: [LColors.glassSurface2, LColors.glassSurface2], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                            )
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }

                        // Notes & date
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes & Date")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                LumeyTextEditor(title: "Session notes (optional)", text: $sessionNotes, minHeight: 80)
                                DatePicker("Date", selection: $sessionDate, displayedComponents: [.date, .hourAndMinute])
                                    .tint(LColors.accent)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        }

                        // Points
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Points Earned")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                    Text("+\(previewPoints) pts")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(LGradients.header)
                                }
                                Spacer()
                                Image("levelup")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(
                                        LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .task {
            // Pre-select the goal that was linked at timer start
            selectedGoal = prefillGoal
            selectedBook = prefillBook
        }
    }

    // MARK: - Header

    private var saveHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Save Session")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Add details and log your session")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button { saveSession() } label: {
                Text("Save")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LinearGradient(
                                colors: [LColors.gradientBlue, LColors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
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
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Save

    private func saveSession() {
        let pages = calculatedPagesRead
        guard prefillMinutes > 0 || pages > 0 else {
            dismiss()
            return
        }

        let session = ReadingSession(
            linkedBookID: selectedBook?.id,
            linkedBookTitle: selectedBook?.title ?? prefillBookTitle,
            linkedGoalID: selectedGoal?.id,
            linkedGoalTitle: selectedGoal?.displayTitle ?? "",
            durationMinutes: prefillMinutes,
            pagesRead: pages,
            notes: sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            date: sessionDate
        )
        modelContext.insert(session)
        updateSelectedBookProgress(to: enteredEndPage)

        // Fetch or create ReadingStats early so goal streak bridging can reference it
        let stats = ReadingStats.fetchOrCreate(in: modelContext)

        // Update linked goal
        if let goal = selectedGoal {
            let previousValue = goal.currentValue
            let previousStreak = goal.currentStreak
            let previousBestStreak = goal.bestStreak
            let previousStatus = goal.status
            
            let increment: Double
            switch goal.type {
            case .minutes: increment = Double(prefillMinutes)
            case .hours:   increment = Double(prefillMinutes) / 60.0
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
                    note: "Timer session added to goal progress."
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
                    note: sessionHistoryNote(minutes: prefillMinutes, pages: pages)
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
                        note: "Reading streak updated from timer session."
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
                    note: "Goal completed from timer session."
                )
            }
        }

        // Update ReadingStats
        stats.totalMinutesRead += prefillMinutes
        stats.totalPagesRead += pages
        stats.totalReadingSessions += 1
        if prefillMinutes > stats.longestReadingSessionMinutes {
            stats.longestReadingSessionMinutes = prefillMinutes
        }
        stats.minutesReadToday += prefillMinutes
        stats.pagesReadToday += pages
        stats.minutesReadThisMonth += prefillMinutes
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

    private func updateSelectedBookProgress(to endPage: Int) {
        guard let selectedBook, endPage > 0 else { return }

        if selectedBook.totalPages > 0 {
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
        return "Timer session logged: \(summary)."
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
