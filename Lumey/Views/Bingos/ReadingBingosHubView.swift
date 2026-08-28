//
//  ReadingBingosHubView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingBingosHubView: View {
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
        GlassCard(variant: .featured) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("starbook")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(LColors.accents.contrast)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(LColors.iconContainer.primary))
                        .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))

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
                    summaryPill(title: "Squares",     value: "\(summary.totalCompletedChallengeSquares)", tint: LColors.accents.primary)
                    summaryPill(title: "Bingos",      value: "\(summary.totalBingoLines)",                 tint: LColors.accents.contrast)
                    summaryPill(title: "Blackouts",   value: "\(summary.totalBlackoutBoards)",             tint: LColors.accents.secondary)
                    summaryPill(title: "In Progress", value: "\(summary.boardsInProgress)",                tint: LColors.accents.special)
                }
            }
        }
    }

    func summaryPill(title: String, value: String, tint: Color = LColors.accents.primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.text.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.30), lineWidth: 1)
        )
    }

    var boardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Boards")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            ForEach(Array(boardSnapshots.enumerated()), id: \.element.id) { index, snapshot in
                NavigationLink {
                    ReadingBingoBoardDetailView(boardID: snapshot.id)
                } label: {
                    ReadingBingoBoardCard(snapshot: snapshot, variant: GlassCardRotation.variant(for: index))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ReadingBingoBoardCard: View {
    let snapshot: ReadingBingoBoardSnapshot
    var variant: GlassCardVariant = .primary

    var body: some View {
        GlassCard(variant: variant) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(snapshot.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(snapshot.accent.gradient)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(snapshot.accent.softGradient))
                            .overlay(Circle().strokeBorder(snapshot.accent.gradient, lineWidth: 1))

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

                    HStack(spacing: 8) {
                        statusPill
                        infoPill("\(snapshot.completedChallengeCount)/\(snapshot.totalChallengeCount) Squares")
                        infoPill("\(snapshot.bingoCount) Bingos")
                    }

                    ReadingBingoAccentProgressBar(progress: snapshot.progress, accent: snapshot.accent)
                        .frame(height: 9)

                    HStack(spacing: 10) {
                        miniStat(title: "State", value: snapshot.state.title)
                        miniStat(title: "Waiting", value: "\(snapshot.remainingChallengeCount)")
                    }
                }

                VStack(alignment: .trailing, spacing: 12) {
                    ReadingBingoMiniBoardPreview(snapshot: snapshot)
                        .frame(width: 110, height: 110)

                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(snapshot.accent.gradient)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(LColors.surface.nested))
                        .overlay(Circle().strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var statusPill: some View {
        Text(snapshot.state.title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(LColors.cardTitle)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(snapshot.accent.gradient)
            )
    }

    private func infoPill(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(LColors.surface.nested)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(LColors.border.nested, lineWidth: 1)
            )
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.surface.nested)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LColors.border.nested, lineWidth: 1)
        )
    }
}

struct ReadingBingoMiniBoardPreview: View {
    let snapshot: ReadingBingoBoardSnapshot

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: ReadingBingoCatalog.boardSize)

        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(snapshot.squares) { square in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(fill(for: square))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(border(for: square), lineWidth: square.isHighlighted ? 1.1 : 0.8)
                    )
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
                .strokeBorder(LColors.border.nested, lineWidth: 1)
        )
    }

    private func fill(for square: ReadingBingoSquareSnapshot) -> Color {
        if square.isFreeSpace {
            return snapshot.accent.primaryColor
        }

        if square.isHighlighted {
            return snapshot.accent.primaryColor.opacity(0.26)
        }

        if square.isCompleted {
            return snapshot.accent.primaryColor.opacity(0.34)
        }

        return LColors.primarySurface
    }

    private func border(for square: ReadingBingoSquareSnapshot) -> Color {
        if square.isHighlighted || square.isFreeSpace {
            return snapshot.accent.secondaryColor.opacity(0.9)
        }

        if square.isCompleted {
            return snapshot.accent.primaryColor.opacity(0.55)
        }

        return LColors.border.primary.opacity(0.9)
    }
}

struct ReadingBingoAccentProgressBar: View {
    let progress: Double
    let accent: ReadingBingoAccentIdentity

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(LColors.border.nested)

                Capsule(style: .continuous)
                    .fill(accent.gradient)
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .clipShape(Capsule(style: .continuous))
    }
}
