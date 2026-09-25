//
//  ChallengeFeedPostCard.swift
//  Lumey
//

import SwiftUI
import UIKit

struct ChallengeFeedPostCard: View {
    @Environment(\.appTheme) private var theme

    let feedItem: ChallengeFeedItemDTO
    let profile: ChallengeUserProfileDTO?
    let post: ChallengeFeedPostDTO?
    let linkedBookTitle: String?
    let linkedChallengeTitle: String?
    var accentColor: Color = LColors.accents.primary

    let isLiked: Bool
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onSubmitComment: (String) -> Void
    let onOpenComments: () -> Void
    let onProfileTapped: () -> Void
    let onDeleteTapped: (() -> Void)?
    
    @State private var showInlineCommentBox = false
    @State private var inlineCommentText = ""

    private var displayUsername: String {
        let profileUsername = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !profileUsername.isEmpty {
            return profileUsername
        }

        let itemUsername = feedItem.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return itemUsername.isEmpty ? "Reader" : itemUsername
    }

    private var displayText: String {
        let postText = post?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !postText.isEmpty {
            return formattedFeedText(postText)
        }

        return formattedFeedText(feedItem.text)
    }

    private var displayPhotoURL: String {
        let postPhoto = post?.photoURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !postPhoto.isEmpty {
            return postPhoto
        }

        return feedItem.photoURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayPhotoBase64: String {
        let postPhoto = post?.photoBase64?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !postPhoto.isEmpty {
            return postPhoto
        }

        return feedItem.photoBase64?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayMood: String {
        post?.mood?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var hasSpoilers: Bool {
        post?.containsSpoilers ?? false
    }

    private var isEdited: Bool {
        post?.isEdited ?? false
    }

    var body: some View {
        GlassCard(padding: 14, variant: .featured, borderColor: accentColor) {
            VStack(alignment: .leading, spacing: 13) {
                headerRow

                if hasSpoilers {
                    spoilerBadge
                }

                if !displayText.isEmpty {
                    Text(displayText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !displayPhotoBase64.isEmpty {
                    base64PhotoView(displayPhotoBase64)
                } else if !displayPhotoURL.isEmpty {
                    remotePhotoView(urlString: displayPhotoURL)
                }

                if let caption = post?.photoCaption?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if shouldShowContextRow {
                    contextRow
                }

                actionRow

                if showInlineCommentBox {
                    inlineCommentBox
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 11) {
            Button {
                onProfileTapped()
            } label: {
                avatarView
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(displayUsername)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .lineLimit(1)

                    if isEdited {
                        Text("EDITED")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                HStack(spacing: 6) {
                    Text(feedItem.createdDate?.formatted(date: .abbreviated, time: .shortened) ?? "Just now")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    if !displayMood.isEmpty {
                        Circle()
                            .fill(LColors.textSecondary.opacity(0.65))
                            .frame(width: 3, height: 3)

                        Text(displayMood)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image("starchat")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .bubblyIconMaterial(tint: accentColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(accentColor, lineWidth: 1)
                        )
                )
        }
    }

    private var avatarView: some View {
        UserAvatarView(
            avatarURL: profile?.avatarURL,
            avatarName: profile?.avatarName,
            size: 40,
            iconSize: 24
        )
    }

    // MARK: - Spoiler

    private var spoilerBadge: some View {
        HStack(spacing: 7) {
            Image("eyeslash")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

            Text("Contains spoilers")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(LColors.surface.nested)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(LColors.accents.contrast, lineWidth: 1)
                )
        )
    }

    // MARK: - Photo

    private func base64PhotoView(_ base64String: String) -> some View {
        let cleaned = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")

        if let data = Data(base64Encoded: cleaned),
           let uiImage = UIImage(data: data) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                    )
            )
        } else {
            return AnyView(
                HStack(spacing: 10) {
                    Image("image")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(LColors.accents.special)

                    Text("Photo could not load")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(LColors.surface.nested)
                )
            )
        }
    }

    private func remotePhotoView(urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LColors.surface.nested)

                    ProgressView()
                        .tint(.white)
                }
                .frame(height: 220)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                    )

            case .failure:
                HStack(spacing: 10) {
                    Image("image")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(LColors.accents.primary)

                    Text("Photo could not load")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(LColors.surface.nested)
                )

            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Context

    private var shouldShowContextRow: Bool {
        !resolvedBookTitle.isEmpty || !resolvedChallengeTitle.isEmpty
    }
    
    private var resolvedBookTitle: String {
        let title = linkedBookTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title
    }

    private var resolvedChallengeTitle: String {
        let passedTitle = linkedChallengeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !passedTitle.isEmpty {
            return passedTitle
        }

        let feedTitle = feedItem.challengeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return feedTitle
    }

    private var contextRow: some View {
        HStack(spacing: 8) {
            let challengeTitle = resolvedChallengeTitle
            let bookTitle = resolvedBookTitle

            if !bookTitle.isEmpty {
                contextBadge(icon: "openbook", text: bookTitle)
            }

            if !challengeTitle.isEmpty {
                contextBadge(icon: "startrophyfill", text: challengeTitle)
            }

            Spacer(minLength: 0)
        }
    }

    private func contextBadge(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)

            Text(text)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(.clear)
                .overlay {
                    BubblyIconMaterial(tint: theme.palette.primaryAction)
                        .clipShape(Capsule(style: .continuous))
                }
        )
    }
    
    private var inlineCommentBox: some View {
        HStack(spacing: 10) {
            TextField("Write a comment...", text: $inlineCommentText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LColors.surface.nested)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1)
                        )
                )

            Button {
                let trimmed = inlineCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                onSubmitComment(trimmed)
                inlineCommentText = ""
                showInlineCommentBox = false
            } label: {
                Image("chatsparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 14) {
            Button {
                onLikeTapped()
            } label: {
                HStack(spacing: 5) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(
                            isLiked
                            ? AnyShapeStyle(theme.palette.indicators)
                            : AnyShapeStyle(LColors.textSecondary)
                        )
                        .bubblyIconMaterial(tint: isLiked ? theme.palette.indicators : theme.palette.secondaryAccent)

                    Text("\(feedItem.likeCount)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .buttonStyle(.plain)

            Button {
                showInlineCommentBox.toggle()
                onCommentTapped()
            } label: {
                HStack(spacing: 5) {
                    Image("chatsparkle")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(
                            AnyShapeStyle(theme.palette.secondaryAccent)
                        )
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

                    Text("\(feedItem.commentCount)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .buttonStyle(.plain)

            Button {
                onOpenComments()
            } label: {
                Image("chatfolder")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(
                        AnyShapeStyle(theme.palette.secondaryAccent)
                    )
                    .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
            }
            .buttonStyle(.plain)

            Spacer()

            if let onDeleteTapped {
                Button {
                    onDeleteTapped()
                } label: {
                    Image("trash")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private func formattedFeedText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard feedItem.feedType == "submission" else { return trimmed }
        guard !trimmed.contains("\n") else { return trimmed }

        return trimmed.replacingOccurrences(of: ", ", with: "\n")
    }
}
