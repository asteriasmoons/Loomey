//
//  BookQuotesView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BookQuotesView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @State private var showAddSheet = false
    @State private var editingQuote: BookQuote? = nil
    @State private var quoteToDelete: BookQuote? = nil
    @State private var showDeleteAlert = false

    private var quotes: [BookQuote] {
        (book.bookQuotes ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    quoteList
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .adaptivePresentation(isPresented: $showAddSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            BookQuoteEditorSheet(book: book, quote: nil)
        }
        .adaptivePresentation(item: $editingQuote, useFullScreenCover: horizontalSizeClass == .regular) { quote in
            BookQuoteEditorSheet(book: book, quote: quote)
        }
        .lumeyAlertConfirm(
            isPresented: $showDeleteAlert,
            title: "Delete Quote",
            message: "Are you sure you want to delete this quote?"
        ) {
            if let quote = quoteToDelete {
                modelContext.delete(quote)
                quoteToDelete = nil
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Favorite Quotes")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.primary)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
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
                    .foregroundStyle(LColors.accents.contrast)
                    .bubblyIconMaterial(tint: theme.palette.indicators)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var quoteList: some View {
        Group {
            if quotes.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                        quoteCard(
                            quote,
                            tint: theme.palette.rotation[index % theme.palette.rotation.count]
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 12) {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LGradients.blue)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

                Text("No favorite quotes yet")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("Tap + to save a quote you love")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func quoteCard(_ quote: BookQuote, tint: Color) -> some View {
        GlassCard(cornerRadius: 18, padding: 0, variant: .secondary, borderColor: tint) {
            ZStack {
                BubblyLightWash(colors: [tint], intensity: 0.34, fadeEnd: 0.82)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image("quote")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(tint)
                        .bubblyIconMaterial(tint: tint)

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            editingQuote = quote
                        } label: {
                            Image("pencil")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(tint)
                                .bubblyIconMaterial(tint: tint)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(tint, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            quoteToDelete = quote
                            showDeleteAlert = true
                        } label: {
                            Image("trash")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(tint)
                                .bubblyIconMaterial(tint: tint)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(tint, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(quote.text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    if !quote.pageNumber.isEmpty {
                        Text("P. \(quote.pageNumber)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer()

                    Text(quote.dateCreated.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

// MARK: - Quote Editor Sheet

struct BookQuoteEditorSheet: View {
    let book: Book
    let quote: BookQuote?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @State private var text = ""
    @State private var pageNumber = ""

    private var isEditing: Bool { quote != nil }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(isEditing ? "Edit Quote" : "New Quote")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.headingPrimary)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(theme.palette.secondaryAccent)
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quote")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                TextEditor(text: $text)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LColors.surface.nested)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                                            )
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Page Number (optional)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                TextField("", text: $pageNumber)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LColors.surface.nested)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                                            )
                                    )
                            }
                    }

                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Add Quote")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(theme.palette.textPrimary)
                            .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                            .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let quote {
                text = quote.text
                pageNumber = quote.pageNumber
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let quote {
            quote.text = trimmed
            quote.pageNumber = pageNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            quote.lastUpdated = Date()
        } else {
            let newQuote = BookQuote(
                text: trimmed,
                pageNumber: pageNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                book: book
            )
            modelContext.insert(newQuote)
            ReadingXPService.awardBookQuote(newQuote, modelContext: modelContext)
        }

        dismiss()
    }
}
