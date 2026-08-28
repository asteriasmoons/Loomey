//
//  AddEditReadingListSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct AddEditReadingListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let list: ReadingList?
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    @State private var title = ""
    @State private var listDescription = ""
    @State private var iconName = "books"
    @State private var status: ReadingListStatus = .active
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedBookIDs: [UUID] = []
    @State private var manualBookTitle = ""
    @State private var manualBookAuthor = ""
    @State private var manualBookSummary = ""
    @State private var isGeneratingManualSummary = false
    @State private var manualSummaryError: String?
    
    @State private var showingIconPicker = false
    
    private var isEditing: Bool { list != nil }
    
    private var availableBooks: [Book] {
        allBooks.filter { !$0.isArchived }
    }
    
    private var availableSeries: [String] {
        let names = Set(allBooks.compactMap { book in
            let trimmed = book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        })
        return names.sorted()
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionCard(title: "List Details") {
                            LumeyTextField(title: "Title", text: $title)
                            LumeyTextEditor(title: "Description", text: $listDescription, minHeight: 80)
                        }
                        
                        sectionCard(title: "Display") {
                            GoalIconPickerRow(iconName: $iconName) {
                                showingIconPicker = true
                            }
                            
                            LumeyEnumPicker(title: "Status", selection: $status, options: ReadingListStatus.allCases)
                        }
                        
                        sectionCard(title: "Due Date") {
                            Toggle("Use Due Date", isOn: $hasDueDate)
                                .tint(LColors.accent)
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .tint(LColors.accent)
                            }
                        }
                        
                        booksSection
                        
                        seriesQuickAddSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .task(id: list?.id) { loadList() }
        .adaptivePresentation(isPresented: $showingIconPicker, useFullScreenCover: horizontalSizeClass == .regular) {
            IconPickerView(selectedIcon: $iconName)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text(isEditing ? "Edit List" : "New List")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            
            Spacer()
            
            Button { saveList() } label: {
                Text("Save")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule(style: .continuous).fill(LGradients.blue))
            }
            .buttonStyle(.plain)
            
            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
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
            Rectangle().fill(LColors.border.nested).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }
    
    // MARK: - Books Section
    
    private var booksSection: some View {
        sectionCard(title: "Books") {
            if !selectedBookIDs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(selectedBookIDs, id: \.self) { bookID in
                        if let book = availableBooks.first(where: { $0.id == bookID }) {
                            HStack(spacing: 10) {
                                Image("books")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(LColors.accents.contrast)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.cardTitle)
                                        .lineLimit(1)
                                    
                                    Text(book.author)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button {
                                    selectedBookIDs.removeAll { $0 == bookID }
                                } label: {
                                    Image("xmarkwavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(LColors.textSecondary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(LColors.iconContainer.primary))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LColors.surface.nested)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(LColors.border.nested, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            let unlinked = availableBooks.filter { !selectedBookIDs.contains($0.id) }
            
            if !unlinked.isEmpty {
                Menu {
                    ForEach(unlinked) { book in
                        Button {
                            selectedBookIDs.append(book.id)
                        } label: {
                            Text("\(book.title) — \(book.author)")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(LColors.accents.secondary)
                        
                        Text("Add Existing Book")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Spacer()
                        
                        Image("chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            manualBookEntry
        }
    }
    
    private var manualBookEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Book")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            LumeyTextField(title: "Title", text: $manualBookTitle)
            LumeyTextField(title: "Author", text: $manualBookAuthor)
            LumeyTextEditor(title: "Summary", text: $manualBookSummary, minHeight: 88)

            Button {
                Task { await generateManualSummary() }
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingManualSummary {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }

                    Text(isGeneratingManualSummary ? "Generating..." : "Get Summary")
                        .font(.system(size: 13, weight: .black, design: .rounded))

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(canGenerateManualSummary ? AnyShapeStyle(LColors.accents.contrast) : AnyShapeStyle(LColors.glassSurface2))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canGenerateManualSummary || isGeneratingManualSummary)
            .opacity(canGenerateManualSummary ? 1 : 0.55)

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
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(canAddManualBook ? AnyShapeStyle(LColors.accents.secondary) : AnyShapeStyle(LColors.glassSurface2))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAddManualBook)
            .opacity(canAddManualBook ? 1 : 0.55)
        }
        .padding(.top, 4)
    }
    
    private var canAddManualBook: Bool {
        !manualBookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !manualBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canGenerateManualSummary: Bool {
        canAddManualBook
    }

    @MainActor
    private func generateManualSummary() async {
        guard canGenerateManualSummary, !isGeneratingManualSummary else { return }

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
    
    // MARK: - Series Quick Add
    
    @ViewBuilder
    private var seriesQuickAddSection: some View {
        if !availableSeries.isEmpty {
            sectionCard(title: "Add Entire Series") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableSeries, id: \.self) { seriesName in
                            Button {
                                addSeriesBooks(seriesName)
                            } label: {
                                Text(seriesName)
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(LColors.glassSurface2)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(LColors.border.nested, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - Section Card
    
    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
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
    
    // MARK: - Load / Save
    
    private func loadList() {
        guard let list else { return }
        title = list.title
        listDescription = list.listDescription
        iconName = list.iconName
        status = list.status
        
        if let due = list.dueDate {
            dueDate = due
            hasDueDate = true
        }
        
        selectedBookIDs = list.items.map { $0.bookID }
    }
    
    private func saveList() {
        if canAddManualBook {
            addManualBook()
        }
        
        let target = list ?? ReadingList()
        let wasNew = list == nil
        
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.listDescription = listDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        target.iconName = iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "books" : iconName
        target.status = status
        target.dueDate = hasDueDate ? dueDate : nil
        
        // Preserve existing item state (completion, order) for books that remain
        let existingItems = target.items
        var newItems: [ReadingListItemData] = []
        
        for (index, bookID) in selectedBookIDs.enumerated() {
            if let existing = existingItems.first(where: { $0.bookID == bookID }) {
                var updated = existing
                updated.sortOrder = index
                newItems.append(updated)
            } else {
                newItems.append(ReadingListItemData(
                    bookID: bookID,
                    sortOrder: index,
                    dateAdded: Date()
                ))
            }
        }
        
        target.items = newItems
        target.updatedAt = Date()
        
        if wasNew {
            modelContext.insert(target)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func addManualBook() {
        let trimmedTitle = manualBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = manualBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = manualBookSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedAuthor.isEmpty else { return }
        
        let book = Book(
            title: trimmedTitle,
            author: trimmedAuthor,
            summary: trimmedSummary
        )
        modelContext.insert(book)
        selectedBookIDs.append(book.id)
        
        manualBookTitle = ""
        manualBookAuthor = ""
        manualBookSummary = ""
    }
    
    private func addSeriesBooks(_ seriesName: String) {
        let seriesBooks = availableBooks.filter {
            $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == seriesName.lowercased()
        }
        
        for book in seriesBooks {
            if !selectedBookIDs.contains(book.id) {
                selectedBookIDs.append(book.id)
            }
        }
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
