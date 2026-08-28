//
//  BuddyPostAnnouncementSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BuddyPostAnnouncementSheet: View {
    let userId: String
    let displayName: String
    var onClose: (() -> Void)?
    var onPost: ((BuddyAnnouncement) -> Void)?

    @Query(sort: \Book.updatedAt, order: .reverse) private var books: [Book]

    @State private var bookTitle: String = ""
    @State private var bookAuthor: String = ""
    @State private var message: String = ""
    @State private var maxMembers: Int = 2
    @State private var currentChapterText: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil

    private var readingBooks: [Book] {
        books.filter { $0.status == .reading && $0.deletedAt == nil }
    }

    private var trimmedTitle: String {
        bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPost: Bool { !trimmedTitle.isEmpty && !isPosting }

    private var closeAction: () -> Void { onClose ?? {} }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if !readingBooks.isEmpty {
                            GlassCard(variant: .featured) {
                                VStack(alignment: .leading, spacing: 10) {
                                    fieldLabel("Currently Reading")

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.adaptive(minimum: 120), spacing: 10)
                                        ],
                                        alignment: .leading,
                                        spacing: 10
                                    ) {
                                        ForEach(readingBooks) { book in
                                            Button {
                                                bookTitle = book.title
                                                bookAuthor = book.author
                                                currentChapterText = "\(book.currentPage)"
                                            } label: {
                                                Text(book.title)
                                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                                    .foregroundStyle(LColors.cardTitle)
                                                    .lineLimit(1)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .frame(maxWidth: .infinity)
                                                    .background(
                                                        Capsule(style: .continuous)
                                                            .fill(LColors.iconContainer.primary)
                                                    )
                                                    .overlay(
                                                        Capsule(style: .continuous)
                                                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Book Title")
                                buddyTextField(placeholder: "Book title", text: $bookTitle)
                            }
                        }

                        GlassCard(variant: .secondary) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Author")
                                buddyTextField(placeholder: "Author (optional)", text: $bookAuthor)
                            }
                        }

                        GlassCard(variant: .tertiary) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Current Page")
                                buddyTextField(placeholder: "e.g. 42", text: $currentChapterText)
                                    .keyboardType(.numberPad)
                            }
                        }

                        GlassCard(variant: .elevated) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Max Buddies")

                                HStack(spacing: 10) {
                                    ForEach(2...4, id: \.self) { count in
                                        Button {
                                            maxMembers = count
                                        } label: {
                                            Text("\(count)")
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                                .foregroundStyle(maxMembers == count ? .white : LColors.textSecondary)
                                                .frame(width: 46, height: 44)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .fill(maxMembers == count ? LColors.glassSurface2 : LColors.surface.subtle.opacity(0.6))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .strokeBorder(
                                                            maxMembers == count ? LColors.accents.contrast : LColors.glassBorder,
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GlassCard(variant: .subtle) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Note Optional")
                                buddyTextEditor(placeholder: "e.g. Looking to discuss themes and theories!", text: $message)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        postButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Post Announcement")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Invite readers to join your buddy group.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                closeAction()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(
                        LColors.accents.contrast
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LColors.accents.contrast,
                                        lineWidth: 1.35
                                    )
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    private var postButton: some View {
        Button { Task { await post() } } label: {
            Group {
                if isPosting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Post to Board")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(canPost ? LColors.accents.contrast : LColors.surface.subtle)
            )
            .shadow(color: canPost ? LColors.accent.opacity(0.3) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canPost)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    private func buddyTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LColors.surface.nestedSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LColors.border.nested, lineWidth: 1)
            )
    }

    private func buddyTextEditor(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }

            TextEditor(text: text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.surface.nestedSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LColors.border.nested, lineWidth: 1)
        )
    }

    private func post() async {
        guard canPost else { return }
        isPosting = true
        errorMessage = nil

        let body = PostAnnouncementBody(
            ownerUserId: userId,
            ownerDisplayName: displayName,
            bookTitle: trimmedTitle,
            bookAuthor: bookAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bookAuthor,
            bookCoverUrl: nil,
            bookKey: nil,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : message,
            currentChapter: nil,
            currentPage: Int(currentChapterText.filter(\Character.isNumber)),
            maxMembers: maxMembers
        )

        do {
            let announcement = try await BuddyService.shared.postAnnouncement(body: body)
            onPost?(announcement)
        } catch {
            errorMessage = "Failed to post. Please try again."
        }

        isPosting = false
    }
}
