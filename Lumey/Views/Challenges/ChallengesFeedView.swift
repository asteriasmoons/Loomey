//
//  ChallengesFeedView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ChallengesFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var submissions: [ChallengeSubmission]

    @Query(sort: \ChallengeComment.createdDate)
    private var comments: [ChallengeComment]

    @Query(sort: \ChallengeLike.createdDate)
    private var likes: [ChallengeLike]

    @Query(sort: \ChallengeUserProfile.username)
    private var profiles: [ChallengeUserProfile]

    @Query(sort: \Book.title)
    private var books: [Book]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var feedResponse: ChallengeFeedResponseDTO?
    @State private var isLoadingFeed = false
    @State private var feedErrorMessage: String?
    @State private var showingCreatePostSheet = false
    @State private var selectedFeedItemForComments: ChallengeFeedItemDTO?
    @State private var selectedChallengeProfile: ChallengeUserProfile?
    @State private var showingAnnouncementComposer = false
    @State private var announcementTitle = ""
    @State private var announcementBody = ""
    @State private var isPostingAnnouncement = false
    @State private var showingAnnouncementIconPicker = false
    @State private var selectedAnnouncementIcon = ""
    @State private var isAnnouncementComposerCollapsed = false

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var currentUsername: String {
        profiles.first(where: { $0.userID == currentUserID })?.username ?? "Reader"
    }

    private var currentProfile: ChallengeUserProfile? {
        profiles.first(where: { $0.userID == currentUserID })
    }

    private var feedItems: [ChallengeFeedItemDTO] {
        feedResponse?.feedItems ?? []
    }

    private var feedPosts: [ChallengeFeedPostDTO] {
        feedResponse?.posts ?? []
    }

    private var feedSubmissions: [ChallengeSubmissionDTO] {
        feedResponse?.submissions ?? []
    }

    private var feedComments: [ChallengeCommentDTO] {
        feedResponse?.comments ?? []
    }

    private var feedLikes: [ChallengeLikeDTO] {
        feedResponse?.likes ?? []
    }

    private var feedCommentLikes: [ChallengeCommentLikeDTO] {
        feedResponse?.commentLikes ?? []
    }

    private var feedProfiles: [ChallengeUserProfileDTO] {
        feedResponse?.profiles ?? []
    }

    private var feedAnnouncements: [ChallengeFeedAnnouncementDTO] {
        feedResponse?.announcements ?? []
    }

    private var isAdmin: Bool {
        currentUserID == VoxAdmin.adminUserID
    }

    private func bookTitle(for id: String?) -> String? {
        guard let id,
              let uuid = UUID(uuidString: id) else {
            return nil
        }

        return books.first(where: { $0.id == uuid })?.title
    }

    private func challengeTitle(for id: String?) -> String? {
        guard let id,
              let uuid = UUID(uuidString: id) else {
            return nil
        }

        return challenges.first(where: { $0.id == uuid })?.title
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Sticky announcement at top
                        ForEach(feedAnnouncements) { announcement in
                            ChallengeAnnouncementCard(
                                announcement: announcement,
                                profile: profileDTO(forUserID: announcement.userID),
                                onDeleteTapped: isAdmin ? {
                                    Task {
                                        await deleteAnnouncement(announcement)
                                    }
                                } : nil
                            )
                        }

                        // Admin-only announcement composer
                        if isAdmin {
                            announcementComposerCard
                        }

                        InlineChallengeFeedPostComposer(
                            currentUserID: currentUserID,
                            currentUsername: currentUsername,
                            onPostCreated: { createdItem in
                                insertFeedItem(createdItem)
                            }
                        )

                        if isLoadingFeed && feedItems.isEmpty {
                            loadingState
                        } else if feedItems.isEmpty {
                            emptyState
                        } else {
                            ForEach(feedItems) { feedItem in
                                feedCard(for: feedItem)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .refreshable {
                    await loadFeed()
                }
            }
        }
        .task {
            await loadFeed()
        }
        .adaptivePresentation(item: $selectedFeedItemForComments, useFullScreenCover: horizontalSizeClass == .regular) { feedItem in
            ChallengeCommentsSheet(
                feedItem: feedItem,
                post: postDTO(for: feedItem),
                profile: profileDTO(for: feedItem),
                comments: commentsFor(feedItem),
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                isCommentLiked: { comment in
                    isCommentLiked(comment)
                },
                onAddComment: { text in
                    Task {
                        await addComment(text, to: feedItem)
                    }
                },
                onAddReply: { text, parentCommentID in
                    Task {
                        await addReply(text, to: feedItem, parentCommentID: parentCommentID)
                    }
                },
                onToggleCommentLike: { comment in
                    Task {
                        await toggleCommentLike(comment)
                    }
                },
                onDeleteComment: { comment in
                    Task {
                        await deleteComment(comment)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $selectedChallengeProfile, useFullScreenCover: horizontalSizeClass == .regular) { profile in
            ProfileView(
                challengeProfile: profile,
                recentChallengeSubmissions: submissions.filter {
                    $0.userID == profile.userID
                },
                showsCloseButton: true
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingAnnouncementIconPicker, useFullScreenCover: horizontalSizeClass == .regular) {
            AnnouncementIconInsertPicker { iconName in
                announcementBody.append("{{" + iconName + "}}")
                showingAnnouncementIconPicker = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Challenge Feed")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("See what readers are submitting")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

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

    // MARK: - Announcement Composer (Admin Only)

    private var announcementComposerCard: some View {
        GlassCard(padding: 14, variant: .secondary) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image("megaphone")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(LColors.accents.contrast)

                    Text("Post Announcement")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            isAnnouncementComposerCollapsed.toggle()
                        }
                    } label: {
                        Image(isAnnouncementComposerCollapsed ? "chevdown" : "chevup")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(LColors.accents.secondary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(LColors.glassSurface)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                if !isAnnouncementComposerCollapsed {
                    TextField("Title", text: $announcementTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LColors.glassSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )

                    FormattingTextEditor(
                        text: $announcementBody,
                        placeholder: "Body",
                        minHeight: 100,
                        onIconPickerTapped: {
                            showingAnnouncementIconPicker = true
                        }
                    )
                    .frame(minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button {
                        Task { await postAnnouncement() }
                    } label: {
                        Text(isPostingAnnouncement ? "Posting..." : "Publish Announcement")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        canPostAnnouncement && !isPostingAnnouncement
                                        ? AnyShapeStyle(LColors.accents.contrast)
                                        : AnyShapeStyle(LColors.glassSurface)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canPostAnnouncement || isPostingAnnouncement)
                }
            }
        }
    }

    private var canPostAnnouncement: Bool {
        !announcementTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !announcementBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func postAnnouncement() async {
        guard canPostAnnouncement else { return }

        isPostingAnnouncement = true

        do {
            let created = try await ChallengeSocialService.shared.createAnnouncement(
                title: announcementTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                body: announcementBody.trimmingCharacters(in: .whitespacesAndNewlines),
                userID: currentUserID,
                username: currentUsername,
                avatarURL: currentProfile?.avatarURL,
                avatarName: currentProfile?.avatarName
            )

            // Add to local state
            if var response = feedResponse {
                var announcements = response.announcements ?? []
                announcements.insert(created, at: 0)
                response.announcements = announcements
                feedResponse = response
            }

            announcementTitle = ""
            announcementBody = ""
        } catch {
            feedErrorMessage = error.localizedDescription
        }

        isPostingAnnouncement = false
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 14) {
                Image("bookchat")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(LColors.accents.special)
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
                    Text("No Feed Entries Yet")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Challenge submissions will appear here once readers submit entries.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Feed Cards

    @ViewBuilder
    private func feedCard(for feedItem: ChallengeFeedItemDTO) -> some View {
        switch feedItem.feedType {
        case "post":
            ChallengeFeedPostCard(
                feedItem: feedItem,
                profile: profileDTO(for: feedItem),
                post: postDTO(for: feedItem),
                linkedBookTitle: bookTitle(for: postDTO(for: feedItem)?.linkedBookID),
                linkedChallengeTitle: challengeTitle(for: postDTO(for: feedItem)?.linkedChallengeID),
                isLiked: isLiked(feedItem),
                onLikeTapped: {
                    Task {
                        await toggleLike(for: feedItem)
                    }
                },
                onCommentTapped: {
                    // Inline comment box opens inside ChallengeFeedPostCard.
                },
                onSubmitComment: { text in
                    Task {
                        await addComment(text, to: feedItem)
                    }
                },
                onOpenComments: {
                    selectedFeedItemForComments = feedItem
                },
                onProfileTapped: {
                    selectChallengeProfile(for: feedItem)
                },
                onDeleteTapped: {
                    Task {
                        await deleteFeedPost(feedItem)
                    }
                }
            )

        case "submission":
            if let submission = submissionDTO(for: feedItem) {
                ChallengeFeedEntryCard(
                    submission: submission,
                    linkedBookTitle: nil,
                    rating: nil,
                    avatarName: profileDTO(for: feedItem)?.avatarName,
                    avatarURL: profileDTO(for: feedItem)?.avatarURL,
                    likeCount: feedItem.likeCount,
                    commentCount: feedItem.commentCount,
                    isLiked: isLiked(feedItem),
                    onLikeTapped: {
                        Task {
                            await toggleLike(for: feedItem)
                        }
                    },
                    onCommentTapped: {
                        // Inline comment box opens inside ChallengeFeedEntryCard.
                    },
                    onSubmitComment: { text in
                        Task {
                            await addComment(text, to: feedItem)
                        }
                    },
                    onOpenComments: {
                        selectedFeedItemForComments = feedItem
                    },
                    onProfileTapped: {
                        selectChallengeProfile(for: feedItem)
                    }
                )
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        GlassCard(variant: .primary) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)

                Text("Loading feed...")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Spacer()
            }
        }
    }

    // MARK: - Backend Actions

    @MainActor
    private func loadFeed() async {
        isLoadingFeed = true

        do {
            feedResponse = try await ChallengeSocialService.shared.fetchFeed()

            print("FEED ITEMS:", feedResponse?.feedItems.count ?? -1)
            print("POST ITEMS:", feedResponse?.feedItems.filter { $0.feedType == "post" }.count ?? -1)
            print("POST DTOs:", feedResponse?.posts.count ?? -1)
            print("POST IDS:", feedResponse?.feedItems.compactMap { $0.postID })
            print("DTO IDS:", feedResponse?.posts.compactMap { $0.id })

            feedErrorMessage = nil
        } catch {
            feedErrorMessage = error.localizedDescription
        }

        isLoadingFeed = false
    }

    @MainActor
    private func toggleLike(for feedItem: ChallengeFeedItemDTO) async {
        guard let feedItemID = feedItem.id else { return }

        do {
            let result = try await ChallengeSocialService.shared.toggleFeedItemLike(
                feedItemID: feedItemID,
                userID: currentUserID
            )

            updateLikeState(
                feedItemID: feedItemID,
                liked: result.liked,
                likeCount: result.likeCount
            )
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteFeedPost(_ feedItem: ChallengeFeedItemDTO) async {
        guard let feedItemID = feedItem.id else { return }
        let postID = feedItem.postID ?? feedItemID

        do {
            try await ChallengeSocialService.shared.deleteFeedPost(postID: postID)
            removeFeedItem(feedItemID)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteAnnouncement(_ announcement: ChallengeFeedAnnouncementDTO) async {
        guard let announcementID = announcement.id else { return }

        do {
            try await ChallengeSocialService.shared.deleteAnnouncement(
                announcementID: announcementID
            )

            removeAnnouncement(announcementID)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func removeFeedItem(_ feedItemID: String) {
        guard var response = feedResponse else { return }

        response.feedItems.removeAll { $0.id == feedItemID }
        response.likes.removeAll { $0.feedItemID == feedItemID }
        response.comments.removeAll { $0.feedItemID == feedItemID }

        feedResponse = response
    }

    @MainActor
    private func removeAnnouncement(_ announcementID: String) {
        guard var response = feedResponse else { return }

        response.announcements?.removeAll {
            $0.id == announcementID
        }

        feedResponse = response
    }

    @MainActor
    private func addComment(_ text: String, to feedItem: ChallengeFeedItemDTO) async {
        guard let feedItemID = feedItem.id else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let comment = try await ChallengeSocialService.shared.addFeedItemComment(
                feedItemID: feedItemID,
                userID: currentUserID,
                username: currentUsername,
                avatarName: profileDTO(for: feedItem)?.avatarName,
                avatarURL: profileDTO(for: feedItem)?.avatarURL,
                text: trimmed
            )

            appendComment(comment, feedItemID: feedItemID)
            ReadingXPService.awardChallengeFeedComment(comment, modelContext: modelContext)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteComment(_ comment: ChallengeCommentDTO) async {
        guard let commentID = comment.id else { return }

        do {
            try await ChallengeSocialService.shared.deleteComment(commentID: commentID)
            removeComment(comment)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func addReply(_ text: String, to feedItem: ChallengeFeedItemDTO, parentCommentID: String) async {
        guard let feedItemID = feedItem.id else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let comment = try await ChallengeSocialService.shared.addFeedItemComment(
                feedItemID: feedItemID,
                userID: currentUserID,
                username: currentUsername,
                avatarName: profileDTO(for: feedItem)?.avatarName,
                avatarURL: profileDTO(for: feedItem)?.avatarURL,
                text: trimmed,
                parentCommentID: parentCommentID
            )
            appendComment(comment, feedItemID: feedItemID)
            ReadingXPService.awardChallengeFeedComment(comment, modelContext: modelContext)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func toggleCommentLike(_ comment: ChallengeCommentDTO) async {
        guard let commentID = comment.id else { return }

        do {
            let result = try await ChallengeSocialService.shared.toggleCommentLike(
                commentID: commentID,
                userID: currentUserID
            )
            updateCommentLikeState(commentID: commentID, liked: result.liked, likeCount: result.likeCount)
        } catch {
            feedErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Local Feed Updates

    @MainActor
    private func insertFeedItem(_ item: ChallengeFeedItemDTO) {
        guard var response = feedResponse else {
            feedResponse = ChallengeFeedResponseDTO(
                feedItems: [item],
                submissions: [],
                posts: [],
                comments: [],
                likes: [],
                commentLikes: [],
                profiles: [],
                announcements: []
            )
            return
        }

        response.feedItems.insert(item, at: 0)
        feedResponse = response
    }

    @MainActor
    private func updateLikeState(feedItemID: String, liked: Bool, likeCount: Int) {
        guard var response = feedResponse else { return }

        response.feedItems = response.feedItems.map { item in
            guard item.id == feedItemID else { return item }

            return ChallengeFeedItemDTO(
                id: item.id,
                feedType: item.feedType,
                submissionID: item.submissionID,
                postID: item.postID,
                userID: item.userID,
                username: item.username,
                challengeID: item.challengeID,
                challengeTitle: item.challengeTitle,
                text: item.text,
                photoURL: item.photoURL,
                photoBase64: item.photoBase64,
                likeCount: likeCount,
                commentCount: item.commentCount,
                createdDate: item.createdDate
            )
        }

        if liked {
            let like = ChallengeLikeDTO(
                id: nil,
                feedItemID: feedItemID,
                userID: currentUserID,
                createdDate: Date()
            )

            response.likes.append(like)
        } else {
            response.likes.removeAll {
                $0.feedItemID == feedItemID && $0.userID == currentUserID
            }
        }

        feedResponse = response
    }

    @MainActor
    private func appendComment(_ comment: ChallengeCommentDTO, feedItemID: String) {
        guard var response = feedResponse else { return }

        response.comments.append(comment)

        response.feedItems = response.feedItems.map { item in
            guard item.id == feedItemID else { return item }

            return ChallengeFeedItemDTO(
                id: item.id,
                feedType: item.feedType,
                submissionID: item.submissionID,
                postID: item.postID,
                userID: item.userID,
                username: item.username,
                challengeID: item.challengeID,
                challengeTitle: item.challengeTitle,
                text: item.text,
                photoURL: item.photoURL,
                photoBase64: item.photoBase64,
                likeCount: item.likeCount,
                commentCount: item.commentCount + 1,
                createdDate: item.createdDate
            )
        }

        feedResponse = response
    }

    @MainActor
    private func removeComment(_ comment: ChallengeCommentDTO) {
        guard var response = feedResponse else { return }

        response.comments.removeAll { $0.id == comment.id }

        response.feedItems = response.feedItems.map { item in
            guard item.id == comment.feedItemID else { return item }

            return ChallengeFeedItemDTO(
                id: item.id,
                feedType: item.feedType,
                submissionID: item.submissionID,
                postID: item.postID,
                userID: item.userID,
                username: item.username,
                challengeID: item.challengeID,
                challengeTitle: item.challengeTitle,
                text: item.text,
                photoURL: item.photoURL,
                photoBase64: item.photoBase64,
                likeCount: item.likeCount,
                commentCount: max(0, item.commentCount - 1),
                createdDate: item.createdDate
            )
        }

        feedResponse = response
    }

    @MainActor
    private func updateCommentLikeState(commentID: String, liked: Bool, likeCount: Int) {
        guard var response = feedResponse else { return }

        response.comments = response.comments.map { c in
            guard c.id == commentID else { return c }
            return ChallengeCommentDTO(
                id: c.id,
                feedItemID: c.feedItemID,
                parentCommentID: c.parentCommentID,
                userID: c.userID,
                username: c.username,
                avatarName: c.avatarName,
                avatarURL: c.avatarURL,
                text: c.text,
                likeCount: likeCount,
                createdDate: c.createdDate
            )
        }

        if liked {
            response.commentLikes.append(ChallengeCommentLikeDTO(
                id: nil, commentID: commentID, userID: currentUserID, createdDate: Date()
            ))
        } else {
            response.commentLikes.removeAll {
                $0.commentID == commentID && $0.userID == currentUserID
            }
        }

        feedResponse = response
    }

    private func isCommentLiked(_ comment: ChallengeCommentDTO) -> Bool {
        guard let commentID = comment.id else { return false }
        return feedCommentLikes.contains {
            $0.commentID == commentID && $0.userID == currentUserID
        }
    }

    // MARK: - Lookup Helpers

    private func isLiked(_ feedItem: ChallengeFeedItemDTO) -> Bool {
        guard let feedItemID = feedItem.id else { return false }

        return feedLikes.contains {
            $0.feedItemID == feedItemID && $0.userID == currentUserID
        }
    }

    private func commentsFor(_ feedItem: ChallengeFeedItemDTO) -> [ChallengeCommentDTO] {
        guard let feedItemID = feedItem.id else { return [] }

        return feedComments.filter { $0.feedItemID == feedItemID }
    }

    @MainActor
    private func selectChallengeProfile(for feedItem: ChallengeFeedItemDTO) {
        let dto = profileDTO(for: feedItem)

        if let existing = profiles.first(where: { $0.userID == feedItem.userID }) {
            syncChallengeProfile(existing, with: dto, fallbackUsername: feedItem.username)
            selectedChallengeProfile = existing
            return
        }

        let username = dto?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? feedItem.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = ChallengeUserProfile(
            userID: feedItem.userID,
            username: username.isEmpty ? "Reader" : username,
            avatarName: cleaned(dto?.avatarName),
            avatarImageData: nil,
            avatarURL: cleaned(dto?.avatarURL),
            bio: cleaned(dto?.bio),
            favoriteGenre: cleaned(dto?.favoriteGenre)
        )

        if let dto {
            profile.readingStreak = dto.readingStreak
            profile.challengePoints = dto.challengePoints
            profile.challengesCompleted = dto.challengesCompleted
            profile.followersCount = dto.followersCount
            profile.followingCount = dto.followingCount
        }

        modelContext.insert(profile)
        try? modelContext.save()

        selectedChallengeProfile = profile
    }

    private func syncChallengeProfile(
        _ profile: ChallengeUserProfile,
        with dto: ChallengeUserProfileDTO?,
        fallbackUsername: String
    ) {
        let fallbackUsername = fallbackUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let dto else {
            if profile.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                profile.username = fallbackUsername.isEmpty ? "Reader" : fallbackUsername
            }
            try? modelContext.save()
            return
        }

        let username = dto.username.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.username = username.isEmpty ? (fallbackUsername.isEmpty ? "Reader" : fallbackUsername) : username
        profile.avatarName = cleaned(dto.avatarName)
        profile.avatarURL = cleaned(dto.avatarURL)
        profile.bio = cleaned(dto.bio)
        profile.favoriteGenre = cleaned(dto.favoriteGenre)
        profile.readingStreak = dto.readingStreak
        profile.challengePoints = dto.challengePoints
        profile.challengesCompleted = dto.challengesCompleted
        profile.followersCount = dto.followersCount
        profile.followingCount = dto.followingCount

        try? modelContext.save()
    }

    private func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func profileDTO(for feedItem: ChallengeFeedItemDTO) -> ChallengeUserProfileDTO? {
        feedProfiles.first { $0.userID == feedItem.userID }
    }

    private func profileDTO(forUserID userID: String) -> ChallengeUserProfileDTO? {
        feedProfiles.first { $0.userID == userID }
    }

    private func postDTO(for feedItem: ChallengeFeedItemDTO) -> ChallengeFeedPostDTO? {
        guard let postID = feedItem.postID else { return nil }

        return feedPosts.first { $0.id == postID }
    }

    private func submissionDTO(for feedItem: ChallengeFeedItemDTO) -> ChallengeSubmissionDTO? {
        guard let submissionID = feedItem.submissionID else { return nil }

        return feedSubmissions.first { $0.id == submissionID }
    }
}

private struct InlineChallengeFeedPostComposer: View {
    let currentUserID: String
    let currentUsername: String
    let onPostCreated: ((ChallengeFeedItemDTO) -> Void)?

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.title)
    private var books: [Book]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var postText = ""
    @State private var photoCaption = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedBook: Book?
    @State private var selectedChallenge: ReadingChallenge?
    @State private var selectedMood = ""
    @State private var containsSpoilers = false
    @State private var visibility: String = "public"
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isComposerFocused: Bool

    private let moods = ["Cozy", "Excited", "Reflective", "Dramatic", "Soft", "Chaotic", "Inspired", "Curious", "Emotional", "Magical"]

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPhotoData != nil
    }

    var body: some View {
        GlassCard(padding: 14, variant: .tertiary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(LColors.accents.primary)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Circle().strokeBorder(LColors.accents.special, lineWidth: 1)
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Post to the Feed")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("Share a thought, update, or reading moment.")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer()
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $postText)
                        .focused($isComposerFocused)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 92)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LColors.surface.nested)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(LColors.border.nested, lineWidth: 1)
                                )
                        )


                    if postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("What are you reading or thinking about?")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.75))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }

                if let selectedPhotoData,
                   let uiImage = UIImage(data: selectedPhotoData) {
                    VStack(spacing: 10) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 170)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .allowsHitTesting(false)

                        TextField("Photo caption optional", text: $photoCaption)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LColors.surface.nested)
                            )
                    }
                }

                WrappingHStack(horizontalSpacing: 10, verticalSpacing: 10) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        miniButton(icon: "image", title: selectedPhotoData == nil ? "Photo" : "Change")
                    }
                    .buttonStyle(.plain)

                    if selectedPhotoData != nil {
                        Button {
                            selectedPhotoItem = nil
                            selectedPhotoData = nil
                            photoCaption = ""
                        } label: {
                            miniButton(icon: "trash", title: "Remove")
                        }
                        .buttonStyle(.plain)
                    }

                    Menu {
                        Button("No Mood") { selectedMood = "" }
                        ForEach(moods, id: \.self) { mood in
                            Button(mood) { selectedMood = mood }
                        }
                    } label: {
                        miniButton(icon: "sparkle", title: selectedMood.isEmpty ? "Mood" : selectedMood)
                    }

                    Menu {
                        Button("No Book") { selectedBook = nil }

                        ForEach(books) { book in
                            Button(book.title) {
                                selectedBook = book
                            }
                        }
                    } label: {
                        miniButton(
                            icon: "openbook",
                            title: selectedBook == nil ? "Book" : "Book Linked"
                        )
                    }

                    Menu {
                        Button("No Challenge") { selectedChallenge = nil }

                        ForEach(challenges) { challenge in
                            Button(challenge.title) {
                                selectedChallenge = challenge
                            }
                        }
                    } label: {
                        miniButton(
                            icon: "startrophyfill",
                            title: selectedChallenge == nil ? "Challenge" : "Challenge Linked"
                        )
                    }
                }

                Toggle("Contains Spoilers", isOn: $containsSpoilers)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Button {
                    Task { await submitPost() }
                } label: {
                    Text(isPosting ? "Posting..." : "Post")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(canPost && !isPosting ? AnyShapeStyle(LColors.accents.secondary) : AnyShapeStyle(LColors.glassSurface))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canPost || isPosting)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await loadPhoto(from: newItem) }
        }
        .alert("Post Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Lumey could not create this feed post.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.accents.contrast)
                }
            }
        }
    }

    private func miniButton(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .layoutPriority(1)

            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
        }
        .foregroundStyle(.white)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LColors.accents.primary, lineWidth: 1)
                )
        )
    }

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            selectedPhotoData = try await item.loadTransferable(type: Data.self)
        } catch {
            errorMessage = "Lumey could not load this photo."
            showError = true
        }
    }

    @MainActor
    private func submitPost() async {
        guard canPost else { return }

        isPosting = true

        do {
            let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCaption = photoCaption.trimmingCharacters(in: .whitespacesAndNewlines)

            let photoURL: String?
            if let selectedPhotoData {
                photoURL = try await ChallengeSocialService.shared.uploadFeedPhoto(imageData: selectedPhotoData)
            } else {
                photoURL = nil
            }

            let created = try await ChallengeSocialService.shared.createFeedPost(
                userID: currentUserID,
                username: currentUsername,
                text: trimmedText,
                photoURL: photoURL,
                photoBase64: nil,
                photoCaption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                linkedBookID: selectedBook?.id.uuidString,
                linkedChallengeID: selectedChallenge?.id.uuidString,
                mood: selectedMood.isEmpty ? nil : selectedMood,
                containsSpoilers: containsSpoilers,
                visibility: visibility
            )

            onPostCreated?(created)
            ReadingXPService.awardChallengeFeedPost(created, modelContext: modelContext)

            postText = ""
            photoCaption = ""
            selectedPhotoItem = nil
            selectedPhotoData = nil
            selectedBook = nil
            selectedChallenge = nil
            selectedMood = ""
            containsSpoilers = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPosting = false
    }

    private struct WrappingHStack: Layout {
        var horizontalSpacing: CGFloat = 8
        var verticalSpacing: CGFloat = 8

        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) -> CGSize {
            let maxWidth = proposal.width ?? .infinity
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var totalWidth: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }

                totalWidth = max(totalWidth, currentX + size.width)
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + horizontalSpacing
            }

            return CGSize(
                width: maxWidth.isFinite ? maxWidth : totalWidth,
                height: currentY + lineHeight
            )
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) {
            var currentX = bounds.minX
            var currentY = bounds.minY
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                    currentX = bounds.minX
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }

                subview.place(
                    at: CGPoint(x: currentX, y: currentY),
                    proposal: ProposedViewSize(size)
                )

                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
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
