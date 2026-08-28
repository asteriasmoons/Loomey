//
//  LibraryComponents.swift
//  Lumey
//

import SwiftUI

struct LibraryMiniStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        GlassCard(cornerRadius: 18, padding: 12, variant: .featured) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.accents.primary)
                
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LibraryDetailLine: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(label):")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .lineLimit(2)
        }
    }
}

struct LibraryDetailBlock: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LibraryRatingRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { number in
                Button {
                    if book.rating == Double(number) {
                        book.rating = 0
                    } else {
                        book.rating = Double(number)
                    }
                    book.lastUpdated = Date()
                } label: {
                    Image("starfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(
                            number <= Int(book.rating)
                            ? LColors.accents.primary
                            : LColors.border.nestedStrong
                        )
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LibraryWrappedPills: View {
    let label: String
    let values: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            FlowLayout(spacing: 7) {
                ForEach(values, id: \.self) { value in
                    LibraryStatusPill(
                        text: value,
                        usePurpleStyle: true
                    )
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        return CGSize(width: maxWidth, height: y + rowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
