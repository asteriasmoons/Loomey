//
//  ChallengeCardView.swift
//  Lumey
//

import SwiftUI

enum ChallengeBadgeType {
    case featured
    case weekly
    case active
}

struct ChallengeCardView: View {
    let challenge: ReadingChallenge
    let entry: ChallengeEntry?
    let badgeType: ChallengeBadgeType?

    var body: some View {
        GlassCard(padding: 14, variant: .featured) {
            HStack(spacing: 12) {
                // Icon
                Image(challenge.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(challenge.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .lineLimit(1)

                        if let badgeType {
                            badgeView(for: badgeType)
                        }

                        if let entry, entry.status == .approved {
                            Image("checkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(LColors.success)
                        }
                    }

                    Text(challenge.challengeDescription)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        // Points
                        HStack(spacing: 3) {
                            Image("starfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 9, height: 9)
                            Text("\(challenge.points)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LColors.gradientYellow)

                        // Duration
                        HStack(spacing: 3) {
                            Image("clockfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 9, height: 9)
                            Text(challenge.displayDuration)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LColors.textSecondary)

                        // Status
                        if let entry {
                            statusBadge(for: entry.status)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(LColors.textSecondary)
            }
        }
    }

    // MARK: - Badge Views

    @ViewBuilder
    private func badgeView(for type: ChallengeBadgeType) -> some View {
        switch type {
        case .featured:
            Text("FEATURED")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(LGradients.blue))

        case .weekly:
            Text("WEEKLY")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(LColors.bg)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white))

        case .active:
            Text("ACTIVE")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(LColors.accent))
        }
    }

    private func statusBadge(for status: ChallengeSubmissionStatus) -> some View {
        Text(status.displayName)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(lumeyHex: status.badgeColor))
            )
    }
}
