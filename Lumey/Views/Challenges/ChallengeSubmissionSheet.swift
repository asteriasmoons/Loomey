//
//  ChallengeSubmissionSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ChallengeSubmissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    let challenge: ReadingChallenge
    let entry: ChallengeEntry

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var allSessions: [ReadingSession]

    @Query(sort: \BookReview.dateCreated, order: .reverse)
    private var allReviews: [BookReview]

    @Query(sort: \ReadingList.updatedAt, order: .reverse)
    private var allReadingLists: [ReadingList]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var allSubmissions: [ChallengeSubmission]

    @State private var selectedBookIDs: [UUID] = []
    @State private var selectedSessionIDs: [UUID] = []
    @State private var selectedReviewIDs: [UUID] = []
    @State private var selectedReadingListIDs: [UUID] = []
    @State private var submissionNote = ""
    @State private var isSubmitting = false
    @State private var showResult = false
    @State private var resultSubmission: ChallengeSubmission?
    @State private var bookPageIndex = 0
    @State private var visibleSessionCount = 6
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var photoErrorMessage: String?
    @State private var showPhotoError = false

    private let bookPageSize = 8

    private var currentUserID: String {
        appState.currentAppleUserId ?? ""
    }

    private var needsBooks: Bool {
        [.bookCompletion, .genre, .rating, .series, .author, .seasonalTheme, .bookLength].contains(challenge.validationType)
    }

    private var needsSessions: Bool {
        [.readingSession, .pageCount, .experience].contains(challenge.validationType)
    }

    private var needsReviews: Bool {
        challenge.validationType == .review
    }

    private var needsReadingLists: Bool {
        challenge.validationType == .collection
    }

    private var needsSubmissionNote: Bool {
        challenge.validationType == .experience || challenge.validationType == .seasonalTheme || challenge.requiresAIValidation
    }

    private var isSubmissionLocked: Bool {
        entry.status == .approved || allSubmissions.contains {
            $0.entryID == entry.id && $0.validationStatus == .approved
        }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        challengeInfoCard

                        if isSubmissionLocked {
                            approvedLockCard
                        }

                        if !isSubmissionLocked && needsBooks {
                            bookPickerSection
                        }

                        if !isSubmissionLocked && needsSessions {
                            sessionPickerSection
                        }

                        if !isSubmissionLocked && needsReviews {
                            reviewPickerSection
                        }

                        if !isSubmissionLocked && needsReadingLists {
                            readingListPickerSection
                        }

                        if !isSubmissionLocked && (needsSubmissionNote || challenge.requiresAIValidation) {
                            submissionNoteSection
                        }

                        if !isSubmissionLocked {
                            photoProofSection

                            proofSummarySection
                        }

                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }

            if isSubmitting {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(LColors.accent)
                        .scaleEffect(1.4)
                    Text("Validating...")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadPhoto(from: newItem)
            }
        }
        .alert("Photo Proof", isPresented: $showPhotoError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(photoErrorMessage ?? "Lumey could not use this photo.")
        }
        .adaptivePresentation(isPresented: $showResult, useFullScreenCover: horizontalSizeClass == .regular) {
            if let submission = resultSubmission {
                ChallengeSubmissionResultView(submission: submission, challenge: challenge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Submit Entry")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(challenge.title)
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

    // MARK: - Challenge Info

    private var challengeInfoCard: some View {
        GlassCard(padding: 14, variant: .tertiary) {
            HStack(spacing: 12) {
                Image(challenge.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.accents.contrast)

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.requirementText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(entry.displayDaysRemaining)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    private var approvedLockCard: some View {
        GlassCard(padding: 14, variant: .elevated) {
            HStack(alignment: .top, spacing: 10) {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Submission Approved")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(challenge.isRecurring ? "This cycle is locked to prevent accidental resubmission. You can join again when the next cycle begins." : "This challenge is locked to prevent accidental resubmission.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Book Picker

    private var bookPickerSection: some View {
        pickerSection(title: bookPickerTitle, icon: "flatbook") {
            let eligible = eligibleBookProofs
            let pageCount = max(1, (eligible.count + bookPageSize - 1) / bookPageSize)
            let clampedPageIndex = min(bookPageIndex, pageCount - 1)
            let startIndex = clampedPageIndex * bookPageSize
            let visibleBooks = Array(eligible.dropFirst(startIndex).prefix(bookPageSize))

            if selectedBookIDs.isEmpty && !eligible.isEmpty {
                Text(bookPickerPrompt)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            if eligible.isEmpty {
                Text(emptyBookPickerMessage)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(visibleBooks) { book in
                let isSelected = selectedBookIDs.contains(book.id)
                Button {
                    toggleBookSelection(book.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "flatbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(book.displayTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)
                            Text(bookProofDetail(for: book))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }

            if eligible.count > bookPageSize {
                bookPaginationControls(
                    pageIndex: clampedPageIndex,
                    pageCount: pageCount
                )
            }
        }
    }

    private var eligibleBookProofs: [Book] {
        let activeBooks = allBooks.filter { !$0.isArchived }

        guard challenge.validationType == .rating else {
            return activeBooks
        }

        if let requiredRating = challenge.requiredRating {
            return activeBooks.filter { $0.rating >= Double(requiredRating) }
        }

        return activeBooks.filter { $0.rating > 0 }
    }

    private var bookPickerTitle: String {
        challenge.validationType == .rating ? "Pick Rated Book" : "Link Books"
    }

    private var bookPickerPrompt: String {
        if challenge.validationType == .rating, let requiredRating = challenge.requiredRating {
            return "Pick a book rated \(requiredRating) stars"
        }

        return challenge.validationType == .rating ? "Pick rated books" : "Tap to select books"
    }

    private var emptyBookPickerMessage: String {
        if challenge.validationType == .rating, let requiredRating = challenge.requiredRating {
            return "No books rated \(requiredRating) stars found"
        }

        return challenge.validationType == .rating ? "No rated books found" : "No books found"
    }

    private func bookProofDetail(for book: Book) -> String {
        let author = book.author.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayAuthor = author.isEmpty ? "Unknown Author" : author

        guard challenge.validationType == .rating else {
            return "\(displayAuthor) · \(book.totalPages)p · \(book.status.rawValue)"
        }

        return "\(displayAuthor) · \(formattedRating(book.rating)) stars · \(book.status.rawValue)"
    }

    private func bookPaginationControls(pageIndex: Int, pageCount: Int) -> some View {
        HStack(spacing: 12) {
            Button {
                bookPageIndex = max(pageIndex - 1, 0)
            } label: {
                paginationIcon("chevleft", isEnabled: pageIndex > 0)
            }
            .buttonStyle(.plain)
            .disabled(pageIndex == 0)

            Spacer()

            Text("Page \(pageIndex + 1) of \(pageCount)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Spacer()

            Button {
                bookPageIndex = min(pageIndex + 1, pageCount - 1)
            } label: {
                paginationIcon("chevright", isEnabled: pageIndex < pageCount - 1)
            }
            .buttonStyle(.plain)
            .disabled(pageIndex >= pageCount - 1)
        }
        .padding(.top, 6)
    }

    private func paginationIcon(_ assetName: String, isEnabled: Bool) -> some View {
        Image(assetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 15)
            .foregroundStyle(isEnabled ? AnyShapeStyle(.white) : AnyShapeStyle(LColors.textSecondary.opacity(0.55)))
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(LColors.glassSurface2)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isEnabled ? AnyShapeStyle(LColors.accents.contrast) : AnyShapeStyle(LColors.glassBorder),
                                lineWidth: 1
                            )
                    )
            )
    }

    // MARK: - Session Picker

    private var sessionPickerSection: some View {
        pickerSection(title: "Link Reading Sessions", icon: "clockfill") {
            if allSessions.isEmpty {
                Text("No reading sessions found")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(allSessions.prefix(visibleSessionCount)) { session in
                let isSelected = selectedSessionIDs.contains(session.id)
                Button {
                    toggleSelection(id: session.id, in: &selectedSessionIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "clockfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)
                            Text("\(session.durationMinutes) min · \(session.pagesRead)p · \(session.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }

            if allSessions.count > visibleSessionCount {
                Button {
                    visibleSessionCount = min(visibleSessionCount + 6, allSessions.count)
                } label: {
                    Text("Load More Sessions")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.glassSurface2)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Review Picker

    private var reviewPickerSection: some View {
        pickerSection(title: "Link Reviews", icon: "pagepencil") {
            if allReviews.isEmpty {
                Text("No reviews found")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(allReviews.prefix(20)) { review in
                let isSelected = selectedReviewIDs.contains(review.id)
                Button {
                    toggleSelection(id: review.id, in: &selectedReviewIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "pagepencil")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(review.title.isEmpty ? "Untitled Review" : review.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)
                            let wordCount = review.content.split(separator: " ").count
                            Text("\(wordCount) words · \(review.dateCreated.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reading List Picker

    private var readingListPickerSection: some View {
        pickerSection(title: "Link Reading Lists", icon: "bookstack") {
            ForEach(allReadingLists.prefix(20)) { list in
                let isSelected = selectedReadingListIDs.contains(list.id)
                Button {
                    toggleSelection(id: list.id, in: &selectedReadingListIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "bookstack")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(list.displayTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)
                            Text("\(list.bookCount) books")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Submission Note

    private var submissionNoteSection: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Submission Note")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                if challenge.requiresAIValidation {
                    Text("Describe your experience — this helps us validate your submission.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                TextEditor(text: $submissionNote)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Photo Proof

    private var photoProofSection: some View {
        GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image("image")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.accents.secondary)

                    Text("Photo Proof")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Spacer()

                    Text("OPTIONAL")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                                )
                        )
                }

                Text("Attach a photo when you want Lumey to validate real-world proof for this challenge.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let previewPhotoData = selectedPhotoData,
                   let uiImage = UIImage(data: previewPhotoData) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 190)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                            )

                        HStack(spacing: 10) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                proofPhotoActionButton(icon: "image", title: "Change Photo")
                            }
                            .buttonStyle(.plain)

                            Button {
                                selectedPhotoItem = nil
                                selectedPhotoData = nil
                            } label: {
                                proofPhotoActionButton(icon: "trash", title: "Remove")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image("upload")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(LColors.accents.special)
                                .frame(width: 66, height: 66)
                                .background(
                                    Circle()
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LColors.accents.special, lineWidth: 1)
                                        )
                                )

                            VStack(spacing: 4) {
                                Text("Add Photo Proof")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)

                                Text("Use this when a photo should prove your challenge entry.")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LColors.surface.nested)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(LColors.border.nested, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func proofPhotoActionButton(icon: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LColors.accents.primary, lineWidth: 1)
                )
        )
    }

    // MARK: - Proof Summary

    private var proofSummarySection: some View {
        ChallengeProofSummaryView(
            challenge: challenge,
            selectedBookIDs: selectedBookIDs,
            selectedSessionIDs: selectedSessionIDs,
            selectedReviewIDs: selectedReviewIDs,
            selectedReadingListIDs: selectedReadingListIDs,
            books: allBooks,
            sessions: allSessions,
            reviews: allReviews,
            readingLists: allReadingLists
        )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            submitEntry()
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image("playwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(isSubmissionLocked ? "Already Approved" : "Submit for Validation")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(LGradients.blue)
            )
            .shadow(color: LColors.gradientPurple.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting || isSubmissionLocked)
        .opacity(isSubmitting || isSubmissionLocked ? 0.6 : 1)
    }

    // MARK: - Picker Section Builder

    private func pickerSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.accents.primary)

                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Toggle Selection

    private func toggleBookSelection(_ id: UUID) {
        if challenge.validationType == .rating, challenge.requiredBookCount == 1 {
            selectedBookIDs = selectedBookIDs.contains(id) ? [] : [id]
            return
        }

        toggleSelection(id: id, in: &selectedBookIDs)
    }

    private func toggleSelection(id: UUID, in array: inout [UUID]) {
        if let index = array.firstIndex(of: id) {
            array.remove(at: index)
        } else {
            array.append(id)
        }
    }

    private func formattedRating(_ rating: Double) -> String {
        if rating.rounded(.down) == rating {
            return "\(Int(rating))"
        }

        return String(format: "%.1f", rating)
    }

    // MARK: - Submit

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data
            }
        } catch {
            photoErrorMessage = "Lumey could not load this photo."
            showPhotoError = true
        }
    }

    private func submitEntry() {
        guard !isSubmissionLocked else { return }

        isSubmitting = true

        print("===== SUBMIT ENTRY START =====")
        print("Selected Book IDs:", selectedBookIDs)
        print("Selected Session IDs:", selectedSessionIDs)
        print("Selected Review IDs:", selectedReviewIDs)
        print("Selected Reading List IDs:", selectedReadingListIDs)
        print("Submission Note:", submissionNote)

        let selectedBooks = allBooks.filter { selectedBookIDs.contains($0.id) }
        let selectedSessions = allSessions.filter { selectedSessionIDs.contains($0.id) }

        let bookProofParts = selectedBooks.map { book in
            let base = "\(book.title) by \(book.author)"
            guard challenge.validationType == .rating, book.rating > 0 else {
                return base
            }

            return "\(base) • \(formattedRating(book.rating)) stars"
        }

        let sessionProofParts = selectedSessions.map { session in
            let title = session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle
            return "\(title) • \(session.durationMinutes) min • \(session.pagesRead) pages"
        }

        let proofParts = bookProofParts + sessionProofParts
        let proofSummary = proofParts.joined(separator: "\n")

        print("Selected Books Count:", selectedBooks.count)
        print("Selected Sessions Count:", selectedSessions.count)

        for session in selectedSessions {
            print("SESSION SELECTED:")
            print("ID:", session.id)
            print("Book:", session.linkedBookTitle)
            print("Minutes:", session.durationMinutes)
            print("Pages:", session.pagesRead)
            print("Date:", session.date)
        }

        print("Proof Summary Being Saved:", proofSummary)

        let photoData = selectedPhotoData

        Task { @MainActor in
            let uploadedPhotoURL: String

            do {
                if let photoData {
                    uploadedPhotoURL = try await ChallengeSocialService.shared.uploadSubmissionPhoto(imageData: photoData)
                } else {
                    uploadedPhotoURL = ""
                }
            } catch {
                isSubmitting = false
                photoErrorMessage = "Lumey could not upload this proof photo. Please try again."
                showPhotoError = true
                return
            }

            let submission = ChallengeSubmission(
                challengeID: challenge.id,
                entryID: entry.id,
                userID: currentUserID,
                username: appState.currentUser?.displayName ?? "Reader",
                challengeTitle: challenge.title,
                linkedBookIDs: selectedBookIDs,
                linkedSessionIDs: selectedSessionIDs,
                linkedReviewIDs: selectedReviewIDs,
                linkedReadingListIDs: selectedReadingListIDs,
                submissionNote: submissionNote,
                proofSummary: uploadedPhotoURL.isEmpty ? proofSummary : proofSummaryWithPhoto(proofSummary),
                photoURL: uploadedPhotoURL,
                cycleID: entry.cycleID,
                cycleStartDate: entry.startDate,
                cycleEndDate: entry.endDate
            )

            print("SUBMISSION CREATED:")
            print("Submission Linked Session IDs:", submission.linkedSessionIDs)
            print("Submission Proof Summary:", submission.proofSummary)
            print("Submission Photo URL:", submission.photoURL)
            print("===== SUBMIT ENTRY BEFORE SAVE =====")

            modelContext.insert(submission)
            print("===== SUBMISSION SAVED =====")
            try? modelContext.save()

            let manager = ChallengeManager(modelContext: modelContext)

            await manager.submitChallenge(
                challenge: challenge,
                entry: entry,
                submission: submission
            )

            isSubmitting = false
            resultSubmission = submission
            showResult = true
        }
    }

    private func proofSummaryWithPhoto(_ proofSummary: String) -> String {
        let trimmed = proofSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Photo proof attached."
        }

        return "\(trimmed)\nPhoto proof attached."
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
