//
//  ChallengeCommentsSheet.swift
//  Lumey
//

import SwiftUI

struct ChallengeCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let feedItem: ChallengeFeedItemDTO
    let post: ChallengeFeedPostDTO?
    let profile: ChallengeUserProfileDTO?
    let comments: [ChallengeCommentDTO]
    let currentUserID: String
    let currentUsername: String

    var isCommentLiked: ((ChallengeCommentDTO) -> Bool)?
    var onAddComment: ((String) -> Void)?
    var onAddReply: ((String, String) -> Void)?
    var onToggleCommentLike: ((ChallengeCommentDTO) -> Void)?
    var onDeleteComment: ((ChallengeCommentDTO) -> Void)?

    @State private var commentText: String = ""
    @State private var replyingTo: ChallengeCommentDTO?
    @State private var commentToDelete: ChallengeCommentDTO?
    @State private var showDeleteAlert = false
    @State private var visibleCount = 6

    // MARK: - Threading

    private var topLevelComments: [ChallengeCommentDTO] {
        comments
            .filter { $0.parentCommentID == nil }
            .sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
    }

    private func directReplies(for comment: ChallengeCommentDTO) -> [ChallengeCommentDTO] {
        guard let commentID = comment.id else { return [] }

        return comments
            .filter { $0.parentCommentID == commentID }
            .sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
    }
    
    private func threadedCommentBranch(_ comment: ChallengeCommentDTO, depth: Int) -> AnyView {
        let replies = directReplies(for: comment)
        let cappedDepth = min(depth, 4)
        let indent = CGFloat(cappedDepth) * 26

        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                threadLine
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 12) {
                    commentCard(comment, isReply: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !replies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(replies, id: \.id) { reply in
                                threadedCommentBranch(reply, depth: depth + 1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, indent)
        )
    }

    private var visibleTopLevel: [ChallengeCommentDTO] {
        Array(topLevelComments.prefix(visibleCount))
    }

    private var hasMore: Bool {
        topLevelComments.count > visibleCount
    }

    private var displayUsername: String {
        let profileName = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !profileName.isEmpty { return profileName }
        let itemName = feedItem.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return itemName.isEmpty ? "Reader" : itemName
    }

    private var displayText: String {
        let postText = post?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !postText.isEmpty { return formattedFeedText(postText) }
        return formattedFeedText(feedItem.text)
    }

    private var displayPhotoURL: String {
        let p = post?.photoURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !p.isEmpty { return p }
        return feedItem.photoURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayPhotoBase64: String {
        let p = post?.photoBase64?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !p.isEmpty { return p }
        return feedItem.photoBase64?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func formattedFeedText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard feedItem.feedType == "submission" else { return trimmed }
        guard !trimmed.contains("\n") else { return trimmed }

        return trimmed.replacingOccurrences(of: ", ", with: "\n")
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        EmptyView()

                        if topLevelComments.isEmpty {
                            emptyState
                        } else {
                            ForEach(visibleTopLevel, id: \.id) { comment in
                                VStack(alignment: .leading, spacing: 12) {
                                    commentCard(comment, isReply: false)

                                    let commentReplies = directReplies(for: comment)
                                    if !commentReplies.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(commentReplies, id: \.id) { reply in
                                                threadedCommentBranch(reply, depth: 1)
                                            }
                                        }
                                        .padding(.top, 6)
                                    }
                                }
                            }

                            if hasMore {
                                loadMoreButton
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 110)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.accents.primary)
                }
            }
        }
        .lumeyAlertConfirm(
            isPresented: $showDeleteAlert,
            title: "Delete Comment?",
            message: "This will remove your comment.",
            confirmTitle: "Delete",
            confirmRole: .destructive
        ) {
            if let commentToDelete {
                onDeleteComment?(commentToDelete)
                self.commentToDelete = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Comments")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("\(comments.count) \(comments.count == 1 ? "comment" : "comments")")
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
                    .foregroundStyle(LColors.accents.contrast)
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

    // MARK: - Thread Line

    private var threadLine: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(LGradients.blue)
            .frame(width: 2)
            .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 14) {
                Image("chatfolder")
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
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                            )
                    )

                VStack(spacing: 6) {
                    Text("No Comments Yet")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Start the conversation on this post.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Load More

    private var loadMoreButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                visibleCount += 6
            }
        } label: {
            Text("Load More")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Capsule(style: .continuous)
                        .fill(LGradients.blue)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Comment Card

    private func commentCard(_ comment: ChallengeCommentDTO, isReply: Bool) -> some View {
        let liked = isCommentLiked?(comment) ?? false

        return GlassCard(padding: 14, variant: .primary) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 11) {
                    commentAvatar(for: comment, size: isReply ? 34 : 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName(for: comment))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)

                        Text((comment.createdDate ?? .now).formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer()

                    if comment.userID == currentUserID {
                        Button {
                            commentToDelete = comment
                            showDeleteAlert = true
                        } label: {
                            Image("trash")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(LColors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(isReply ? "chatsparkle" : "starchat")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(LColors.accents.special)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(LColors.glassSurface)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                                    )
                            )
                    }
                }

                Text(comment.text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    Button {
                        onToggleCommentLike?(comment)
                    } label: {
                        HStack(spacing: 5) {
                            Image("heartwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(
                                    liked
                                    ? AnyShapeStyle(LColors.gradientPurple)
                                    : AnyShapeStyle(LColors.textSecondary)
                                )

                            Text("\(comment.likeCount)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        if replyingTo?.id == comment.id {
                            replyingTo = nil
                            commentText = ""
                        } else {
                            replyingTo = comment
                            commentText = "@\(displayName(for: comment)) "
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image("chatsparkle")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(
                                    replyingTo?.id == comment.id
                                    ? AnyShapeStyle(.white)
                                    : AnyShapeStyle(LColors.textSecondary)
                                )

                            Text("Reply")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 2)

                if replyingTo?.id == comment.id {
                    commentComposer
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func commentAvatar(for comment: ChallengeCommentDTO, size: CGFloat) -> some View {
        UserAvatarView(
            avatarURL: resolvedAvatarURL(for: comment),
            avatarName: resolvedAvatarName(for: comment),
            size: size,
            iconSize: size * 0.6
        )
    }
    
    private func resolvedAvatarURL(for comment: ChallengeCommentDTO) -> String? {
        let commentURL = comment.avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !commentURL.isEmpty {
            return commentURL
        }

        if comment.userID == profile?.userID {
            let profileURL = profile?.avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return profileURL.isEmpty ? nil : profileURL
        }

        return nil
    }

    private func resolvedAvatarName(for comment: ChallengeCommentDTO) -> String? {
        let commentAvatarName = comment.avatarName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !commentAvatarName.isEmpty {
            return commentAvatarName
        }

        if comment.userID == profile?.userID {
            let profileAvatarName = profile?.avatarName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return profileAvatarName.isEmpty ? nil : profileAvatarName
        }

        return nil
    }

    // MARK: - Composer

    private var commentComposer: some View {
        GlassCard(padding: 14, variant: .secondary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image("chatsparkle")
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
                                    Circle()
                                        .strokeBorder(LColors.accents.special, lineWidth: 1)
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyingTo == nil ? "Add a Comment" : "Write a Reply")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(replyingTo == nil ? "Join the conversation on this post." : "Replying to \(displayName(for: replyingTo!))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if replyingTo != nil {
                        Button {
                            replyingTo = nil
                            commentText = ""
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField(
                    replyingTo != nil ? "Write a reply..." : "Write a comment...",
                    text: $commentText,
                    axis: .vertical
                )
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2...5)
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LColors.surface.nested)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(LColors.border.nested, lineWidth: 1)
                        )
                )

                Button {
                    submitComment()
                } label: {
                    HStack(spacing: 8) {
                        Image("starmailing")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)

                        Text(replyingTo == nil ? "Post Comment" : "Post Reply")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(canSubmit ? AnyShapeStyle(LColors.accents.primary) : AnyShapeStyle(LColors.glassSurface))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
        }
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let replyingTo, let parentID = replyingTo.id {
            onAddReply?(trimmed, parentID)
        } else {
            onAddComment?(trimmed)
        }

        commentText = ""
        replyingTo = nil
    }

    private func displayName(for comment: ChallengeCommentDTO) -> String {
        let trimmed = comment.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }
}
