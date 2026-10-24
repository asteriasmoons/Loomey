import SwiftUI

struct HomeAutomaticCatalogsSection: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var catalogs = AutomaticBookCatalogService.shared
    @State private var selectedBook: AutomaticCatalogBook?

    private var errorMessage: String? { catalogs.lastFailure?.localizedDescription ?? (catalogs.response?.partial == true && !catalogs.isPreparing ? "Some recommendations couldn't update. Your saved catalogs are still available." : nil) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let response = catalogs.response, !response.catalogs.isEmpty {
                ForEach(Array(response.catalogs.enumerated()), id: \.element.id) { index, catalog in
                    AutomaticCatalogShelf(catalog: catalog, accent: theme.palette.rotation[index % theme.palette.rotation.count]) { book in
                        CatalogDiagnostics.log("view.open_book", ["workID": book.id, "language": book.language ?? "unknown"], traceID: response.traceID)
                        selectedBook = book
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if catalogs.isPreparing {
                    Text("Loading more books...")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
                if let errorMessage { statusRow(errorMessage) }
            } else if catalogs.hasRecommendationSources {
                Text("Discover Your Next Read")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.cardTitle)
                if catalogs.isPreparing {
                    HStack(spacing: 12) {
                        LumeyDottedGradientSpinner(size: 32)
                        Text("Finding books for you")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                    .accessibilityElement(children: .combine)
                } else {
                    statusRow(errorMessage ?? "No matching catalogs yet.")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("automatic-catalogs-stack")
        .adaptivePresentation(item: $selectedBook, useFullScreenCover: horizontalSizeClass == .regular) { book in
            RecommendedBookDetailSheet(book: book.recommendationBook, catalogBook: book)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
        }
    }

    private func statusRow(_ message: String) -> some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            Spacer(minLength: 0)
            Button {
                CatalogDiagnostics.log("view.retry")
                catalogs.retry()
            } label: {
                Image("reset")
                    .renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 22, height: 22)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retry book catalogs")
            .disabled(catalogs.isPreparing)
        }
    }

}

private extension View {
    @ViewBuilder
    func adaptivePresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        if useFullScreenCover {
            fullScreenCover(item: item, content: content)
        } else {
            sheet(item: item, content: content)
        }
    }
}
