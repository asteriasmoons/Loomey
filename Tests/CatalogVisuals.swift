import SwiftUI

// Isolated simulator harness. Not included in the Loomey application target.
private final class FixtureCoverProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "catalog-fixture.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 116, height: 174)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 116, height: 174))
            let text = "COVER\nFIXTURE"
            text.draw(in: CGRect(x: 14, y: 35, width: 90, height: 100), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.white])
        }
        let data = image.pngData()!
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/png"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
private struct CatalogVisualsApp: App {
    init() { URLProtocol.registerClass(FixtureCoverProtocol.self) }
    var body: some Scene {
        WindowGroup { CatalogVisualsRoot().preferredColorScheme(.dark) }
    }
}

private struct CatalogVisualsRoot: View {
    @State private var selectedTitle = "Catalog UI Verification"
    private let coverLoader: CatalogCoverLoader = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FixtureCoverProtocol.self]
        return CatalogCoverLoader(session: URLSession(configuration: config))
    }()
    private var books: [AutomaticCatalogBook] {
        (0..<12).map { index in
            AutomaticCatalogBook(id: "fixture-\(index)", title: index == 0 ? "A Long Title That Stays Inside Its Own Tile" : "Fixture Book \(index)", author: "A Long Author Name", summary: "Fixture metadata", subtitle: nil, isbn: nil, pages: 200, publisher: nil, releaseYear: nil, coverUrl: "https://catalog-fixture.test/\(index).png", imageID: nil, genres: ["Speculative Fiction"], subjects: [], source: "Test Fixture")
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(selectedTitle).font(.title2.bold()).foregroundStyle(.white)
                ForEach(0..<3) { index in
                    AutomaticCatalogShelf(catalog: AutomaticBookCatalog(id: "fixture-\(index)", title: ["You Might Also Like", "Based on Your Favorite Genres", "Explore Similar Themes"][index], books: books), accent: AppTheme.default.palette.rotation[index], onSelect: { selectedTitle = $0.title }, coverLoader: coverLoader)
                }
            }
            .padding(20)
        }
        .background(AppTheme.default.palette.background)
    }
}
