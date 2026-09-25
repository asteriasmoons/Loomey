//
//  BookInsightsView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BookInsightsView: View {
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @State private var isGeneratingReview = false
    @State private var errorMessage: String?
    @State private var selectedReview: BookReview?
    @State private var showingBetaInfo = false

    private var insights: [ReadingInsight] {
        (book.insights ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    betaPill
                    createReviewButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.86))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.red.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.red.opacity(0.20), lineWidth: 1)
                                    )
                            )
                    }

                    insightList
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(item: $selectedReview, useFullScreenCover: horizontalSizeClass == .regular) { review in
            BookReviewDetailSheet(review: review)
        }
    }

    private var topBar: some View {
        HStack {
            Text("Insights")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

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

    private var betaPill: some View {
        Button {
            showingBetaInfo = true
        } label: {
            HStack(spacing: 7) {
                Image("sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(.white)

                Text("BETA")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background {
                BubblyIconMaterial(tint: theme.palette.indicators)
                    .clipShape(Capsule(style: .continuous))
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(theme.palette.indicators, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingBetaInfo, arrowEdge: .top) {
            betaPopoverContent
                .presentationCompactAdaptation(.popover)
        }
    }

    private var betaPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(LColors.accents.contrast)

                Text("Review Generator")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
            }

            Text("This feature is still being developed. It uses your saved insights to draft a review, but it may not be exact or perfectly stable yet.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
        .background(LColors.bg)
    }

    private var createReviewButton: some View {
        Button {
            Task { await createReview() }
        } label: {
            HStack(spacing: 10) {
                Image(isGeneratingReview ? "sparkle" : "pagepencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(isGeneratingReview ? "Creating Review..." : "Create Review")
                    .font(.system(size: 15, weight: .black, design: .rounded))

                Spacer()
            }
            .foregroundStyle(theme.palette.textPrimary)
            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background { BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 18) }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .disabled(insights.isEmpty || isGeneratingReview)
        .opacity(insights.isEmpty ? 0.45 : 1)
    }

    private var insightList: some View {
        Group {
            if insights.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        insightCard(insight, number: insights.count - index)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 12) {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(LColors.accents.secondary)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

                Text("No insights yet")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("Log a reading session and tap Insights to capture one.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func insightCard(_ insight: ReadingInsight, number: Int) -> some View {
        NavigationLink {
            BookInsightDetailView(insight: insight, number: number)
        } label: {
            GlassCard(cornerRadius: 20, padding: 18, variant: .secondary) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image("pencil")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LColors.accents.special)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(LColors.iconContainer.primary))
                            .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Insight #\(number)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text(relativeDate(insight.dateCreated))
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        if let session = insight.session {
                            Text("Linked Session")
                            Text("\(session.durationMinutes) min")
                            Text("\(session.pagesRead) pages")
                        } else {
                            Text("Not linked")
                        }

                        Spacer()

                        Text("\(BookInsightContent.answerRows(for: insight).count) answers")
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.surface.nested)
                            .overlay(Capsule().strokeBorder(LColors.glassBorder, lineWidth: 1))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func createReview() async {
        guard !insights.isEmpty, !isGeneratingReview else { return }

        isGeneratingReview = true
        errorMessage = nil

        do {
            let response = try await ReadingInsightReviewService.shared.generateReview(
                book: book,
                insights: insights
            )
            let review = BookReview(
                title: response.title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: response.content.trimmingCharacters(in: .whitespacesAndNewlines),
                rating: book.rating,
                book: book
            )
            modelContext.insert(review)
            ReadingXPService.awardBookReview(review, modelContext: modelContext)
            try? modelContext.save()
            selectedReview = review
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingReview = false
    }
}

private struct BookInsightDetailView: View {
    let insight: ReadingInsight
    let number: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var expandedAnswerIDs: Set<String> = []

    private var answers: [InsightAnswerRow] {
        BookInsightContent.answerRows(for: insight)
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar

                    insightHeaderCard

                    if answers.isEmpty {
                        Text("No answers saved for this insight.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LColors.iconContainer.primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(LColors.border.subtle, lineWidth: 1)
                                    )
                            )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(answers) { answer in
                                collapsibleAnswerCard(answer)
                            }
                        }
                    }

                    detailsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Insight #\(number)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(relativeDate(insight.dateCreated))
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
                    .foregroundStyle(LColors.accents.secondary)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                    .frame(width: 42, height: 42)
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
    }

    private var insightHeaderCard: some View {
        GlassCard(cornerRadius: 20, padding: 18, variant: .tertiary) {
            HStack(alignment: .top, spacing: 12) {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.accents.special, lineWidth: 1))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Session Insight")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    if let session = insight.session {
                        HStack(spacing: 8) {
                            Text("Linked Session")
                            Text("\(session.durationMinutes) min")
                            Text("\(session.pagesRead) pages")
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                }

                Spacer()
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            GlassCard(variant: .primary) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if let session = insight.session {
                        frostedDetailTile(value: compactDateTime(session.date), label: "Linked Session", icon: "linkfilled")
                        frostedDetailTile(value: "\(session.durationMinutes) min", label: "Duration", icon: "clockfill")
                        frostedDetailTile(value: "\(session.pagesRead)", label: "Pages", icon: "lovedocument")
                    } else {
                        frostedDetailTile(value: "Not linked", label: "Linked Session", icon: "linkfilled")
                    }

                    frostedDetailTile(value: compactDateTime(insight.dateCreated), label: "Logged", icon: "starcal")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactDateTime(_ date: Date) -> String {
        "\(date.formatted(.dateTime.month(.defaultDigits).day().year(.twoDigits))) at \(date.formatted(.dateTime.hour().minute()))"
    }

    private func frostedDetailTile(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.accents.secondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(LColors.iconContainer.primary))
                .overlay(Circle().strokeBorder(LColors.border.nestedStrong, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LColors.border.nested, lineWidth: 1)
        )
    }

    private func collapsibleAnswerCard(_ answer: InsightAnswerRow) -> some View {
        let isExpanded = expandedAnswerIDs.contains(answer.id)
        let trimmed = answer.value.trimmingCharacters(in: .whitespacesAndNewlines)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                toggleAnswer(answer.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(answer.title)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(LColors.accents.special)
                }

                if isExpanded {
                    fullWidthDottedDivider

                    if answer.isMoodAnswer && !answer.moodTags.isEmpty {
                        moodTileGrid(answer.moodTags)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        if !answer.feelingNote.isEmpty {
                            Text(answer.feelingNote)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.text.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } else {
                        Text(trimmed)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LColors.glassSurface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                LColors.gradientBlue.opacity(0.72),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: LColors.gradientBlue.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var fullWidthDottedDivider: some View {
        GeometryReader { proxy in
            let dotCount = max(Int(proxy.size.width / 8), 1)

            HStack(spacing: 4) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                        .background(
                            Circle()
                                .fill(LColors.surface.nested)
                        )
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moodTileGrid(_ moods: [String]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(moods, id: \.self) { mood in
                moodMiniTile(mood)
            }
        }
    }

    private func moodMiniTile(_ mood: String) -> some View {
        HStack(spacing: 8) {
            Image("starfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(LColors.accents.primary)

            Text(mood)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(LColors.iconContainer.primary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }

    private func toggleAnswer(_ id: String) {
        if expandedAnswerIDs.contains(id) {
            expandedAnswerIDs.remove(id)
        } else {
            expandedAnswerIDs.insert(id)
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct InsightAnswerRow: Identifiable {
    let id: String
    let title: String
    let value: String
    var moodTags: [String] = []
    var feelingNote: String = ""

    var isMoodAnswer: Bool {
        title == "How I feel"
    }
}

private enum BookInsightContent {
    static func answerRows(for insight: ReadingInsight) -> [InsightAnswerRow] {
        [
            InsightAnswerRow(id: "\(insight.id.uuidString)-whatHappened", title: "What happened today?", value: insight.whatHappened),
            InsightAnswerRow(id: "\(insight.id.uuidString)-whatStoodOut", title: "What stood out?", value: insight.whatStoodOut),
            InsightAnswerRow(
                id: "\(insight.id.uuidString)-howIFeel",
                title: "How I feel",
                value: insight.howIFeel,
                moodTags: insight.displayMoodTags,
                feelingNote: insight.displayFeelingNote
            ),
            InsightAnswerRow(id: "\(insight.id.uuidString)-predictions", title: "Predictions / Questions", value: insight.predictions),
            InsightAnswerRow(id: "\(insight.id.uuidString)-notes", title: "Notes & Thoughts", value: insight.favoriteMoment),
            InsightAnswerRow(id: "\(insight.id.uuidString)-quote", title: "Favorite Quote", value: insight.favoriteQuote)
        ]
        .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !$0.moodTags.isEmpty }
    }
}

private extension View {
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
