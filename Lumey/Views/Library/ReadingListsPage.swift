//
//  ReadingListsPage.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingListsPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Query(sort: \ReadingList.updatedAt, order: .reverse)
    private var allLists: [ReadingList]
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    @State private var showingAddSheet = false
    @State private var selectedList: ReadingList?
    @State private var editingList: ReadingList?
    
    private var activeLists: [ReadingList] {
        allLists.filter { $0.status != .archived }
    }
    
    private var archivedLists: [ReadingList] {
        allLists.filter { $0.status == .archived }
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    
                    if activeLists.isEmpty && archivedLists.isEmpty {
                        emptyState
                    } else {
                        if !activeLists.isEmpty {
                            activeSection
                        }
                        
                        if !archivedLists.isEmpty {
                            archivedSection
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(isPresented: $showingAddSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            AddEditReadingListSheet(list: nil)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $selectedList, useFullScreenCover: horizontalSizeClass == .regular) { list in
            ReadingListDetailSheet(list: list)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $editingList, useFullScreenCover: horizontalSizeClass == .regular) { list in
            AddEditReadingListSheet(list: list)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(alignment: .top) {
            Text("Reading Lists")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            HStack(spacing: 10) {
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

                Button {
                    showingAddSheet = true
                } label: {
                    Image("addwavy")
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
        }
    }
    
    // MARK: - Active Section
    
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                
                Spacer()
                
                Text("\(activeLists.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(activeLists.enumerated()), id: \.element.id) { index, list in
                    ReadingListCard(list: list, allBooks: allBooks, variant: GlassCardRotation.variant(for: index), accentIndex: index) {
                        selectedList = list
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Archived Section
    
    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Archived")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(archivedLists.enumerated()), id: \.element.id) { index, list in
                    ReadingListCard(list: list, allBooks: allBooks, variant: .subtle, accentIndex: index) {
                        selectedList = list
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 14) {
                Image("books")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(LColors.accents.secondary)
                
                Text("No reading lists yet")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                
                Text("Create curated collections like Summer TBR, Cozy Reads, or Books to Reread.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                        Text("Create a List")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(LGradients.blue))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
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

// MARK: - Reading List Card

struct ReadingListCard: View {
    let list: ReadingList
    let allBooks: [Book]
    var variant: GlassCardVariant = .primary
    var accentIndex: Int = 0
    let onTap: () -> Void

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    private var effectiveCompletedCount: Int {
        let listBookIDs = Set(list.items.map { $0.bookID })

        let manuallyCompletedIDs = Set(
            list.items
                .filter { $0.isCompleted }
                .map { $0.bookID }
        )

        let finishedBookIDs = Set(
            allBooks
                .filter { $0.status == .finished }
                .map { $0.id }
        )

        return listBookIDs.filter { bookID in
            manuallyCompletedIDs.contains(bookID) || finishedBookIDs.contains(bookID)
        }.count
    }

    private var effectiveProgressValue: Double {
        guard list.bookCount > 0 else { return 0 }
        return Double(effectiveCompletedCount) / Double(list.bookCount)
    }

    private var effectiveProgressText: String {
        "\(effectiveCompletedCount) of \(list.bookCount) read"
    }
    
    var body: some View {
        Button(action: onTap) {
            GlassCard(variant: variant) {
                HStack(spacing: 14) {
                    Image(list.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(accent)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(accent, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(list.displayTitle)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !list.listDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(list.listDescription)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: 8) {
                            Text(effectiveProgressText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)

                            if let days = list.daysRemaining {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundStyle(LColors.textSecondary)

                                Text(days >= 0 ? "\(days)d left" : "Overdue")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(days >= 0 ? LColors.textSecondary : LColors.danger)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if list.bookCount > 0 {
                            GeometryReader { proxy in
                                let intrinsicWidth: CGFloat = 25 * 8 + 24 * 4 // dot + spacing
                                let scale = min(1, max(0.01, proxy.size.width / intrinsicWidth))
                                DottedGoalProgressBar(value: effectiveProgressValue)
                                    .frame(width: intrinsicWidth, height: 8)
                                    .scaleEffect(x: scale, y: 1, anchor: .leading)
                            }
                            .frame(height: 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LColors.text.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
