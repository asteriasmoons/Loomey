//
//  ReadingListDetailSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingListDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Bindable var list: ReadingList
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirm = false
    @State private var selectedBookForSummary: Book?
    
    private var listBooks: [(item: ReadingListItemData, book: Book)] {
        list.items.compactMap { item in
            guard let book = allBooks.first(where: { $0.id == item.bookID }) else { return nil }
            return (item, book)
        }
    }
    
    // Count a book as read when either this list item or the library book status says it is finished.
    private var effectiveCompletedCount: Int {
        listBooks.filter { entry in
            entry.item.isCompleted || entry.book.status == .finished
        }.count
    }

    private var effectiveProgressValue: Double {
        guard list.bookCount > 0 else { return 0 }
        return Double(effectiveCompletedCount) / Double(list.bookCount)
    }

    private var effectiveProgressPercentage: Int {
        Int((effectiveProgressValue * 100).rounded())
    }

    private var effectiveProgressText: String {
        "\(effectiveCompletedCount) of \(list.bookCount) read"
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        overviewCard
                        
                        if !list.listDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            descriptionCard
                        }
                        
                        booksSection
                        
                        actionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .adaptivePresentation(isPresented: $showingEditSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            AddEditReadingListSheet(list: list)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $selectedBookForSummary) { book in
            ReadingListBookSummarySheet(book: book)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .alert("Delete List?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(list)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This reading list will be permanently removed. Your books will not be affected.")
        }
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text(list.displayTitle)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                showingEditSheet = true
            } label: {
                Image("pencil")
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
            
            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
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
    
    // MARK: - Overview
    
    private var overviewCard: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(list.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(LColors.accents.secondary)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(LColors.accents.secondary, lineWidth: 1.15))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(list.displayTitle)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            ReadingGoalPill(text: list.status.rawValue)
                            
                            Text(effectiveProgressText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                if list.bookCount > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        DottedGoalProgressBar(value: effectiveProgressValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 10)
                        
                        HStack {
                            Text("\(effectiveCompletedCount) of \(list.bookCount) read")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(effectiveProgressPercentage)%")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }
                    }
                }
                
                HStack(spacing: 10) {
                    ListDetailMiniStat(title: "Books", value: "\(list.bookCount)")
                    ListDetailMiniStat(title: "Read", value: "\(effectiveCompletedCount)")
                    
                    if let days = list.daysRemaining {
                        ListDetailMiniStat(
                            title: "Due",
                            value: days >= 0 ? "\(days)d" : "Late"
                        )
                    }
                    
                    ListDetailMiniStat(
                        title: "Created",
                        value: list.createdAt.formatted(.dateTime.month(.abbreviated).day())
                    )
                }
            }
        }
    }
    
    // MARK: - Description
    
    private var descriptionCard: some View {
        GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                
                Text(list.listDescription)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Books
    
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Books")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            
            if listBooks.isEmpty {
                GlassCard(variant: .secondary) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No books in this list")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Text("Edit this list to add books from your library.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(listBooks, id: \.item.id) { entry in
                        ReadingListBookRow(
                            book: entry.book,
                            isCompleted: entry.item.isCompleted || entry.book.status == .finished,
                            onToggle: {
                                list.toggleBookCompleted(bookID: entry.book.id)
                                try? modelContext.save()
                            },
                            onOpenSummary: {
                                selectedBookForSummary = entry.book
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 10) {
            if list.status == .active && list.bookCount > 0 && effectiveCompletedCount == list.bookCount {
                Button {
                    list.status = .completed
                    try? modelContext.save()
                } label: {
                    HStack(spacing: 8) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                        Text("Mark List Complete")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule(style: .continuous).fill(LGradients.blue))
                }
                .buttonStyle(.plain)
            }
            
            Button {
                showingDeleteConfirm = true
            } label: {
                Text("Delete List")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.danger.opacity(0.12))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LColors.danger.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// MARK: - Book Row

struct ReadingListBookRow: View {
    let book: Book
    let isCompleted: Bool
    let onToggle: () -> Void
    let onOpenSummary: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            GlassCard(variant: .tertiary) {
                HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(isCompleted ? "checkwavy" : "sparkle")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(
                            isCompleted
                            ? AnyShapeStyle(LColors.accents.special)
                            : AnyShapeStyle(LColors.text.muted)
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isCompleted ? LColors.border.nested : LColors.surface.subtle.opacity(0.5))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isCompleted
                                    ? AnyShapeStyle(LColors.accents.primary)
                                    : AnyShapeStyle(LColors.border.nestedStrong),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: onOpenSummary) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(book.title)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(isCompleted ? .white.opacity(0.55) : .white)
                                .strikethrough(isCompleted, color: .white.opacity(0.3))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(book.author)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                        
                        Text(book.status.rawValue)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(LColors.iconContainer.primary))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 84)
    }
}

// MARK: - Mini Stat

struct ListDetailMiniStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
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
