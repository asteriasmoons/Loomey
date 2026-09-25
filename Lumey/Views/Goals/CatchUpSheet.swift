//
//  CatchUpSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct CatchUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    let books: [Book]
    let sessions: [ReadingSession]

    @State private var selectedBook: Book? = nil
    @State private var currentPage = ""
    @State private var readingDays = ""
    @State private var isBookPickerExpanded = false
    @State private var saveError: String? = nil
    @State private var isSaving = false

    private var availableBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    private var lastLoggedPage: Int {
        guard let selectedBook else { return 0 }
        return ReadingCatchUpService.lastLoggedPage(for: selectedBook, sessions: sessions)
    }

    private var previewResult: Result<ReadingCatchUpPreview, ReadingCatchUpError>? {
        guard let selectedBook else { return nil }

        do {
            return .success(
                try ReadingCatchUpService.makePreview(
                    lastLoggedPage: lastLoggedPage,
                    currentPage: Int(currentPage),
                    readingDays: Int(readingDays),
                    bookTotalPages: selectedBook.totalPages
                )
            )
        } catch let error as ReadingCatchUpError {
            return .failure(error)
        } catch {
            return .failure(.saveFailed)
        }
    }

    private var validPreview: ReadingCatchUpPreview? {
        guard case .success(let preview) = previewResult else { return nil }
        return preview
    }

    private var visibleValidationMessage: String? {
        if let saveError { return saveError }
        guard selectedBook != nil else { return nil }
        guard !currentPage.isEmpty || !readingDays.isEmpty else { return nil }
        guard case .failure(let error) = previewResult else { return nil }
        return error.localizedDescription
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        introductionCard
                        bookPickerCard

                        if let selectedBook {
                            catchUpInputs(for: selectedBook)
                        }

                        if let visibleValidationMessage {
                            validationCard(message: visibleValidationMessage)
                        }

                        if let preview = validPreview, let selectedBook {
                            previewCard(preview: preview, book: selectedBook)
                            sessionBreakdown(preview.sessions)
                            submitButton(preview: preview, book: selectedBook)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 44)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .lumeyDismissKeyboardOnTap()
    }
}

private struct CatchUpPreviewTile: View {
    @Environment(\.appTheme) private var theme

    let label: String
    let value: String
    let tint: Color
    var valueLineLimit: Int = 1
    var valueFontSize: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(1)

            Text(value)
                .font(.system(size: valueFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(valueLineLimit)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }
}

private extension CatchUpSheet {
    var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catch Up")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Recover reading sessions you forgot to log")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(theme.palette.raisedSurface)
                            .overlay {
                                BubblyIconMaterial(tint: theme.palette.primaryAction)
                                    .mask { Circle().strokeBorder(lineWidth: 1.2) }
                            }
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle().fill(LColors.border.nested).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    var introductionCard: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            HStack(alignment: .top, spacing: 12) {
                Image("clockwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)

                Text("Tell Lumey where you are now and how many days you read. Your missing page-based sessions will be rebuilt without adding made-up reading time.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var bookPickerCard: some View {
        GlassCard(variant: .primary, borderColor: theme.palette.secondaryAccent) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Book")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBookPickerExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image("openbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedBook?.displayTitle ?? "Select a Book")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                .lineLimit(1)

                            if let selectedBook {
                                Text(selectedBook.displayAuthor)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.82))
                                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(isBookPickerExpanded ? "chevup" : "chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                    .bubblyTileLift()
                }
                .buttonStyle(.plain)

                if isBookPickerExpanded {
                    if availableBooks.isEmpty {
                        Text("Mark a book as Reading before using Catch Up.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.vertical, showsIndicators: availableBooks.count > 4) {
                            LazyVStack(spacing: 8) {
                                ForEach(availableBooks) { book in
                                    bookSelectionRow(book)
                                }
                            }
                        }
                        .frame(height: CGFloat(min(availableBooks.count, 4)) * 56)
                        .padding(9)
                        .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
                        .bubblyTileLift()
                    }
                }
            }
        }
    }

    func bookSelectionRow(_ book: Book) -> some View {
        let isSelected = selectedBook?.id == book.id

        return Button {
            selectedBook = book
            currentPage = ""
            readingDays = ""
            saveError = nil
            withAnimation(.easeInOut(duration: 0.2)) {
                isBookPickerExpanded = false
            }
        } label: {
            HStack(spacing: 10) {
                Image(isSelected ? "checkwavy" : "flatbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.displayTitle)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .lineLimit(1)

                    Text(book.displayAuthor)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        .lineLimit(1)
                }

                Spacer()

                Text("Page \(ReadingCatchUpService.lastLoggedPage(for: book, sessions: sessions))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? theme.palette.raisedSurface : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    func catchUpInputs(for book: Book) -> some View {
        GlassCard(variant: .secondary, borderColor: theme.palette.indicators) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Reading Progress")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                HStack {
                    Text("Last Logged Page")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Spacer()

                    Text("\(lastLoggedPage)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.primaryAction)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LColors.iconContainer.primary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                )

                LumeyNumberField(
                    title: "Current Book Page",
                    text: $currentPage,
                    borderColor: theme.palette.secondaryAccent
                )
                LumeyNumberField(
                    title: "Number of Reading Days",
                    text: $readingDays,
                    borderColor: theme.palette.indicators
                )

                if book.totalPages > 0 {
                    Text("This book has \(book.totalPages) pages.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
    }

    func validationCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image("infowavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(theme.palette.indicators)
                .bubblyIconMaterial(tint: theme.palette.indicators)

            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LColors.accents.contrast, lineWidth: 1)
        )
    }

    func previewCard(preview: ReadingCatchUpPreview, book: Book) -> some View {
        GlassCard(variant: .tertiary, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        CatchUpPreviewTile(
                            label: "Last Logged Page",
                            value: "\(preview.lastLoggedPage)",
                            tint: theme.palette.rotation[0]
                        )

                        CatchUpPreviewTile(
                            label: "Current Page",
                            value: "\(preview.currentPage)",
                            tint: theme.palette.rotation[1]
                        )
                    }

                    HStack(spacing: 10) {
                        CatchUpPreviewTile(
                            label: "Missing Pages",
                            value: "\(preview.missingPages)",
                            tint: theme.palette.rotation[2]
                        )

                        CatchUpPreviewTile(
                            label: "Reading Days",
                            value: "\(preview.readingDays)",
                            tint: theme.palette.rotation[0]
                        )
                    }

                    CatchUpPreviewTile(
                        label: "Sessions Created",
                        value: "\(preview.sessions.count)",
                        tint: theme.palette.rotation[1]
                    )

                    CatchUpPreviewTile(
                        label: "Book",
                        value: book.displayTitle,
                        tint: theme.palette.rotation[2],
                        valueLineLimit: 2,
                        valueFontSize: 16
                    )
                }
            }
        }
    }

    func sessionBreakdown(_ plans: [ReadingCatchUpSessionPlan]) -> some View {
        GlassCard(variant: .elevated, borderColor: theme.palette.secondaryAccent) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Breakdown")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                ForEach(Array(plans.reversed().enumerated()), id: \.element.id) { index, plan in
                    let tint = theme.palette.rotation[index % theme.palette.rotation.count]
                    HStack(spacing: 12) {
                        Text(plan.date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Pages \(plan.startPage) to \(plan.endPage)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

                            Text("\(plan.pagesRead) pages")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                        }
                    }
                    .padding(11)
                    .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
                    .bubblyTileLift()
                }
            }
        }
    }

    func submitButton(preview: ReadingCatchUpPreview, book: Book) -> some View {
        Button {
            createSessions(preview: preview, book: book)
        } label: {
            HStack(spacing: 10) {
                Image("clockwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(isSaving ? "Creating Sessions" : "Create Catch Up Sessions")
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .opacity(isSaving ? 0.65 : 1)
    }

    func createSessions(preview: ReadingCatchUpPreview, book: Book) {
        guard !isSaving else { return }

        isSaving = true
        saveError = nil

        do {
            try ReadingCatchUpService.createSessions(
                for: book,
                preview: preview,
                existingSessions: sessions,
                modelContext: modelContext
            )
            dismiss()
        } catch {
            saveError = error.localizedDescription
            isSaving = false
        }
    }
}
