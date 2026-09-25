//
//  GoalNotesTimelinePage.swift
//  Lumey
//

import SwiftData
import SwiftUI

// MARK: - Filter

private enum GoalNoteFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    var id: String {
        rawValue
    }
}

// MARK: - Timeline Page

struct GoalNotesTimelinePage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    let goal: ReadingGoals

    @Query(sort: \GoalNote.createdAt, order: .reverse)
    private var allGoalNotes: [GoalNote]

    @State private var activeFilter: GoalNoteFilter = .all
    @State private var showingAddNote = false
    @State private var selectedNote: GoalNote?
    @State private var notePendingDelete: GoalNote?
    @State private var newNoteText = ""

    private var goalNotes: [GoalNote] {
        allGoalNotes.filter { $0.goalID == goal.id }
    }

    private var filteredNotes: [GoalNote] {
        let calendar = Calendar.current
        let now = Date()

        switch activeFilter {
        case .all:
            return goalNotes
        case .today:
            return goalNotes.filter { calendar.isDateInToday($0.createdAt) }
        case .thisWeek:
            return goalNotes.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .weekOfYear) }
        case .thisMonth:
            return goalNotes.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }
        }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    filterPills

                    if filteredNotes.isEmpty {
                        emptyState
                    } else {
                        notesTimeline
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(isPresented: $showingAddNote, useFullScreenCover: horizontalSizeClass == .regular) {
            AddGoalNoteSheet(goal: goal, onSave: { text in
                let note = GoalNote(
                    goalID: goal.id,
                    noteText: text,
                    progressSnapshot: goal.progressValue,
                    completionCountSnapshot: goal.mode == .recurring ? Int(goal.currentValue) : 0
                )
                modelContext.insert(note)
                ReadingXPService.awardGoalNote(note, modelContext: modelContext)
                try? modelContext.save()
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $selectedNote, useFullScreenCover: horizontalSizeClass == .regular) { note in
            GoalNoteDetailSheet(note: note, goal: goal)
                .presentationDetents(note.noteText.count > 200 ? [.medium, .large] : [.medium])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Goal Notes")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                HStack(spacing: 6) {
                    Text("\(goalNotes.count) Notes")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    if let latest = goalNotes.first {
                        Text("•")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)

                        Text("Last Updated \(relativeDate(from: latest.createdAt))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Button {
                    showingAddNote = true
                } label: {
                    Image("addwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(theme.palette.secondaryAccent)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(theme.palette.raisedSurface)
                                .overlay {
                                    BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                        .mask { Circle().strokeBorder(lineWidth: 1.2) }
                                }
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
        }
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        HStack(spacing: 8) {
            ForEach(Array(GoalNoteFilter.allCases.enumerated()), id: \.element.id) { index, filter in
                let isActive = activeFilter == filter
                let tint = theme.palette.rotation[index % theme.palette.rotation.count]

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            BubblyIconMaterial(tint: tint)
                                .clipShape(Capsule(style: .continuous))
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(isActive ? 0.72 : 0.20), lineWidth: isActive ? 1.3 : 0.8)
                        }
                        .opacity(isActive ? 1 : 0.64)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Notes Timeline

    private var notesTimeline: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                let accent = theme.palette.rotation[index % theme.palette.rotation.count]
                Button {
                    selectedNote = note
                } label: {
                    GoalNoteTimelineRow(
                        note: note,
                        goal: goal,
                        accent: accent
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        deleteNote(note)
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image("trash")
                                .renderingMode(.template)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 14) {
                Image("lovepage")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(LColors.accents.contrast)

                Text(activeFilter == .all ? "No notes yet" : "No notes for \(activeFilter.rawValue.lowercased())")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text("Capture your thoughts, reactions, and progress as you work toward this goal.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showingAddNote = true
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)

                        Text("Add Note")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(LGradients.completion))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func relativeDate(from date: Date) -> String {
        let diff = Calendar.current.dateComponents([.day], from: date, to: Date())
        let days = diff.day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) Days Ago"
    }
    
    // MARK: - DELETE NOTE HELPER
    private func deleteNote(_ note: GoalNote) {
        if selectedNote?.id == note.id {
            selectedNote = nil
        }

        modelContext.delete(note)
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

// MARK: - Timeline Row

struct GoalNoteTimelineRow: View {
    let note: GoalNote
    let goal: ReadingGoals
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("•")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("\(note.progressPercentage)%")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Spacer()
            }

            Text(note.noteText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if goal.mode == .recurring && note.completionCountSnapshot > 0 {
                Text("Completed \(note.completionCountSnapshot) times")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LColors.glassSurface2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent, lineWidth: 1)
        )
    }
}

// MARK: - Add Note Sheet

struct AddGoalNoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let goal: ReadingGoals
    let onSave: (String) -> Void

    @State private var noteText = ""

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Note")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        Text("\(goal.progressPercentage)% Complete")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { dismiss(); return }
                        onSave(trimmed)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Capsule(style: .continuous).fill(LGradients.completion))
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(
                                LColors.accents.special
                            )
                            .frame(width: 46, height: 46)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LColors.accents.special,
                                                lineWidth: 1.35
                                            )
                                    )
                                    .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Note")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                LumeyTextEditor(title: "What's on your mind?", text: $noteText, minHeight: 120)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
    }
}

// MARK: - Note Detail Sheet

struct GoalNoteDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let note: GoalNote
    let goal: ReadingGoals

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.createdAt.formatted(date: .long, time: .shortened))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        HStack(spacing: 6) {
                            Text("\(note.progressPercentage)% Complete")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)

                            if goal.mode == .recurring && note.completionCountSnapshot > 0 {
                                Text("• Completed \(note.completionCountSnapshot) times")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(
                                LColors.accents.special
                            )
                            .frame(width: 46, height: 46)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LColors.accents.special,
                                                lineWidth: 1.35
                                            )
                                    )
                                    .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard(variant: .secondary) {
                            Text(note.noteText)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.text.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
    }
}
