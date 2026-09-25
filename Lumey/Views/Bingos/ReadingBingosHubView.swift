//
//  ReadingBingosHubView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingBingosHubView: View {
    @Environment(\.appTheme) private var theme

    @Query(sort: \ReadingBingoProgress.updatedAt, order: .reverse)
    private var progressRecords: [ReadingBingoProgress]

    private var boardSnapshots: [ReadingBingoBoardSnapshot] {
        ReadingBingoCatalog.allBoards.map { definition in
            ReadingBingoEngine.snapshot(
                for: definition,
                progressRecord: ReadingBingoProgress.preferredRecord(for: definition.id, from: progressRecords)
            )
        }
    }

    private var summary: ReadingBingoHubSummary {
        ReadingBingoEngine.hubSummary(progressRecords: progressRecords)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        summaryCard
                        boardsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private extension ReadingBingosHubView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading Bingos")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Text("Curated 5x5 boards with real Bingo lines, fixed prompts, and progress that carries across every board independently.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var summaryCard: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("starbook")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .bubblyIconMaterial(tint: theme.palette.secondaryAccent)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay(Circle().strokeBorder(theme.palette.secondaryAccent, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overall Bingo Progress")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.primary)

                        Text("\(summary.totalCompletedChallengeSquares) challenge squares completed across \(boardSnapshots.count) boards")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                    }
                }

                GradientProgressBar(value: summary.overallProgress)
                    .frame(height: 10)

                HStack(spacing: 10) {
                    summaryPill(title: "Squares",     value: "\(summary.totalCompletedChallengeSquares)", tint: theme.palette.primaryAction)
                    summaryPill(title: "Bingos",      value: "\(summary.totalBingoLines)",                 tint: theme.palette.secondaryAccent)
                    summaryPill(title: "Blackouts",   value: "\(summary.totalBlackoutBoards)",             tint: theme.palette.indicators)
                    summaryPill(title: "In Progress", value: "\(summary.boardsInProgress)",                tint: theme.palette.primaryAction)
                }
            }
        }
    }

    func summaryPill(title: String, value: String, tint: Color = LColors.accents.primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)

            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }

    var boardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Boards")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            ForEach(Array(boardSnapshots.enumerated()), id: \.element.id) { index, snapshot in
                let tint = theme.palette.rotation[index % theme.palette.rotation.count]
                NavigationLink {
                    ReadingBingoBoardDetailView(boardID: snapshot.id, accentIndex: index)
                } label: {
                    ReadingBingoBoardCard(
                        snapshot: snapshot,
                        variant: GlassCardRotation.variant(for: index),
                        tint: tint
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ReadingBingoBoardCard: View {
    @Environment(\.appTheme) private var theme

    let snapshot: ReadingBingoBoardSnapshot
    var variant: GlassCardVariant = .primary
    let tint: Color

    var body: some View {
        GlassCard(variant: variant, borderColor: tint) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(snapshot.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .bubblyIconMaterial(tint: tint)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(theme.palette.raisedSurface))
                            .overlay(Circle().strokeBorder(tint, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.title)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text(snapshot.description)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    FlowLayout(spacing: 8) {
                        statusPill
                        infoPill("\(snapshot.completedChallengeCount)/\(snapshot.totalChallengeCount) Squares")
                        infoPill("\(snapshot.bingoCount) Bingos")
                    }

                    ReadingBingoAccentProgressBar(progress: snapshot.progress, tint: tint)
                        .frame(height: 9)

                    HStack(spacing: 10) {
                        miniStat(title: "State", value: snapshot.state.title)
                        miniStat(title: "Waiting", value: "\(snapshot.remainingChallengeCount)")
                    }
                }

                VStack(alignment: .trailing, spacing: 12) {
                    ReadingBingoMiniBoardPreview(snapshot: snapshot, tint: tint)
                        .frame(width: 110, height: 110)

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .bubblyIconMaterial(tint: tint)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay(Circle().strokeBorder(tint, lineWidth: 1))
                }
            }
        }
    }

    private var statusPill: some View {
        Text(snapshot.state.title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
            .bubblyTileLift()
    }

    private func infoPill(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .background { BubblyTileSurface(tint: tint, cornerRadius: 999) }
            .bubblyTileLift()
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 14) }
        .bubblyTileLift()
    }
}

struct ReadingBingoMiniBoardPreview: View {
    @Environment(\.appTheme) private var theme

    let snapshot: ReadingBingoBoardSnapshot
    let tint: Color

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: ReadingBingoCatalog.boardSize)

        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(snapshot.squares) { square in
                let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
                BubblyIconMaterial(tint: square.isCompleted || square.isFreeSpace ? tint : theme.palette.textSecondary.opacity(0.42))
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(tint, lineWidth: square.isCompleted || square.isFreeSpace ? 1.1 : 0.55))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint, lineWidth: 1)
        )
    }
}

struct ReadingBingoAccentProgressBar: View {
    @Environment(\.appTheme) private var theme

    let progress: Double
    let tint: Color

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(theme.palette.raisedSurface)

                BubblyTileSurface(tint: tint, cornerRadius: 999)
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .clipShape(Capsule(style: .continuous))
    }
}
