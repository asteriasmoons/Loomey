//
// SprintLeaderboardView.swift
// Lumey
//

import SwiftUI

struct SprintLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var entries: [SprintLeaderboardEntry] = []
    @State private var isLoading = false

    private var userId: String { appState.currentAppleUserId ?? "" }

    var body: some View {
        ZStack {
            LumeyBackground()
            VStack(spacing: 0) {
                header
                content
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { Task { await load() } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("All-Time Leaderboard")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Button {
                    dismiss()
                } label: {
                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(
                            LColors.accents.primary
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(LColors.bg)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LColors.accents.primary,
                                            lineWidth: 1.35
                                        )
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .safeAreaPadding(.top)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 10) {
                if entries.isEmpty && !isLoading {
                    GlassCard(variant: .featured) {
                        Text("No sprints completed yet. Be the first!")
                            .font(.subheadline)
                            .foregroundStyle(LColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(entry: entry, rank: index + 1)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
    }

    private func leaderboardRow(entry: SprintLeaderboardEntry, rank: Int) -> some View {
        let isMe = entry.userId == userId

        return GlassCard(variant: .primary) {
            HStack(spacing: 12) {
                rankIcon(for: rank - 1)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(entry.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isMe ? LColors.accent : LColors.textPrimary)
                        if isMe {
                            Text("you")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(LColors.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(entry.sprintsParticipated) sprint\(entry.sprintsParticipated == 1 ? "" : "s") · \(entry.totalPagesRead) pages read")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.totalPoints)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LColors.textPrimary)
                    Text("pts")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func rankIcon(for index: Int) -> some View {
        switch index {
        case 0:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.primary)
        case 1:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.contrast)
        case 2:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.secondary)
        default:
            Image("sparklybook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.special)
        }
    }

    private func load() async {
        isLoading = true
        entries = (try? await SprintService.shared.getAllTimeLeaderboard()) ?? []
        isLoading = false
    }
}
