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
    @Environment(\.appTheme) private var theme

    let challenge: ReadingChallenge
    let entry: ChallengeEntry?
    let badgeType: ChallengeBadgeType?
    let accentIndex: Int

    init(
        challenge: ReadingChallenge,
        entry: ChallengeEntry?,
        badgeType: ChallengeBadgeType?,
        accentIndex: Int = 0
    ) {
        self.challenge = challenge
        self.entry = entry
        self.badgeType = badgeType
        self.accentIndex = accentIndex
    }

    var body: some View {
        let tint = theme.palette.rotation[accentIndex % theme.palette.rotation.count]

        GlassCard(padding: 14, variant: .featured, borderColor: tint) {
            HStack(spacing: 12) {
                // Icon
                Image(challenge.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .bubblyIconMaterial(tint: tint)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(theme.palette.raisedSurface)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(tint, lineWidth: 1.2)
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
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                            Text("\(challenge.points)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        }

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
                    .bubblyIconMaterial(tint: theme.palette.textSecondary)
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
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.72), radius: 1, y: 1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    BubblyIconMaterial(tint: theme.palette.primaryAction)
                        .clipShape(Capsule(style: .continuous))
                }

        case .weekly:
            Text("WEEKLY")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.90), radius: 1, y: 1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    BubblyIconMaterial(tint: .black)
                        .clipShape(Capsule(style: .continuous))
                }

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
            .foregroundStyle(status == .joined ? Color.white : LColors.cardTitle)
            .shadow(
                color: status == .joined ? theme.palette.background.opacity(0.72) : .clear,
                radius: 1,
                y: 1
            )
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background {
                if status == .joined {
                    BubblyIconMaterial(tint: theme.palette.indicators)
                        .clipShape(Capsule(style: .continuous))
                } else {
                    Capsule(style: .continuous)
                        .fill(Color(lumeyHex: status.badgeColor))
                }
            }
    }
}
