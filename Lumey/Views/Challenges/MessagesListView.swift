//
//  MessagesListView.swift
//  Lumey
//

import SwiftUI

struct MessagesListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    @State private var conversations: [ConversationDTO] = []
    @State private var messageableUsers: [MessageableUserDTO] = []
    @State private var isLoading = false
    @State private var showingNewConversation = false
    @State private var selectedConversation: ConversationDTO?
    @State private var selectedConversationUser: MessageableUserDTO?

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var currentUsername: String {
        appState.currentUser?.displayName ?? "Reader"
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        if isLoading && conversations.isEmpty {
                            loadingCard
                        } else if conversations.isEmpty {
                            emptyCard
                        } else {
                            ForEach(conversations) { conversation in
                                conversationRow(conversation)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
                .refreshable {
                    await loadConversations()
                }
            }
        }
        .task {
            await loadConversations()
            await loadMessageableUsers()
        }
        .adaptivePresentation(isPresented: $showingNewConversation, useFullScreenCover: horizontalSizeClass == .regular) {
            NewConversationSheet(
                messageableUsers: messageableUsers,
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                onConversationCreated: { (conversation: ConversationDTO) in
                    selectedConversation = conversation
                    showingNewConversation = false
                    Task { await loadConversations() }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $selectedConversation, useFullScreenCover: horizontalSizeClass == .regular) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                otherAvatarURL: selectedConversationUser?.avatarURL,
                otherAvatarName: selectedConversationUser?.avatarName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .onDisappear {
                Task { await loadConversations() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Messages")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Direct messages with readers you follow")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                showingNewConversation = true
            } label: {
                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 40, height: 40)
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
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 40, height: 40)
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    // MARK: - Conversation Row

    private func conversationRow(_ conversation: ConversationDTO) -> some View {
        let otherUsername = conversation.otherUsername(currentUserID: currentUserID)
        let unread = conversation.unreadCount(for: currentUserID)

        return Button {
            selectedConversationUser = messageableUser(for: conversation)
            selectedConversation = conversation
        } label: {
            GlassCard(padding: 14, variant: .secondary) {
                HStack(spacing: 12) {
                    UserAvatarView(
                        avatarURL: messageableUser(for: conversation)?.avatarURL,
                        avatarName: messageableUser(for: conversation)?.avatarName,
                        size: 40,
                        iconSize: 20
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(otherUsername)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)

                            Spacer()

                            if let date = conversation.lastMessageDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }

                        HStack {
                            Text(conversation.lastMessageText.isEmpty ? "No messages yet" : conversation.lastMessageText)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)

                            Spacer()

                            if unread > 0 {
                                Text("\(unread)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(LGradients.completion))
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func messageableUser(for conversation: ConversationDTO) -> MessageableUserDTO? {
        let otherUserID = conversation.participantA == currentUserID
            ? conversation.participantB
            : conversation.participantA

        return messageableUsers.first { $0.userID == otherUserID }
    }

    // MARK: - States

    private var loadingCard: some View {
        GlassCard(variant: .featured) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)

                Text("Loading messages...")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Spacer()
            }
        }
    }

    private var emptyCard: some View {
        GlassCard(variant: .primary) {
            VStack(spacing: 14) {
                Image("starchat")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(LColors.accents.secondary)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                            )
                    )

                VStack(spacing: 6) {
                    Text("No Conversations Yet")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Start a conversation with readers you follow.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Data

    @MainActor
    private func loadConversations() async {
        isLoading = true

        do {
            conversations = try await ChallengeSocialService.shared.fetchConversations(userID: currentUserID)
        } catch {
            // Silently fail — conversations list will be empty
        }

        isLoading = false
    }

    @MainActor
    private func loadMessageableUsers() async {
        do {
            messageableUsers = try await ChallengeSocialService.shared.fetchMessageableUsers(userID: currentUserID)
        } catch {
            // Silently fail
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

// MARK: - New Conversation Sheet

private struct NewConversationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let messageableUsers: [MessageableUserDTO]
    let currentUserID: String
    let currentUsername: String
    let onConversationCreated: (ConversationDTO) -> Void

    @State private var searchText = ""
    @State private var isCreating = false

    private var filteredUsers: [MessageableUserDTO] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return messageableUsers }
        return messageableUsers.filter { $0.username.lowercased().contains(trimmed) }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("New Message")
                        .font(.system(size: 28, weight: .black, design: .rounded))
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
                            .foregroundStyle(LColors.accents.special)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LColors.accents.special, lineWidth: 1.2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
                .safeAreaPadding(.top)

                TextField("Search users...", text: $searchText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        if filteredUsers.isEmpty {
                            Text("No connected users found")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .padding(.top, 20)
                        }

                        ForEach(filteredUsers) { user in
                            Button {
                                Task { await startConversation(with: user) }
                            } label: {
                                GlassCard(padding: 12, variant: .tertiary) {
                                    HStack(spacing: 12) {
                                        UserAvatarView(
                                            avatarURL: user.avatarURL,
                                            avatarName: user.avatarName,
                                            size: 34,
                                            iconSize: 16
                                        )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.username)
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                                .foregroundStyle(LColors.cardTitle)

                                            if let bio = user.bio, !bio.isEmpty {
                                                Text(bio)
                                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(LColors.textSecondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        Image("chatbubble")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .foregroundStyle(LColors.textSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    @MainActor
    private func startConversation(with user: MessageableUserDTO) async {
        guard !isCreating else { return }
        isCreating = true

        do {
            let conversation = try await ChallengeSocialService.shared.createConversation(
                senderUserID: currentUserID,
                senderUsername: currentUsername,
                recipientUserID: user.userID,
                recipientUsername: user.username
            )
            onConversationCreated(conversation)
        } catch {
            // Handle error silently for now
        }

        isCreating = false
    }
}
