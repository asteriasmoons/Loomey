//
//  ChallengeCompletedChallengesPage.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengeCompletedChallengesPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var submissions: [ChallengeSubmission]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var selectedChallenge: ReadingChallenge?

    let userID: String
    let username: String

    private var completedRows: [CompletedChallengeRow] {
        submissions
            .filter { $0.userID == userID && $0.validationStatus == .approved }
            .compactMap { submission in
                let challenge = challenges.first { $0.id == submission.challengeID }
                return CompletedChallengeRow(submission: submission, challenge: challenge)
            }
            .sorted {
                let lhsDate = $0.submission.approvedDate ?? $0.submission.submittedDate
                let rhsDate = $1.submission.approvedDate ?? $1.submission.submittedDate
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if completedRows.isEmpty {
                            emptyState
                        } else {
                            ForEach(completedRows) { row in
                                if let challenge = row.challenge {
                                    Button {
                                        selectedChallenge = challenge
                                    } label: {
                                        completedChallengeCard(row)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    completedChallengeCard(row)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 110)
                }
            }
        }
        .adaptivePresentation(item: $selectedChallenge, useFullScreenCover: horizontalSizeClass == .regular) { challenge in
            ChallengeDetailView(challenge: challenge)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Completed Challenges")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("\(completedRows.count) completed challenge\(completedRows.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer(minLength: 0)

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

    private var emptyState: some View {
        GlassCard(variant: .featured) {
            VStack(spacing: 12) {
                Image("startrophyhands")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LColors.accents.primary)

                Text("No completed challenges yet.")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)

                Text(emptyStateMessage)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private var emptyStateMessage: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "This reader" : trimmed
        return "\(displayName) has not completed any challenges yet."
    }

    private func completedChallengeCard(_ row: CompletedChallengeRow) -> some View {
        GlassCard(padding: 14, variant: .primary) {
            HStack(alignment: .top, spacing: 12) {
                Image(row.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(row.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)

                        Text("COMPLETED")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule(style: .continuous).fill(LGradients.header))
                    }

                    Text(row.description)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        metadataPill(icon: "checkwavy", text: row.completedDateText)

                        if let pointsText = row.pointsText {
                            metadataPill(icon: "starfill", text: pointsText)
                        }
                    }

                    if !row.proofSummary.isEmpty {
                        Text(row.proofSummary)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)

                if row.challenge != nil {
                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.textSecondary)
                        .padding(.top, 16)
                }
            }
        }
    }

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)

            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(LColors.accents.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
        )
    }

    private func headerIconButton(_ iconName: String) -> some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(LColors.accents.special)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(LColors.bg)
                    .overlay(
                        Circle()
                            .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                    )
                    .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
            )
    }
}

private struct CompletedChallengeRow: Identifiable {
    let submission: ChallengeSubmission
    let challenge: ReadingChallenge?

    var id: UUID {
        submission.id
    }

    var title: String {
        let challengeTitle = challenge?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !challengeTitle.isEmpty { return challengeTitle }

        let submissionTitle = submission.challengeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return submissionTitle.isEmpty ? "Completed Challenge" : submissionTitle
    }

    var description: String {
        let description = challenge?.challengeDescription.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return description.isEmpty ? "Challenge completed and approved." : description
    }

    var iconName: String {
        challenge?.iconName ?? "startrophyhands"
    }

    var completedDateText: String {
        let date = submission.approvedDate ?? submission.submittedDate
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var pointsText: String? {
        guard let points = challenge?.points else { return nil }
        return "\(points) pts"
    }

    var proofSummary: String {
        submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines)
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
