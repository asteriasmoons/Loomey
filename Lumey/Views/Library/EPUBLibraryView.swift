//
//  EPUBLibraryView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct EPUBLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]

    @Query(sort: \EPUBCollection.sortIndex)
    private var collections: [EPUBCollection]

    @State private var searchText = ""
    @State private var selectedCollectionID: UUID? = nil
    @State private var showImporter = false
    @State private var showCreateCollection = false
    @State private var newCollectionName = ""
    @State private var showReader = false
    @State private var readerURL: URL?
    @State private var readerBookID: UUID?
    @State private var readerLocationJSON: String?
    @State private var importError: String?
    @State private var showManageCollections = false
    @State private var bookToAddToCollection: Book?

    private var epubBooks: [Book] {
        allBooks.filter { $0.hasEPUB && $0.deletedAt == nil && !$0.isArchived }
    }

    private var filteredBooks: [Book] {
        var result = epubBooks

        if let collectionID = selectedCollectionID,
           let collection = collections.first(where: { $0.id == collectionID }) {
            let ids = collection.bookIDs
            result = result.filter { ids.contains($0.id) }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(trimmed)
                || $0.displayAuthor.localizedCaseInsensitiveContains(trimmed)
            }
        }

        return result
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        searchBar
                        collectionFilters
                        bookGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.epubFile],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result)
            }
            .alert("New Collection", isPresented: $showCreateCollection) {
                TextField("Collection name", text: $newCollectionName)
                Button("Cancel", role: .cancel) { newCollectionName = "" }
                Button("Create") { createCollection() }
            }
            .sheet(item: $bookToAddToCollection) { book in
                AddToCollectionSheet(
                    book: book,
                    collections: collections,
                    onAddToCollection: { collection in
                        collection.addBook(book.id)
                        try? modelContext.save()
                    },
                    onCreateNew: { name in
                        let c = EPUBCollection(name: name, sortIndex: collections.count)
                        c.addBook(book.id)
                        modelContext.insert(c)
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showManageCollections) {
                ManageCollectionsSheet(
                    collections: collections,
                    onDelete: { collection in
                        modelContext.delete(collection)
                        if selectedCollectionID == collection.id {
                            selectedCollectionID = nil
                        }
                        try? modelContext.save()
                    },
                    onRename: { collection, newName in
                        collection.name = newName
                        collection.updatedAt = Date()
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $showReader) {
                if let readerURL, let readerBookID {
                    EPUBReaderDestinationView(
                        fileURL: readerURL,
                        bookID: readerBookID,
                        onClose: {
                            showReader = false
                            appState.hideTabBar = false
                        },
                        onProgressChanged: { location in
                            if let book = epubBooks.first(where: { $0.id == readerBookID }) {
                                book.epubReaderLocation = location
                                book.epubLastOpenedAt = Date()
                                book.updatedAt = Date()
                                book.lastUpdated = Date()
                            }
                        },
                        initialLocationJSON: readerLocationJSON
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("Library")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            Button {
                showManageCollections = true
            } label: {
                Image("folderfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                showImporter = true
            } label: {
                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.textSecondary)

            TextField("Search ebooks...", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.glassSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                }
        }
    }

    // MARK: - Collection Filters

    private var collectionFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                collectionChip(label: "All", id: nil, accentIndex: 0)

                ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                    collectionChip(label: collection.name, id: collection.id, accentIndex: index + 1)
                }

                Button {
                    showCreateCollection = true
                } label: {
                    HStack(spacing: 5) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.white)
                            .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)

                        Text("New")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        BubblyIconMaterial(
                            tint: theme.palette.rotation[(collections.count + 1) % theme.palette.rotation.count]
                        )
                        .clipShape(Capsule(style: .continuous))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func collectionChip(label: String, id: UUID?, accentIndex: Int) -> some View {
        let isSelected = selectedCollectionID == id
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedCollectionID = id
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.75), radius: 1, y: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    BubblyIconMaterial(tint: tint)
                        .clipShape(Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(isSelected ? 0.68 : 0.24), lineWidth: isSelected ? 1.4 : 1)
                        }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid

    private var bookGrid: some View {
        Group {
            if filteredBooks.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(filteredBooks) { book in
                        epubCoverCard(book)
                    }
                }
            }
        }
    }

    private func epubCoverCard(_ book: Book) -> some View {
        VStack(spacing: 8) {
            Button {
                openReader(for: book)
            } label: {
                Group {
                    if let data = book.coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ZStack {
                            Color(libraryHex: book.coverColorHex) ?? LColors.gradientBlue

                            VStack(spacing: 6) {
                                Image("sparklybook")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(LColors.text.secondary)

                                Text(book.displayTitle)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    bookToAddToCollection = book
                } label: {
                    Label("Add to Collection", image: "folderfill")
                }

                if !collections.isEmpty {
                    Menu("Remove from Collection") {
                        ForEach(collections.filter { $0.contains(book.id) }) { collection in
                            Button(collection.name) {
                                collection.removeBook(book.id)
                                try? modelContext.save()
                            }
                        }
                    }
                }

                Divider()

                Button(role: .destructive) {
                    book.epubFileData = nil
                    book.epubBookmarkData = nil
                    book.epubOriginalFileName = ""
                    book.updatedAt = Date()
                    book.lastUpdated = Date()
                    try? modelContext.save()
                } label: {
                    Label("Remove EPUB", image: "xmarkwavy")
                }
            }

            Text(book.displayTitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(book.displayAuthor)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("sparklybook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundStyle(LColors.accents.secondary)

            Text(selectedCollectionID != nil ? "No ebooks in this collection" : "No ebooks yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Text("Tap + to import an EPUB file")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Button {
                showImporter = true
            } label: {
                Text("Import EPUB")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.bg)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(LGradients.header, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        importError = nil

        do {
            let urls = try result.get()
            var knownBooks = allBooks

            for url in urls {
                let fileName = url.lastPathComponent
                if knownBooks.contains(where: { $0.hasEPUB && $0.epubOriginalFileName == fileName }) {
                    continue
                }

                let meta = EPUBFileAccess.extractMetadata(from: url)

                let fallbackTitle = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                let resolvedTitle = meta.title.isEmpty ? fallbackTitle : meta.title

                if let existingBook = LibraryImportExportService.existingBookMatching(
                    title: resolvedTitle,
                    author: meta.author,
                    in: knownBooks
                ) {
                    guard !existingBook.hasEPUB else { continue }

                    try attachImportedEPUB(from: url, metadata: meta, fallbackTitle: resolvedTitle, to: existingBook)
                } else {
                    let book = Book(
                        title: resolvedTitle,
                        author: meta.author,
                        format: .ebook,
                        coverImageData: meta.coverImageData
                    )

                    modelContext.insert(book)
                    try EPUBFileAccess.attachEPUB(from: url, to: book)
                    knownBooks.append(book)
                }
            }

            try? modelContext.save()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func attachImportedEPUB(
        from url: URL,
        metadata: EPUBMetadata,
        fallbackTitle: String,
        to book: Book
    ) throws {
        if book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            book.title = fallbackTitle
        }

        if book.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            book.author = metadata.author
        }

        if book.coverImageData == nil {
            book.coverImageData = metadata.coverImageData
        }

        try EPUBFileAccess.attachEPUB(from: url, to: book)
    }

    private func openReader(for book: Book) {
        do {
            guard let url = try EPUBFileAccess.resolvedEPUBURL(for: book) else {
                importError = "EPUB file not found."
                return
            }

            book.epubLastOpenedAt = Date()
            book.updatedAt = Date()
            book.lastUpdated = Date()

            readerURL = url
            readerBookID = book.id
            readerLocationJSON = book.epubReaderLocation.isEmpty ? nil : book.epubReaderLocation
            appState.hideTabBar = true
            showReader = true
        } catch {
            importError = error.localizedDescription
        }
    }

    private func createCollection() {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let collection = EPUBCollection(name: trimmed, sortIndex: collections.count)
        modelContext.insert(collection)
        try? modelContext.save()
        newCollectionName = ""
    }
}

// MARK: - Add To Collection Sheet

private struct AddToCollectionSheet: View {
    let book: Book
    let collections: [EPUBCollection]
    let onAddToCollection: (EPUBCollection) -> Void
    let onCreateNew: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var showNewField = false

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Collection")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                    .padding(.top, 8)

                if collections.isEmpty && !showNewField {
                    Text("No collections yet. Create one below.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                ForEach(collections) { collection in
                    let alreadyAdded = collection.contains(book.id)

                    Button {
                        if !alreadyAdded {
                            onAddToCollection(collection)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image("folderfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LColors.accents.special)

                            Text(collection.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Spacer()

                            if alreadyAdded {
                                Image("checkwavy")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(LColors.success)
                            }
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LColors.glassSurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .opacity(alreadyAdded ? 0.5 : 1)
                }

                if showNewField {
                    HStack(spacing: 10) {
                        TextField("Collection name", text: $newName)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(LColors.glassSurface)
                            }

                        Button {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            onCreateNew(trimmed)
                            dismiss()
                        } label: {
                            Text("Add")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.bg)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(LGradients.header, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        showNewField = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)

                            Text("Create New Collection")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LColors.accents.primary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(22)
        }
    }
}

// MARK: - Manage Collections Sheet

private struct ManageCollectionsSheet: View {
    let collections: [EPUBCollection]
    let onDelete: (EPUBCollection) -> Void
    let onRename: (EPUBCollection, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var editingID: UUID?
    @State private var editName = ""

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Collections")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)

                    Spacer()

                    Button { dismiss() } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close Collections")
                }
                .padding(.top, 8)

                if collections.isEmpty {
                    Text("No collections yet.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .padding(.top, 20)
                }

                ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                    let tint = theme.palette.rotation[index % theme.palette.rotation.count]

                    HStack(spacing: 12) {
                        Image("folderfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .bubblyIconMaterial(tint: tint)

                        if editingID == collection.id {
                            TextField("Name", text: $editName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .onSubmit {
                                    let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        onRename(collection, trimmed)
                                    }
                                    editingID = nil
                                }
                        } else {
                            Text(collection.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }

                        Spacer()

                        Text("\(collection.bookIDs.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)

                        Button {
                            editingID = collection.id
                            editName = collection.name
                        } label: {
                            Image("linespencil")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .bubblyIconMaterial(tint: theme.palette.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onDelete(collection)
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .bubblyIconMaterial(tint: LColors.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LColors.glassSurface)
                            .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(tint, lineWidth: 1)
                            }
                    }
                }

                Spacer()
            }
            .padding(22)
        }
    }
}

// MARK: - Color Hex Helper

private extension Color {
    init?(libraryHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        guard cleaned.count == 6 else { return nil }

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
