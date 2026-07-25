//
//  RecommendedBookDetailSheet.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct RecommendedBookDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var libraryBooks: [Book]

    let book: LumeyRecommendationCollectionBook

    @State private var detail: RecommendationBookDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var bookToEditAfterAdd: Book?
    @State private var showEditBookAfterAdd = false
    @State private var addedBookKeys: Set<String> = []

    private var displayedDetail: RecommendationBookDetail? {
        detail
    }

    var body: some View {
        let content = NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        topBar

                        hero

                        if detail == nil {
                            if isLoading {
                                summaryLoadingCard
                            } else if let errorMessage {
                                errorCard(errorMessage)
                            }
                        } else {
                            summaryCard
                        }

                        metadataSections
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .task(id: book.id) {
                await fetchDetail()
            }
        }

        if horizontalSizeClass == .regular {
            content
                .fullScreenCover(isPresented: $showEditBookAfterAdd) {
                    editBookSheet
                }
        } else {
            content
                .sheet(isPresented: $showEditBookAfterAdd) {
                    editBookSheet
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                }
        }
    }

    @ViewBuilder
    private var editBookSheet: some View {
        if let bookToEditAfterAdd {
            AddEditBookSheet(book: bookToEditAfterAdd) { _ in }
        } else {
            LumeyBackground()
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        let alreadyAdded = isBookInLibrary

        return HStack(spacing: 12) {
            Text("Book Details")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Spacer(minLength: 0)

            if detail != nil || alreadyAdded {
                addToLibraryButton(alreadyAdded: alreadyAdded)
            }

            Button {
                dismiss()
            } label: {
                headerCircleIcon("xmarkwavy")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.bottom, 6)
    }

    private func addToLibraryButton(alreadyAdded: Bool) -> some View {
        Button {
            addToLibrary()
        } label: {
            HStack(spacing: 8) {
                Image(alreadyAdded ? "checkwavy" : "addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text(alreadyAdded ? "Added to Library" : "Add to Library")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(alreadyAdded ? LColors.textSecondary : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        alreadyAdded
                            ? LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(alreadyAdded ? 0.14 : 0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded)
        .accessibilityLabel(alreadyAdded ? "Added to Library" : "Add to Library")
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                coverView(displayedDetail?.coverUrl ?? book.coverUrl)

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayedDetail?.title ?? book.title)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(4)

                    Text(displayedDetail?.author ?? book.author)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    if let subtitle = displayedDetail?.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(3)
                    }
                }
            }

            let quickFacts = [
                (displayedDetail?.publicationYear ?? book.releaseYear).map(String.init),
                (displayedDetail?.pages ?? book.pages).map { "\($0) pages" },
                (displayedDetail?.rating ?? book.rating).map { String(format: "%.1f stars", $0) },
                displayedDetail?.tone,
                displayedDetail?.pacing
            ].compactMap { $0 }.filter { !$0.isEmpty }

            if !quickFacts.isEmpty {
                pillRow(quickFacts, limit: 6)
            }
        }
    }

    private var summaryLoadingCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                LumeyDottedGradientSpinner(size: 40)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Writing summary")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Lumey is writing the recommendation detail copy.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Detail unavailable")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(displayedDetail?.summary ?? "")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.80))
                    .lineSpacing(4)
            }
        }
    }

    @ViewBuilder
    private var metadataSections: some View {
        let genreValues = uniqueValues((displayedDetail?.genres ?? book.genres ?? []) + (displayedDetail?.subgenres ?? []))
        let moodValues = uniqueValues(displayedDetail?.moods ?? book.moods ?? [])
        let tropeValues = uniqueValues(displayedDetail?.tropes ?? book.tropes ?? [])
        let tagValues = uniqueValues(displayedDetail?.tags ?? book.tags ?? [])
        let themeValues = uniqueValues(displayedDetail?.themes ?? book.themes ?? [])
        let factValues = factualDetails

        if !genreValues.isEmpty {
            metadataCard(title: "Genres", values: genreValues)
        }

        if !moodValues.isEmpty {
            metadataCard(title: "Moods", values: moodValues)
        }

        if !tropeValues.isEmpty {
            metadataCard(title: "Tropes", values: tropeValues)
        }

        if !themeValues.isEmpty {
            metadataCard(title: "Themes", values: themeValues)
        }

        if !tagValues.isEmpty {
            metadataCard(title: "Tags", values: tagValues)
        }

        if !factValues.isEmpty {
            metadataCard(title: "Details", values: factValues)
        }
    }

    private var factualDetails: [String] {
        var values: [String] = []

        if let publisher = displayedDetail?.publisher, !publisher.isEmpty {
            values.append(publisher)
        }

        if let isbn = displayedDetail?.isbn, !isbn.isEmpty {
            values.append("ISBN \(isbn)")
        }

        if let audience = displayedDetail?.audience, !audience.isEmpty {
            values.append(audience)
        }

        if let romanceLevel = displayedDetail?.romanceLevel, !romanceLevel.isEmpty {
            values.append("Romance \(romanceLevel)")
        }

        if let darknessLevel = displayedDetail?.darknessLevel, !darknessLevel.isEmpty {
            values.append("Darkness \(darknessLevel)")
        }

        if let source = displayedDetail?.source, !source.isEmpty {
            values.append(source)
        } else if let source = book.source, !source.isEmpty {
            values.append(source)
        }

        return uniqueValues(values)
    }

    private func metadataCard(title: String, values: [String]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                FlowLayout(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        metadataPill(value)
                    }
                }
            }
        }
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
                        fallbackCover
                    }
                }
            } else {
                fallbackCover
            }
        }
        .frame(width: 108, height: 162)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
    }

    private var fallbackCover: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LColors.gradientBlue.opacity(0.48),
                    LColors.gradientPurple.opacity(0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("bookstand")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(.white.opacity(0.84))
        }
    }

    private func pillRow(_ values: [String], limit: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(values.prefix(limit)), id: \.self) { value in
                    metadataPill(value)
                }
            }
        }
    }

    private func metadataPill(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.10), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func headerCircleIcon(_ icon: String) -> some View {
        Image(icon)
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

    @MainActor
    private func fetchDetail() async {
        guard detail == nil else { return }

        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }

        do {
            let loadedDetail = try await RecommendationBookDetailService.shared.fetchDetail(for: book)

            if !Task.isCancelled {
                detail = loadedDetail
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = "Lumey couldn't load extra details for this book right now."
                print("Recommendation book detail error:", book.title, book.author, error)
            }
        }
    }

    private var isBookInLibrary: Bool {
        let targetKey = bookKey(title: displayedDetail?.title ?? book.title, author: displayedDetail?.author ?? book.author)

        if addedBookKeys.contains(targetKey) {
            return true
        }

        return libraryBooks.contains { existingBook in
            bookKey(title: existingBook.title, author: existingBook.author) == targetKey
        }
    }

    private func addToLibrary() {
        guard !isBookInLibrary, detail != nil else { return }

        let currentDetail = displayedDetail
        let bookTitle = currentDetail?.title ?? book.title
        let bookAuthor = currentDetail?.author ?? book.author
        let publicationYear = currentDetail?.publicationYear.map(String.init) ?? book.releaseYear.map(String.init) ?? ""
        let genres = uniqueValues((currentDetail?.genres ?? book.genres ?? []) + (currentDetail?.subgenres ?? []))
        let moods = uniqueValues(currentDetail?.moods ?? book.moods ?? [])
        let tags = uniqueValues(currentDetail?.tags ?? book.tags ?? [])
        let tropes = uniqueValues(currentDetail?.tropes ?? book.tropes ?? [])
        let topics = uniqueValues(currentDetail?.themes ?? book.themes ?? [])
        let source = currentDetail?.source ?? book.source ?? ""
        let details = [
            book.strategyLabel,
            book.rationale,
            currentDetail?.tone,
            currentDetail?.pacing
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
        let notes = details.isEmpty
            ? "Recommended by Lumey. Source: \(source)."
            : "Recommended by Lumey. \(details). Source: \(source)."

        let draftBook = Book(
            title: bookTitle,
            author: bookAuthor,
            subtitle: currentDetail?.subtitle ?? "",
            publisher: currentDetail?.publisher ?? "",
            publicationYear: publicationYear,
            isbn: currentDetail?.isbn ?? "",
            summary: currentDetail?.summary ?? book.summary,
            rating: currentDetail?.rating ?? book.rating ?? 0,
            status: .toBeRead,
            format: .other,
            ownership: .wishlist,
            totalPages: currentDetail?.pages ?? book.pages ?? 0,
            notes: notes,
            genres: genres,
            moods: moods,
            tags: tags,
            tropes: tropes,
            topics: topics,
            coverURL: currentDetail?.coverUrl ?? book.coverUrl ?? ""
        )

        modelContext.insert(draftBook)
        addedBookKeys.insert(bookKey(title: bookTitle, author: bookAuthor))
        bookToEditAfterAdd = draftBook

        do {
            try modelContext.save()
            showEditBookAfterAdd = true
        } catch {
            print("Failed to save recommended shelf book:", error)
            errorMessage = "Lumey couldn't add this book to your library."
        }
    }

    private func bookKey(title: String, author: String) -> String {
        let rawKey = "\(title)|\(author)"
        return rawKey
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9|]", with: "", options: .regularExpression)
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
}
