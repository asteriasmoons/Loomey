//
//  ReadingBingoBoardDetailView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingBingoBoardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingBingoProgress.updatedAt, order: .reverse)
    private var progressRecords: [ReadingBingoProgress]

    let boardID: String
    let accentIndex: Int

    @State private var selectedSquare: ReadingBingoSquareDefinition?
    @State private var celebrationMessage: String?
    @State private var showingCelebration = false
    @State private var emphasizedLineIDs = Set<String>()
    @State private var actionError: String?

    private var definition: ReadingBingoBoardDefinition? {
        ReadingBingoCatalog.definition(for: boardID)
    }

    private var progressRecord: ReadingBingoProgress? {
        guard let definition else { return nil }
        return ReadingBingoProgress.preferredRecord(for: definition.id, from: progressRecords)
    }

    private var snapshot: ReadingBingoBoardSnapshot? {
        guard let definition else { return nil }
        return ReadingBingoEngine.snapshot(for: definition, progressRecord: progressRecord)
    }

    private let columnHeaders = ["B", "I", "N", "G", "O"]

    private var boardTint: Color {
        theme.palette.rotation[accentIndex % theme.palette.rotation.count]
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            if let snapshot {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header(snapshot: snapshot)
                        heroCard(snapshot: snapshot)
                        boardCard(snapshot: snapshot)
                        lineSummaryCard(snapshot: snapshot)
                        if let actionError {
                            errorCard(actionError)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
                .safeAreaPadding(.top, 18)
            } else {
                VStack(spacing: 14) {
                    Text("Board not found")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)

                    Text("This Bingo board could not be loaded.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
                .padding(24)
                .padding(.bottom, 140)
                .safeAreaPadding(.top, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedSquare) { square in
            if let snapshot {
                ReadingBingoSquareCompletionSheet(
                    boardSnapshot: snapshot,
                    tint: boardTint,
                    square: square,
                    books: books.filter { !$0.isArchived },
                    completionRecord: progressRecord?.squareStates.first(where: { $0.squareID == square.id }),
                    onComplete: { book in
                        complete(square: square, with: book)
                    },
                    onUndo: {
                        undo(square: square)
                    }
                )
            }
        }
        .completionBanner(isShowing: showingCelebration, message: celebrationMessage ?? "Challenge Complete")
    }
}

private extension ReadingBingoBoardDetailView {
    func header(snapshot: ReadingBingoBoardSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(snapshot.state.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .bubblyIconMaterial(tint: boardTint)
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
                    .bubblyIconMaterial(tint: boardTint)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LColors.bg))
                    .overlay(Circle().strokeBorder(boardTint, lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
    }

    func heroCard(snapshot: ReadingBingoBoardSnapshot) -> some View {
        GlassCard(variant: .featured, borderColor: boardTint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(snapshot.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .bubblyIconMaterial(tint: boardTint)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay(Circle().strokeBorder(boardTint, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(snapshot.state.title)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .bubblyIconMaterial(tint: boardTint)

                        Text(snapshot.description)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(snapshot.statusText)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)
                        .lineLimit(2)

                    ReadingBingoAccentProgressBar(progress: snapshot.progress, tint: boardTint)
                        .frame(height: 10)

                    HStack(spacing: 10) {
                        heroTile(title: "Squares", value: "\(snapshot.completedChallengeCount)/\(snapshot.totalChallengeCount)")
                        heroTile(title: "Bingos", value: "\(snapshot.bingoCount)")
                        heroTile(title: "Waiting", value: "\(snapshot.remainingChallengeCount)")
                    }
                }
            }
        }
    }

    func heroTile(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background { BubblyTileSurface(tint: boardTint, cornerRadius: 16) }
        .bubblyTileLift()
    }

    func boardCard(snapshot: ReadingBingoBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                ForEach(Array(columnHeaders.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .bubblyIconMaterial(tint: boardTint)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: ReadingBingoCatalog.boardSize)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(snapshot.squares) { square in
                    ReadingBingoSquareCell(
                        square: square,
                        tint: boardTint,
                        isEmphasized: !emphasizedLineIDs.isDisjoint(with: Set(square.lineIDs))
                    ) {
                        guard !square.isFreeSpace else { return }
                        actionError = nil
                        selectedSquare = square.definition
                    }
                }
            }
        }
    }

    func lineSummaryCard(snapshot: ReadingBingoBoardSnapshot) -> some View {
        GlassCard(variant: .secondary, borderColor: boardTint) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bingo Lines")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                if snapshot.earnedLineIDs.isEmpty {
                    Text("Complete any full row, column, or diagonal to earn your first Bingo.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(snapshot.lineDefinitions.filter { snapshot.earnedLineIDs.contains($0.id) }) { line in
                            Text(line.title)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background { BubblyTileSurface(tint: boardTint, cornerRadius: 999) }
                                .bubblyTileLift()
                        }
                    }

                    if let firstBingoDate = snapshot.firstBingoEarnedAt {
                        detailLabel("First Bingo", value: shortDateTime(firstBingoDate))
                    }

                    if let blackoutDate = snapshot.blackoutCompletedAt {
                        detailLabel("Blackout", value: shortDateTime(blackoutDate))
                    }
                }
            }
        }
    }

    func detailLabel(_ title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
        }
    }

    func errorCard(_ message: String) -> some View {
        GlassCard(variant: .tertiary) {
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.gradientPink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func complete(square: ReadingBingoSquareDefinition, with book: Book?) {
        do {
            let result = try ReadingBingoEngine.completeSquare(
                boardID: boardID,
                squareID: square.id,
                linkedBookID: book?.id,
                linkedBookTitle: book?.displayTitle ?? "",
                in: modelContext
            )
            selectedSquare = nil
            triggerCelebration(for: result)
        } catch {
            actionError = "The square could not be completed right now."
        }
    }

    func undo(square: ReadingBingoSquareDefinition) {
        do {
            let result = try ReadingBingoEngine.undoSquare(
                boardID: boardID,
                squareID: square.id,
                in: modelContext
            )
            selectedSquare = nil
            if !result.removedLineIDs.isEmpty {
                showCelebration("Bingo line updated")
            }
        } catch {
            actionError = "The square could not be updated right now."
        }
    }

    func triggerCelebration(for result: ReadingBingoMutationResult) {
        let newLineIDs = Set(result.newlyEarnedLineIDs)
        emphasizedLineIDs = newLineIDs

        if result.didEarnBlackout {
            showCelebration("Blackout complete")
        } else if result.newlyEarnedLineIDs.count > 1 {
            showCelebration("\(result.newlyEarnedLineIDs.count) new Bingos earned")
        } else if result.didEarnFirstBingo {
            showCelebration("BINGO!")
        } else if !result.newlyEarnedLineIDs.isEmpty {
            showCelebration("New Bingo Line")
        } else if result.completedSquare {
            showCelebration("Challenge Complete")
        }

        guard !newLineIDs.isEmpty else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            emphasizedLineIDs.subtract(newLineIDs)
        }
    }

    func showCelebration(_ message: String) {
        celebrationMessage = message
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            showingCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                showingCelebration = false
            }
        }
    }

    func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

private struct ReadingBingoSquareCell: View {
    @Environment(\.appTheme) private var theme

    let square: ReadingBingoSquareSnapshot
    let tint: Color
    let isEmphasized: Bool
    let action: () -> Void

    private let cornerRadius: CGFloat = 16

    var body: some View {
        Button(action: action) {
            ZStack {
                if square.isCompleted || square.isFreeSpace {
                    BubblyTileSurface(tint: tint, cornerRadius: cornerRadius)
                } else {
                    tileShape.fill(LColors.primarySurface)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(square.isFreeSpace ? "FREE" : square.title)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(square.isCompleted || square.isFreeSpace ? .white : LColors.primaryText)
                        .shadow(
                            color: square.isCompleted || square.isFreeSpace ? theme.palette.background.opacity(0.65) : .clear,
                            radius: 1,
                            y: 2
                        )
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .minimumScaleFactor(0.76)

                    if !square.linkedBookTitle.isEmpty {
                        Text(square.linkedBookTitle)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle((square.isCompleted || square.isFreeSpace) ? .white.opacity(0.86) : LColors.textSecondary)
                            .shadow(
                                color: square.isCompleted || square.isFreeSpace ? theme.palette.background.opacity(0.65) : .clear,
                                radius: 1,
                                y: 2
                            )
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 90, alignment: .bottomLeading)
                .padding(10)
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
            .clipShape(tileShape)
            .overlay(
                tileShape
                    .strokeBorder(tint, lineWidth: isEmphasized ? 1.8 : 1)
            )
            .contentShape(tileShape)
            .compositingGroup()
            .shadow(color: shadowColor, radius: isEmphasized ? 16 : 0, y: isEmphasized ? 8 : 0)
            .scaleEffect(isEmphasized ? 1.02 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isEmphasized)
        }
        .buttonStyle(.plain)
        .disabled(square.isFreeSpace)
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var shadowColor: Color {
        if isEmphasized {
            return tint.opacity(0.28)
        }
        return .clear
    }
}

private struct ReadingBingoSquareCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let boardSnapshot: ReadingBingoBoardSnapshot
    let tint: Color
    let square: ReadingBingoSquareDefinition
    let books: [Book]
    let completionRecord: ReadingBingoSquareStateRecord?
    let onComplete: (Book?) -> Void
    let onUndo: () -> Void

    @State private var searchText = ""
    @State private var selectedBookID: UUID?

    private var selectedBook: Book? {
        books.first { $0.id == selectedBookID }
    }

    private var filteredBooks: [Book] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let eligibleBooks = books.sorted {
            $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
        }

        guard !trimmed.isEmpty else { return eligibleBooks }
        return eligibleBooks.filter { book in
            book.displayTitle.localizedCaseInsensitiveContains(trimmed)
            || book.displayAuthor.localizedCaseInsensitiveContains(trimmed)
            || book.seriesName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var canComplete: Bool {
        square.allowsBookSelection ? selectedBook != nil : true
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(tint.opacity(0.75))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        challengeCard
                        if square.allowsBookSelection {
                            bookPickerCard
                        }
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .lumeyDismissKeyboardOnTap()
        .onAppear {
            selectedBookID = completionRecord?.linkedBookID
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(square.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(boardSnapshot.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .bubblyIconMaterial(tint: tint)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .bubblyIconMaterial(tint: tint)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(theme.palette.raisedSurface))
                    .overlay(Circle().strokeBorder(tint, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var challengeCard: some View {
        GlassCard(variant: .elevated, borderColor: tint) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Requirement")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .bubblyIconMaterial(tint: tint)

                Text(square.description)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                materialDottedDivider

                HStack(spacing: 12) {
                    statusTile(
                        title: "State",
                        value: completionRecord == nil ? "Incomplete" : "Completed"
                    )

                    statusTile(
                        title: "Book",
                        value: completionRecord?.linkedBookTitle.isEmpty == false
                        ? completionRecord?.linkedBookTitle ?? "Linked"
                        : "None"
                    )

                    statusTile(
                        title: "Date",
                        value: completionRecord.map { shortDate($0.completedAt) } ?? "Not yet"
                    )
                }
            }
        }
    }

    private func statusTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }

    private var materialDottedDivider: some View {
        HStack(spacing: 4) {
            ForEach(0..<28, id: \.self) { _ in
                Circle()
                    .frame(width: 3, height: 3)
                    .bubblyIconMaterial(tint: tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }

    private var bookPickerCard: some View {
        GlassCard(variant: .subtle, borderColor: tint) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose Book")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                if books.isEmpty {
                    Text("There are no books in your library yet to link to this Bingo square.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 10) {
                        Image("searchwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .bubblyIconMaterial(tint: tint)

                        TextField("Search library books...", text: $searchText)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.primarySurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(tint, lineWidth: 1)
                    )

                    if let selectedBook {
                        selectedBookCard(selectedBook)
                    }

                    VStack(spacing: 8) {
                        ForEach(filteredBooks.prefix(12)) { book in
                            ReadingBingoBookSelectionRow(
                                book: book,
                                isSelected: selectedBookID == book.id,
                                tint: tint
                            ) {
                                if selectedBookID == book.id {
                                    selectedBookID = nil
                                } else {
                                    selectedBookID = book.id
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func selectedBookCard(_ book: Book) -> some View {
        HStack(spacing: 12) {
            LibraryBookCover(book: book)
                .scaleEffect(0.86)
                .frame(width: 54, height: 76)

            VStack(alignment: .leading, spacing: 5) {
                Text(book.displayTitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .lineLimit(2)

                Text(book.displayAuthor)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

                Text(book.progressText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 16) }
        .bubblyTileLift()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint, lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onComplete(selectedBook)
            } label: {
                Text(completionRecord == nil ? "Complete Challenge" : "Save Completion")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        BubblyTileSurface(
                            tint: canComplete ? tint : tint.opacity(0.38),
                            cornerRadius: 16
                        )
                    }
                    .bubblyTileLift()
            }
            .buttonStyle(.plain)
            .disabled(!canComplete)

            if completionRecord != nil {
                Button {
                    onUndo()
                } label: {
                    Text("Undo Completion")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LColors.iconContainer.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(LColors.border.subtle, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

private struct ReadingBingoBookSelectionRow: View {
    @Environment(\.appTheme) private var theme

    let book: Book
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                LibraryBookCover(book: book)
                    .scaleEffect(0.72)
                    .frame(width: 46, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.displayTitle)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? .white : LColors.cardTitle)
                        .shadow(color: isSelected ? theme.palette.background.opacity(0.65) : .clear, radius: 1, y: 2)
                        .lineLimit(2)

                    Text(book.displayAuthor)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                        .shadow(color: isSelected ? theme.palette.background.opacity(0.65) : .clear, radius: 1, y: 2)
                        .lineLimit(1)

                    Text(book.status.rawValue)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                        .shadow(color: isSelected ? theme.palette.background.opacity(0.65) : .clear, radius: 1, y: 2)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image("checkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .bubblyIconMaterial(tint: tint)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.5))
                } else {
                    Circle()
                        .fill(theme.palette.raisedSurface)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().strokeBorder(tint, lineWidth: 1))
                }
            }
            .padding(10)
            .background {
                if isSelected {
                    BubblyTileSurface(tint: tint, cornerRadius: 16)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LColors.surface.subtle.opacity(0.5))
                }
            }
            .bubblyTileLift(isEnabled: isSelected)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.82) : tint, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
