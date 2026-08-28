//
//  ChallengeSubmissionResultView.swift
//  Lumey
//

import SwiftUI

struct ChallengeSubmissionResultView: View {
    @Environment(\.dismiss) private var dismiss

    let submission: ChallengeSubmission
    let challenge: ReadingChallenge

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        resultHeroCard

                        messageCard

                        if submission.validationStatus == .approved {
                            pointsCard
                        }

                        proofCard

                        if submission.hasPhotoProof {
                            photoProofCard
                        }

                        actionButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Submission Result")
                .font(.system(size: 24, weight: .black, design: .rounded))
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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LColors.border.nested)
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Hero

    private var resultHeroCard: some View {
        GlassCard(variant: .featured) {
            VStack(alignment: .center, spacing: 14) {
                Image(statusIcon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 76, height: 76)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.contrast, lineWidth: 1.3)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 14, y: 7)
                    )

                VStack(spacing: 6) {
                    Text(statusTitle)
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)
                        .multilineTextAlignment(.center)

                    Text(challenge.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                statusBadge
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statusBadge: some View {
        Text(submission.validationStatus.displayName.uppercased())
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(lumeyHex: submission.validationStatus.badgeColor).opacity(0.25))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color(lumeyHex: submission.validationStatus.badgeColor).opacity(0.75), lineWidth: 1)
                    )
            )
    }

    // MARK: - Message

    private var messageCard: some View {
        GlassCard(variant: .primary) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "sparkle", title: "Validation Message")

                Text(resultMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Points

    private var pointsCard: some View {
        GlassCard(variant: .secondary) {
            HStack(spacing: 14) {
                Image("achievement")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LColors.accents.secondary)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.secondary, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Points Awarded")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("\(challenge.points) points earned")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Proof

    private var proofCard: some View {
        GlassCard(variant: .tertiary) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "checkwavy", title: "Submitted Proof")

                if displayProofSummary.isEmpty {
                    Text("No proof summary was saved for this submission.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                } else {
                    Text(displayProofSummary)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .background(LColors.border.subtle)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Note")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(submission.submissionNote)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var photoProofCard: some View {
        GlassCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "image", title: "Photo Validation")

                AsyncImage(url: URL(string: submission.photoURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderPhoto
                    case .empty:
                        ZStack {
                            placeholderPhoto
                            ProgressView()
                                .tint(.white)
                        }
                    @unknown default:
                        placeholderPhoto
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                )

                HStack(spacing: 8) {
                    Image(statusIcon(for: submission.photoValidationStatus))
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(LColors.accents.special)

                    Text(submission.photoValidationStatus.displayName)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    if submission.photoValidationConfidence > 0 {
                        Text("\(Int((submission.photoValidationConfidence * 100).rounded()))% confidence")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                if let message = submission.photoValidationMessage,
                   !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(message)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var placeholderPhoto: some View {
        Rectangle()
            .fill(LColors.glassSurface)
            .overlay {
                Image("image")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(LColors.accents.primary)
            }
    }

    // MARK: - Action

    private var actionButton: some View {
        Button {
            dismiss()
        } label: {
            Text(buttonTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LGradients.header)
                        .shadow(color: LColors.gradientBlue.opacity(0.22), radius: 14, y: 7)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Small Pieces

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LColors.accents.contrast)

            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)

            Spacer()
        }
    }

    // MARK: - Computed Text

    private var statusIcon: String {
        statusIcon(for: submission.validationStatus)
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
            return "clockwavy"
        }
    }

    private var statusTitle: String {
        switch submission.validationStatus {
        case .approved:
            return "Challenge Approved"
        case .inProgress:
            return "In Progress"
        case .needsMoreInfo:
            return "Needs More Info"
        case .rejected:
            return "Not Eligible Yet"
        case .validating:
            return "Validating Submission"
        case .submitted:
            return "Submission Received"
        case .joined:
            return "Challenge Joined"
        case .readyToSubmit:
            return "Ready to Submit"
        case .expired:
            return "Challenge Expired"
        }
    }

    private var resultMessage: String {
        if let message = submission.validationMessage,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        switch submission.validationStatus {
        case .approved:
            return "Your submission was approved and your points have been awarded."
        case .inProgress:
            return "Your challenge progress has been saved. Keep going until you meet the full requirement."
        case .needsMoreInfo:
            return "This submission needs a little more information before it can be approved."
        case .rejected:
            return "This submission does not meet the challenge requirements yet."
        case .validating:
            return "Lumey is checking your linked proof and validation details."
        case .submitted:
            return "Your submission has been received and is ready for validation."
        case .joined:
            return "You joined this challenge. Submit an entry when your proof is ready."
        case .readyToSubmit:
            return "Your challenge looks ready for an entry."
        case .expired:
            return "This challenge entry expired before approval."
        }
    }

    private var buttonTitle: String {
        switch submission.validationStatus {
        case .approved:
            return "Done"
        case .inProgress:
            return "Close"
        case .needsMoreInfo:
            return "Review Submission"
        case .rejected:
            return "Close"
        case .validating, .submitted:
            return "Close"
        case .joined, .readyToSubmit:
            return "Close"
        case .expired:
            return "Close"
        }
    }

    private var displayProofSummary: String {
        let trimmed = submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard !trimmed.contains("\n") else { return trimmed }

        return trimmed.replacingOccurrences(of: ", ", with: "\n")
    }
}
