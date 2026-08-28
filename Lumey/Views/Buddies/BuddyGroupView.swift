//
//  BuddyGroupView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BuddyGroupView: View {
    let group: BuddyGroup
    let userId: String
    let displayName: String
    @Environment(\.modelContext) private var modelContext

    @State private var messages: [BuddyMessage] = []
    @State private var messageText: String = ""
    @State private var isSending = false
    @State private var isLoadingMessages = false
    @State private var showProgressSheet = false
    @State private var chapterText: String = ""
    @State private var currentGroup: BuddyGroup
    @State private var showClearConfirm = false
    
    @Environment(\.dismiss) private var dismiss

    private let socketManager = BuddySocketManager.shared

    private var isAdminUser: Bool {
        userId == "001664.f2fefbb84f024544b98e865fa6c6b49e.1524"
    }

    init(group: BuddyGroup, userId: String, displayName: String) {
        self.group = group
        self.userId = userId
        self.displayName = displayName
        _currentGroup = State(initialValue: group)
    }

    private var joinedMembers: [BuddyMember] {
        currentGroup.joinedMembers
    }

    var body: some View {
        ZStack {
            LumeyBackground()
            VStack(spacing: 0) {
                groupHeader
                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(height: 1)
                messagesArea
                chatInputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            socketManager.joinRoom(group.id)
            socketManager.onMessage = { message in
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
            socketManager.onMemberJoined = { _, memberDisplayName in
                let systemMsg = BuddyMessage(
                    id: UUID().uuidString,
                    groupId: group.id,
                    senderUserId: "system",
                    senderDisplayName: "system",
                    type: "system",
                    text: "\(memberDisplayName) joined the group.",
                    progressChapter: nil,
                    progressPage: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                messages.append(systemMsg)
            }
            socketManager.onMemberLeft = { _, memberDisplayName in
                let systemMsg = BuddyMessage(
                    id: UUID().uuidString,
                    groupId: group.id,
                    senderUserId: "system",
                    senderDisplayName: "system",
                    type: "system",
                    text: "\(memberDisplayName) left the group.",
                    progressChapter: nil,
                    progressPage: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                messages.append(systemMsg)
            }
            socketManager.onChatCleared = {
                messages = []
            }
            Task { await loadMessages() }
        }
        .onDisappear {
            socketManager.leaveRoom(group.id)
        }
        .overlay { progressSheetOverlay }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showProgressSheet)
        .confirmationDialog("Clear all messages in this chat?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear Chat", role: .destructive) {
                Task { await clearChat() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Group header

    private var groupHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentGroup.bookTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)

                if let author = currentGroup.bookAuthor, !author.isEmpty {
                    Text(author)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(1)
                }

                Text(joinedMembers.map(\.displayName).joined(separator: ", "))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)

                if let owner = currentGroup.ownerLabel(currentUserId: userId) {
                    Text(owner)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                Button {
                    dismiss()
                } label: {
                    headerIconButton("xmarkwavy")
                }
                .buttonStyle(.plain)

                if isAdminUser {
                    Button {
                        showClearConfirm = true
                    } label: {
                        headerIconButton("trash")
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showProgressSheet = true
                } label: {
                    headerIconButton("starchart")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
    
    private func headerIconButton(_ iconName: String) -> some View {
        Image(iconName)
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

    // MARK: - Messages area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        BuddyMessageBubble(message: message, currentUserId: userId)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .padding(.bottom, 140)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Chat input

    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LColors.glassBorder)
                .frame(height: 1)

            HStack(spacing: 12) {

                GlassCard(variant: .featured) {
                    TextField("Message...", text: $messageText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image("arrowupwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AnyShapeStyle(LColors.textSecondary)
                            : AnyShapeStyle(
                                LColors.accents.contrast
                            )
                        )
                        .frame(width: 46, height: 46)
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
                        .opacity(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
                            ? 0.45
                            : 1
                        )
                }
                .buttonStyle(.plain)
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    isSending
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 104) // raises above tab bar
        }
    }

    // MARK: - Progress sheet overlay

    private var progressSheetOverlay: some View {
        ZStack {
            if showProgressSheet {
                BuddyProgressUpdateSheet(
                    userId: userId,
                    displayName: displayName,
                    groupId: group.id,
                    onClose: { showProgressSheet = false },
                    onSend: { message in
                        messages.append(message)
                        ReadingXPService.awardBuddyProgressUpdate(message, modelContext: modelContext)
                        showProgressSheet = false
                    }
                )
                .preferredColorScheme(.dark)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(80)
            }
        }
    }

    // MARK: - Actions

    private func loadMessages() async {
        isLoadingMessages = true
        messages = (try? await BuddyService.shared.getMessages(groupId: group.id, userId: userId)) ?? []
        isLoadingMessages = false
    }

    private func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        messageText = ""

        let body = SendMessageBody(
            senderUserId: userId,
            senderDisplayName: displayName,
            type: "text",
            text: text,
            progressChapter: nil,
            progressPage: nil
        )

        if let sent = try? await BuddyService.shared.sendMessage(groupId: group.id, body: body) {
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
                ReadingXPService.awardBuddyMessage(sent, modelContext: modelContext)
            }
        }

        isSending = false
    }

    private func clearChat() async {
        _ = try? await BuddyService.shared.clearGroupMessages(groupId: group.id, userId: userId)
        messages = []
    }
}

// MARK: - Message bubble

struct BuddyMessageBubble: View {
    let message: BuddyMessage
    let currentUserId: String

    private var isMe: Bool { message.senderUserId == currentUserId }
    private var isSystem: Bool { message.isSystem }

    var body: some View {
        if isSystem {
            Text(message.text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        } else if message.isProgressUpdate {
            progressUpdateBubble
        } else {
            regularBubble
        }
    }

    private var regularBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.senderDisplayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LColors.textSecondary)
                }

                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMe ? LColors.accent : LColors.border.subtle)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }

    private var progressUpdateBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 40) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.senderDisplayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LColors.textSecondary)
                }

                HStack(spacing: 8) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.accents.contrast)
                    Text(message.text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LColors.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(LColors.glassSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(LColors.glassBorder, lineWidth: 1))
            }

            if !isMe { Spacer(minLength: 40) }
        }
    }
}
