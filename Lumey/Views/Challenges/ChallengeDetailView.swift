//
//  ChallengeDetailView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState

    let challenge: ReadingChallenge

    @Query(sort: \ChallengeEntry.startDate, order: .reverse)
    private var allEntries: [ChallengeEntry]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var allSubmissions: [ChallengeSubmission]

    @Query(sort: \ChallengeUserProfile.username)
    private var profiles: [ChallengeUserProfile]

    @Query(sort: \ChallengeBookmark.createdAt, order: .reverse)
    private var bookmarks: [ChallengeBookmark]

    @State private var showingSubmissionSheet = false
    @State private var showingResultView = false
    @State private var challengeManager: ChallengeManager?

    private var currentUserID: String {
        appState.currentAppleUserId ?? ""
    }

    private var bookmarkUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var activeBookmark: ChallengeBookmark? {
        bookmarks.first {
            $0.userID == bookmarkUserID &&
            $0.challengeID == challenge.id &&
            $0.isActive
        }
    }

    private var isBookmarked: Bool {
        activeBookmark != nil
    }

    private var currentCycle: ChallengeCycle {
        challenge.cycle()
    }

    private var userEntry: ChallengeEntry? {
        let entries = allEntries.filter {
            $0.challengeID == challenge.id && $0.userID == currentUserID
        }

        guard challenge.isRecurring else {
            return entries.first
        }

        return entries.first(where: entryIsInCurrentCycle)
    }

    private var userSubmission: ChallengeSubmission? {
        guard let entry = userEntry else { return nil }
        let submissions = allSubmissions.filter { $0.entryID == entry.id }
        return submissions.first(where: { $0.validationStatus == .approved }) ?? submissions.first
    }

    private var userSubmissions: [ChallengeSubmission] {
        guard let entry = userEntry else { return [] }
        return allSubmissions.filter { $0.entryID == entry.id }
    }

    private var currentUserChallengeSubmissions: [ChallengeSubmission] {
        allSubmissions.filter {
            $0.challengeID == challenge.id && $0.userID == currentUserID
        }
    }

    private var hasApprovedSubmission: Bool {
        userEntry?.status == .approved || userSubmissions.contains { $0.validationStatus == .approved }
    }

    private var challengeSubmissions: [ChallengeSubmission] {
        allSubmissions.filter { $0.challengeID == challenge.id }
    }

    private var isJoined: Bool {
        userEntry != nil
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        challengeInfoSection
                        requirementSection
                        statsSection
                        actionSection
                        userStatusSection
                        feedSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            challengeManager = ChallengeManager(modelContext: modelContext)
            challengeManager?.backfillCycleMetadata()
            Task {
                await postApprovedSubmissionsToFeedIfNeeded()
            }
        }
        .adaptivePresentation(isPresented: $showingSubmissionSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            if let entry = userEntry {
                ChallengeSubmissionSheet(challenge: challenge, entry: entry)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .adaptivePresentation(isPresented: $showingResultView, useFullScreenCover: horizontalSizeClass == .regular) {
            if let submission = userSubmission {
                ChallengeSubmissionResultView(submission: submission, challenge: challenge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text("Challenge")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            Button {
                toggleBookmark()
            } label: {
                headerIconButton("starmark", isActive: isBookmarked)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? "Remove challenge bookmark" : "Bookmark challenge")

            Button {
                dismiss()
            } label: {
                headerIconButton("xmarkwavy")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    private func headerIconButton(_ iconName: String, isActive: Bool = false) -> some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .bubblyIconMaterial(tint: theme.palette.primaryAction)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(isActive ? theme.palette.primaryAction.opacity(0.18) : LColors.bg)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.palette.primaryAction, lineWidth: 1.2)
                    )
            )
    }

    // MARK: - Challenge Info

    private var challengeInfoSection: some View {
        GlassCard(padding: 18, variant: .featured) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(challenge.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(theme.palette.raisedSurface)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1.2)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(challenge.title)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.headingPrimary)

                            if challenge.isFeatured {
                                Text("FEATURED")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.cardTitle)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(LGradients.header))
                            }

                            if challenge.isWeekly {
                                Text("WEEKLY")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.bg)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.white))
                            }
                        }

                        Text("Hosted by Lumey")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                Text(challenge.challengeDescription)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Requirement

    private var requirementSection: some View {
        GlassCard(padding: 14, variant: .primary) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Requirement")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(challenge.requirementText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 10) {
            statCard(icon: "starfill", value: "\(challenge.points)", label: "Points", accentIndex: 0)
            statCard(icon: "clockfill", value: challenge.displayDuration, label: "Duration", accentIndex: 1)
            statCard(icon: "groupfill", value: "\(challenge.participantCount)", label: "Joined", accentIndex: 2)
            statCard(icon: "checkwavy", value: "\(challenge.completedCount)", label: "Completed", accentIndex: 3)
        }
    }

    private func statCard(icon: String, value: String, label: String, accentIndex: Int) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return VStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.72), radius: 1, y: 1)

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: theme.palette.background.opacity(0.72), radius: 1, y: 1)

            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.72), radius: 1, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 18)
        }
        .bubblyTileLift()
    }

    // MARK: - Action Buttons

    private var actionSection: some View {
        VStack(spacing: 10) {
            if !isJoined {
                Button {
                    joinChallenge()
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Join Challenge")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        BubblyTileSurface(
                            tint: theme.palette.primaryAction,
                            cornerRadius: 18
                        )
                    }
                    .bubblyTileLift()
                }
                .buttonStyle(.plain)
            } else if let entry = userEntry {
                if hasApprovedSubmission {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image("checkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)

                            Text(challenge.isRecurring ? "Completed This Cycle" : "Approved")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)

                        if challenge.isRecurring {
                            Text("This cycle is locked. You can join again when the next cycle begins \(currentCycle.endDate.formatted(date: .abbreviated, time: .omitted)).")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, challenge.isRecurring ? 12 : 14)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LColors.success.opacity(0.75), lineWidth: 1)
                    )
                } else if entry.status == .joined || entry.status == .needsMoreInfo {
                    Button {
                        showingSubmissionSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("playwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("Submit Entry")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            BubblyTileSurface(
                                tint: theme.palette.primaryAction,
                                cornerRadius: 18
                            )
                        }
                        .bubblyTileLift()
                    }
                    .buttonStyle(.plain)
                }

                if userSubmission != nil {
                    Button {
                        showingResultView = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("hearteye")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("View Submission")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.glassSurface2)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - User Status

    @ViewBuilder
    private var userStatusSection: some View {
        if let entry = userEntry {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                statusTile(label: "Status", value: entry.status.displayName, accentIndex: 0)
                statusTile(
                    label: challenge.isRecurring ? "Cycle Left" : "Time Left",
                    value: entry.displayDaysRemaining,
                    accentIndex: 1
                )
                statusTile(
                    label: challenge.isRecurring ? "Cycle Start" : "Started",
                    value: entry.startDate.formatted(date: .abbreviated, time: .omitted),
                    accentIndex: 2
                )
                statusTile(
                    label: challenge.isRecurring ? "Cycle End" : "Ends",
                    value: entry.endDate.formatted(date: .abbreviated, time: .omitted),
                    accentIndex: 3
                )

                if entry.status == .approved {
                    statusTile(
                        label: "Points Earned",
                        value: "+\(entry.earnedPoints)",
                        accentIndex: 4
                    )
                }
            }
        }
    }

    private func statusTile(label: String, value: String, accentIndex: Int) -> some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textSecondary)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.72), radius: 1, y: 1)
        }
        .frame(maxWidth: .infinity, minHeight: 29, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background {
            BubblyTileSurface(tint: tint, cornerRadius: 12)
        }
        .bubblyTileLift()
    }

    // MARK: - Feed

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !challengeSubmissions.isEmpty {
                Text("Submissions")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                ForEach(challengeSubmissions) { submission in
                    ChallengeFeedEntryCard(
                        submission: ChallengeSubmissionDTO(
                            id: submission.id.uuidString,
                            challengeID: submission.challengeID.uuidString,
                            entryID: submission.entryID.uuidString,
                            userID: submission.userID,
                            username: submission.username,
                            linkedBookIDs: submission.linkedBookIDs.map { $0.uuidString },
                            linkedSessionIDs: submission.linkedSessionIDs.map { $0.uuidString },
                            linkedReviewIDs: submission.linkedReviewIDs.map { $0.uuidString },
                            linkedReadingListIDs: submission.linkedReadingListIDs.map { $0.uuidString },
                            submissionNote: submission.submissionNote,
                            proofSummary: submission.proofSummary,
                            validationStatus: submission.validationStatus.rawValue,
                            validationMessage: submission.validationMessage,
                            submittedDate: submission.submittedDate,
                            approvedDate: submission.approvedDate,
                            postedToFeed: submission.postedToFeed,
                            feedItemID: submission.feedItemID,
                            likeCount: submission.likeCount,
                            commentCount: submission.commentCount
                        ),
                        avatarName: profile(for: submission)?.avatarName,
                        avatarURL: profile(for: submission)?.avatarURL
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func joinChallenge() {
        guard let manager = challengeManager else { return }
        _ = manager.joinChallenge(challenge, userID: currentUserID)
    }

    @MainActor
    private func postApprovedSubmissionsToFeedIfNeeded() async {
        let manager = challengeManager ?? ChallengeManager(modelContext: modelContext)
        challengeManager = manager

        for submission in currentUserChallengeSubmissions where submission.validationStatus == .approved {
            await manager.postApprovedSubmissionToFeedIfNeeded(submission, challenge: challenge)
        }
    }

    private func entryIsInCurrentCycle(_ entry: ChallengeEntry) -> Bool {
        entry.cycleID == currentCycle.id || (
            Calendar.current.isDate(entry.startDate, inSameDayAs: currentCycle.startDate) &&
            Calendar.current.isDate(entry.endDate, inSameDayAs: currentCycle.endDate)
        )
    }

    private func profile(for submission: ChallengeSubmission) -> ChallengeUserProfile? {
        profiles.first { $0.userID == submission.userID }
    }

    private func toggleBookmark() {
        if let activeBookmark {
            activeBookmark.deletedAt = Date()
            activeBookmark.updatedAt = Date()
            try? modelContext.save()
            return
        }

        if let existing = bookmarks.first(where: {
            $0.userID == bookmarkUserID &&
            $0.challengeID == challenge.id
        }) {
            existing.deletedAt = nil
            existing.refreshSnapshot(from: challenge)
            try? modelContext.save()
            return
        }

        let bookmark = ChallengeBookmark(
            userID: bookmarkUserID,
            challenge: challenge
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
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
}
