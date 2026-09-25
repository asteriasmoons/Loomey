//
//  BookSearchSheet.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct BookSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @State private var query = ""
    @State private var results: [BookSearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addedBookKeys: Set<String> = []

    @State private var bookToEditAfterAdd: Book?
    @State private var showEditBookAfterAdd = false

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
                        } else if results.isEmpty {
                            emptyState
                        } else {
                            resultsList
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
                Text("Book Search")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Search for a book, view its details, then add it directly to your library.")
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
                TextField("Fourth Wing, Rebecca Yarros, ISBN...", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                    }

                Button {
                    Task {
                        await searchBooks()
                    }
                } label: {
                    Text(isLoading ? "Searching..." : "Search Books")
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
                .disabled(isLoading || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
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

            Text("No search results yet")
                .font(.headline)

            Text("Search by title, author, or ISBN to find books from Open Library and Google Books.")
                .font(.callout)
                .foregroundStyle(LColors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var resultsList: some View {
        VStack(spacing: 14) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, book in
                resultCard(book, accentIndex: index)
            }
        }
    }

    private func resultCard(_ book: BookSearchResult, accentIndex: Int) -> some View {
        let accent = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

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

                    HStack(spacing: 8) {
                        if let releaseYear = book.releaseYear {
                            metadataPill("\(releaseYear)", tint: theme.palette.rotation[0])
                        }

                        if let pages = book.pages {
                            metadataPill("\(pages) pages", tint: theme.palette.rotation[1])
                        }

                        if let rating = book.rating {
                            metadataPill(String(format: "%.1f", rating), tint: theme.palette.rotation[2])
                        }
                    }
                }

                Spacer()
            }

            if !book.summary.isEmpty {
                Text(book.summary)
                    .font(.callout)
                    .foregroundStyle(LColors.text.secondary)
                    .lineLimit(5)
            }

            if let tags = book.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(tags.prefix(6).enumerated()), id: \.element) { index, tag in
                            metadataPill(
                                tag,
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

    private func addToLibraryButton(for searchResult: BookSearchResult, tint: Color) -> some View {
        let alreadyAdded = isBookInLibrary(searchResult)

        return Button {
            addBookToLibrary(searchResult)
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

    private func addBookToLibrary(_ searchResult: BookSearchResult) {
        guard !isBookInLibrary(searchResult) else { return }

        let bookTitle = searchResult.title
        let bookAuthor = searchResult.author
        let bookSummary = searchResult.summary
        let bookRating = searchResult.rating ?? 0
        let bookTotalPages = searchResult.pages ?? 0
        let bookCoverURL = searchResult.coverUrl ?? ""
        let bookTags = searchResult.tags ?? []
        let bookGenres: [String] = bookTags.first.map { [$0] } ?? []

        let bookPublicationYear: String
        if let releaseYear = searchResult.releaseYear {
            bookPublicationYear = String(releaseYear)
        } else {
            bookPublicationYear = ""
        }

        let bookNotes = "Added from Lumey Book Search. Source: \(searchResult.source)."

        let newBook = Book(
            title: bookTitle,
            author: bookAuthor,
            publisher: searchResult.publisher ?? "",
            publicationYear: bookPublicationYear,
            isbn: searchResult.isbn ?? "",
            summary: bookSummary,
            rating: bookRating,
            status: BookStatus.toBeRead,
            format: BookFormat.other,
            ownership: BookOwnership.wishlist,
            totalPages: bookTotalPages,
            notes: bookNotes,
            genres: bookGenres,
            tags: bookTags,
            coverURL: bookCoverURL
        )

        modelContext.insert(newBook)
        addedBookKeys.insert(bookKey(searchResult))
        bookToEditAfterAdd = newBook

        do {
            try modelContext.save()
            showEditBookAfterAdd = true
        } catch {
            print("Failed to save searched book:", error)
            errorMessage = "Lumey couldn't add this book to your library."
        }
    }

    private func isBookInLibrary(_ searchResult: BookSearchResult) -> Bool {
        let targetKey = bookKey(searchResult)

        if addedBookKeys.contains(targetKey) {
            return true
        }

        for existingBook in books {
            let existingKey = bookKey(title: existingBook.title, author: existingBook.author)

            if existingKey == targetKey {
                return true
            }
        }

        return false
    }

    private func bookKey(_ searchResult: BookSearchResult) -> String {
        bookKey(title: searchResult.title, author: searchResult.author)
    }

    private func bookKey(title: String, author: String) -> String {
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
                        Image(systemName: "book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(LColors.text.secondary)
                    }
                }
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
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

    @MainActor
    private func searchBooks() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            results = try await BookSearchService.shared.searchBooks(query: trimmedQuery)

            if results.isEmpty {
                errorMessage = "No books found. Try a different title, author, or ISBN."
            }
        } catch {
            print("Book Search Error:", error)

            let nsError = error as NSError
            print("Book Search Error Domain:", nsError.domain)
            print("Book Search Error Code:", nsError.code)
            print("Book Search Error Description:", nsError.localizedDescription)

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
