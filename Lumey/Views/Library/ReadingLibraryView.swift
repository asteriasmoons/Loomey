//
//  ReadingLibraryView.swift
//  Lumey
//

import SwiftUI
import SwiftData


private struct BookSheetMode: Identifiable {
    let id = UUID()
    let book: Book?
}

struct ReadingLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var librarySettings: [ReadingLibrarySettings]

    @Query(sort: \ReadingLibraryCustomFilter.sortIndex)
    private var customFilters: [ReadingLibraryCustomFilter]

    @State private var searchText = ""
    @State private var selectedStatus: BookStatus? = nil
    @State private var selectedSeries: String? = nil
    @State private var selectedCustomFilterID: UUID? = nil
    @State private var isCustomFilterExpanded = false
    @State private var isSeriesFilterExpanded = false
    @State private var activeBookSheet: BookSheetMode? = nil
    @State private var showRecommendationsSheet = false
    @State private var showBookSearchSheet = false
    @State private var showReadingMissionSheet = false
    @State private var showAddCustomFilterDialog = false
    @State private var customFilterName = ""
    @State private var hasAppeared = false

    private var visibleBooks: [Book] {
        books
            .filter { !$0.isArchived }
            .filter { book in
                guard let selectedStatus else { return true }
                return book.status == selectedStatus
            }
            .filter { book in
                guard let selectedSeries else { return true }
                return book.seriesName == selectedSeries
            }
            .filter { book in
                guard let selectedCustomFilterID else { return true }
                return book.customFilterIDs.contains(selectedCustomFilterID)
            }
            .filter { book in
                let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedSearch.isEmpty else { return true }

                return book.displayTitle.localizedCaseInsensitiveContains(trimmedSearch)
                || book.displayAuthor.localizedCaseInsensitiveContains(trimmedSearch)
                || book.seriesName.localizedCaseInsensitiveContains(trimmedSearch)
                || book.genres.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.moods.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.tags.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.tropes.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
            }
    }

    private var activeBooksCount: Int {
        books.filter { !$0.isArchived }.count
    }

    private var readingCount: Int {
        books.filter { $0.status == .reading && !$0.isArchived }.count
    }

    private var finishedCount: Int {
        books.filter { $0.status == .finished && !$0.isArchived }.count
    }

    private var tbrCount: Int {
        books.filter { $0.status == .toBeRead && !$0.isArchived }.count
    }

    private var defaultStatus: BookStatus? {
        librarySettings.first?.defaultStatusFilter
    }

    private var availableSeries: [String] {
        Array(
            Set(
                books
                    .filter { !$0.isArchived }
                    .map { $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var shouldShowCustomFilterCollapseControl: Bool {
        customFilters.count > 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        searchBar
                        recommendationButtonSection
                        statusFilter
                        customFilterSection
                        readingListsButton
                        seriesFilter
                        libraryOverview
                        bookListSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
            .adaptivePresentation(item: $activeBookSheet, useFullScreenCover: horizontalSizeClass == .regular) { sheetMode in
                AddEditBookSheet(book: sheetMode.book) { savedBook in
                    if sheetMode.book == nil {
                        modelContext.insert(savedBook)
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showRecommendationsSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                BookRecommendationsSheet()
            }
            .adaptivePresentation(isPresented: $showBookSearchSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                BookSearchSheet()
            }
            .adaptivePresentation(isPresented: $showReadingMissionSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                ReadingMissionSheet()
            }
            .alert("New Filter", isPresented: $showAddCustomFilterDialog) {
                TextField("Two words max", text: $customFilterName)

                Button("Cancel", role: .cancel) {
                    customFilterName = ""
                }

                Button("Create") {
                    createCustomFilter()
                }
                .disabled(sanitizedCustomFilterTitle(customFilterName).isEmpty)
            } message: {
                Text("Use up to two words or 22 characters.")
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                selectedStatus = defaultStatus
            }
        }
    }
}

// MARK: - Header

private extension ReadingLibraryView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Library")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Spacer()

                addBookButton
            }

            Text("Browse, search, and organize your books")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var addBookButton: some View {
        Button {
            activeBookSheet = BookSheetMode(book: nil)
        } label: {
            Image("addwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(
                    LColors.accents.primary
                )
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LColors.accents.primary,
                                    lineWidth: 1.35
                                )
                        )
                        .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search

private extension ReadingLibraryView {
    var searchBar: some View {
        HStack(spacing: 10) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.textSecondary)

            TextField("Search books, authors, series, tags...", text: $searchText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .tint(LColors.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LColors.gradientBlue.opacity(0.08)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LColors.gradientBlue.opacity(0.65),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Reading Lists Button

private extension ReadingLibraryView {
    var readingListsButton: some View {
        NavigationLink {
            ReadingListsPage()
        } label: {
            HStack(spacing: 10) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.appBackground)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Lists")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.appBackground)

                    Text("Curated collections and TBR plans")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.75))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LGradients.header)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Filter

private extension ReadingLibraryView {
    var recommendationButtonSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                libraryActionButton(
                    title: "Recommend",
                    iconName: "sparkle"
                ) {
                    showRecommendationsSheet = true
                }

                libraryActionButton(
                    title: "Look Up",
                    iconName: "searchwavy"
                ) {
                    showBookSearchSheet = true
                }
            }

            libraryActionButton(
                title: "Reading Mission",
                iconName: "wand"
            ) {
                showReadingMissionSheet = true
            }
        }
    }

    func libraryActionButton(
        title: String,
        iconName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(LColors.appBackground)
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .center)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LColors.accents.primary
                    )
            )
        }
        .buttonStyle(.plain)
    }

    var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                customFilterAddButton

                if shouldShowCustomFilterCollapseControl {
                    customFilterCollapseButton
                }

                statusFilterChip(title: "All", status: nil)

                ForEach(BookStatus.allCases) { status in
                    statusFilterChip(title: status.rawValue, status: status)
                }
            }
            .padding(.vertical, 2)
        }
    }

    var customFilterSection: some View {
        Group {
            if !customFilters.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(customFilters) { filter in
                        customFilterChip(filter)
                    }
                }
                .frame(maxHeight: shouldShowCustomFilterCollapseControl && !isCustomFilterExpanded ? 39 : nil, alignment: .top)
                .clipped()
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isCustomFilterExpanded)
            }
        }
    }

    var customFilterAddButton: some View {
        Button {
            customFilterName = ""
            showAddCustomFilterDialog = true
        } label: {
            Image("addwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(LColors.gradientPurple)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.gradientPurple, lineWidth: 1.35)
                        )
                        .shadow(color: LColors.gradientPurple.opacity(0.24), radius: 10, y: 5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create custom library filter")
    }

    var customFilterCollapseButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isCustomFilterExpanded.toggle()
            }
        } label: {
            Image(isCustomFilterExpanded ? "chevup" : "chevdown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(LColors.gradientPurple)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    Circle()
                        .strokeBorder(LColors.gradientPurple.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCustomFilterExpanded ? "Collapse custom filters" : "Expand custom filters")
    }

    var seriesFilter: some View {
        Group {
            if !availableSeries.isEmpty {
                LibrarySeriesFilterDropdown(
                    availableSeries: availableSeries,
                    selectedSeries: $selectedSeries,
                    isExpanded: $isSeriesFilterExpanded
                )
            }
        }
    }

    func setDefaultStatusFilter(_ status: BookStatus?) {
        let rawValue = status?.rawValue ?? "All"

        if let settings = librarySettings.first {
            settings.defaultStatusFilterRawValue = rawValue
        } else {
            let settings = ReadingLibrarySettings(defaultStatusFilterRawValue: rawValue)
            modelContext.insert(settings)
        }

        if librarySettings.count > 1 {
            for i in 1..<librarySettings.count {
                modelContext.delete(librarySettings[i])
            }
        }

        try? modelContext.save()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            selectedStatus = status
        }
    }

    func isDefaultStatusFilter(_ status: BookStatus?) -> Bool {
        defaultStatus == status
    }

    func statusFilterChip(title: String, status: BookStatus?) -> some View {
        let isSelected = selectedStatus == status

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selectedStatus = status
                selectedCustomFilterID = nil
            }
        } label: {
            HStack(spacing: 6) {
                if isDefaultStatusFilter(status) {
                    Image("starfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                }

                Text(title)
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(isSelected ? .white : LColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                        ? LColors.gradientBlue.opacity(0.36)
                        : LColors.surface.subtle.opacity(0.6)
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                            ? [LColors.accents.primary, LColors.accents.secondary]
                            : [LColors.border.subtle, LColors.border.nested],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                setDefaultStatusFilter(status)
            } label: {
                Label {
                    Text("Set as Default")
                } icon: {
                    Image("starfill")
                }
            }
        }
    }

    func customFilterChip(_ filter: ReadingLibraryCustomFilter) -> some View {
        let isSelected = selectedCustomFilterID == filter.id

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selectedCustomFilterID = isSelected ? nil : filter.id
                if !isSelected {
                    selectedStatus = nil
                }
            }
        } label: {
            Text(filter.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? LColors.gradientPurple : LColors.surface.nestedSoft)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected ? LColors.gradientPurple : LColors.border.subtle,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteCustomFilter(filter)
            } label: {
                Label {
                    Text("Delete Filter")
                } icon: {
                    Image("trash")
                }
            }
        }
    }

    func sanitizedCustomFilterTitle(_ title: String) -> String {
        let words = title
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(2)
            .map(String.init)

        let twoWordTitle = words.joined(separator: " ")
        return String(twoWordTitle.prefix(22))
    }

    func createCustomFilter() {
        let title = sanitizedCustomFilterTitle(customFilterName)
        guard !title.isEmpty else { return }

        let isDuplicate = customFilters.contains {
            $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
        }
        guard !isDuplicate else {
            customFilterName = ""
            return
        }

        let nextIndex = (customFilters.map(\.sortIndex).max() ?? -1) + 1
        let filter = ReadingLibraryCustomFilter(title: title, sortIndex: nextIndex)
        modelContext.insert(filter)
        try? modelContext.save()

        customFilterName = ""
    }

    func deleteCustomFilter(_ filter: ReadingLibraryCustomFilter) {
        let filterID = filter.id

        for book in books where book.customFilterIDs.contains(filterID) {
            book.customFilterIDs = book.customFilterIDs.filter { $0 != filterID }
        }

        if selectedCustomFilterID == filterID {
            selectedCustomFilterID = nil
        }

        modelContext.delete(filter)
        try? modelContext.save()
    }


}

// MARK: - Overview

private extension ReadingLibraryView {
    var libraryOverview: some View {
        HStack(spacing: 12) {
            LibraryMiniStatCard(title: "Total", value: "\(activeBooksCount)")
            LibraryMiniStatCard(title: "Reading", value: "\(readingCount)")
            LibraryMiniStatCard(title: "TBR", value: "\(tbrCount)")
            LibraryMiniStatCard(title: "Finished", value: "\(finishedCount)")
        }
    }
}

// MARK: - Book List

private extension ReadingLibraryView {
    var bookListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Books")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Spacer()

                Text("\(visibleBooks.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
            }

            if visibleBooks.isEmpty {
                emptyLibraryCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(visibleBooks.enumerated()), id: \.element.id) { index, book in
                        LibraryBookRow(book: book, variant: GlassCardRotation.variant(for: index), accentIndex: index) {
                            activeBookSheet = BookSheetMode(book: book)
                        }
                        .contextMenu {
                            if !customFilters.isEmpty {
                                ForEach(customFilters) { filter in
                                    let isAssigned = book.customFilterIDs.contains(filter.id)

                                    Button {
                                        toggleCustomFilter(filter, for: book)
                                    } label: {
                                        Label {
                                            Text(isAssigned ? "Remove \(filter.title)" : "Add \(filter.title)")
                                        } icon: {
                                            Image(isAssigned ? "checkwavy" : "addwavy")
                                                .renderingMode(.template)
                                        }
                                    }
                                }

                                Divider()
                            }

                            Button(role: .destructive) {
                                deleteBook(book)
                            } label: {
                                Label {
                                    Text("Delete Book")
                                } icon: {
                                    Image("trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var readingChallengesCard: some View {
        NavigationLink {
            ChallengesView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LColors.gradientPurple.opacity(0.9)
                        )
                        .frame(width: 56, height: 56)

                    Image("readinggoals")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Challenges")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Build quests for your TBR, series, authors, and formats.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(LColors.gradientPurple.opacity(0.32), lineWidth: 1)
                    )
                    .shadow(color: LColors.gradientPurple.opacity(0.16), radius: 18, y: 10)
            )
        }
        .buttonStyle(.plain)
    }

    var emptyLibraryCard: some View {
        GlassCard(variant: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text("No books found")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)

                Text(searchText.isEmpty ? "Your saved books will appear here." : "Try a different search or filter.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func deleteBook(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
    }

    func toggleCustomFilter(_ filter: ReadingLibraryCustomFilter, for book: Book) {
        if book.customFilterIDs.contains(filter.id) {
            book.customFilterIDs = book.customFilterIDs.filter { $0 != filter.id }
        } else {
            book.customFilterIDs.append(filter.id)
        }

        try? modelContext.save()
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

// MARK: - Preview

#Preview {
    ReadingLibraryView()
}

struct LibrarySeriesFilterDropdown: View {
    let availableSeries: [String]
    @Binding var selectedSeries: String?
    @Binding var isExpanded: Bool
    
    private var selectedTitle: String {
        selectedSeries ?? "All Series"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Series")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .padding(.horizontal, 2)
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.accents.primary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(LColors.iconContainer.primary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.accents.primary, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Filter Library")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        
                        Text(selectedTitle)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Text("\(availableSeries.count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.iconContainer.primary)
                        )
                    
                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.accents.contrast)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(dropdownBackground)
                .overlay(dropdownBorder)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    dropdownOption(title: "All Series", seriesName: nil)
                    
                    ForEach(availableSeries, id: \.self) { series in
                        dropdownOption(title: series, seriesName: series)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LColors.gradientBlue.opacity(0.08)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LColors.gradientBlue.opacity(0.55),
                            lineWidth: 1
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var dropdownBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LColors.gradientBlue.opacity(0.10)
            )
    }
    
    private var dropdownBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                LColors.gradientBlue.opacity(0.72),
                lineWidth: 1
            )
    }
    
    private func dropdownOption(title: String, seriesName: String?) -> some View {
        let isSelected = selectedSeries == seriesName
        
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedSeries = seriesName
                isExpanded = false
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSelected ? LColors.accents.primary : LColors.border.subtle)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(isSelected ? LColors.border.primary.opacity(0.75) : Color.clear)
                            .frame(width: 4, height: 4)
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                if isSelected {
                    Image("checkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LColors.accents.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? LColors.iconContainer.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
