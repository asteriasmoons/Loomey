//
//  ChallengeBookmarksPage.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengeBookmarksPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \ChallengeBookmark.createdAt, order: .reverse)
    private var bookmarks: [ChallengeBookmark]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var selectedChallenge: ReadingChallenge?

    let userID: String

    private var bookmarkedChallengeRows: [BookmarkedChallengeRow] {
        bookmarks
            .filter { $0.userID == userID && $0.isActive }
            .compactMap { bookmark in
                guard let challenge = challenges.first(where: { $0.id == bookmark.challengeID }) else {
                    return nil
                }
                return BookmarkedChallengeRow(bookmark: bookmark, challenge: challenge)
            }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if bookmarkedChallengeRows.isEmpty {
                            emptyState
                        } else {
                            ForEach(bookmarkedChallengeRows) { row in
                                Button {
                                    selectedChallenge = row.challenge
                                } label: {
                                    ChallengeCardView(
                                        challenge: row.challenge,
                                        entry: nil,
                                        badgeType: nil
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 110)
                }
            }
        }
        .adaptivePresentation(item: $selectedChallenge, useFullScreenCover: horizontalSizeClass == .regular) { challenge in
            ChallengeDetailView(challenge: challenge)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bookmarked Challenges")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("\(bookmarkedChallengeRows.count) saved challenge\(bookmarkedChallengeRows.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                headerIconButton("xmarkwavy")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 12) {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LColors.accents.primary)

                Text("No bookmarked challenges yet.")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text("Tap the starmark on a challenge to save it here.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private func headerIconButton(_ iconName: String) -> some View {
        Image(iconName)
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
                            .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                    )
                    .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
            )
    }
}

private struct BookmarkedChallengeRow: Identifiable {
    let bookmark: ChallengeBookmark
    let challenge: ReadingChallenge

    var id: UUID {
        bookmark.id
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
