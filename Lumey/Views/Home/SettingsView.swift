//
//  SettingsView.swift
//  Lumey
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LumeyLibraryExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.lumeyCSV]
    }

    var csv: String

    init(csv: String = "") {
        self.csv = csv
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let csv = String(data: data, encoding: .utf8) {
            self.csv = csv
        } else {
            self.csv = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}

private struct SettingsNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct LegacyGoodreadsCleanupPreview: Identifiable {
    let id = UUID()
    let books: [Book]
}

private struct PendingReadingStreakSettingsChange {
    let configuration: ReadingStreakConfiguration
    let affectedKinds: Set<ReadingStreakKind>
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query(sort: \ReadingStreakPreferences.updatedAt, order: .reverse)
    private var streakPreferenceRecords: [ReadingStreakPreferences]

    @State private var showGoodreadsImporter = false
    @State private var showLumeyExporter = false
    @State private var showUndoLastImportConfirm = false
    @State private var exportDocument = LumeyLibraryExportDocument()
    @State private var notice: SettingsNotice?
    @State private var goodreadsPreview: GoodreadsImportPreview?
    @State private var selectedGoodreadsCandidateIDs: Set<UUID> = []
    @State private var legacyCleanupPreview: LegacyGoodreadsCleanupPreview?
    @State private var selectedLegacyCleanupBookIDs: Set<UUID> = []
    @State private var pendingStreakChange: PendingReadingStreakSettingsChange?
    @State private var showStreakResetConfirm = false

    private var syncedBooks: [Book] {
        books.filter { $0.deletedAt == nil }
    }

    private var activeBooks: [Book] {
        syncedBooks.filter { !$0.isArchived }
    }

    private var finishedBooks: [Book] {
        activeBooks.filter { $0.status == .finished }
    }

    private var readingBooks: [Book] {
        activeBooks.filter { $0.status == .reading }
    }

    private var likelyLegacyGoodreadsImports: [Book] {
        LibraryImportExportService.likelyLegacyGoodreadsImportedBooks(from: books)
    }

    private var lastGoodreadsBatch: (id: String, importedAt: Date, count: Int)? {
        let grouped = Dictionary(grouping: books.filter {
            $0.deletedAt == nil
            && $0.importSource == LibraryImportSource.goodreads
            && !$0.importBatchID.isEmpty
        }, by: \.importBatchID)

        return grouped
            .compactMap { batchID, batchBooks -> (id: String, importedAt: Date, count: Int)? in
                let importedAt = batchBooks.compactMap(\.importedAt).max() ?? batchBooks.map(\.lastUpdated).max() ?? Date.distantPast
                return (batchID, importedAt, batchBooks.count)
            }
            .sorted { $0.importedAt > $1.importedAt }
            .first
    }

    private var streakPreferences: ReadingStreakPreferences? {
        ReadingStreakPreferences.preferredRecord(from: streakPreferenceRecords)
    }

    private var streakConfiguration: ReadingStreakConfiguration {
        streakPreferences?.configuration ?? .default
    }

    private var streakSummaries: [ReadingStreakSummary] {
        ReadingStreakEngine.summaries(
            sessions: sessions,
            preferences: streakPreferences
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        commandCenter
                        libraryPulse
                        readingStreaksSettings
                        dataVault
                        cloudKitCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showGoodreadsImporter,
                allowedContentTypes: [.lumeyCSV, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleGoodreadsImport(result)
            }
            .fileExporter(
                isPresented: $showLumeyExporter,
                document: exportDocument,
                contentType: .lumeyCSV,
                defaultFilename: exportFilename
            ) { result in
                handleExportResult(result)
            }
            .sheet(item: $goodreadsPreview) { preview in
                GoodreadsImportReviewSheet(
                    preview: preview,
                    selectedCandidateIDs: $selectedGoodreadsCandidateIDs,
                    onCancel: {
                        goodreadsPreview = nil
                        selectedGoodreadsCandidateIDs = []
                    },
                    onImport: {
                        importSelectedGoodreadsCandidates(from: preview)
                    }
                )
            }
            .sheet(item: $legacyCleanupPreview) { preview in
                LegacyGoodreadsCleanupSheet(
                    books: preview.books,
                    selectedBookIDs: $selectedLegacyCleanupBookIDs,
                    onCancel: {
                        legacyCleanupPreview = nil
                        selectedLegacyCleanupBookIDs = []
                    },
                    onDelete: {
                        deleteSelectedLegacyGoodreadsImports()
                    }
                )
            }
            .confirmationDialog(
                "Undo Last Goodreads Import?",
                isPresented: $showUndoLastImportConfirm,
                titleVisibility: .visible
            ) {
                if let lastGoodreadsBatch {
                    Button("Delete \(lastGoodreadsBatch.count) Imported Books", role: .destructive) {
                        deleteGoodreadsBatch(lastGoodreadsBatch.id)
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes only books tagged with the most recent Goodreads import batch.")
            }
            .alert("Reset Reading Streak?", isPresented: $showStreakResetConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingStreakChange = nil
                }

                Button("Reset & Save", role: .destructive) {
                    savePendingStreakChange()
                }
            } message: {
                Text("Changing this setting will start a new streak because your consistency schedule is changing. Your longest streak will be preserved, but your current streak will reset. This cannot be undone.")
            }
            .alert(item: $notice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - Sections

private extension SettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Your Lumey control room")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var commandCenter: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("settingswavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(LGradients.header))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library Ops")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(activeBooks.count) active books moving through iCloud")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    SettingsSignalPill(title: "Reading", value: "\(readingBooks.count)")
                    SettingsSignalPill(title: "Finished", value: "\(finishedBooks.count)")
                    SettingsSignalPill(title: "Saved", value: "\(syncedBooks.count)")
                }
            }
        }
    }

    var libraryPulse: some View {
        HStack(spacing: 12) {
            SettingsMetricCard(
                title: "Active",
                value: "\(activeBooks.count)",
                iconName: "books"
            )

            SettingsMetricCard(
                title: "Archive",
                value: "\(syncedBooks.count - activeBooks.count)",
                iconName: "folderfill"
            )
        }
    }

    var readingStreaksSettings: some View {
        ReadingStreakSettingsSection(
            configuration: streakConfiguration,
            summaries: streakSummaries,
            onChange: requestStreakConfigurationChange
        )
    }

    var dataVault: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Data Vault")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            SettingsActionCard(
                title: "Import Goodreads",
                subtitle: "Review CSV rows first. Likely duplicates are off by default.",
                iconName: "upload",
                gradientColors: [LColors.gradientBlue, LColors.gradientPurple]
            ) {
                showGoodreadsImporter = true
            }

            SettingsActionCard(
                title: "Export Lumey",
                subtitle: "Save your Lumey library as a clean CSV file",
                iconName: "exportfill",
                gradientColors: [LColors.gradientYellow, LColors.gradientBlue]
            ) {
                prepareLumeyExport()
            }

            if let lastGoodreadsBatch {
                SettingsActionCard(
                    title: "Undo Last Goodreads Import",
                    subtitle: "Delete \(lastGoodreadsBatch.count) books from the most recent tagged batch",
                    iconName: "reset",
                    gradientColors: [LColors.gradientPink, LColors.gradientPurple]
                ) {
                    showUndoLastImportConfirm = true
                }
            }

            if !likelyLegacyGoodreadsImports.isEmpty {
                SettingsActionCard(
                    title: "Review Recent Import Cleanup",
                    subtitle: "Preview \(likelyLegacyGoodreadsImports.count) likely books from the broken untagged import",
                    iconName: "trash",
                    gradientColors: [LColors.gradientPink, LColors.gradientBlue]
                ) {
                    legacyCleanupPreview = LegacyGoodreadsCleanupPreview(books: likelyLegacyGoodreadsImports)
                    selectedLegacyCleanupBookIDs = Set(likelyLegacyGoodreadsImports.map(\.id))
                }
            }
        }
    }

    var cloudKitCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                Image("cloudmind")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().strokeBorder(LColors.glassBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    Text("CloudKit Library")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Confirmed imports become normal Lumey books with a Goodreads batch tag, so future batch undo deletes exactly that import and syncs through iCloud.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Actions

private extension SettingsView {
    var exportFilename: String {
        "Lumey-Library-\(Self.filenameDateFormatter.string(from: Date()))"
    }

    func handleGoodreadsImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let preview = try LibraryImportExportService.previewGoodreadsImport(
                from: url,
                existingBooks: books
            )

            goodreadsPreview = preview
            selectedGoodreadsCandidateIDs = preview.defaultSelectedIDs
        } catch {
            notice = SettingsNotice(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    func importSelectedGoodreadsCandidates(from preview: GoodreadsImportPreview) {
        let selectedCandidates = preview.candidates.filter {
            selectedGoodreadsCandidateIDs.contains($0.id)
        }

        guard !selectedCandidates.isEmpty else {
            notice = SettingsNotice(
                title: "Nothing Imported",
                message: "No Goodreads rows were selected."
            )
            return
        }

        do {
            for candidate in selectedCandidates {
                let book = candidate.draft.makeBook(batchID: preview.id, importedAt: preview.importedAt)
                modelContext.insert(book)

                let privateNotes = candidate.draft.privateNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                if !privateNotes.isEmpty {
                    modelContext.insert(BookNote(content: privateNotes, book: book))
                }

                let review = candidate.draft.review.trimmingCharacters(in: .whitespacesAndNewlines)
                if !review.isEmpty {
                    modelContext.insert(
                        BookReview(
                            title: "Goodreads Review",
                            content: review,
                            rating: candidate.draft.rating,
                            book: book
                        )
                    )
                }
            }

            try modelContext.save()

            let duplicateCount = preview.candidates.count - selectedCandidates.count
            goodreadsPreview = nil
            selectedGoodreadsCandidateIDs = []
            notice = SettingsNotice(
                title: "Goodreads Imported",
                message: "Created \(selectedCandidates.count) Lumey book cards. Left \(duplicateCount) unselected or duplicate rows untouched."
            )
        } catch {
            notice = SettingsNotice(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    func prepareLumeyExport() {
        do {
            let csv = try LibraryImportExportService.lumeyExportCSV(from: books)
            exportDocument = LumeyLibraryExportDocument(csv: csv)
            showLumeyExporter = true
        } catch {
            notice = SettingsNotice(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            notice = SettingsNotice(
                title: "Lumey Exported",
                message: "Your library CSV is ready."
            )
        case .failure(let error):
            notice = SettingsNotice(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    func requestStreakConfigurationChange(
        _ configuration: ReadingStreakConfiguration,
        affectedKinds: Set<ReadingStreakKind>
    ) {
        let normalized = configuration.normalized()
        guard normalized != streakConfiguration.normalized(), !affectedKinds.isEmpty else { return }

        pendingStreakChange = PendingReadingStreakSettingsChange(
            configuration: normalized,
            affectedKinds: affectedKinds
        )
        showStreakResetConfirm = true
    }

    func savePendingStreakChange() {
        guard let pendingStreakChange else { return }

        let preferences = ReadingStreakPreferences.fetchOrCreate(in: modelContext)
        let currentSummaries = ReadingStreakEngine.summaries(
            sessions: sessions,
            preferences: preferences
        )
        let now = Date()

        for kind in pendingStreakChange.affectedKinds {
            let currentLongest = currentSummaries.first { $0.kind == kind }?.longest ?? 0

            switch kind {
            case .daily:
                break
            case .weekend:
                preferences.preservedLongestWeekendStreak = max(
                    preferences.preservedLongestWeekendStreak,
                    currentLongest
                )
                preferences.weekendCurrentResetAt = now
            case .weekly:
                preferences.preservedLongestWeeklyStreak = max(
                    preferences.preservedLongestWeeklyStreak,
                    currentLongest
                )
                preferences.weeklyCurrentResetAt = now
            case .monthly:
                preferences.preservedLongestMonthlyStreak = max(
                    preferences.preservedLongestMonthlyStreak,
                    currentLongest
                )
                preferences.monthlyCurrentResetAt = now
            }
        }

        preferences.applyConfiguration(pendingStreakChange.configuration)
        self.pendingStreakChange = nil
        try? modelContext.save()
    }

    func deleteGoodreadsBatch(_ batchID: String) {
        let batchBooks = books.filter {
            $0.importSource == LibraryImportSource.goodreads
            && $0.importBatchID == batchID
        }

        for book in batchBooks {
            modelContext.delete(book)
        }

        do {
            try modelContext.save()
            notice = SettingsNotice(
                title: "Import Undone",
                message: "Deleted \(batchBooks.count) books from the last Goodreads import batch."
            )
        } catch {
            notice = SettingsNotice(
                title: "Undo Failed",
                message: error.localizedDescription
            )
        }
    }

    func deleteSelectedLegacyGoodreadsImports() {
        let selectedBooks = books.filter {
            selectedLegacyCleanupBookIDs.contains($0.id)
        }

        for book in selectedBooks {
            modelContext.delete(book)
        }

        do {
            try modelContext.save()
            legacyCleanupPreview = nil
            selectedLegacyCleanupBookIDs = []
            notice = SettingsNotice(
                title: "Cleanup Complete",
                message: "Deleted \(selectedBooks.count) selected books from the recent untagged Goodreads import."
            )
        } catch {
            notice = SettingsNotice(
                title: "Cleanup Failed",
                message: error.localizedDescription
            )
        }
    }

    static var filenameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

// MARK: - Review Sheets

private struct GoodreadsImportReviewSheet: View {
    let preview: GoodreadsImportPreview
    @Binding var selectedCandidateIDs: Set<UUID>
    let onCancel: () -> Void
    let onImport: () -> Void

    private var selectedCount: Int {
        preview.candidates.filter { selectedCandidateIDs.contains($0.id) }.count
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                reviewHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        summaryCard

                        ForEach(preview.candidates) { candidate in
                            GoodreadsCandidateRow(
                                candidate: candidate,
                                isSelected: selectedCandidateIDs.contains(candidate.id)
                            ) {
                                toggle(candidate)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 26)
                }
            }
        }
    }

    private var reviewHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review Import")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(selectedCount) selected of \(preview.candidates.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                onImport()
            } label: {
                Text("Import \(selectedCount)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(LGradients.header))
            }
            .buttonStyle(.plain)
            .disabled(selectedCount == 0)
            .opacity(selectedCount == 0 ? 0.45 : 1)

            Button(action: onCancel) {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LColors.bg))
                    .overlay(Circle().strokeBorder(LGradients.header, lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private var summaryCard: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Likely duplicates are off by default")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(preview.duplicateCount) possible duplicates found. \(preview.skippedInvalidRows) invalid rows skipped before review.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func toggle(_ candidate: GoodreadsImportCandidate) {
        if selectedCandidateIDs.contains(candidate.id) {
            selectedCandidateIDs.remove(candidate.id)
        } else {
            selectedCandidateIDs.insert(candidate.id)
        }
    }
}

private struct GoodreadsCandidateRow: View {
    let candidate: GoodreadsImportCandidate
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(isSelected ? "checkwavy" : "addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(isSelected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.textSecondary))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(candidate.draft.title)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if candidate.isLikelyDuplicate {
                            Text("Possible Duplicate")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule(style: .continuous).fill(LColors.gradientYellow))
                        }
                    }

                    Text(candidate.draft.author.isEmpty ? "Unknown Author" : candidate.draft.author)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Text(candidateDetailText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.85))

                    if let match = candidate.duplicateMatches.first {
                        Text("Matches \(match.title) by \(match.author): \(match.reason)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.gradientYellow)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? LColors.glassSurface2 : Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? LColors.gradientBlue.opacity(0.8) : Color.white.opacity(0.10),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var candidateDetailText: String {
        var details = [candidate.draft.status.rawValue, candidate.draft.format.rawValue]

        if !candidate.draft.isbn.isEmpty {
            details.append(candidate.draft.isbn)
        }

        if candidate.draft.totalPages > 0 {
            details.append("\(candidate.draft.totalPages) pages")
        }

        return details.joined(separator: " | ")
    }
}

private struct LegacyGoodreadsCleanupSheet: View {
    let books: [Book]
    @Binding var selectedBookIDs: Set<UUID>
    let onCancel: () -> Void
    let onDelete: () -> Void

    private var selectedCount: Int {
        books.filter { selectedBookIDs.contains($0.id) }.count
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                cleanupHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        GlassCard(cornerRadius: 20, padding: 16) {
                            Text("These are only likely matches from the recent untagged import. Uncheck anything you want to keep before deleting.")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(books) { book in
                            LegacyCleanupBookRow(
                                book: book,
                                isSelected: selectedBookIDs.contains(book.id)
                            ) {
                                toggle(book)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 26)
                }
            }
        }
    }

    private var cleanupHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cleanup Preview")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(selectedCount) selected of \(books.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Text("Delete \(selectedCount)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(LColors.gradientPink))
            }
            .buttonStyle(.plain)
            .disabled(selectedCount == 0)
            .opacity(selectedCount == 0 ? 0.45 : 1)

            Button(action: onCancel) {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LColors.bg))
                    .overlay(Circle().strokeBorder(LGradients.header, lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private func toggle(_ book: Book) {
        if selectedBookIDs.contains(book.id) {
            selectedBookIDs.remove(book.id)
        } else {
            selectedBookIDs.insert(book.id)
        }
    }
}

private struct LegacyCleanupBookRow: View {
    let book: Book
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(isSelected ? "checkwavy" : "addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(isSelected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.textSecondary))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.displayTitle)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(book.displayAuthor)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Text("\(book.status.rawValue) | \(book.format.rawValue) | \(book.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.85))
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? LColors.glassSurface2 : Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? LColors.gradientPink.opacity(0.8) : Color.white.opacity(0.10),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Components

private struct ReadingStreakSettingsSection: View {
    let configuration: ReadingStreakConfiguration
    let summaries: [ReadingStreakSummary]
    let onChange: (ReadingStreakConfiguration, Set<ReadingStreakKind>) -> Void

    private var normalizedConfiguration: ReadingStreakConfiguration {
        configuration.normalized()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reading Streaks")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            dailyCard
            weekendCard
            weeklyCard
            monthlyCard
        }
    }

    private var dailyCard: some View {
        StreakSettingsCard(
            title: "Daily Reading Streak",
            subtitle: "Counts any day with a timed session, manual session, or goal check-in.",
            iconName: ReadingStreakKind.daily.iconName,
            summary: summary(for: .daily)
        )
    }

    private var weekendCard: some View {
        StreakSettingsCard(
            title: "Weekend Reading Streak",
            subtitle: "Your weekend is complete when both selected consecutive days have reading activity.",
            iconName: ReadingStreakKind.weekend.iconName,
            summary: summary(for: .weekend)
        ) {
            VStack(alignment: .leading, spacing: 13) {
                Text("Current Weekend: \(normalizedConfiguration.weekendDay1.fullName) + \(normalizedConfiguration.weekendDay2.fullName)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                weekdaySelector(
                    title: "Weekend Day 1",
                    selectedDay: normalizedConfiguration.weekendDay1,
                    enabledDay: nil
                ) { day in
                    var next = normalizedConfiguration
                    next.weekendDay1 = day
                    next.weekendDay2 = day.nextDay
                    onChange(next, [.weekend])
                }

                weekdaySelector(
                    title: "Weekend Day 2",
                    selectedDay: normalizedConfiguration.weekendDay2,
                    enabledDay: normalizedConfiguration.weekendDay1.nextDay
                ) { day in
                    guard ReadingStreakConfiguration.areConsecutive(
                        day1: normalizedConfiguration.weekendDay1,
                        day2: day
                    ) else { return }
                    var next = normalizedConfiguration
                    next.weekendDay2 = day
                    onChange(next, [.weekend])
                }
            }
        }
    }

    private var weeklyCard: some View {
        StreakSettingsCard(
            title: "Weekly Reading Streak",
            subtitle: "Each calendar week counts when you read on your chosen weekday.",
            iconName: ReadingStreakKind.weekly.iconName,
            summary: summary(for: .weekly)
        ) {
            weekdaySelector(
                title: "Reading Day",
                selectedDay: normalizedConfiguration.weeklyReadingDay,
                enabledDay: nil
            ) { day in
                var next = normalizedConfiguration
                next.weeklyReadingDay = day
                onChange(next, [.weekly])
            }
        }
    }

    private var monthlyCard: some View {
        StreakSettingsCard(
            title: "Monthly Reading Streak",
            subtitle: "Read on your chosen day each month. Shorter months automatically use their final day.",
            iconName: ReadingStreakKind.monthly.iconName,
            summary: summary(for: .monthly)
        ) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Reading Day of Month")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7),
                    spacing: 7
                ) {
                    ForEach(1...31, id: \.self) { day in
                        numberOption(
                            value: day,
                            isSelected: normalizedConfiguration.monthlyReadingDay == day
                        ) {
                            var next = normalizedConfiguration
                            next.monthlyReadingDay = day
                            onChange(next, [.monthly])
                        }
                    }
                }
            }
        }
    }

    private func summary(for kind: ReadingStreakKind) -> ReadingStreakSummary {
        summaries.first { $0.kind == kind }
        ?? ReadingStreakSummary(kind: kind, current: 0, longest: 0, detail: "")
    }

    private func weekdaySelector(
        title: String,
        selectedDay: ReadingWeekday,
        enabledDay: ReadingWeekday?,
        action: @escaping (ReadingWeekday) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            HStack(spacing: 6) {
                ForEach(ReadingWeekday.allCases) { day in
                    let isEnabled = enabledDay == nil || enabledDay == day

                    Button {
                        guard isEnabled else { return }
                        action(day)
                    } label: {
                        Text(day.shortName)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(selectedDay == day ? LColors.bg : LColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        selectedDay == day
                                        ? AnyShapeStyle(LGradients.header)
                                        : AnyShapeStyle(LColors.glassSurface)
                                    )
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        isEnabled ? LColors.glassBorder : Color.white.opacity(0.06),
                                        lineWidth: 1
                                    )
                            )
                            .opacity(isEnabled ? 1 : 0.32)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                }
            }
        }
    }

    private func numberOption(value: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? LColors.bg : LColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.glassSurface))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? Color.white.opacity(0.16) : LColors.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct StreakSettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let iconName: String
    let summary: ReadingStreakSummary
    let content: Content

    init(
        title: String,
        subtitle: String,
        iconName: String,
        summary: ReadingStreakSummary,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.summary = summary
        self.content = content()
    }

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().strokeBorder(LGradients.header, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    SettingsSignalPill(title: "Current", value: "\(summary.current)")
                    SettingsSignalPill(title: "Longest", value: "\(summary.longest)")
                }

                content
            }
        }
    }
}

private struct SettingsSignalPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct SettingsMetricCard: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            HStack(spacing: 12) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.06)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct SettingsActionCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LColors.glassSurface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                LColors.gradientBlue.opacity(0.72),
                                LColors.gradientPurple.opacity(0.72),
                                Color.white.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
