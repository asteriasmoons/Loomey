//
//  ChallengeUserProfileView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ChallengeUserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var editedUsername: String = ""
    @State private var isEditingUsername = false
    @State private var isFollowing = false
    @State private var selectedConversation: ConversationDTO?
    @State private var isCreatingConversation = false
    @State private var showingMessagesList = false

    let profile: ChallengeUserProfile
    var currentChallengeTitle: String?
    var recentSubmissions: [ChallengeSubmission]
    var onSubmissionTapped: ((ChallengeSubmission) -> Void)?

    init(
        profile: ChallengeUserProfile,
        currentChallengeTitle: String? = nil,
        recentSubmissions: [ChallengeSubmission] = [],
        onSubmissionTapped: ((ChallengeSubmission) -> Void)? = nil
    ) {
        self.profile = profile
        self.currentChallengeTitle = currentChallengeTitle
        self.recentSubmissions = recentSubmissions
        self.onSubmissionTapped = onSubmissionTapped
    }
    
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
                    VStack(spacing: 18) {
                        profileHero

                        statsGrid

                        if let currentChallengeTitle,
                           !currentChallengeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            currentChallengeCard(currentChallengeTitle)
                        }

                        if !displayBio.isEmpty {
                            bioCard
                        }

                        recentEntriesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 110)
                }
            }
        }
        .adaptivePresentation(item: $selectedConversation, useFullScreenCover: horizontalSizeClass == .regular) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                otherAvatarURL: profile.avatarURL,
                otherAvatarName: profile.avatarName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingMessagesList, useFullScreenCover: horizontalSizeClass == .regular) {
            MessagesListView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Reader Profile")
                .font(.system(size: 32, weight: .black, design: .rounded))
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    // MARK: - Hero

    private var profileHero: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 16) {
                avatarUploadButton

                VStack(spacing: 10) {
                    if isEditingUsername {
                        VStack(spacing: 10) {
                            TextField("Username", text: $editedUsername)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                )

                            Button {
                                saveUsername()
                            } label: {
                                Text("Save Username")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(LGradients.header)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            editedUsername = displayUsername
                            isEditingUsername = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(displayUsername)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.headingPrimary)
                                    .multilineTextAlignment(.center)

                                Image("pencil")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if !displayFavoriteGenre.isEmpty {
                        HStack(spacing: 6) {
                            Image("sparklybook")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(LColors.accents.contrast)

                            Text(displayFavoriteGenre)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            toggleFollow()
                        } label: {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(isFollowing ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LColors.accents.secondary))
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                await startMessage()
                            }
                        } label: {
                            Image("sendbutton")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(isCreatingConversation ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LColors.accents.special))
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreatingConversation)

                        Button {
                            showingMessagesList = true
                        } label: {
                            Image("chatlinesfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LColors.accents.secondary)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LColors.accents.special, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 10) {
                    socialMiniStat(title: "Followers", value: "\(profile.followersCount)")
                    socialMiniStat(title: "Following", value: "\(profile.followingCount)")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .task {
            editedUsername = displayUsername
            isFollowing = profile.isFollowing
        }
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task {
                await loadAvatarImage(from: newItem)
            }
        }
    }

    private var avatarUploadButton: some View {
        PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                avatarView

                Image("upload")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(LGradients.header)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.border.primary, lineWidth: 1)
                            )
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var avatarView: some View {
        UserAvatarView(
            avatarURL: profile.avatarURL,
            avatarName: profile.avatarName,
            size: 104,
            iconSize: 60
        )
        .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 16, y: 8)
    }

    private func socialMiniStat(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

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
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            profileStatCard(
                icon: "startrophyhands",
                title: "Completed",
                value: "\(profile.challengesCompleted)",
                subtitle: "Challenges"
            )

            profileStatCard(
                icon: "starfill",
                title: "Points",
                value: "\(profile.challengePoints)",
                subtitle: "Earned"
            )

            profileStatCard(
                icon: "loveflame",
                title: "Streak",
                value: "\(profile.readingStreak)",
                subtitle: profile.readingStreak == 1 ? "Day" : "Days"
            )

            profileStatCard(
                icon: "sparkle",
                title: "Entries",
                value: "\(recentSubmissions.count)",
                subtitle: "Recent"
            )
        }
    }

    private func profileStatCard(
        icon: String,
        title: String,
        value: String,
        subtitle: String
    ) -> some View {
        GlassCard(padding: 14, variant: .elevated) {
            VStack(alignment: .leading, spacing: 12) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LColors.accents.special)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.primary, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)

                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(subtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Current Challenge

    private func currentChallengeCard(_ title: String) -> some View {
        GlassCard(variant: .primary) {
            HStack(spacing: 12) {
                Image("stargoal")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Challenge")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
    }

    // MARK: - Bio

    private var bioCard: some View {
        GlassCard(variant: .secondary) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "starnote", title: "About")

                Text(displayBio)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "sparkle", title: "Recent Challenge Entries")

            if recentSubmissions.isEmpty {
                GlassCard(variant: .tertiary) {
                    VStack(spacing: 10) {
                        Image("openbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(LColors.accents.contrast)

                        Text("No recent entries yet.")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("Challenge submissions will appear here once this reader starts joining events.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(recentSubmissions, id: \.id) { submission in
                        Button {
                            onSubmissionTapped?(submission)
                        } label: {
                            recentSubmissionRow(submission)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func recentSubmissionRow(_ submission: ChallengeSubmission) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(statusIcon(for: submission.validationStatus))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LColors.accents.secondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(submission.validationStatus.displayName)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(submission.submittedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.accents.special)

                    Text("\(submission.likeCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.textSecondary)

                    Text("\(submission.commentCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LColors.surface.nested)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(LColors.border.nested, lineWidth: 1)
                )
        )
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LColors.accents.primary)

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var displayUsername: String {
        let trimmed = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }

    private var displayBio: String {
        profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayFavoriteGenre: String {
        profile.favoriteGenre?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    @MainActor
    private func startMessage() async {
        guard !isCreatingConversation else { return }

        isCreatingConversation = true

        do {
            let conversation = try await ChallengeSocialService.shared.createConversation(
                senderUserID: currentUserID,
                senderUsername: currentUsername,
                recipientUserID: profile.userID,
                recipientUsername: displayUsername
            )

            selectedConversation = conversation
        } catch {
            print("Failed to start conversation:", error)
        }

        isCreatingConversation = false
    }
    
    private func saveUsername() {
        let trimmed = editedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        profile.username = trimmed
        isEditingUsername = false

        try? modelContext.save()

        Task {
            try? await ChallengeSocialService.shared.updateProfile(
                userID: profile.userID,
                username: trimmed,
                avatarName: profile.avatarName,
                avatarURL: profile.avatarURL,
                bio: profile.bio,
                favoriteGenre: profile.favoriteGenre,
                readingStreak: profile.readingStreak,
                challengePoints: profile.challengePoints,
                challengesCompleted: profile.challengesCompleted,
                followersCount: profile.followersCount,
                followingCount: profile.followingCount
            )
        }
    }

    private func toggleFollow() {
        isFollowing.toggle()
        profile.isFollowing = isFollowing

        if isFollowing {
            profile.followersCount += 1
        } else {
            profile.followersCount = max(0, profile.followersCount - 1)
        }

        try? modelContext.save()

        Task {
            try? await ChallengeSocialService.shared.updateProfile(
                userID: profile.userID,
                username: profile.username,
                avatarName: profile.avatarName,
                avatarURL: profile.avatarURL,
                bio: profile.bio,
                favoriteGenre: profile.favoriteGenre,
                readingStreak: profile.readingStreak,
                challengePoints: profile.challengePoints,
                challengesCompleted: profile.challengesCompleted,
                followersCount: profile.followersCount,
                followingCount: profile.followingCount
            )
        }
    }

    @MainActor
    private func loadAvatarImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let avatarURL = try await ChallengeSocialService.shared.uploadProfileAvatar(
                    imageData: data
                )

                profile.avatarURL = avatarURL
                try? modelContext.save()

                try? await ChallengeSocialService.shared.updateProfile(
                    userID: profile.userID,
                    username: profile.username,
                    avatarName: profile.avatarName,
                    avatarURL: avatarURL,
                    bio: profile.bio,
                    favoriteGenre: profile.favoriteGenre,
                    readingStreak: profile.readingStreak,
                    challengePoints: profile.challengePoints,
                    challengesCompleted: profile.challengesCompleted,
                    followersCount: profile.followersCount,
                    followingCount: profile.followingCount
                )
            }
        } catch {
            print("Failed to upload avatar image:", error)
        }
    }

    private func statusIcon(for status: ChallengeSubmissionStatus) -> String {
        switch status {
        case .approved:
            return "checkwavy"
        case .inProgress:
            return "clockfill"
        case .needsMoreInfo:
            return "questionwavy"
        case .rejected:
            return "xmarkwavy"
        case .validating, .submitted:
            return "sparkle"
        case .joined, .readyToSubmit:
            return "openbook"
        case .expired:
            return "clockfill"
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
