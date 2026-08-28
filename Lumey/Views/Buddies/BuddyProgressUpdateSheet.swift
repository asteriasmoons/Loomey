//
//  BuddyProgressUpdateSheet.swift
//  Lumey
//

import SwiftUI

struct BuddyProgressUpdateSheet: View {
    let userId: String
    let displayName: String
    let groupId: String
    var onClose: (() -> Void)?
    var onSend: ((BuddyMessage) -> Void)?

    @State private var chapterText: String = ""
    @State private var pageText: String = ""
    @State private var noteText: String = ""
    @State private var isSending = false
    @State private var errorMessage: String? = nil

    private var closeAction: () -> Void { onClose ?? {} }

    private var canSend: Bool {
        (!chapterText.isEmpty || !pageText.isEmpty) && !isSending
    }

    private var progressText: String {
        var parts: [String] = []
        if let chapter = Int(chapterText), chapter > 0 {
            parts.append("chapter \(chapter)")
        }
        if let page = Int(pageText), page > 0 {
            parts.append("page \(page)")
        }
        let base = "I'm on \(parts.joined(separator: ", "))"
        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? base : "\(base) — \(note)"
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            GlassCard(variant: .featured) {
                                VStack(alignment: .leading, spacing: 12) {
                                    fieldLabel("Chapter")
                                    buddyTextField(placeholder: "5", text: $chapterText)
                                        .keyboardType(.numberPad)
                                }
                            }

                            GlassCard(variant: .primary) {
                                VStack(alignment: .leading, spacing: 12) {
                                    fieldLabel("Page")
                                    buddyTextField(placeholder: "120", text: $pageText)
                                        .keyboardType(.numberPad)
                                }
                            }
                        }

                        GlassCard(variant: .secondary) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Add a Note Optional")
                                buddyTextField(placeholder: "Can't believe that plot twist!", text: $noteText)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        shareButton
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
                Text("Progress Update")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Share where you are in the book.")
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
                    .frame(width: 24, height: 24)
                    .foregroundStyle(
                        LColors.accents.primary
                    )
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LColors.accents.primary,
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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LColors.border.nested)
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private var shareButton: some View {
        Button { Task { await send() } } label: {
            Group {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Share Progress")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(canSend ? LColors.accents.contrast : LColors.surface.subtle)
            )
            .shadow(color: canSend ? LColors.accent.opacity(0.3) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
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

    private func send() async {
        guard canSend else { return }
        isSending = true
        errorMessage = nil

        let chapter = Int(chapterText)
        let page = Int(pageText)

        let body = SendMessageBody(
            senderUserId: userId,
            senderDisplayName: displayName,
            type: "progress_update",
            text: progressText,
            progressChapter: chapter,
            progressPage: page
        )

        do {
            let message = try await BuddyService.shared.sendMessage(groupId: groupId, body: body)
            onSend?(message)
        } catch {
            errorMessage = "Failed to send update. Please try again."
        }

        isSending = false
    }
}
