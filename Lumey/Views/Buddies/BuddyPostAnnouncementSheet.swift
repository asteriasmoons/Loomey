//
//  BuddyPostAnnouncementSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BuddyPostAnnouncementSheet: View {
    @Environment(\.appTheme) private var theme

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
    @State private var isReadingDropdownExpanded = false

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
                            currentlyReadingDropdown
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Book Title")
                            buddyTextField(
                                placeholder: "Book title",
                                text: $bookTitle,
                                tint: theme.palette.secondaryAccent
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Author")
                            buddyTextField(
                                placeholder: "Author (optional)",
                                text: $bookAuthor,
                                tint: theme.palette.indicators
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Current Page")
                            buddyTextField(
                                placeholder: "e.g. 42",
                                text: $currentChapterText,
                                tint: theme.palette.primaryAction
                            )
                            .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Max Buddies")

                            HStack(spacing: 10) {
                                ForEach(Array((2...4).enumerated()), id: \.element) { index, count in
                                    let accent = theme.palette.rotation[index % theme.palette.rotation.count]
                                    Button {
                                        maxMembers = count
                                    } label: {
                                        Text("\(count)")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                            .frame(width: 46, height: 44)
                                            .background {
                                                BubblyIconMaterial(tint: accent)
                                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            }
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(
                                                        maxMembers == count ? Color.white : Color.white.opacity(0.18),
                                                        lineWidth: maxMembers == count ? 2.5 : 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Note Optional")
                            buddyTextEditor(
                                placeholder: "e.g. Looking to discuss themes and theories!",
                                text: $message,
                                tint: theme.palette.secondaryAccent
                            )
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

    private var currentlyReadingDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Currently Reading")

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isReadingDropdownExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)

                    Text(bookTitle.isEmpty ? "Choose a Book" : bookTitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .lineLimit(1)

                    Spacer()

                    Image(isReadingDropdownExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 16) }
                .bubblyTileLift()
            }
            .buttonStyle(.plain)

            if isReadingDropdownExpanded {
                ScrollView(.vertical, showsIndicators: readingBooks.count > 4) {
                    LazyVStack(spacing: 7) {
                        ForEach(readingBooks) { book in
                            Button {
                                bookTitle = book.title
                                bookAuthor = book.author
                                currentChapterText = "\(book.currentPage)"
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    isReadingDropdownExpanded = false
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image("books")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.title)
                                            .font(.system(size: 13, weight: .black, design: .rounded))
                                            .lineLimit(1)

                                        Text(book.author)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .opacity(0.82)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if bookTitle == book.title && bookAuthor == book.author {
                                        Image("checkwavy")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                    }
                                }
                                .foregroundStyle(.white)
                                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(theme.palette.raisedSurface)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                }
                .frame(height: CGFloat(min(readingBooks.count, 4)) * 58)
                .background { BubblyTileSurface(tint: theme.palette.primaryAction, cornerRadius: 18) }
                .bubblyTileLift()
                .transition(.move(edge: .top).combined(with: .opacity))
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
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(LColors.bg))
                    .overlay(Circle().strokeBorder(theme.palette.primaryAction, lineWidth: 1.35))
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
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                BubblyTileSurface(
                    tint: canPost ? theme.palette.indicators : theme.palette.indicators.opacity(0.34),
                    cornerRadius: 16
                )
            }
            .bubblyTileLift()
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

    private func buddyTextField(placeholder: String, text: Binding<String>, tint: Color) -> some View {
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
                    .strokeBorder(tint, lineWidth: 1.35)
            )
    }

    private func buddyTextEditor(placeholder: String, text: Binding<String>, tint: Color) -> some View {
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
                .strokeBorder(tint, lineWidth: 1.35)
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
