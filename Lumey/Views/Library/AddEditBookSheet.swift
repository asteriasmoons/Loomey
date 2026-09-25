//
//  AddEditBookSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditBookSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @Query(sort: \ReadingLibraryCustomFilter.sortIndex)
    private var customFilters: [ReadingLibraryCustomFilter]
    
    let book: Book?
    let onSave: (Book) -> Void
    
    @State private var title = ""
    @State private var author = ""
    @State private var subtitle = ""
    @State private var seriesName = ""
    @State private var seriesNumber = ""
    @State private var publisher = ""
    @State private var publicationYear = ""
    @State private var isbn = ""
    @State private var summary = ""
    @State private var rating = 0.0
    @State private var status: BookStatus = .toBeRead
    @State private var format: BookFormat = .physical
    @State private var ownership: BookOwnership = .owned
    @State private var currentPage = ""
    @State private var totalPages = ""
    @State private var currentChapter = ""
    @State private var totalChapters = ""
    @State private var genre = ""
    @State private var mood = ""
    @State private var isFavorite = false
    @State private var isReread = false
    @State private var selectedCoverItem: PhotosPickerItem? = nil
    @State private var coverImageData: Data? = nil
    @State private var tagsText = ""
    @State private var tropesText = ""
    @State private var topicsText = ""
    @State private var selectedCustomFilterIDs: Set<UUID> = []
    @State private var ebookTotalPagesText = ""
    @State private var ebookCurrentPageText = ""
    @State private var isFetchingBookDetails = false
    @State private var bookDetailsMessage: String? = nil
    @State private var bookDetailsError: String? = nil
    
    private var isEditing: Bool {
        book != nil
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        bookIdentityCard

                        sectionCard(title: "Basic Info", accentIndex: 1) {
                            LumeyTextField(title: "Subtitle", text: $subtitle, borderColor: theme.palette.primaryAction)
                            LumeyTextField(title: "Series Name", text: $seriesName, borderColor: theme.palette.secondaryAccent)
                            LumeyTextField(title: "Series Number", text: $seriesNumber, borderColor: theme.palette.indicators)
                            LumeyTextField(title: "Publisher", text: $publisher, borderColor: theme.palette.primaryAction)
                            LumeyTextField(title: "Publication Year", text: $publicationYear, borderColor: theme.palette.secondaryAccent)
                            LumeyTextField(title: "ISBN", text: $isbn, borderColor: theme.palette.indicators)
                            LumeyTextEditor(title: "Summary", text: $summary, minHeight: 100, borderColor: theme.palette.primaryAction)
                            LumeyRatingPicker(title: "Rating", value: $rating, tint: theme.palette.primaryAction)
                            LumeyCoverPicker(
                                selectedItem: $selectedCoverItem,
                                coverImageData: $coverImageData,
                                tint: theme.palette.secondaryAccent
                            )
                        }
                        
                        sectionCard(title: "Reading Details", accentIndex: 2) {
                            LumeyEnumPicker(title: "Status", selection: $status, options: BookStatus.allCases, tint: theme.palette.primaryAction)
                            LumeyEnumPicker(title: "Format", selection: $format, options: BookFormat.allCases, tint: theme.palette.secondaryAccent)
                            LumeyEnumPicker(title: "Ownership", selection: $ownership, options: BookOwnership.allCases, tint: theme.palette.indicators)
                        }
                        
                        sectionCard(title: "Progress", accentIndex: 3) {
                            LumeyNumberField(title: "Current Page", text: $currentPage, borderColor: theme.palette.primaryAction)
                            LumeyNumberField(title: "Total Pages", text: $totalPages, borderColor: theme.palette.secondaryAccent)

                            LumeyNumberField(title: "Ebook Total Pages", text: $ebookTotalPagesText, borderColor: theme.palette.indicators)
                            LumeyNumberField(title: "Ebook Current Page", text: $ebookCurrentPageText, borderColor: theme.palette.primaryAction)

                            ebookConversionPreview

                            LumeyNumberField(title: "Current Chapter", text: $currentChapter, borderColor: theme.palette.secondaryAccent)
                            LumeyNumberField(title: "Total Chapters", text: $totalChapters, borderColor: theme.palette.indicators)
                        }
                        
                        sectionCard(title: "Organization", accentIndex: 4) {
                            LumeyTextField(title: "Genres", text: $genre, borderColor: theme.palette.primaryAction)
                            LumeyTextField(title: "Moods", text: $mood, borderColor: theme.palette.secondaryAccent)
                            LumeyTextField(title: "Topics", text: $topicsText, borderColor: theme.palette.indicators)
                            LumeyTextField(title: "Tags", text: $tagsText, borderColor: theme.palette.primaryAction)
                            LumeyTextField(title: "Tropes", text: $tropesText, borderColor: theme.palette.secondaryAccent)
                            customFilterPicker
                        }
                        
                        sectionCard(title: "Flags", accentIndex: 5) {
                            LumeyIconToggle(
                                title: "Favorite",
                                iconName: "heartfill",
                                isOn: $isFavorite,
                                tint: theme.palette.primaryAction
                            )
                            LumeyIconToggle(
                                title: "Reread",
                                iconName: "repeat",
                                isOn: $isReread,
                                tint: theme.palette.secondaryAccent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .lumeyDismissKeyboardOnTap()
        .onAppear {
            loadBook()
        }
        .onChange(of: book?.id) { _, _ in
            loadBook()
        }
    }

    private var canGetBookDetails: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isFetchingBookDetails
    }

    private var bookIdentityCard: some View {
        sectionCard(title: "Book Identity", accentIndex: 0) {
            LumeyTextField(title: "Title", text: $title, borderColor: theme.palette.primaryAction)
            LumeyTextField(title: "Author", text: $author, borderColor: theme.palette.secondaryAccent)

            Button {
                getBookDetails()
            } label: {
                HStack(spacing: 10) {
                    if isFetchingBookDetails {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.82)
                    } else {
                        Image("sparklesearch")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.white)
                    }

                    Text(isFetchingBookDetails ? "Getting Details..." : "Get Details")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.textPrimary)
                        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background { BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 14) }
                .bubblyTileLift()
                .opacity(canGetBookDetails || isFetchingBookDetails ? 1 : 0.45)
            }
            .buttonStyle(.plain)
            .disabled(!canGetBookDetails)

            if let bookDetailsMessage {
                bookDetailsStatusCard(
                    message: bookDetailsMessage,
                    assetName: "checkwavy",
                    tint: LColors.gradientBlue
                )
            }

            if let bookDetailsError {
                bookDetailsStatusCard(
                    message: bookDetailsError,
                    assetName: "infowavy",
                    tint: LColors.gradientPink
                )
            }
        }
    }

    private func bookDetailsStatusCard(
        message: String,
        assetName: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(tint)
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LColors.surface.nestedSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Edit Book" : "Add Book")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                
                Text(isEditing ? "Update this book in your library" : "Add a new book to your library")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                saveBook()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
                    .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background {
                        BubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            .clipShape(Capsule(style: .continuous))
                    }
            }
            .buttonStyle(.plain)
            
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

    // MARK: - Ebook Conversion Preview

    @ViewBuilder
    private var ebookConversionPreview: some View {
        let ebookTotal = Int(ebookTotalPagesText) ?? 0
        let ebookCurrent = Int(ebookCurrentPageText) ?? 0
        let physicalTotal = Int(totalPages) ?? 0

        if ebookTotal > 0 && physicalTotal > 0 && ebookCurrent > 0 {
            let ratio = Double(ebookCurrent) / Double(ebookTotal)
            let physicalEquiv = min(Int(round(ratio * Double(physicalTotal))), physicalTotal)

            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LColors.accents.contrast)

                Text("Ebook pg \(ebookCurrent) ≈ Physical pg \(physicalEquiv) / \(physicalTotal)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LColors.gradientBlue.opacity(0.08)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LColors.gradientBlue.opacity(0.25),
                        lineWidth: 1
                    )
            )
        } else if ebookTotal > 0 && physicalTotal == 0 {
            Text("Enter Total Pages (physical) to enable conversion")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.muted)
                .italic()
        }
    }

    @ViewBuilder
    private var customFilterPicker: some View {
        if !customFilters.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Filters")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(Array(customFilters.enumerated()), id: \.element.id) { index, filter in
                        customFilterAssignmentChip(
                            filter,
                            tint: theme.palette.rotation[index % theme.palette.rotation.count]
                        )
                    }
                }
            }
        }
    }

    private func customFilterAssignmentChip(
        _ filter: ReadingLibraryCustomFilter,
        tint: Color
    ) -> some View {
        let isSelected = selectedCustomFilterIDs.contains(filter.id)

        return Button {
            if isSelected {
                selectedCustomFilterIDs.remove(filter.id)
            } else {
                selectedCustomFilterIDs.insert(filter.id)
            }
        } label: {
            Text(filter.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(tint)
                .bubblyIconMaterial(tint: tint)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? LColors.gradientPurple : LColors.surface.subtle.opacity(0.6))
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
    }
    
    private func loadBook() {
        guard let book else { return }

        title = book.title
        author = book.author
        subtitle = book.subtitle
        seriesName = book.seriesName
        seriesNumber = book.seriesNumber
        publisher = book.publisher
        publicationYear = book.publicationYear
        isbn = book.isbn
        summary = book.summary
        rating = book.rating
        status = book.status
        format = book.format
        ownership = book.ownership

        currentPage = book.currentPage == 0 ? "" : String(book.currentPage)
        totalPages = book.totalPages == 0 ? "" : String(book.totalPages)
        currentChapter = book.currentChapter == 0 ? "" : String(book.currentChapter)
        totalChapters = book.totalChapters == 0 ? "" : String(book.totalChapters)

        genre = book.genres.joined(separator: ", ")
        mood = book.moods.joined(separator: ", ")
        isFavorite = book.isFavorite
        isReread = book.isReread
        coverImageData = book.coverImageData
        tagsText = book.tags.joined(separator: ", ")
        tropesText = book.tropes.joined(separator: ", ")
        topicsText = book.topics.joined(separator: ", ")
        selectedCustomFilterIDs = Set(book.customFilterIDs)
        ebookTotalPagesText = book.ebookTotalPages == 0 ? "" : String(book.ebookTotalPages)
        ebookCurrentPageText = book.ebookCurrentPage == 0 ? "" : String(book.ebookCurrentPage)
        bookDetailsMessage = nil
        bookDetailsError = nil
    }

    private func getBookDetails() {
        guard canGetBookDetails else { return }

        isFetchingBookDetails = true
        bookDetailsMessage = nil
        bookDetailsError = nil

        Task {
            do {
                let details = try await BookDetailsEnrichmentService.shared.enrich(
                    title: title,
                    author: author
                )
                applyBookDetails(details)
                bookDetailsMessage = "Details added from \(details.source). Categories were refreshed."
            } catch {
                bookDetailsError = error.localizedDescription
            }

            isFetchingBookDetails = false
        }
    }

    private func applyBookDetails(_ details: BookDetailsEnrichmentResponse) {
        subtitle = fillBlank(subtitle, with: details.subtitle)
        seriesName = fillBlank(seriesName, with: details.seriesName)
        seriesNumber = fillBlank(seriesNumber, with: details.seriesNumber)
        publisher = fillBlank(publisher, with: details.publisher)
        publicationYear = fillBlank(publicationYear, with: details.publicationYear)
        isbn = fillBlank(isbn, with: details.isbn)
        summary = fillBlank(summary, with: details.summary)
        totalPages = fillBlank(totalPages, with: details.totalPages)
        ebookTotalPagesText = fillBlank(ebookTotalPagesText, with: details.ebookTotalPages)
        totalChapters = fillBlank(totalChapters, with: details.totalChapters)

        genre = details.genres.joined(separator: ", ")
        mood = details.moods.joined(separator: ", ")
        topicsText = details.topics.joined(separator: ", ")
        tagsText = details.tags.joined(separator: ", ")
        tropesText = details.tropes.joined(separator: ", ")
    }

    private func fillBlank(_ currentValue: String, with value: String?) -> String {
        guard currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let value,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return currentValue }

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fillBlank(_ currentValue: String, with value: Int?) -> String {
        guard currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let value,
              value > 0
        else { return currentValue }

        return String(value)
    }
    
    private func commaSeparatedValues(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func saveBook() {
        let targetBook = book ?? Book()
        let previousStatus = targetBook.status
        targetBook.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.subtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.seriesName = seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.seriesNumber = seriesNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.publisher = publisher.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.publicationYear = publicationYear.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.isbn = isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        targetBook.rating = rating
        targetBook.format = format
        targetBook.ownership = ownership
        targetBook.currentPage = Int(currentPage) ?? 0
        targetBook.totalPages = Int(totalPages) ?? 0
        targetBook.currentChapter = Int(currentChapter) ?? 0
        targetBook.totalChapters = Int(totalChapters) ?? 0
        targetBook.genres = commaSeparatedValues(genre)
        targetBook.moods = commaSeparatedValues(mood)
        targetBook.isFavorite = isFavorite
        targetBook.isReread = isReread
        targetBook.lastUpdated = Date()
        targetBook.coverImageData = coverImageData
        targetBook.tags = commaSeparatedValues(tagsText)
        targetBook.tropes = commaSeparatedValues(tropesText)
        targetBook.topics = commaSeparatedValues(topicsText)
        targetBook.customFilterIDs = Array(selectedCustomFilterIDs)

        targetBook.ebookTotalPages = Int(ebookTotalPagesText) ?? 0
        targetBook.ebookCurrentPage = Int(ebookCurrentPageText) ?? 0

        // Auto-convert ebook page to physical if both totals are set
        if targetBook.ebookTotalPages > 0 && targetBook.totalPages > 0 {
            targetBook.currentPage = targetBook.convertedPhysicalPage(from: targetBook.ebookCurrentPage)
        }

        if previousStatus == status {
            targetBook.status = status
        } else {
            targetBook.updateStatus(to: status)
        }
        
        onSave(targetBook)
        ReadingXPService.awardBookStatusChange(
            book: targetBook,
            previousStatus: previousStatus,
            newStatus: targetBook.status,
            modelContext: modelContext
        )
        dismiss()
    }
}

// MARK: - Sheet Controls

struct LumeyTextField: View {
    let title: String
    @Binding var text: String
    var borderColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            TextField(title, text: $text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .tint(LColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor ?? LColors.border.nestedStrong, lineWidth: 1)
                )
        }
    }
}

struct LumeyNumberField: View {
    let title: String
    @Binding var text: String
    var borderColor: Color? = nil
    
    var body: some View {
        LumeyTextField(title: title, text: $text, borderColor: borderColor)
            .keyboardType(.numberPad)
    }
}

struct LumeyTextEditor: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat
    var borderColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            TextEditor(text: $text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .tint(LColors.accent)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .frame(minHeight: minHeight)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor ?? LColors.border.nestedStrong, lineWidth: 1)
                )
        }
    }
}

struct LumeyEnumPicker<Value: RawRepresentable & CaseIterable & Hashable & Identifiable>: View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
    @Environment(\.appTheme) private var theme

    let title: String
    @Binding var selection: Value
    let options: Value.AllCases
    var tint: Color? = nil
    @State private var isExpanded = false

    var body: some View {
        if let tint {
            customDropdown(tint: tint)
        } else {
            legacyPicker
        }
    }

    private func customDropdown(tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selection.rawValue)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(theme.palette.textPrimary)
                        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                    Spacer()

                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .bubblyIconMaterial(tint: theme.palette.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(options) { option in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selection = option
                                isExpanded = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(selection == option ? theme.palette.textPrimary : theme.palette.raisedSurface)
                                    .frame(width: 12, height: 12)
                                    .overlay {
                                        Circle()
                                            .fill(selection == option ? tint : Color.clear)
                                            .frame(width: 4, height: 4)
                                    }

                                Text(option.rawValue)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(theme.palette.textPrimary)
                                    .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)

                                Spacer()

                                if selection == option {
                                    Image("checkwavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundStyle(theme.palette.textPrimary)
                                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.palette.raisedSurface)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(9)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 16) }
                .bubblyTileLift()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var legacyPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Menu {
                ForEach(options) { option in
                    Button(option.rawValue) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image("chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(LColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
            }
        }
    }
}

struct LumeyRatingPicker: View {
    @Environment(\.appTheme) private var theme

    let title: String
    @Binding var value: Double
    var tint: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { number in
                    Button {
                        if value == Double(number) {
                            value = 0
                        } else {
                            value = Double(number)
                        }
                    } label: {
                        Image("starfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(number <= Int(value) ? (tint ?? LColors.accents.secondary) : LColors.border.nestedStrong)
                            .bubblyIconMaterial(
                                tint: number <= Int(value) ? (tint ?? theme.palette.primaryAction) : LColors.border.nestedStrong,
                                isEnabled: tint != nil
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text(value == 0 ? "No rating" : String(format: "%.0f / 5", value))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint ?? LColors.border.nestedStrong, lineWidth: 1)
            )
        }
    }
}

struct LumeyIconToggle: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let iconName: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)

                Spacer()

                ZStack(alignment: isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(isOn ? tint.opacity(0.28) : theme.palette.raisedSurface)

                    Circle()
                        .fill(theme.palette.background)
                        .frame(width: 26, height: 26)
                        .overlay {
                            Image(iconName)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)
                                .bubblyIconMaterial(tint: tint)
                        }
                        .padding(2)
                }
                .frame(width: 54, height: 30)
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(tint, lineWidth: 1.2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct LumeyCoverPicker: View {
    @Environment(\.appTheme) private var theme

    @Binding var selectedItem: PhotosPickerItem?
    @Binding var coverImageData: Data?
    var tint: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cover")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint == nil ? LColors.gradientBlue.opacity(0.28) : theme.palette.raisedSurface)
                    
                    if let coverImageData,
                       let image = UIImage(data: coverImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 104)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Image("books")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(tint ?? LColors.text.primary)
                            .bubblyIconMaterial(tint: tint ?? theme.palette.secondaryAccent, isEnabled: tint != nil)
                    }
                }
                .frame(width: 72, height: 104)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(tint ?? LColors.border.nestedStrong, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text(coverImageData == nil ? "Upload Cover" : "Replace Cover")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background {
                                BubblyTileSurface(
                                    tint: tint ?? theme.palette.secondaryAccent,
                                    cornerRadius: 999
                                )
                            }
                            .bubblyTileLift()
                    }
                    
                    if coverImageData != nil {
                        Button {
                            coverImageData = nil
                            selectedItem = nil
                        } label: {
                            Text("Remove Cover")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                coverImageData = data
            }
        }
    }
}
