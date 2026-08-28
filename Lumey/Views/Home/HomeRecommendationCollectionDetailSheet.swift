//
//  HomeRecommendationCollectionDetailSheet.swift
//  Lumey
//

import SwiftUI

struct HomeRecommendationCollectionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let collection: LumeyRecommendationCollection
    let userID: String?
    let readerContext: LumeyRecommendationCollectionReaderContext
    let excludeBookKeys: [String]

    @State private var loadedCollection: LumeyRecommendationCollection?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRecommendedBook: LumeyRecommendationCollectionBook?
    @State private var fetchAttempt = 0

    private var displayedCollection: LumeyRecommendationCollection {
        loadedCollection ?? collection
    }

    private var books: [LumeyRecommendationCollectionBook] {
        displayedCollection.books
    }

    var body: some View {
        let content = ZStack {
            LumeyBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        shelfIntro

                        if isLoading && books.isEmpty {
                            loadingCard
                        } else if let errorMessage, books.isEmpty {
                            retryCard(message: errorMessage)
                        } else if books.isEmpty {
                            emptyCard(
                                title: "No books yet",
                                message: "Lumey could not find enough verified books for this shelf."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(books) { book in
                                    recommendationRow(book)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
        .task(id: "\(collection.id)-\(fetchAttempt)") {
            await fetchCollection()
        }

        if horizontalSizeClass == .regular {
            content
                .fullScreenCover(item: $selectedRecommendedBook) { book in
                    RecommendedBookDetailSheet(book: book)
                        .preferredColorScheme(.dark)
                }
        } else {
            content
                .sheet(item: $selectedRecommendedBook) { book in
                    RecommendedBookDetailSheet(book: book)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                        .preferredColorScheme(.dark)
                }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                    .lineLimit(2)

                Text("\(collection.bookCount ?? 30) books")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                headerCircleIcon("xmarkwavy")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial.opacity(0.20))
    }

    private var shelfIntro: some View {
        GlassCard(cornerRadius: 16, padding: 12, variant: .tertiary) {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayedCollection.description)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(displayedCollection.reason)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        }
    }

    private var loadingCard: some View {
        GlassCard(variant: .featured) {
            HStack(spacing: 14) {
                LumeyDottedGradientSpinner(size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Finding this shelf")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Lumey is running recommendations for this shelf now.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func retryCard(message: String) -> some View {
        GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shelf unavailable")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Button {
                    errorMessage = nil
                    loadedCollection = nil
                    fetchAttempt += 1
                } label: {
                    Text("Try again")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.appBackground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LGradients.blue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func emptyCard(title: String, message: String) -> some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
    }

    private func recommendationRow(_ book: LumeyRecommendationCollectionBook) -> some View {
        Button {
            selectedRecommendedBook = book
        } label: {
            GlassCard(cornerRadius: 16, padding: 10, variant: .elevated) {
                HStack(alignment: .top, spacing: 12) {
                    bookCover(book.coverUrl)

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(book.title)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(2)

                            Text(book.author)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)
                        }

                        Text(book.summary)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                            .lineLimit(3)

                        labels(for: book)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            }
        }
        .buttonStyle(.plain)
    }

    private func bookCover(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackCover
                    }
                }
            } else {
                fallbackCover
            }
        }
        .frame(width: 52, height: 78)
        .background(LColors.border.nestedStrong)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }

    private var fallbackCover: some View {
        ZStack {
            LColors.gradientBlue.opacity(0.45)

            Image("bookstand")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(LColors.text.primary)
        }
    }

    private func headerCircleIcon(_ icon: String) -> some View {
        Image(icon)
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

    private func labels(for book: LumeyRecommendationCollectionBook) -> some View {
        let values = [
            book.strategyLabel,
            book.genres?.first,
            book.moods?.first,
            book.tropes?.first
        ].compactMap { value in
            value?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(values.prefix(4)), id: \.self) { value in
                    Text(value)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(LColors.border.nestedStrong, in: Capsule())
                }
            }
        }
    }

    @MainActor
    private func fetchCollection() async {
        guard loadedCollection == nil, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }

        do {
            let hydratedCollection = try await LumeyRecommendationCollectionsService.shared.fetchRecommendationCollection(
                id: collection.id,
                userID: userID,
                readerContext: readerContext,
                excludeBookKeys: excludeBookKeys
            )

            if !Task.isCancelled {
                loadedCollection = hydratedCollection
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = "Recommendations are busy right now. Try this shelf again in a moment."
                print("Recommendation shelf error:", collection.id, error)
            }
        }
    }
}
