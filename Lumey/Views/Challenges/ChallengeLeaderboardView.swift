//
//  ChallengeLeaderboardView.swift
//  Lumey
//

import SwiftUI

struct ChallengeLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme

    @State private var selectedProfile: ChallengeUserProfile?

    let challenge: ReadingChallenge?
    let submissions: [ChallengeSubmission]
    let profiles: [ChallengeUserProfile]

    var onProfileTapped: ((ChallengeUserProfile) -> Void)?
    var onSubmissionTapped: ((ChallengeSubmission) -> Void)?

    private var approvedSubmissions: [ChallengeSubmission] {
        submissions.filter { $0.validationStatus == .approved }
    }

    private var visibleRankedSubmissions: [ChallengeSubmission] {
        Array(rankedSubmissions.prefix(9))
    }

    private var rankedSubmissions: [ChallengeSubmission] {
        approvedSubmissions.sorted { first, second in
            if first.likeCount != second.likeCount {
                return first.likeCount > second.likeCount
            }

            if first.commentCount != second.commentCount {
                return first.commentCount > second.commentCount
            }

            return first.submittedDate < second.submittedDate
        }
    }

    private var approvedCount: Int {
        approvedSubmissions.count
    }

    private var leaderboardTitle: String {
        challenge?.title ?? "All Challenges"
    }

    private var rewardValue: String {
        guard let challenge else { return "Mixed" }
        return "\(challenge.points)"
    }

    private var isAllChallengesLeaderboard: Bool {
        challenge == nil
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard

                        if rankedSubmissions.isEmpty {
                            emptyState
                        } else {
                            leaderboardList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 34)
                }
            }
        }
        .adaptivePresentation(item: $selectedProfile, useFullScreenCover: horizontalSizeClass == .regular) { profile in
            ProfileView(
                challengeProfile: profile,
                currentChallengeTitle: challenge?.title,
                recentChallengeSubmissions: submissions.filter {
                    $0.userID == profile.userID
                },
                onChallengeSubmissionTapped: onSubmissionTapped,
                showsCloseButton: true
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(leaderboardTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
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
        .safeAreaPadding(.top)
    }

    // MARK: - Hero

    private var heroCard: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image("startrophyfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Circle()
                                    .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1.2)
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 14, y: 7)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Challenge Rankings")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text("Ranked by likes, comments, then earliest approved submission.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    leaderboardMiniStat(title: "Top", value: "\(visibleRankedSubmissions.count)", accentIndex: 0)
                    leaderboardMiniStat(title: "Approved", value: "\(approvedCount)", accentIndex: 1)
                    leaderboardMiniStat(title: "Reward", value: rewardValue, accentIndex: 2)
                }
            }
        }
    }

    private func leaderboardMiniStat(title: String, value: String, accentIndex: Int) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }

    // MARK: - Empty

    private var emptyState: some View {
        GlassCard(variant: .primary) {
            VStack(spacing: 14) {
                Image("sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
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
                    Text("No Rankings Yet")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Approved challenge entries will appear here once readers complete submissions.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - List

    private var leaderboardList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "startrophyfill", title: "Top Entries")

            VStack(spacing: 10) {
                ForEach(Array(visibleRankedSubmissions.enumerated()), id: \.element.id) { index, submission in
                    leaderboardRow(
                        rank: index + 1,
                        submission: submission,
                        profile: profile(for: submission),
                        accent: theme.palette.rotation[index % theme.palette.rotation.count]
                    )
                }
            }
        }
    }

    private func leaderboardRow(
        rank: Int,
        submission: ChallengeSubmission,
        profile: ChallengeUserProfile?,
        accent: Color
    ) -> some View {
        Button {
            onSubmissionTapped?(submission)
        } label: {
            GlassCard(padding: 14, variant: .secondary, borderColor: accent) {
                HStack(spacing: 12) {
                    rankBadge(rank, accent: accent)

                    Button {
                        if let profile {
                            if let onProfileTapped {
                                onProfileTapped(profile)
                            } else {
                                selectedProfile = profile
                            }
                        }
                    } label: {
                        avatarView(profile: profile, submission: submission)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(displayUsername(profile: profile, submission: submission))
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(1)

                            statusBadge(for: submission.validationStatus)
                        }

                        if !submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(submission.submissionNote)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(2)
                        } else if isAllChallengesLeaderboard && !displayChallengeTitle(for: submission).isEmpty {
                            Text(displayChallengeTitle(for: submission))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)
                        } else {
                            Text(submission.submittedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        HStack(spacing: 12) {
                            smallCount(icon: "heartwavy", value: submission.likeCount)
                            smallCount(icon: "starchat", value: submission.commentCount)
                        }
                    }

                    Spacer()

                    if submission.validationStatus == .approved {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .bubblyIconMaterial(tint: theme.palette.indicators)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func rankBadge(_ rank: Int, accent: Color) -> some View {
        let tint = rank <= 3 ? accent : theme.palette.textSecondary

        return Image("\(rank)wavy")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background { BubblyIconMaterial(tint: tint).clipShape(Circle()) }
            .overlay { Circle().strokeBorder(tint, lineWidth: 1) }
    }

    private func avatarView(
        profile: ChallengeUserProfile?,
        submission: ChallengeSubmission
    ) -> some View {
        UserAvatarView(
            avatarURL: profile?.avatarURL,
            avatarName: profile?.avatarName,
            size: 40,
            iconSize: 22
        )
    }

    private func statusBadge(for status: ChallengeSubmissionStatus) -> some View {
        Text(status.displayName.uppercased())
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(.clear)
                    .overlay {
                        BubblyIconMaterial(tint: Color(lumeyHex: status.badgeColor))
                            .clipShape(Capsule(style: .continuous))
                    }
            )
    }

    private func smallCount(icon: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)

            Text("\(value)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .bubblyIconMaterial(tint: theme.palette.primaryAction)

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func profile(for submission: ChallengeSubmission) -> ChallengeUserProfile? {
        profiles.first { $0.userID == submission.userID }
    }

    private func displayUsername(
        profile: ChallengeUserProfile?,
        submission: ChallengeSubmission
    ) -> String {
        if let username = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines),
           !username.isEmpty {
            return username
        }

        let submissionUsername = submission.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return submissionUsername.isEmpty ? "Reader" : submissionUsername
    }

    private func displayChallengeTitle(for submission: ChallengeSubmission) -> String {
        submission.challengeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Solid rank colors — palette accents at descending intensity, then a
    /// dark surface for everyone else. No gradients.
    private func rankGradient(for rank: Int) -> Color {
        switch rank {
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.primary
        case 3:  return LColors.accents.secondary
        default: return LColors.glassSurface
        }
    }
}

private extension View {
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
