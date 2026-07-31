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

    @State private var showAddSheet = false
    @State private var editingQuote: BookQuote? = nil
    @State private var quoteToDelete: BookQuote? = nil
    @State private var showDeleteAlert = false

    private var quotes: [BookQuote] {
        (book.bookQuotes ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }

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
                .foregroundStyle(.white)

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
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
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
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
                VStack(spacing: 14) {
                    ForEach(quotes, id: \.id) { quote in
                        quoteCard(quote)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image("starmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LGradients.blue)

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

    private func quoteCard(_ quote: BookQuote) -> some View {
        GlassCard(cornerRadius: 18, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image("quote")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(LGradients.blue)

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
                                .foregroundStyle(LGradients.blue)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LGradients.blue, lineWidth: 1)
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
                                .foregroundStyle(LGradients.blue)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LGradients.blue, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(quote.text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
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
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LGradients.blue)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    GlassCard {
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
                                            .fill(Color.white.opacity(0.04))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
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
                                            .fill(Color.white.opacity(0.04))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Add Quote")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LGradients.blue)
                            )
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
