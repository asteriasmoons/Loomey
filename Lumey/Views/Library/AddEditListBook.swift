//
//  AddEditListBook.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct AddEditListBook: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @Bindable var list: ReadingList

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]

    @State private var selectedBookIDs: [UUID] = []
    @State private var manualBookTitle = ""
    @State private var manualBookAuthor = ""
    @State private var manualBookSummary = ""
    @State private var isGeneratingManualSummary = false
    @State private var manualSummaryError: String?
    @State private var isExistingBookPickerExpanded = false

    private var availableBooks: [Book] {
        allBooks.filter { !$0.isArchived }
    }

    private var unlinkedBooks: [Book] {
        availableBooks.filter { !selectedBookIDs.contains($0.id) }
    }

    private var availableSeries: [String] {
        let names = Set(allBooks.compactMap { book in
            let trimmed = book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        })
        return names.sorted()
    }

    private var canAddManualBook: Bool {
        !manualBookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !manualBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        booksSection
                        seriesQuickAddSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .task(id: list.id) {
            selectedBookIDs = list.items.map(\.bookID)
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text(list.bookCount == 0 ? "Add List Books" : "Edit List Books")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer()

            Button { saveBooks() } label: {
                Text("Save")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background {
                        BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            .clipShape(Capsule(style: .continuous))
                    }
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(theme.palette.background)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1.2)
                            )
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

    private var booksSection: some View {
        sectionCard(title: "Books", accentIndex: 0) {
            selectedBookPreviews
            existingBookDropdown
            manualBookEntry
        }
    }

    @ViewBuilder
    private var selectedBookPreviews: some View {
        if !selectedBookIDs.isEmpty {
            VStack(spacing: 8) {
                ForEach(Array(selectedBookIDs.enumerated()), id: \.element) { index, bookID in
                    if let book = availableBooks.first(where: { $0.id == bookID }) {
                        selectedBookPreview(book, index: index)
                    }
                }
            }
        }
    }

    private func selectedBookPreview(_ book: Book, index: Int) -> some View {
        let accent = theme.palette.rotation[index % theme.palette.rotation.count]

        return HStack(spacing: 10) {
            Image("books")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .lineLimit(1)

                Text(book.author)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                selectedBookIDs.removeAll { $0 == book.id }
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(theme.palette.raisedSurface))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background { BubblyTileSurface(tint: accent, cornerRadius: 14) }
        .bubblyTileLift()
    }

    @ViewBuilder
    private var existingBookDropdown: some View {
        if !unlinkedBooks.isEmpty {
            VStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isExistingBookPickerExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)

                        Text("Add Existing Book")
                            .font(.system(size: 13, weight: .black, design: .rounded))

                        Spacer()

                        Image(isExistingBookPickerExpanded ? "chevup" : "chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background { BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 16) }
                    .bubblyTileLift()
                }
                .buttonStyle(.plain)

                if isExistingBookPickerExpanded {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 7) {
                            ForEach(unlinkedBooks) { book in
                                Button {
                                    selectedBookIDs.append(book.id)
                                    if unlinkedBooks.count <= 1 {
                                        isExistingBookPickerExpanded = false
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image("books")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(book.title)
                                                .font(.system(size: 13, weight: .black, design: .rounded))
                                                .lineLimit(1)

                                            Text(book.author)
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .opacity(0.82)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        Image("addwavy")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                    }
                                    .foregroundStyle(.white)
                                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(theme.palette.raisedSurface)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: CGFloat(min(unlinkedBooks.count, 4)) * 54)
                    .padding(10)
                    .background { BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 18) }
                    .bubblyTileLift()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var manualBookEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Book")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            LumeyTextField(title: "Title", text: $manualBookTitle, borderColor: theme.palette.primaryAction)
            LumeyTextField(title: "Author", text: $manualBookAuthor, borderColor: theme.palette.secondaryAccent)
            LumeyTextEditor(
                title: "Summary",
                text: $manualBookSummary,
                minHeight: 88,
                borderColor: theme.palette.indicators
            )

            Button {
                Task { await generateManualSummary() }
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingManualSummary {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image("sparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                    }

                    Text(isGeneratingManualSummary ? "Generating..." : "Get Summary")
                        .font(.system(size: 13, weight: .black, design: .rounded))

                    Spacer()
                }
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)
            .disabled(!canAddManualBook || isGeneratingManualSummary)
            .opacity(canAddManualBook ? 1 : 0.55)

            if let manualSummaryError {
                Text(manualSummaryError)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                addManualBook()
            } label: {
                HStack(spacing: 8) {
                    Image("addwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)

                    Text("Add Manual Book")
                        .font(.system(size: 13, weight: .black, design: .rounded))

                    Spacer()
                }
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background { BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 16) }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)
            .disabled(!canAddManualBook)
            .opacity(canAddManualBook ? 1 : 0.55)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var seriesQuickAddSection: some View {
        if !availableSeries.isEmpty {
            sectionCard(title: "Add Entire Series", accentIndex: 1) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(availableSeries.enumerated()), id: \.element) { index, seriesName in
                            let accent = theme.palette.rotation[index % theme.palette.rotation.count]
                            Button {
                                addSeriesBooks(seriesName)
                            } label: {
                                HStack(spacing: 6) {
                                    Image("books")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .bubblyIconMaterial(tint: .white)

                                    Text(seriesName)
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background { BubblyTileSurface(tint: accent, cornerRadius: 999) }
                                .bubblyTileLift()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        accentIndex: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let accent = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return GlassCard(variant: .featured, borderColor: accent) {
            VStack(alignment: .leading, spacing: 13) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                VStack(spacing: 12) {
                    content()
                }
            }
        }
    }

    @MainActor
    private func generateManualSummary() async {
        guard canAddManualBook, !isGeneratingManualSummary else { return }

        isGeneratingManualSummary = true
        manualSummaryError = nil

        do {
            let summary = try await RegularRecBookSummaryService.shared.fetchSummary(
                title: manualBookTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                author: manualBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: manualBookSummary
            )
            manualBookSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            manualSummaryError = error.localizedDescription
        }

        isGeneratingManualSummary = false
    }

    private func addManualBook() {
        let trimmedTitle = manualBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = manualBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = manualBookSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedAuthor.isEmpty else { return }

        let book = Book(title: trimmedTitle, author: trimmedAuthor, summary: trimmedSummary)
        modelContext.insert(book)
        selectedBookIDs.append(book.id)

        manualBookTitle = ""
        manualBookAuthor = ""
        manualBookSummary = ""
        manualSummaryError = nil
    }

    private func addSeriesBooks(_ seriesName: String) {
        let seriesBooks = availableBooks.filter {
            $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(seriesName) == .orderedSame
        }

        for book in seriesBooks where !selectedBookIDs.contains(book.id) {
            selectedBookIDs.append(book.id)
        }
    }

    private func saveBooks() {
        if canAddManualBook {
            addManualBook()
        }

        let existingItems = list.items
        list.items = selectedBookIDs.enumerated().map { index, bookID in
            if let existing = existingItems.first(where: { $0.bookID == bookID }) {
                var updated = existing
                updated.sortOrder = index
                return updated
            }

            return ReadingListItemData(
                bookID: bookID,
                sortOrder: index,
                dateAdded: Date()
            )
        }
        list.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
}
