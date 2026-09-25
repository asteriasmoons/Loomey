//
//  BookRecommendationsSheet.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct BookRecommendationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @State private var searchText: String = ""
    @State private var recommendations: [LumeyBookRecommendation] = []
    @State private var recommendationMeta: LumeyBookRecommendationsMeta?
    @State private var selectedStrategy: String = "all"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addedRecommendationKeys: Set<String> = []
    @State private var expandedRecommendationKeys: Set<String> = []
    @State private var bookToEditAfterAdd: Book?
    @State private var showEditBookAfterAdd = false
    @State private var fetchedSummaries: [String: String] = [:]
    @State private var loadingSummaryKeys: Set<String> = []
    @State private var summaryErrorKeys: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        searchCard

                        if isLoading {
                            loadingState
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(LColors.text.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                        } else if recommendations.isEmpty {
                            emptyState
                        } else {
                            recommendationsList
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .adaptivePresentation(isPresented: $showEditBookAfterAdd, useFullScreenCover: horizontalSizeClass == .regular) {
                if let bookToEditAfterAdd {
                    AddEditBookSheet(book: bookToEditAfterAdd) { _ in }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                }
            }
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer(minLength: 0)

            LumeyDottedGradientSpinner(size: 62, useBubblyPalette: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .center)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recommendations")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Search by a book, author, genre, trope, theme, mood, or the kind of reading experience you want next.")
                    .font(.callout)
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

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
                    .background {
                        Circle()
                            .fill(theme.palette.background)
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)

                        BubblyIconMaterial(tint: theme.palette.primaryAction)
                            .mask { Circle().strokeBorder(lineWidth: 1.2) }
                    }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var searchCard: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Fourth Wing, cozy mystery, found family...", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                    }

                Text("Lumey will blend close matches, safer picks, hidden gems, recent releases, backlist, and adjacent reads.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.leading)

                Button {
                    Task {
                        await fetchRecommendations()
                    }
                } label: {
                    Text(isLoading ? "Finding Books..." : "Find Recommendations")
                        .font(.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 18)
                        }
                        .bubblyTileLift()
                }
                .disabled(isLoading || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundStyle(theme.palette.indicators)
                .bubblyIconMaterial(tint: theme.palette.indicators)

            Text("No recommendations yet")
                .font(.headline)

            Text("Search for a favorite book, a genre, a mood, a trope, or a plain-language reading craving.")
                .font(.callout)
                .foregroundStyle(LColors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var recommendationsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            recommendationSummary
            strategyFilter

            if selectedStrategy == "all" {
                ForEach(strategySections, id: \.strategy) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(strategyDisplayName(section.strategy))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .padding(.top, 4)

                        ForEach(Array(section.books.enumerated()), id: \.element.id) { index, book in
                            recommendationCard(
                                book,
                                accent: theme.palette.rotation[index % theme.palette.rotation.count]
                            )
                        }
                    }
                }
            } else {
                ForEach(Array(filteredRecommendations.enumerated()), id: \.element.id) { index, book in
                    recommendationCard(
                        book,
                        accent: theme.palette.rotation[index % theme.palette.rotation.count]
                    )
                }
            }
        }
    }

    private var recommendationSummary: some View {
        HStack(spacing: 8) {
            metadataPill("\(recommendations.count) books", tint: theme.palette.rotation[0])

            if let recommendationMeta {
                metadataPill(
                    requestTypeLabel(recommendationMeta.requestType),
                    tint: theme.palette.rotation[1]
                )

                if recommendationMeta.seedResolved {
                    metadataPill("Seed matched", tint: theme.palette.rotation[2])
                }
            }
        }
    }

    private var strategyFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                strategyFilterButton(
                    title: "All",
                    strategy: "all",
                    tint: theme.palette.rotation[0]
                )

                ForEach(Array(availableStrategies.enumerated()), id: \.element) { index, strategy in
                    strategyFilterButton(
                        title: strategyDisplayName(strategy),
                        strategy: strategy,
                        tint: theme.palette.rotation[(index + 1) % theme.palette.rotation.count]
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var availableStrategies: [String] {
        recommendations
            .compactMap(\.strategy)
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, strategy in
                if !result.contains(strategy) {
                    result.append(strategy)
                }
            }
    }

    private var filteredRecommendations: [LumeyBookRecommendation] {
        guard selectedStrategy != "all" else { return recommendations }
        return recommendations.filter { $0.strategy == selectedStrategy }
    }

    private var strategySections: [(strategy: String, books: [LumeyBookRecommendation])] {
        if availableStrategies.isEmpty {
            return [(strategy: "recommended", books: recommendations)]
        }

        var sections: [(strategy: String, books: [LumeyBookRecommendation])] = []

        for strategy in availableStrategies {
            let books = recommendations.filter { $0.strategy == strategy }
            if !books.isEmpty {
                sections.append((strategy: strategy, books: books))
            }
        }

        return sections
    }

    private func strategyFilterButton(title: String, strategy: String, tint: Color) -> some View {
        let isSelected = selectedStrategy == strategy

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedStrategy = strategy
            }
        } label: {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.palette.textPrimary)
                .bubblyIconMaterial(tint: theme.palette.textPrimary)
                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
                .overlay {
                    if isSelected {
                        Capsule().stroke(theme.palette.textPrimary.opacity(0.72), lineWidth: 1.25)
                    }
                }
                .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }

    private func recommendationCard(
        _ book: LumeyBookRecommendation,
        accent: Color
    ) -> some View {
        let isExpanded = isRecommendationExpanded(book)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                coverView(book.coverUrl)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(LColors.text.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            metadataPill(
                                strategyDisplayName(book.strategyLabel ?? book.strategy),
                                tint: theme.palette.rotation[0]
                            )

                            if let matchScore = book.matchScore {
                                metadataPill("Match \(matchScore)", tint: theme.palette.rotation[1])
                            }

                            if let releaseYear = book.releaseYear {
                                metadataPill("\(releaseYear)", tint: theme.palette.rotation[2])
                            }

                            if let pages = book.pages {
                                metadataPill("\(pages) pages", tint: theme.palette.rotation[0])
                            }

                            if let rating = book.rating {
                                metadataPill(String(format: "%.1f", rating), tint: theme.palette.rotation[1])
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                Button {
                    toggleRecommendationExpanded(book)
                } label: {
                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(accent)
                        .bubblyIconMaterial(tint: accent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: accent)
                                .mask { Circle().strokeBorder(lineWidth: 1.2) }
                        }
                }
                .buttonStyle(.plain)
            }

            summaryOrGetDetails(for: book, isExpanded: isExpanded, tint: accent)

            if isExpanded, let rationale = book.rationale, !rationale.isEmpty {
                Text(rationale)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(LColors.text.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            let readerLabels = recommendationLabels(for: book)
            if !readerLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(readerLabels.prefix(8).enumerated()), id: \.element) { index, label in
                            metadataPill(
                                label,
                                tint: theme.palette.rotation[index % theme.palette.rotation.count]
                            )
                        }
                    }
                }
            }

            addToLibraryButton(for: book, tint: accent)
        }
        .padding(14)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func summaryOrGetDetails(
        for book: LumeyBookRecommendation,
        isExpanded: Bool,
        tint: Color
    ) -> some View {
        let key = recommendationKey(book)
        let trimmed = book.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let effective = fetchedSummaries[key] ?? (trimmed.isEmpty ? "" : book.summary)

        if !effective.isEmpty {
            Text(effective)
                .font(.callout)
                .foregroundStyle(LColors.text.secondary)
                .lineLimit(isExpanded ? nil : 5)
        } else if loadingSummaryKeys.contains(key) {
            getDetailsLabel("Getting details\u{2026}", loading: true, tint: tint)
        } else {
            Button {
                Task { await getBookSummary(for: book) }
            } label: {
                getDetailsLabel(
                    summaryErrorKeys.contains(key) ? "Try Again" : "Get Details",
                    loading: false,
                    tint: tint
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func getDetailsLabel(_ text: String, loading: Bool, tint: Color) -> some View {
        HStack(spacing: 8) {
            if loading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            }
            Text(text)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
        .bubblyTileLift()
    }

    @MainActor
    private func getBookSummary(for book: LumeyBookRecommendation) async {
        let key = recommendationKey(book)
        guard fetchedSummaries[key] == nil, !loadingSummaryKeys.contains(key) else { return }

        loadingSummaryKeys.insert(key)
        summaryErrorKeys.remove(key)

        do {
            let summary = try await RegularRecBookSummaryService.shared.fetchSummary(for: book)
            fetchedSummaries[key] = summary
        } catch {
            summaryErrorKeys.insert(key)
        }

        loadingSummaryKeys.remove(key)
    }

    private func isRecommendationExpanded(_ recommendation: LumeyBookRecommendation) -> Bool {
        expandedRecommendationKeys.contains(recommendationKey(recommendation))
    }

    private func toggleRecommendationExpanded(_ recommendation: LumeyBookRecommendation) {
        let key = recommendationKey(recommendation)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            if expandedRecommendationKeys.contains(key) {
                expandedRecommendationKeys.remove(key)
            } else {
                expandedRecommendationKeys.insert(key)
            }
        }
    }

    private func addToLibraryButton(
        for recommendation: LumeyBookRecommendation,
        tint: Color
    ) -> some View {
        let alreadyAdded = isRecommendationInLibrary(recommendation)

        return Button {
            addRecommendationToLibrary(recommendation)
        } label: {
            HStack(spacing: 8) {
                Image(alreadyAdded ? "checkwavy" : "addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text(alreadyAdded ? "Added to Library" : "Add to Library")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(alreadyAdded ? LColors.textSecondary : theme.palette.textPrimary)
            .shadow(
                color: alreadyAdded ? .clear : theme.palette.background.opacity(0.55),
                radius: 1,
                y: 2
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                if alreadyAdded {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LColors.border.nestedStrong)
                } else {
                    BubblyTileSurface(tint: tint, cornerRadius: 16)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(alreadyAdded ? 0.14 : 0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded)
    }

    private func addRecommendationToLibrary(_ recommendation: LumeyBookRecommendation) {
        guard !isRecommendationInLibrary(recommendation) else { return }

        let bookTitle = recommendation.title
        let bookAuthor = recommendation.author
        let bookSummary = recommendation.summary
        let bookRating = recommendation.rating ?? 0
        let bookTotalPages = recommendation.pages ?? 0
        let bookCoverURL = recommendation.coverUrl ?? ""
        let bookTags = recommendation.tags ?? []
        let bookGenres = recommendation.genres ?? []
        let bookMoods = recommendation.moods ?? []
        let bookTropes = recommendation.tropes ?? []
        let bookTopics = recommendation.themes ?? []

        let bookPublicationYear: String
        if let releaseYear = recommendation.releaseYear {
            bookPublicationYear = String(releaseYear)
        } else {
            bookPublicationYear = ""
        }

        let bookNotes: String
        let recommendationDetails = [
            recommendation.strategyLabel ?? strategyDisplayName(recommendation.strategy),
            recommendation.rationale
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")

        if let source = recommendation.source, !source.isEmpty {
            bookNotes = recommendationDetails.isEmpty
                ? "Recommended by Lumey. Source: \(source)."
                : "Recommended by Lumey. \(recommendationDetails). Source: \(source)."
        } else {
            bookNotes = recommendationDetails.isEmpty
                ? "Recommended by Lumey."
                : "Recommended by Lumey. \(recommendationDetails)."
        }

        let bookStatus = BookStatus.toBeRead
        let bookFormat = BookFormat.other
        let bookOwnership = BookOwnership.wishlist

        let newBook = Book(
            title: bookTitle,
            author: bookAuthor,
            publicationYear: bookPublicationYear,
            summary: bookSummary,
            rating: bookRating,
            status: bookStatus,
            format: bookFormat,
            ownership: bookOwnership,
            totalPages: bookTotalPages,
            notes: bookNotes,
            genres: bookGenres,
            moods: bookMoods,
            tags: bookTags,
            tropes: bookTropes,
            topics: bookTopics,
            coverURL: bookCoverURL
        )

        modelContext.insert(newBook)
        addedRecommendationKeys.insert(recommendationKey(recommendation))
        bookToEditAfterAdd = newBook

        do {
            try modelContext.save()
            showEditBookAfterAdd = true
        } catch {
            print("Failed to save recommended book:", error)
            errorMessage = "Lumey couldn't add this book to your library."
        }
    }

    private func isRecommendationInLibrary(_ recommendation: LumeyBookRecommendation) -> Bool {
        let targetKey = recommendationKey(recommendation)

        if addedRecommendationKeys.contains(targetKey) {
            return true
        }

        for existingBook in books {
            let existingTitle = existingBook.title
            let existingAuthor = existingBook.author
            let existingKey = recommendationKey(title: existingTitle, author: existingAuthor)

            if existingKey == targetKey {
                return true
            }
        }

        return false
    }

    private func recommendationKey(_ recommendation: LumeyBookRecommendation) -> String {
        recommendationKey(title: recommendation.title, author: recommendation.author)
    }

    private func recommendationKey(title: String, author: String) -> String {
        let rawKey = "\(title)|\(author)"
        let lowercasedKey = rawKey.lowercased()
        return lowercasedKey.replacingOccurrences(
            of: "[^a-z0-9|]",
            with: "",
            options: .regularExpression
        )
    }

    private func coverView(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image("bookstand")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(LColors.text.secondary)
                    }
                }
            } else {
                Image("bookstand")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LColors.text.secondary)
            }
        }
        .frame(width: 62, height: 92)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metadataPill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.palette.textPrimary)
            .bubblyIconMaterial(tint: theme.palette.textPrimary)
            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
            .bubblyTileLift()
    }

    private func recommendationLabels(for recommendation: LumeyBookRecommendation) -> [String] {
        uniqueValues(
            (recommendation.genres ?? [])
            + (recommendation.moods ?? [])
            + (recommendation.tropes ?? [])
            + (recommendation.themes ?? [])
            + (recommendation.tags ?? [])
        )
    }

    private func strategyDisplayName(_ strategy: String?) -> String {
        guard let strategy, !strategy.isEmpty else { return "Recommended" }

        switch strategy {
        case "closest_match":
            return "Closest Match"
        case "reader_safe":
            return "Reader Safe"
        case "hidden_gems":
            return "Hidden Gem"
        case "recent_releases":
            return "Recent Release"
        case "backlist":
            return "Backlist"
        case "adjacent_reads":
            return "Adjacent Read"
        default:
            return strategy
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.capitalized }
                .joined(separator: " ")
        }
    }

    private func requestTypeLabel(_ requestType: String) -> String {
        strategyDisplayName(requestType)
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        values.reduce(into: [String]()) { result, value in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else { return }

            if !result.contains(where: { $0.localizedCaseInsensitiveCompare(trimmedValue) == .orderedSame }) {
                result.append(trimmedValue)
            }
        }
    }

    private func topValues(_ values: [String], limit: Int) -> [String] {
        let grouped = Dictionary(grouping: values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }) {
            $0.lowercased()
        }

        return grouped
            .map { _, values in
                (value: values[0], count: values.count)
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.value.localizedCaseInsensitiveCompare(rhs.value) == .orderedAscending
                }

                return lhs.count > rhs.count
            }
            .map(\.value)
            .prefix(limit)
            .map { $0 }
    }

    private func makeReaderContext(excludeBookKeys: [String]) -> LumeyRecommendationReaderContext {
        let activeBooks = books.filter { !$0.isArchived }
        let finishedBooks = activeBooks.filter { $0.status == .finished || $0.dateFinished != nil }
        let lovedBooks = activeBooks.filter { $0.isFavorite || $0.rating >= 4 }
        let recentBooks = activeBooks
            .sorted { $0.lastUpdated > $1.lastUpdated }
            .prefix(20)
            .map { recommendationKey(title: $0.title, author: $0.author) }
        let recentSessions = sessions.prefix(40).map { session in
            LumeyRecommendationReadingSession(
                bookKey: readingSessionBookKey(session),
                lastReadAt: isoFormatter.string(from: session.date),
                pagesRead: session.pagesRead > 0 ? session.pagesRead : nil,
                minutesRead: session.durationMinutes > 0 ? session.durationMinutes : nil
            )
        }

        return LumeyRecommendationReaderContext(
            libraryBookKeys: activeBooks.map { recommendationKey(title: $0.title, author: $0.author) },
            finishedBookKeys: finishedBooks.map { recommendationKey(title: $0.title, author: $0.author) },
            ratings: activeBooks
                .filter { $0.rating > 0 }
                .prefix(80)
                .map { LumeyRecommendationRating(title: $0.title, author: $0.author, rating: $0.rating) },
            readingSessions: Array(recentSessions),
            pagePreferences: pagePreferences(from: finishedBooks),
            favoriteGenres: topValues(lovedBooks.flatMap(\.genres), limit: 8),
            favoriteTropes: topValues(lovedBooks.flatMap(\.tropes), limit: 8),
            favoriteMoods: topValues(lovedBooks.flatMap(\.moods), limit: 8),
            favoriteAuthors: topValues(lovedBooks.map(\.author), limit: 8),
            favoriteTags: topValues(lovedBooks.flatMap(\.tags), limit: 10),
            recentBookKeys: Array(recentBooks),
            alreadyRecommendedBookKeys: excludeBookKeys
        )
    }

    private var isoFormatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }

    private func pagePreferences(from books: [Book]) -> LumeyRecommendationPagePreferences? {
        let pageCounts = books
            .map(\.totalPages)
            .filter { $0 > 0 }
            .sorted()

        guard pageCounts.count >= 3 else { return nil }

        let lowerIndex = max(0, Int(Double(pageCounts.count - 1) * 0.20))
        let upperIndex = min(pageCounts.count - 1, Int(Double(pageCounts.count - 1) * 0.80))

        return LumeyRecommendationPagePreferences(
            preferredMinPages: pageCounts[lowerIndex],
            preferredMaxPages: pageCounts[upperIndex]
        )
    }

    private func readingSessionBookKey(_ session: ReadingSession) -> String {
        if let linkedBookID = session.linkedBookID,
           let book = books.first(where: { $0.id == linkedBookID }) {
            return recommendationKey(title: book.title, author: book.author)
        }

        return recommendationKey(title: session.linkedBookTitle, author: "")
    }

    @MainActor
    private func fetchRecommendations() async {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        recommendations = []
        recommendationMeta = nil
        selectedStrategy = "all"

        do {
            let excludeBookKeys = books
                .filter { !$0.isArchived }
                .map { recommendationKey(title: $0.title, author: $0.author) }
            let response = try await LumeyBookRecommendationService.shared.fetchRecommendations(
                query: trimmedSearchText,
                readerContext: makeReaderContext(excludeBookKeys: excludeBookKeys),
                excludeBookKeys: excludeBookKeys
            )

            recommendations = response.recs
            recommendationMeta = response.meta

            if recommendations.isEmpty {
                errorMessage = "No recommendations found. Try a slightly more specific book, mood, trope, or reading vibe."
            }
        } catch {
            print("❌ Recommendation Error:", error)

            let nsError = error as NSError
            print("❌ Recommendation Error Domain:", nsError.domain)
            print("❌ Recommendation Error Code:", nsError.code)
            print("❌ Recommendation Error Description:", nsError.localizedDescription)

            errorMessage = nsError.localizedDescription
        }

        isLoading = false
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
