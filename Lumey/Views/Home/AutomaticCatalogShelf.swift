import SwiftUI

struct AutomaticCatalogShelf: View {
    let catalog: AutomaticBookCatalog
    let accent: Color
    let onSelect: (AutomaticCatalogBook) -> Void
    var coverLoader: CatalogCoverLoader = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !catalog.books.isEmpty {
            Text(catalog.title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(catalog.books) { book in
                        Button { onSelect(book) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                CatalogBookCover(urlString: book.coverUrl, imageID: book.imageID, fallbackURLs: book.coverUrls ?? [], title: book.title, width: 116, height: 174, accent: accent, loader: coverLoader)
                                Text(book.title)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.text.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(book.author)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let genre = book.genres.first ?? book.subjects.first {
                                    Text(genre)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 116, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(book.title), by \(book.author)")
                        .accessibilityIdentifier("catalog-book-\(book.id)")
                    }
                }
                .padding(.vertical, 2)
            }
            .accessibilityIdentifier("catalog-row-\(catalog.id)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("catalog-section-\(catalog.id)")
    }
}

struct CatalogBookCover: View {
    let urlString: String?
    var imageID: String? = nil
    var fallbackURLs: [String] = []
    let title: String
    let width: CGFloat
    let height: CGFloat
    let accent: Color
    var loader: CatalogCoverLoader = .shared
    var onFailure: (() -> Void)? = nil
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            accent.opacity(0.28)
            if let image = image ?? loader.cachedData(urlString: urlString, imageID: imageID, fallbackURLs: fallbackURLs).flatMap({ UIImage(data: $0) }) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("bookstand").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 32, height: 32)
                    .bubblyIconMaterial(tint: accent)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accent, lineWidth: 1))
        .accessibilityLabel("Cover of \(title)")
        .task(id: "\(urlString ?? ""):\(imageID ?? ""):\(fallbackURLs.joined(separator: "|"))") {
            image = loader.cachedData(urlString: urlString, imageID: imageID, fallbackURLs: fallbackURLs).flatMap { UIImage(data: $0) }
            if let data = try? await loader.load(urlString: urlString, imageID: imageID, fallbackURLs: fallbackURLs), !Task.isCancelled { image = UIImage(data: data) }
            if !Task.isCancelled {
                CatalogDiagnostics.log("cover.render", ["imageID": imageID ?? "none", "rendered": image != nil, "hasISBNImage": urlString != nil])
                if image == nil { onFailure?() }
            }
        }
    }
}
