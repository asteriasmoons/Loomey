//
//  HomeRecommendationCollectionCard.swift
//  Lumey
//

import SwiftUI

struct HomeRecommendationCollectionCard: View {
    let collection: LumeyRecommendationCollection
    let coverAssetName: String
    var variant: GlassCardVariant = .primary
    var accentIndex: Int = 0

    private var accent: Color {
        switch accentIndex % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    private var displayBookCount: Int {
        collection.bookCount ?? collection.books.count
    }

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 14, variant: variant) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    collectionCover

                    Spacer(minLength: 0)

                    Text("\(displayBookCount) books")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.appBackground)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(accent, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(collection.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.text.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(collection.description)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let firstBook = collection.books.first {
                    HStack(spacing: 6) {
                        Image("sparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(accent)

                        Text(firstBook.title)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.primary.opacity(0.92))
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 6) {
                        Image("sparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(accent)

                        Text("Open shelf")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.text.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(width: 246, alignment: .topLeading)
            .frame(minHeight: 190, alignment: .topLeading)
        }
    }

    private var collectionCover: some View {
        Image(coverAssetName)
            .resizable()
            .frame(width: 64, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(accent.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: LColors.bg.opacity(0.35), radius: 8, y: 5)
    }
}
