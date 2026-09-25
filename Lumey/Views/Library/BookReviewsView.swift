//
//  BookReviewsView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BookReviewsView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @State private var showAddSheet = false
    @State private var editingReview: BookReview? = nil
    @State private var selectedReview: BookReview? = nil
    @State private var reviewToDelete: BookReview? = nil
    @State private var showDeleteAlert = false

    private var reviews: [BookReview] {
        (book.bookReviews ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    reviewList
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(isPresented: $showAddSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            BookReviewEditorSheet(book: book, review: nil)
        }
        .adaptivePresentation(item: $editingReview, useFullScreenCover: horizontalSizeClass == .regular) { review in
            BookReviewEditorSheet(book: book, review: review)
        }
        .adaptivePresentation(item: $selectedReview, useFullScreenCover: horizontalSizeClass == .regular) { review in
            BookReviewDetailSheet(review: review)
        }
        .lumeyAlertConfirm(
            isPresented: $showDeleteAlert,
            title: "Delete Review",
            message: "Are you sure you want to delete this review?"
        ) {
            if let review = reviewToDelete {
                modelContext.delete(review)
                reviewToDelete = nil
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Reviews")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Image("addwavy")
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

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.contrast)
                    .bubblyIconMaterial(tint: theme.palette.indicators)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var reviewList: some View {
        Group {
            if reviews.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                        reviewCard(
                            review,
                            tint: theme.palette.rotation[index % theme.palette.rotation.count]
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 12) {
                Image("starcircle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LGradients.blue)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

                Text("No reviews yet")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("Tap + to write your first review")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func reviewCard(_ review: BookReview, tint: Color) -> some View {
        GlassCard(cornerRadius: 20, padding: 0, variant: .tertiary, borderColor: tint) {
            ZStack {
                BubblyLightWash(colors: [tint], intensity: 0.34, fadeEnd: 0.82)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if !review.title.isEmpty {
                        Text(review.title)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            editingReview = review
                        } label: {
                            Image("pencil")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(tint)
                                .bubblyIconMaterial(tint: tint)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(tint, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            reviewToDelete = review
                            showDeleteAlert = true
                        } label: {
                            Image("trash")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(tint)
                                .bubblyIconMaterial(tint: tint)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(tint, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if review.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image("starfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(
                                    star <= Int(review.rating)
                                    ? LColors.accents.secondary
                                    : LColors.border.nestedStrong
                                )
                                .bubblyIconMaterial(
                                    tint: star <= Int(review.rating)
                                    ? theme.palette.secondaryAccent
                                    : LColors.border.nestedStrong
                                )
                        }
                    }
                }

                Text(review.content)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(review.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                }
                .padding(18)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            selectedReview = review
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

// MARK: - Review Detail Sheet

struct BookReviewDetailSheet: View {
    let review: BookReview
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Review")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LGradients.blue)
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    GlassCard(variant: .primary) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !review.title.isEmpty {
                                Text(review.title)
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                            }

                            if review.rating > 0 {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image("starfill")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(
                                                star <= Int(review.rating)
                                                ? LColors.accents.secondary
                                                : LColors.border.nestedStrong
                                            )
                                            .bubblyIconMaterial(
                                                tint: star <= Int(review.rating)
                                                ? theme.palette.secondaryAccent
                                                : LColors.border.nestedStrong
                                            )
                                    }
                                }
                            }

                            Text(review.content)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.text.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(review.dateCreated.formatted(date: .long, time: .shortened))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Review Editor Sheet

struct BookReviewEditorSheet: View {
    let book: Book
    let review: BookReview?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @State private var title = ""
    @State private var content = ""
    @State private var rating: Double = 0

    private var isEditing: Bool { review != nil }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(isEditing ? "Edit Review" : "New Review")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(theme.palette.secondaryAccent)
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title (optional)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                TextField("", text: $title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LColors.surface.nested)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                                            )
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Rating")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            rating = rating == Double(star) ? 0 : Double(star)
                                        } label: {
                                            Image("starfill")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(
                                                    star <= Int(rating)
                                                    ? LColors.accents.secondary
                                                    : LColors.border.nestedStrong
                                                )
                                                .bubblyIconMaterial(
                                                    tint: star <= Int(rating)
                                                    ? theme.palette.secondaryAccent
                                                    : LColors.border.nestedStrong
                                                )
                                                .frame(width: 28, height: 28)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Review")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                TextEditor(text: $content)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 150)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LColors.surface.nested)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                                            )
                                    )
                            }
                    }

                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Add Review")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                    .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let review {
                title = review.title
                content = review.content
                rating = review.rating
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        if let review {
            review.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            review.content = trimmedContent
            review.rating = rating
            review.lastUpdated = Date()
        } else {
            let newReview = BookReview(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: trimmedContent,
                rating: rating,
                book: book
            )
            modelContext.insert(newReview)
            ReadingXPService.awardBookReview(newReview, modelContext: modelContext)
        }

        dismiss()
    }
}
