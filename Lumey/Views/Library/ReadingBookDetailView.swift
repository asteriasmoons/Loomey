//
//  ReadingBookDetailView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ReadingBookDetailView: View {
    @Bindable var book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState
    @State private var isSummaryExpanded = false
    @State private var showEPUBImporter = false
    @State private var showReader = false
    @State private var readerURL: URL?
    @State private var epubError: String?
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    detailHeader
                    epubReaderCard
                    featureCards
                    detailSections
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .fileImporter(
            isPresented: $showEPUBImporter,
            allowedContentTypes: [.epubFile],
            allowsMultipleSelection: false
        ) { result in
            handleEPUBImport(result)
        }
        .navigationDestination(isPresented: $showReader) {
            if let readerURL {
                EPUBReaderDestinationView(
                    fileURL: readerURL,
                    bookID: book.id,
                    onClose: {
                        showReader = false
                        appState.hideTabBar = false
                    },
                    onProgressChanged: { location in
                        book.epubReaderLocation = location
                        book.epubLastOpenedAt = Date()
                        book.updatedAt = Date()
                        book.lastUpdated = Date()
                    },
                    initialLocationJSON: book.epubReaderLocation.isEmpty ? nil : book.epubReaderLocation
                )
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text(book.displayTitle)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(theme.palette.primaryAction)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(theme.palette.raisedSurface))
                    .overlay {
                        BubblyIconMaterial(tint: theme.palette.primaryAction)
                            .mask { Circle().strokeBorder(lineWidth: 1.2) }
                    }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - EPUB Reader

    private var epubReaderCard: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.secondaryAccent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image("openbook")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(theme.palette.primaryAction)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: theme.palette.primaryAction)
                                .mask { Circle().strokeBorder(lineWidth: 1) }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.hasEPUB ? "EPUB Attached" : "No EPUB Attached")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)

                        Text(book.hasEPUB ? book.epubOriginalFileName : "Import an EPUB file to read inside Lumey.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                if let epubError {
                    Text(epubError)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color.red.opacity(0.85))
                }

                HStack(spacing: 10) {
                    Button {
                        showEPUBImporter = true
                    } label: {
                        epubActionPill(
                            icon: book.hasEPUB ? "reset" : "addwavy",
                            title: book.hasEPUB ? "Replace EPUB" : "Import EPUB"
                        )
                    }
                    .buttonStyle(.plain)

                    if book.hasEPUB {
                        Button {
                            openReader()
                        } label: {
                            epubActionPill(icon: "openbook", title: "Open Reader")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func epubActionPill(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(theme.palette.textPrimary)
        .shadow(color: theme.palette.background.opacity(0.55), radius: 1, y: 2)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background { BubblyTileSurface(tint: theme.palette.secondaryAccent, cornerRadius: 999) }
        .bubblyTileLift()
    }

    // MARK: - Feature Cards Grid

    private var featureCards: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            NavigationLink {
                BookNotesView(book: book)
            } label: {
                featureCard(icon: "lovedocument", title: "Notes", count: book.bookNotes?.count ?? 0, tint: theme.palette.rotation[0])
            }
            .buttonStyle(.plain)

            NavigationLink {
                BookQuotesView(book: book)
            } label: {
                featureCard(icon: "starmark", title: "Quotes", count: book.bookQuotes?.count ?? 0, tint: theme.palette.rotation[1])
            }
            .buttonStyle(.plain)

            NavigationLink {
                BookReviewsView(book: book)
            } label: {
                featureCard(icon: "starcircle", title: "Reviews", count: book.bookReviews?.count ?? 0, tint: theme.palette.rotation[2])
            }
            .buttonStyle(.plain)

            NavigationLink {
                BookInsightsView(book: book)
            } label: {
                featureCard(icon: "pencil", title: "Insights", count: book.insights?.count ?? 0, tint: theme.palette.rotation[0])
            }
            .buttonStyle(.plain)
        }
    }

    private func featureCard(icon: String, title: String, count: Int, tint: Color) -> some View {
        GlassCard(cornerRadius: 18, padding: 0, variant: .tertiary, borderColor: tint) {
            ZStack {
                BubblyLightWash(colors: [tint], intensity: 0.34, fadeEnd: 0.82)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 12) {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(tint)
                            .bubblyIconMaterial(tint: tint)
                            .frame(height: 54)

                        Text(title)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)

                    Text("\(count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                        .bubblyIconMaterial(tint: tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(theme.palette.raisedSurface))
                        .overlay {
                            BubblyIconMaterial(tint: tint)
                                .mask { Capsule().strokeBorder(lineWidth: 1) }
                        }
                }
                .padding(14)
            }
        }
    }

    // MARK: - Detail Header

    private var detailHeader: some View {
        GlassCard(variant: .primary, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top, spacing: 14) {
                        LibraryBookCover(book: book)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(book.displayTitle)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.headingPrimary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.trailing, book.summary.isEmpty ? 0 : 44)
                            
                            Text(book.displayAuthor)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                            
                            if !book.seriesName.isEmpty {
                                LibrarySeriesBadge(
                                    seriesName: book.seriesName,
                                    seriesNumber: book.seriesNumber
                                )
                            }
                            
                            FlowLayout(spacing: 8) {
                                LibraryStatusPill(text: book.status.rawValue, tint: theme.palette.rotation[0])
                                LibraryStatusPill(text: book.format.rawValue, tint: theme.palette.rotation[1])
                                LibraryStatusPill(text: book.ownership.rawValue, tint: theme.palette.rotation[2])
                                
                                if book.isFavorite {
                                    LibraryStatusPill(text: "Favorite", tint: theme.palette.rotation[0])
                                }
                                if book.isReread {
                                    LibraryStatusPill(text: "Reread", tint: theme.palette.rotation[1])
                                }
                                if book.isDNF {
                                    LibraryStatusPill(text: "DNF", tint: theme.palette.rotation[2])
                                }
                            }
                        }
                    }

                    if !book.summary.isEmpty {
                        summaryToggleButton
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    LibraryRatingRow(
                        book: book,
                        useBubblyMaterial: true,
                        tint: theme.palette.secondaryAccent
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        GradientProgressBar(
                            value: book.calculatedProgress,
                            isPaused: book.status == .paused,
                            tint: theme.palette.indicators
                        )
                            .frame(height: 8)
                        
                        Text(progressSummaryText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !book.summary.isEmpty {
                    summarySection
                }
            }
        }
    }

    private var progressSummaryText: String {
        book.status == .paused ? "Paused at \(book.progressText)" : book.progressText
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Text(book.summary)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .lineLimit(isSummaryExpanded ? nil : 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var summaryToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isSummaryExpanded.toggle()
            }
        } label: {
            Image(isSummaryExpanded ? "chevup" : "chevdown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(theme.palette.primaryAction)
                .bubblyIconMaterial(tint: theme.palette.primaryAction)
                .frame(width: 34, height: 34)
                .background(Circle().fill(theme.palette.raisedSurface))
                .overlay {
                    BubblyIconMaterial(tint: theme.palette.primaryAction)
                        .mask { Circle().strokeBorder(lineWidth: 1.2) }
                }
        }
        .buttonStyle(.plain)
    }
    
    private var detailSections: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !book.subtitle.isEmpty {
                detailCard(title: "Subtitle", borderColor: theme.palette.indicators) {
                    LibraryDetailBlock(label: "Subtitle", value: book.subtitle)
                }
            }
            
            if !book.genres.isEmpty || !book.tags.isEmpty || !book.moods.isEmpty || !book.tropes.isEmpty || !book.topics.isEmpty {
                detailCard(title: "Organization", borderColor: theme.palette.primaryAction) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !book.genres.isEmpty {
                            organizationPills(
                                label: "Genre",
                                values: book.genres,
                                tint: theme.palette.primaryAction
                            )
                        }
                        if !book.topics.isEmpty {
                            organizationPills(
                                label: "Topics",
                                values: book.topics,
                                tint: theme.palette.secondaryAccent
                            )
                        }
                        if !book.tags.isEmpty {
                            organizationPills(
                                label: "Tags",
                                values: book.tags,
                                tint: theme.palette.secondaryAccent
                            )
                        }
                        if !book.moods.isEmpty {
                            organizationPills(
                                label: "Mood",
                                values: book.moods,
                                tint: theme.palette.indicators
                            )
                        }
                        if !book.tropes.isEmpty {
                            organizationPills(
                                label: "Tropes",
                                values: book.tropes,
                                tint: theme.palette.primaryAction
                            )
                        }
                    }
                }
            }
            
            if !book.publisher.isEmpty || !book.publicationYear.isEmpty || !book.isbn.isEmpty {
                detailCard(title: "Publishing", borderColor: theme.palette.secondaryAccent) {
                    VStack(alignment: .leading, spacing: 8) {
                        if !book.publisher.isEmpty {
                            LibraryDetailLine(label: "Publisher", value: book.publisher)
                        }
                        if !book.publicationYear.isEmpty {
                            LibraryDetailLine(label: "Year", value: book.publicationYear)
                        }
                        if !book.isbn.isEmpty {
                            LibraryDetailLine(label: "ISBN", value: book.isbn)
                        }
                    }
                }
            }
        }
    }
    
    private func detailCard<Content: View>(
        title: String,
        borderColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard(variant: .secondary, borderColor: borderColor) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func organizationPills(label: String, values: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            FlowLayout(spacing: 7) {
                ForEach(values, id: \.self) { value in
                    LibraryStatusPill(text: value, tint: tint)
                }
            }
        }
    }

    private func handleEPUBImport(_ result: Result<[URL], Error>) {
        epubError = nil

        do {
            guard let url = try result.get().first else { return }
            try EPUBFileAccess.attachEPUB(from: url, to: book)
        } catch {
            epubError = error.localizedDescription
        }
    }

    private func openReader() {
        epubError = nil

        do {
            guard let url = try EPUBFileAccess.resolvedEPUBURL(for: book) else {
                epubError = "No EPUB file is attached."
                return
            }

            book.epubLastOpenedAt = Date()
            book.updatedAt = Date()
            book.lastUpdated = Date()
            readerURL = url
            appState.hideTabBar = true
            showReader = true
        } catch {
            epubError = error.localizedDescription
        }
    }
}
