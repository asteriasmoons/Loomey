//
//  LibraryBookRow.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct LibraryBookRow: View {
    let book: Book
    var onEdit: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 13) {
                    LibraryBookCover(book: book)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.displayTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        Text(book.displayAuthor)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                        
                        if !book.seriesName.isEmpty {
                            LibrarySeriesBadge(
                                seriesName: book.seriesName,
                                seriesNumber: book.seriesNumber
                            )
                        }
                        
                        FlowLayout(spacing: 8) {
                            LibraryStatusPill(text: book.status.rawValue)
                            LibraryStatusPill(text: book.format.rawValue)
                            LibraryStatusPill(text: book.ownership.rawValue)
                            
                            if book.isFavorite {
                                LibraryStatusPill(text: "Favorite")
                            }
                            if book.isReread {
                                LibraryStatusPill(text: "Reread")
                            }
                            if book.isDNF {
                                LibraryStatusPill(text: "DNF")
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    VStack(spacing: 8) {
                        Button {
                            onEdit?()
                        } label: {
                            LibraryBookIconButtonImage(
                                iconName: "pencil",
                                accessibilityLabel: "Edit book"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            ReadingBookDetailView(book: book)
                        } label: {
                            LibraryBookIconButtonImage(iconName: "chevright")
                        }
                        .buttonStyle(.plain)

                        Menu {
                            ForEach(BookStatus.allCases) { status in
                                Button {
                                    setStatus(status)
                                } label: {
                                    Label {
                                        Text(status.rawValue)
                                    } icon: {
                                        Image(status == book.status ? "checkwavy" : "starmark")
                                            .renderingMode(.template)
                                    }
                                }
                            }
                        } label: {
                            LibraryBookIconButtonImage(
                                iconName: "starmark",
                                accessibilityLabel: "Change reading status"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    LibraryRatingRow(book: book)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        GradientProgressBar(value: book.calculatedProgress, isPaused: book.status == .paused)
                            .frame(height: 8)
                        
                        Text(progressSummaryText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    
                    if !book.summary.isEmpty {
                        LibraryDetailBlock(label: "Summary", value: book.summary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progressSummaryText: String {
        book.status == .paused ? "Paused at \(book.progressText)" : book.progressText
    }

    private func setStatus(_ status: BookStatus) {
        let previousStatus = book.status
        book.updateStatus(to: status)
        ReadingXPService.awardBookStatusChange(
            book: book,
            previousStatus: previousStatus,
            newStatus: book.status,
            modelContext: modelContext
        )

        try? modelContext.save()
    }
}

private struct LibraryBookIconButtonImage: View {
    let iconName: String
    var accessibilityLabel: String? = nil

    var body: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(LGradients.header)
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        Circle()
                            .strokeBorder(LGradients.header, lineWidth: 1.2)
                    )
            )
            .accessibilityLabel(accessibilityLabel ?? iconName)
    }
}

// MARK: - LIBRARY SERIES BADGE
struct LibrarySeriesBadge: View {
    let seriesName: String
    let seriesNumber: String

    private var bookLabel: String? {
        let trimmed = seriesNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : "Book \(trimmed)"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            SeriesBadgeBorder(
                topGapStart: 14,
                topGapWidth: 43,
                bottomGapWidth: bookLabel == nil ? 0 : 43,
                cornerRadius: 14
            )
            .stroke(
                LinearGradient(
                    colors: [
                        LColors.gradientBlue,
                        LColors.gradientPurple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
            )

            Text(seriesName)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)

            Text("SERIES")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.white)
                .offset(x: 17, y: -6)
        }
        .overlay(alignment: .bottomTrailing) {
            if let bookLabel {
                Text(bookLabel)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(x: -16, y: 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.018))
        )
    }
}

// MARK: - SERIES BADGE BORDER
struct SeriesBadgeBorder: Shape {
    let topGapStart: CGFloat
    let topGapWidth: CGFloat
    let bottomGapWidth: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        let topGapEnd = topGapStart + topGapWidth
        let bottomGapEnd = rect.width - 14
        let bottomGapStart = bottomGapEnd - bottomGapWidth

        path.move(to: CGPoint(x: r, y: 0))

        if topGapStart > r {
            path.addLine(to: CGPoint(x: topGapStart, y: 0))
        }

        path.move(to: CGPoint(x: topGapEnd, y: 0))
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))

        path.addArc(
            center: CGPoint(x: rect.width - r, y: r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))

        path.addArc(
            center: CGPoint(x: rect.width - r, y: rect.height - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        if bottomGapWidth > 0 {
            path.addLine(to: CGPoint(x: bottomGapEnd, y: rect.height))
            path.move(to: CGPoint(x: bottomGapStart, y: rect.height))
        }

        path.addLine(to: CGPoint(x: r, y: rect.height))

        path.addArc(
            center: CGPoint(x: r, y: rect.height - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: 0, y: r))

        path.addArc(
            center: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        return path
    }
}

// MARK: - LIBRARY SERIES DROP DOWN PICKER
struct LibrarySeriesDropdownPicker: View {
    let seriesName: String
    let seriesNumber: String
    @Binding var isExpanded: Bool
    
    private var displayValue: String {
        seriesNumber.isEmpty ? seriesName : "Book \(seriesNumber)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 0.9)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Series")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        
                        Text(seriesName)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Text(displayValue)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                    
                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(LGradients.header)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(pickerBackground)
                .overlay(pickerBorder)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    pickerDetailRow(label: "Series Name", value: seriesName)
                    if !seriesNumber.isEmpty {
                        pickerDetailRow(label: "Position", value: "Book \(seriesNumber)")
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var pickerBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        LColors.gradientPurple.opacity(0.20),
                        LColors.gradientBlue.opacity(0.10),
                        Color.white.opacity(0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var pickerBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        LColors.gradientPurple.opacity(0.92),
                        LColors.gradientBlue.opacity(0.72),
                        Color.white.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private func pickerDetailRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(LGradients.header)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Spacer(minLength: 0)
            
            Text(value)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

struct GradientProgressBar: View {
    let value: Double
    var isPaused: Bool = false
    
    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var fill: LinearGradient {
        if isPaused {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.24)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [LColors.gradientBlue, LColors.gradientPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(isPaused ? Color.white.opacity(0.07) : Color.white.opacity(0.10))
                
                Capsule(style: .continuous)
                    .fill(fill)
                    .frame(width: proxy.size.width * clampedValue)
            }
        }
        .clipShape(Capsule(style: .continuous))
    }
}

struct LibraryBookCover: View {
    let book: Book
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            LColors.gradientBlue.opacity(0.55),
                            LColors.gradientPurple.opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            if let data = book.coverImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text(book.displayTitle.prefix(1).uppercased())
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 58, height: 84)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
        )
    }
}

struct LibraryStatusPill: View {
    let text: String
    var usePurpleStyle: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: usePurpleStyle
                            ? [
                                LColors.gradientPurple.opacity(0.30),
                                LColors.gradientPurple.opacity(0.18)
                            ]
                            : [
                                LColors.gradientBlue.opacity(0.20),
                                LColors.gradientPurple.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: usePurpleStyle
                            ? [
                                LColors.gradientPurple,
                                LColors.gradientPurple.opacity(0.7)
                            ]
                            : [
                                LColors.gradientBlue.opacity(0.7),
                                LColors.gradientPurple.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}
