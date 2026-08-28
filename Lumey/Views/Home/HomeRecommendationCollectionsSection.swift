//
//  HomeRecommendationCollectionsSection.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct HomeRecommendationCollectionsSection: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var recommendationCollections: [LumeyRecommendationCollection] = []
    @State private var isLoadingRecommendationCollections = false
    @State private var recommendationCollectionsError: String?
    @State private var selectedRecommendationCollection: LumeyRecommendationCollection?

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var stats: [ReadingStats]

    @Query(sort: \ReadingGoals.updatedAt, order: .reverse)
    private var goals: [ReadingGoals]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var authUsers: [AuthUser]

    @Query
    private var challengeEntries: [ChallengeEntry]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var challengeSubmissions: [ChallengeSubmission]

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var activeReadingGoals: [ReadingGoals] {
        goals.filter { $0.status == .active && !$0.isArchived }
    }

    private var readingStats: ReadingStats? {
        ReadingStats.preferredRecord(from: stats)
    }

    private var savedAuthUser: AuthUser? {
        authUsers.first
    }

    /// Changes every 3 days so shelves refresh on the same cadence as the backend cache TTL.
    private var refreshKey: String {
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        let epoch = Int(Date().timeIntervalSince1970 / threeDays)
        return "\(epoch)"
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            sectionContent
                .task(id: refreshKey) {
                    await fetchRecommendationCollections()
                }
                .fullScreenCover(item: $selectedRecommendationCollection) { collection in
                    collectionDetailSheet(for: collection)
                        .preferredColorScheme(.dark)
                }
        } else {
            sectionContent
                .task(id: refreshKey) {
                    await fetchRecommendationCollections()
                }
                .sheet(item: $selectedRecommendationCollection) { collection in
                    collectionDetailSheet(for: collection)
                        .presentationDetents([.large])
                        .preferredColorScheme(.dark)
                }
        }
    }

    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Discover Your Next Read")

            if isLoadingRecommendationCollections && recommendationCollections.isEmpty {
                recommendationLoadingCard
            } else if recommendationCollections.isEmpty {
                emptyCard(
                    title: recommendationCollectionsError ?? "Books You Might Love",
                    message: activeBooks.isEmpty
                    ? "Add or rate a few books to unlock shelves shaped around your taste."
                    : "Lumey is still learning this shelf. Try again after your latest reads sync."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(Array(recommendationCollections.enumerated()), id: \.element.id) { index, collection in
                            Button {
                                selectedRecommendationCollection = collection
                            } label: {
                                HomeRecommendationCollectionCard(
                                    collection: collection,
                                    coverAssetName: collectionCoverAssetName(for: index),
                                    variant: GlassCardRotation.variant(for: index),
                                    accentIndex: index
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -2)
            }
        }
    }

    private func collectionDetailSheet(for collection: LumeyRecommendationCollection) -> some View {
        HomeRecommendationCollectionDetailSheet(
            collection: collection,
            userID: appState.currentAppleUserId ?? savedAuthUser?.appleUserId ?? savedAuthUser?.serverId,
            readerContext: makeReaderContext(excludeBookKeys: excludeBookKeys),
            excludeBookKeys: excludeBookKeys
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
    }

    private func collectionCoverAssetName(for index: Int) -> String {
        "bcoll\(index % 5 + 1)"
    }

    private var recommendationLoadingCard: some View {
        GlassCard(variant: .featured) {
            HStack(spacing: 14) {
                LumeyDottedGradientSpinner(size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Books You Might Love")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.primary)

                    Text("Finding personalized shelves for your next read.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var excludeBookKeys: [String] {
        activeBooks.map {
            LumeyRecommendationCollectionContextBuilder.recommendationKey(
                title: $0.title,
                author: $0.author
            )
        }
    }

    private func makeReaderContext(
        excludeBookKeys: [String]
    ) -> LumeyRecommendationCollectionReaderContext {
        LumeyRecommendationCollectionContextBuilder.makeReaderContext(
            books: books,
            sessions: sessions,
            goals: goals,
            readingStats: readingStats,
            challengeEntries: challengeEntries,
            challengeSubmissions: challengeSubmissions,
            excludeBookKeys: excludeBookKeys
        )
    }

    private func emptyCard(title: String, message: String) -> some View {
        GlassCard(variant: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
            }
        }
    }

    @MainActor
    private func fetchRecommendationCollections() async {
        guard !activeBooks.isEmpty || !activeReadingGoals.isEmpty else {
            recommendationCollections = []
            recommendationCollectionsError = nil
            return
        }

        isLoadingRecommendationCollections = true
        recommendationCollectionsError = nil
        defer {
            isLoadingRecommendationCollections = false
        }

        do {
            let response = try await LumeyRecommendationCollectionsService.shared.fetchRecommendationCollectionSummaries(
                userID: appState.currentAppleUserId ?? savedAuthUser?.appleUserId ?? savedAuthUser?.serverId,
                readerContext: makeReaderContext(excludeBookKeys: excludeBookKeys),
                excludeBookKeys: excludeBookKeys
            )

            if !Task.isCancelled {
                recommendationCollections = response.collections
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                recommendationCollectionsError = "Recommendations are unavailable right now"
                print("Recommendation collections error:", error)
            }
        }
    }
}
