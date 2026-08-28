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

                        sectionCard(title: "Basic Info") {
                            LumeyTextField(title: "Subtitle", text: $subtitle)
                            LumeyTextField(title: "Series Name", text: $seriesName)
                            LumeyTextField(title: "Series Number", text: $seriesNumber)
                            LumeyTextField(title: "Publisher", text: $publisher)
                            LumeyTextField(title: "Publication Year", text: $publicationYear)
                            LumeyTextField(title: "ISBN", text: $isbn)
                            LumeyTextEditor(title: "Summary", text: $summary, minHeight: 100)
                            LumeyRatingPicker(title: "Rating", value: $rating)
                            LumeyCoverPicker(selectedItem: $selectedCoverItem, coverImageData: $coverImageData)
                        }
                        
                        sectionCard(title: "Reading Details") {
                            LumeyEnumPicker(title: "Status", selection: $status, options: BookStatus.allCases)
                            LumeyEnumPicker(title: "Format", selection: $format, options: BookFormat.allCases)
                            LumeyEnumPicker(title: "Ownership", selection: $ownership, options: BookOwnership.allCases)
                        }
                        
                        sectionCard(title: "Progress") {
                            LumeyNumberField(title: "Current Page", text: $currentPage)
                            LumeyNumberField(title: "Total Pages", text: $totalPages)

                            LumeyNumberField(title: "Ebook Total Pages", text: $ebookTotalPagesText)
                            LumeyNumberField(title: "Ebook Current Page", text: $ebookCurrentPageText)

                            ebookConversionPreview

                            LumeyNumberField(title: "Current Chapter", text: $currentChapter)
                            LumeyNumberField(title: "Total Chapters", text: $totalChapters)
                        }
                        
                        sectionCard(title: "Organization") {
                            LumeyTextField(title: "Genres", text: $genre)
                            LumeyTextField(title: "Moods", text: $mood)
                            LumeyTextField(title: "Topics", text: $topicsText)
                            LumeyTextField(title: "Tags", text: $tagsText)
                            LumeyTextField(title: "Tropes", text: $tropesText)
                            customFilterPicker
                        }
                        
                        sectionCard(title: "Flags") {
                            Toggle("Favorite", isOn: $isFavorite)
                                .tint(LColors.accent)
                            Toggle("Reread", isOn: $isReread)
                                .tint(LColors.accent)
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
        sectionCard(title: "Book Identity") {
            LumeyTextField(title: "Title", text: $title)
            LumeyTextField(title: "Author", text: $author)

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
                        .foregroundStyle(LColors.cardTitle)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: canGetBookDetails || isFetchingBookDetails
                                ? [LColors.accents.secondary, LColors.accents.special]
                                : [LColors.border.nestedStrong, LColors.iconContainer.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LColors.border.subtle, lineWidth: 1)
                )
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
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LColors.accents.secondary
                            )
                    )
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
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
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
    
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard(variant: .featured) {
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
                    ForEach(customFilters) { filter in
                        customFilterAssignmentChip(filter)
                    }
                }
            }
        }
    }

    private func customFilterAssignmentChip(_ filter: ReadingLibraryCustomFilter) -> some View {
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
                .foregroundStyle(isSelected ? .white : LColors.textSecondary)
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
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
        }
    }
}

struct LumeyNumberField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        LumeyTextField(title: title, text: $text)
            .keyboardType(.numberPad)
    }
}

struct LumeyTextEditor: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat
    
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
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
        }
    }
}

struct LumeyEnumPicker<Value: RawRepresentable & CaseIterable & Hashable & Identifiable>: View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: Value
    let options: Value.AllCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Menu {
                ForEach(options) { option in
                    Button(option.rawValue) {
                        selection = option
                    }
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
    let title: String
    @Binding var value: Double
    
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
                            .foregroundStyle(
                                number <= Int(value)
                                ? LColors.accents.secondary
                                : LColors.border.nestedStrong
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
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
        }
    }
}

struct LumeyCoverPicker: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var coverImageData: Data?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cover")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LColors.gradientBlue.opacity(0.28)
                        )
                    
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
                            .foregroundStyle(LColors.text.primary)
                    }
                }
                .frame(width: 72, height: 104)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text(coverImageData == nil ? "Upload Cover" : "Replace Cover")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LColors.accents.secondary
                                    )
                            )
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
