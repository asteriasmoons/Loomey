//
//  ChallengeProofSummaryView.swift
//  Lumey
//

import SwiftUI

struct ChallengeProofSummaryView: View {
    @Environment(\.appTheme) private var theme

    let challenge: ReadingChallenge
    let selectedBookIDs: [UUID]
    let selectedSessionIDs: [UUID]
    let selectedReviewIDs: [UUID]
    let selectedReadingListIDs: [UUID]
    let books: [Book]
    let sessions: [ReadingSession]
    let reviews: [BookReview]
    let readingLists: [ReadingList]
    let accentIndex: Int

    private var linkedBooks: [Book] {
        books.filter { selectedBookIDs.contains($0.id) }
    }

    private var linkedSessions: [ReadingSession] {
        sessions.filter { selectedSessionIDs.contains($0.id) }
    }

    private var linkedReviews: [BookReview] {
        reviews.filter { selectedReviewIDs.contains($0.id) }
    }

    private var linkedReadingLists: [ReadingList] {
        readingLists.filter { selectedReadingListIDs.contains($0.id) }
    }

    private var hasAnyProof: Bool {
        !linkedBooks.isEmpty || !linkedSessions.isEmpty || !linkedReviews.isEmpty || !linkedReadingLists.isEmpty
    }

    var body: some View {
        if hasAnyProof {
            let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

            GlassCard(padding: 14, variant: .featured, borderColor: tint) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image("searchsparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)

                        Text("Proof Summary")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                    }

                    if !linkedBooks.isEmpty {
                        proofRow(
                            icon: "books",
                            label: "\(linkedBooks.count) book\(linkedBooks.count == 1 ? "" : "s") linked",
                            detail: linkedBooks.prefix(3).map(\.displayTitle).joined(separator: ", ")
                        )

                        // Genre info
                        let allGenres = linkedBooks.flatMap(\.genres)
                        if !allGenres.isEmpty {
                            let uniqueGenres = Array(Set(allGenres)).prefix(4)
                            proofRow(icon: "sparklybook", label: "Genres", detail: uniqueGenres.joined(separator: ", "))
                        }

                        // Total pages
                        let totalPages = linkedBooks.reduce(0) { $0 + $1.totalPages }
                        if totalPages > 0 {
                            proofRow(icon: "linedpages", label: "Total pages", detail: "\(totalPages)")
                        }

                        // Finished status
                        let finishedCount = linkedBooks.filter { $0.status == .finished }.count
                        if finishedCount > 0 {
                            proofRow(
                                icon: "checkwavy",
                                label: "Finished",
                                detail: "\(finishedCount) of \(linkedBooks.count)",
                                color: LColors.success
                            )
                        }

                        let ratedBooks = linkedBooks.filter { $0.rating > 0 }
                        if !ratedBooks.isEmpty {
                            proofRow(
                                icon: "starfill",
                                label: "Ratings",
                                detail: ratedBooks.prefix(3)
                                    .map { "\($0.displayTitle): \(formattedRating($0.rating))" }
                                    .joined(separator: ", "),
                                color: theme.palette.primaryAction
                            )
                        }
                    }

                    if !linkedSessions.isEmpty {
                        let totalMinutes = linkedSessions.reduce(0) { $0 + $1.durationMinutes }
                        let totalPages = linkedSessions.reduce(0) { $0 + $1.pagesRead }
                        proofRow(
                            icon: "clockfill",
                            label: "\(linkedSessions.count) session\(linkedSessions.count == 1 ? "" : "s")",
                            detail: "\(totalMinutes) min · \(totalPages) pages"
                        )
                    }

                    if !linkedReviews.isEmpty {
                        let totalWords = linkedReviews.reduce(0) { $0 + $1.content.split(separator: " ").count }
                        proofRow(
                            icon: "pagepencil",
                            label: "\(linkedReviews.count) review\(linkedReviews.count == 1 ? "" : "s")",
                            detail: "\(totalWords) words total"
                        )
                    }

                    if !linkedReadingLists.isEmpty {
                        let totalBooks = linkedReadingLists.reduce(0) { $0 + $1.bookCount }
                        proofRow(
                            icon: "bookstack",
                            label: "\(linkedReadingLists.count) list\(linkedReadingLists.count == 1 ? "" : "s")",
                            detail: "\(totalBooks) books across lists"
                        )
                    }
                }
            }
        }
    }

    // MARK: - Proof Row

    private func proofRow(
        icon: String,
        label: String,
        detail: String,
        color: Color? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .bubblyIconMaterial(tint: color ?? theme.palette.textSecondary)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()

            Text(detail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .lineLimit(1)
        }
    }

    private func formattedRating(_ rating: Double) -> String {
        if rating.rounded(.down) == rating {
            return "\(Int(rating)) stars"
        }

        return "\(String(format: "%.1f", rating)) stars"
    }
}
