//
//  ChallengeLeaderboardView.swift
//  Lumey
//

import SwiftUI

struct ChallengeLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

    private var heroCard: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image("startrophyfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(LColors.accents.contrast)
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(LColors.glassSurface)
                                .overlay(
                                    Circle()
                                        .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
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
                    leaderboardMiniStat(title: "Top", value: "\(visibleRankedSubmissions.count)")
                    leaderboardMiniStat(title: "Approved", value: "\(approvedCount)")
                    leaderboardMiniStat(title: "Reward", value: rewardValue)
                }
            }
        }
    }

    private func leaderboardMiniStat(title: String, value: String) -> some View {
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
                        profile: profile(for: submission)
                    )
                }
            }
        }
    }

    private func leaderboardRow(
        rank: Int,
        submission: ChallengeSubmission,
        profile: ChallengeUserProfile?
    ) -> some View {
        Button {
            onSubmissionTapped?(submission)
        } label: {
            GlassCard(padding: 14, variant: .secondary) {
                HStack(spacing: 12) {
                    rankBadge(rank)

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
                            .foregroundStyle(LColors.accents.special)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func rankBadge(_ rank: Int) -> some View {
        Image("\(rank)wavy")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(rankGradient(for: rank))
                    .shadow(
                        color: LColors.gradientBlue.opacity(rank <= 3 ? 0.20 : 0.06),
                        radius: rank <= 3 ? 12 : 4,
                        y: 5
                    )
            )
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
                    .fill(Color(lumeyHex: status.badgeColor).opacity(0.75))
            )
    }

    private func smallCount(icon: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(LColors.textSecondary)

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
                .foregroundStyle(LColors.accents.primary)

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
