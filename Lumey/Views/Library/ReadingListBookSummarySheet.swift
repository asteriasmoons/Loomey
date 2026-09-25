//
//  ReadingListBookSummarySheet.swift
//  Lumey
//

import SwiftUI

struct ReadingListBookSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let book: Book

    private var hasSummary: Bool {
        !book.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        bookHeader
                        summaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                }
            }
        }
    }
}

private extension ReadingListBookSummarySheet {
    var header: some View {
        HStack(spacing: 12) {
            Text("Book Summary")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            Spacer()

            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(Circle().strokeBorder(theme.palette.primaryAction, lineWidth: 1.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    var bookHeader: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(book.author)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text(book.status.rawValue)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.palette.background.opacity(0.65), radius: 1, y: 2)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background {
                        BubblyIconMaterial(tint: theme.palette.indicators)
                            .clipShape(Capsule(style: .continuous))
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var summaryCard: some View {
        GlassCard(variant: .primary, borderColor: theme.palette.secondaryAccent) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text(hasSummary ? book.summary : "No summary has been added for this book yet.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(hasSummary ? .white.opacity(0.86) : LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
