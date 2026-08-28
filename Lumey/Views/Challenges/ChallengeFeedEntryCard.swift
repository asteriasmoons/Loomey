//
//  ChallengeFeedEntryCard.swift
//  Lumey
//

import SwiftUI

struct ChallengeFeedEntryCard: View {
    let submission: ChallengeSubmissionDTO

    var linkedBookTitle: String?
    var rating: Double?
    var avatarName: String?
    var avatarURL: String?
    var likeCount: Int?
    var commentCount: Int?
    var isLiked: Bool
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?
    var onSubmitComment: ((String) -> Void)?
    var onOpenComments: (() -> Void)?
    var onProfileTapped: (() -> Void)?
    var isCommenting: Bool = false

    @State private var showInlineCommentBox = false
    @State private var inlineCommentText = ""

    init(
        submission: ChallengeSubmissionDTO,
        linkedBookTitle: String? = nil,
        rating: Double? = nil,
        avatarName: String? = nil,
        avatarURL: String? = nil,
        likeCount: Int? = nil,
        commentCount: Int? = nil,
        isLiked: Bool = false,
        onLikeTapped: (() -> Void)? = nil,
        onCommentTapped: (() -> Void)? = nil,
        onSubmitComment: ((String) -> Void)? = nil,
        onOpenComments: (() -> Void)? = nil,
        onProfileTapped: (() -> Void)? = nil,
        isCommenting: Bool = false
    ) {
        self.submission = submission
        self.linkedBookTitle = linkedBookTitle
        self.rating = rating
        self.avatarName = avatarName
        self.avatarURL = avatarURL
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.onLikeTapped = onLikeTapped
        self.onCommentTapped = onCommentTapped
        self.onSubmitComment = onSubmitComment
        self.onOpenComments = onOpenComments
        self.onProfileTapped = onProfileTapped
        self.isCommenting = isCommenting
    }

    var body: some View {
        GlassCard(padding: 14, variant: .featured) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if let linkedBookTitle, !linkedBookTitle.isEmpty {
                    linkedBookPill(linkedBookTitle)
                }

                if let rating, rating > 0 {
                    ratingStars(rating)
                }

                if !displayNote.isEmpty {
                    Text("“\(displayNote)”")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let photoURL = submission.photoURL,
                   !photoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    proofPhoto(urlString: photoURL)
                }

                if !submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    proofPreview
                }

                footer

                if showInlineCommentBox {
                    inlineCommentBox
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                onProfileTapped?()
            } label: {
                avatarView
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayUsername)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                HStack(spacing: 6) {
                    Text((submission.submittedDate ?? .now).formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    statusBadge
                }
            }

            Spacer()
        }
    }

    private var avatarView: some View {
        UserAvatarView(
            avatarURL: avatarURL,
            avatarName: avatarName,
            size: 42,
            iconSize: 24
        )
    }

    private var statusBadge: some View {
        Text(submission.validationStatus.uppercased())
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(statusBadgeColor.opacity(0.75))
            )
    }

    private var statusBadgeColor: Color {
        switch submission.validationStatus {
        case "approved":
            return LColors.gradientGreen
        case "needsMoreInfo":
            return LColors.gradientYellow
        case "rejected":
            return LColors.gradientPurple
        case "validating":
            return LColors.gradientBlue
        default:
            return LColors.textSecondary
        }
    }

    // MARK: - Content

    private func linkedBookPill(_ title: String) -> some View {
        HStack(spacing: 6) {
            Image("openbook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(LColors.accents.primary)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
        )
    }

    private func ratingStars(_ rating: Double) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image("starfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(
                        index <= Int(rating.rounded())
                        ? AnyShapeStyle(.white)
                        : AnyShapeStyle(LColors.textSecondary)
                    )
            }
        }
    }

    private func proofPhoto(urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                proofPhotoPlaceholder
            case .empty:
                ZStack {
                    proofPhotoPlaceholder
                    ProgressView()
                        .tint(.white)
                }
            @unknown default:
                proofPhotoPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
        )
    }

    private var proofPhotoPlaceholder: some View {
        Rectangle()
            .fill(LColors.glassSurface)
            .overlay {
                Image("image")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.accents.contrast)
            }
    }

    private var proofPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Proof")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Text(displayProofSummary)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.surface.nested)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            Button {
                onLikeTapped?()
            } label: {
                HStack(spacing: 5) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(
                            isLiked
                            ? AnyShapeStyle(LColors.gradientPurple)
                            : AnyShapeStyle(LColors.textSecondary)
                        )

                    Text("\(displayLikeCount)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .buttonStyle(.plain)

            Button {
                showInlineCommentBox.toggle()
                onCommentTapped?()
            } label: {
                HStack(spacing: 5) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(
                            showInlineCommentBox
                            ? AnyShapeStyle(.white)
                            : AnyShapeStyle(LColors.textSecondary)
                        )

                    Text("\(displayCommentCount)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .buttonStyle(.plain)
            .disabled(onSubmitComment == nil)

            Button {
                onOpenComments?()
            } label: {
                Image("chatfolder")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(
                        displayCommentCount > 0 || isCommenting
                        ? AnyShapeStyle(.white)
                        : AnyShapeStyle(LColors.textSecondary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(onOpenComments == nil)

            Spacer()
        }
        .padding(.top, 2)
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
                                .strokeBorder(LColors.border.nested, lineWidth: 1)
                        )
                )

            Button {
                let trimmed = inlineCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                onSubmitComment?(trimmed)
                inlineCommentText = ""
                showInlineCommentBox = false
            } label: {
                Image("chatsparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LGradients.blue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    // MARK: - Helpers

    private var displayLikeCount: Int {
        likeCount ?? submission.likeCount
    }

    private var displayCommentCount: Int {
        commentCount ?? submission.commentCount
    }

    private var displayUsername: String {
        let trimmed = submission.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }

    private var displayNote: String {
        submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayProofSummary: String {
        let trimmed = submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard !trimmed.contains("\n") else { return trimmed }

        return trimmed.replacingOccurrences(of: ", ", with: "\n")
    }
}
