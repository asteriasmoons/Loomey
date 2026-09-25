//
//  HomeRecommendationCollectionCard.swift
//  Lumey
//

import SwiftUI

struct HomeRecommendationCollectionCard: View {
    @Environment(\.appTheme) private var theme

    let collection: LumeyRecommendationCollection
    let coverAssetName: String
    var variant: GlassCardVariant = .primary
    var accentIndex: Int = 0

    private var accent: Color {
        theme.palette.rotation[accentIndex % theme.palette.rotation.count]
    }

    private var displayBookCount: Int {
        collection.bookCount ?? collection.books.count
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 6) {
                    Image("sparkle")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .background {
                            BubblyIconMaterial(tint: accent)
                                .mask {
                                    Image("sparkle")
                                        .resizable()
                                        .scaledToFit()
                                }
                        }
                        .foregroundStyle(.clear)

                    Text("Open shelf")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                }
                .frame(minHeight: 24, alignment: .leading)

                Spacer(minLength: 0)

                Text("\(displayBookCount) books")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background {
                        BubblyIconMaterial(tint: accent)
                            .clipShape(Capsule())
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(collection.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.text.primary)
                    .lineLimit(2)

                Text(collection.description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .lineLimit(2)
            }

        }
        .frame(width: 246, height: 112, alignment: .topLeading)
        .padding(14)
        .background(shape.fill(theme.palette.surface))
        .overlay(shape.strokeBorder(accent, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
    }
}
