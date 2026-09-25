//
//  ConversationView.swift
//  Lumey
//

import SwiftUI

struct ConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let conversation: ConversationDTO
    let currentUserID: String
    let currentUsername: String
    let otherAvatarURL: String?
    let otherAvatarName: String?

    @State private var messages: [DirectMessageDTO] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool

    private var otherUsername: String {
        conversation.otherUsername(currentUserID: currentUserID)
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if isLoading && messages.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(messages) { message in
                                    messageBubble(message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .padding(.bottom, 10)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let lastID = messages.last?.id {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            if let lastID = messages.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }

                    inputBar
                }
            }
        }
        .task {
            await loadMessages()
            await markRead()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image("profilewavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(theme.palette.background))
                .overlay {
                    Circle()
                        .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1.2)
                }

            Text(otherUsername)
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
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1.2)
                            )
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

    // MARK: - Message Bubble

    private func messageBubble(_ message: DirectMessageDTO) -> some View {
        let isMine = message.senderUserID == currentUserID

        return HStack {
            if isMine { Spacer(minLength: 60) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        BubblyTileSurface(
                            tint: isMine ? theme.palette.primaryAction : theme.palette.secondaryAccent,
                            cornerRadius: 18
                        )
                    }
                    .bubblyTileLift()

                if let date = message.createdDate {
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }

            if !isMine { Spacer(minLength: 60) }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(alignment: .trailing, spacing: 6) {
            GlassCard(padding: 0, variant: .featured, borderColor: theme.palette.indicators) {
                HStack(alignment: .center, spacing: 10) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1...10)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 18)
                        .padding(.vertical, 16)

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image("sendbutton")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(canSend ? AnyShapeStyle(LColors.accents.secondary) : AnyShapeStyle(LColors.glassSurface))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || isSending)
                }
            }
            .padding(.horizontal, 20)

            if isInputFocused {
                keyboardDoneButton
                    .padding(.trailing, 20)
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
            }
        }
        .padding(.top, 12)
        .padding(.bottom, isInputFocused ? 0 : 12)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.bottom, isInputFocused ? 0 : nil)
        .animation(.easeOut(duration: 0.16), value: isInputFocused)
    }

    private var keyboardDoneButton: some View {
        Button {
            isInputFocused = false
        } label: {
            HStack(spacing: 5) {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .bubblyIconMaterial(tint: .white)

                Text("Done")
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background {
                BubblyTileSurface(
                    tint: theme.palette.primaryAction,
                    cornerRadius: 14
                )
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Data

    @MainActor
    private func loadMessages() async {
        guard let conversationID = conversation.id else { return }

        isLoading = true

        do {
            messages = try await ChallengeSocialService.shared.fetchMessages(
                conversationID: conversationID,
                userID: currentUserID
            )
        } catch {
            // Silently fail
        }

        isLoading = false
    }

    @MainActor
    private func sendMessage() async {
        guard let conversationID = conversation.id else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        let textToSend = trimmed
        messageText = ""

        do {
            let sent = try await ChallengeSocialService.shared.sendMessage(
                conversationID: conversationID,
                senderUserID: currentUserID,
                senderUsername: currentUsername,
                text: textToSend
            )

            messages.append(sent)
        } catch {
            messageText = textToSend
        }

        isSending = false
    }

    @MainActor
    private func markRead() async {
        guard let conversationID = conversation.id else { return }

        try? await ChallengeSocialService.shared.markMessagesRead(
            conversationID: conversationID,
            userID: currentUserID
        )
    }
}
