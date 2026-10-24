import Foundation
import CoreGraphics
import ImageIO

private final class CatalogProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            var request = request
            if request.httpBody == nil, let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var body = Data()
                var buffer = [UInt8](repeating: 0, count: 4096)
                while true {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeContentData) }
                    if count == 0 { break }
                    body.append(contentsOf: buffer.prefix(count))
                }
                request.httpBody = body
            }
            let (status, data) = try Self.handler(request)
            let mime = request.url?.path.hasSuffix(".png") == true ? "image/png" : "application/json"
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": mime])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@main
private struct AutomaticCatalogContracts {
    @MainActor
    static func main() async throws {
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ name: String) { precondition(condition(), name); checks += 1 }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("loomey-catalog-contracts-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        func session() -> URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [CatalogProtocol.self]
            return URLSession(configuration: configuration)
        }
        func service(_ folder: String? = nil) -> AutomaticBookCatalogService {
            AutomaticBookCatalogService(baseURL: URL(string: "https://example.test/catalogs")!, session: session(), cacheDirectory: folder.map { root.appendingPathComponent($0) })
        }
        func wire(_ response: AutomaticCatalogResponse) throws -> Data { try JSONEncoder().encode(response) }
        func book(_ id: String, title: String? = nil, source: String = "google-books") throws -> AutomaticCatalogBook {
            let value: [String: Any] = ["id": id, "title": title ?? "New Book \(id)", "author": "Other Author \(id)", "summary": "Documented metadata", "pages": 200,
                "coverUrl": "https://images.example.test/\(id).png", "genres": ["Fantasy"], "subjects": ["Friendship"], "source": source, "language": "eng"]
            return try JSONDecoder().decode(AutomaticCatalogBook.self, from: JSONSerialization.data(withJSONObject: value))
        }
        let now = ISO8601DateFormatter().string(from: Date())
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
        let expired = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60))
        let signal = AutomaticCatalogLibraryBook(id: "finished", title: "Finished Book", author: "Known Author", isbn: "0140328726", genres: ["Fantasy"], subjects: [], rating: 5, favorite: true, status: "Finished", activity: 20)
        let reading = AutomaticCatalogLibraryBook(id: "reading", title: "Reading Book", author: "Reading Author", isbn: "", genres: ["Romance"], subjects: [], rating: 5, favorite: true, status: "Reading", activity: 900)
        let books = [signal, reading]
        let rows = try ["similar", "genres", "themes"].enumerated().map { index, id in
            AutomaticBookCatalog(id: id, title: id, books: try [book("\(index)-one"), book("\(index)-two")])
        }
        let original = AutomaticCatalogResponse(catalogs: rows, generatedAt: now, expiresAt: future, partial: false, refreshAfter: future, engineVersion: "loomey-1")
        let originalData = try wire(original)
        var calls = 0
        CatalogProtocol.handler = { request in
            calls += 1
            precondition(request.url?.host == "example.test")
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil && request.value(forHTTPHeaderField: "X-API-Key") == nil)
            precondition(UUID(uuidString: request.value(forHTTPHeaderField: "X-Loomey-Catalog-Trace") ?? "") != nil)
            return (200, originalData)
        }
        check(AutomaticCatalogIdentity.isbn("0140328726") == AutomaticCatalogIdentity.isbn("9780140328721"), "ISBN10 and ISBN13 share identity")
        check(AutomaticCatalogIdentity.isbn("9780140328722") == nil, "invalid ISBN excluded from identity")
        check(AutomaticCatalogIdentity.isbn("ISBN-13: 978-0-140-32872-1") == AutomaticCatalogIdentity.isbn("0140328726"), "labelled and punctuated ISBNs normalize")
        check(AutomaticCatalogIdentity.cleanTitle("<b>Dune</b> (Paperback)") == "Dune", "HTML and format annotations removed")
        check(AutomaticCatalogIdentity.cleanTitle("Dune: Messiah") == "Dune: Messiah", "legitimate subtitle preserved")
        check(AutomaticCatalogIdentity.cleanTitle("A Book (Volume 2)") == "A Book (Volume 2)", "legitimate series annotations preserved")
        check(AutomaticCatalogIdentity.cleanTitle("Salt &amp; Sea: A Novel") == "Salt & Sea", "redundant metadata decoded")
        check(!AutomaticCatalogIdentity.authorKeys("J. R. R. Tolkien").isDisjoint(with: AutomaticCatalogIdentity.authorKeys("Tolkien, JRR")), "initials and author order normalize")
        var readingChanged = reading
        readingChanged = AutomaticCatalogLibraryBook(id: reading.id, title: reading.title, author: reading.author, isbn: reading.isbn, genres: ["Mystery"], subjects: [], rating: 1, favorite: false, status: "Archived", activity: 0)
        check(AutomaticBookCatalogService.fingerprint(books) == AutomaticBookCatalogService.fingerprint([signal, readingChanged]), "unfinished preferences do not invalidate recommendations")
        let changed = AutomaticCatalogLibraryBook(id: signal.id, title: signal.title, author: signal.author, isbn: signal.isbn, genres: signal.genres, subjects: [], rating: 4, favorite: true, status: "Finished", activity: 20)
        check(AutomaticBookCatalogService.fingerprint(books) != AutomaticBookCatalogService.fingerprint([changed, reading]), "finished preference changes invalidate freshness")
        let outgoing = AutomaticBookCatalogService.requestSignals(books).first { $0.id == reading.id }!
        check(outgoing.genres.isEmpty && outgoing.subjects.isEmpty && outgoing.rating == 0 && !outgoing.favorite && outgoing.activity == 0, "unfinished books send exclusion identity only")
        var readingSeries = reading
        readingSeries.seriesName = "Unfinished series"
        readingSeries.seriesNumber = "2"
        check(AutomaticBookCatalogService.requestSignals([readingSeries])[0].seriesName == nil, "unfinished series metadata is never a personalization signal")
        var finishedSeries = signal
        finishedSeries.seriesName = "Finished series"
        finishedSeries.seriesNumber = "1"
        check(AutomaticBookCatalogService.requestSignals([finishedSeries])[0].seriesName == "Finished series", "existing Finished series metadata is forwarded to the new engine")

        let first = service("catalogs")
        let loaded = try await first.catalogs(books: books)
        check(loaded.catalogs.count == 3 && loaded.catalogs.allSatisfy { $0.books.count == 2 }, "multiple populated category rows decode")
        check(loaded.catalogs[0].books[0].recommendationDetail.themes == ["Friendship"], "existing detail metadata preserved")
        check(calls == 1, "one initial request")
        let libraryDetailData = try JSONEncoder().encode(rows[0].books[0].recommendationDetail)
        CatalogProtocol.handler = { request in
            precondition(request.httpMethod == "POST" && request.url?.path.hasSuffix("/library-metadata") == true)
            let identity = try JSONDecoder().decode(AutomaticCatalogBook.self, from: request.httpBody!)
            precondition(identity.title == rows[0].books[0].title)
            return (200, libraryDetailData)
        }
        let independentDetail = try await first.libraryDetail(id: rows[0].books[0].id, book: rows[0].books[0])
        check(independentDetail.title == rows[0].books[0].title, "existing or legacy catalog cards carry lookup identity when saving without sending personalization preferences")
        var coalescedCalls = 0
        CatalogProtocol.handler = { _ in coalescedCalls += 1; return (200, originalData) }
        let coalesced = service()
        async let concurrentFirst = coalesced.catalogs(books: books)
        async let concurrentSecond = coalesced.catalogs(books: books)
        _ = try await [concurrentFirst, concurrentSecond]
        check(coalescedCalls == 1, "concurrent identical preparations share one request")
        let restarted = service("catalogs")
        check(restarted.cachedCatalogs(books: books)?.catalogs.count == 3, "disk catalogs load before any network request after restart")
        _ = try await restarted.catalogs(books: books)
        check(calls == 1, "fresh persistent catalogs do not request identical data")
        restarted.prepare(books: books)
        check(restarted.response?.catalogs.count == 3 && !restarted.isPreparing, "startup immediately publishes fresh persisted rows")

        var variant = try book("alternate-edition", title: "Unrelated ISBN title")
        variant.isbns = ["9780140328721"]
        var renamed = try book("renamed", title: "Finished Book (Kindle Edition)")
        renamed.author = "Known Author"
        var alias = try book("alias", title: "Provider Variant")
        alias.titleVariants = [reading.title]
        alias.authorNames = [reading.author]
        var duplicate = rows[0].books[0]
        duplicate = try book("different-provider-id", title: duplicate.title + " (Paperback)")
        duplicate.author = rows[0].books[0].author
        var defensive = original
        defensive.catalogs[0].books += [variant, renamed, alias, duplicate]
        defensive.catalogs[1].books.append(rows[0].books[0])
        let filtered = defensive.validated(for: books)
        check(filtered.catalogs.flatMap(\.books).count == 6, "all library statuses, ISBN variants, aliases and duplicate editions excluded")
        var crossProvider = try book("hardcover-id")
        crossProvider.providerIDs = ["google-books": ["shared-volume"]]
        var secondProvider = try book("openlibrary-id")
        secondProvider.providerIDs = ["google-books": ["shared-volume"]]
        check(!AutomaticCatalogIdentity.tokens(crossProvider).isDisjoint(with: AutomaticCatalogIdentity.tokens(secondProvider)), "provider aliases identify duplicate cross-source records")
        var durable = original
        durable.expiresAt = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3 * 86400))
        check(durable.validated(for: books).expirationDate > Date().addingTimeInterval(2 * 86400), "independent multi-source catalogs retain their multi-day cache lifetime")
        var foreign = rows[0].books[0]
        foreign.language = "nld"
        defensive.catalogs = [AutomaticBookCatalog(id: "similar", title: "Similar", books: [foreign])]
        check(defensive.validated(for: books).catalogs.isEmpty, "foreign editions never display")
        let newlyOwned = AutomaticCatalogLibraryBook(id: "new-owned", title: rows[0].books[0].title, author: rows[0].books[0].author, isbn: "", genres: [], subjects: [], rating: 0, favorite: false, status: "To Be Read", activity: 0)
        check(restarted.cachedCatalogs(books: books + [newlyOwned])?.catalogs.flatMap(\.books).count == 5, "newly saved books removed from cached rows immediately")
        check(restarted.cachedCatalogs(books: [reading]) == nil, "a removed or unfinished source cannot personalize cached rows")

        for (network, expected) in [(URLError.secureConnectionFailed, AutomaticCatalogError.secureConnection), (.notConnectedToInternet, .offline), (.timedOut, .timedOut)] {
            CatalogProtocol.handler = { _ in throw URLError(network) }
            let retained = try await restarted.catalogs(books: books, forceRefresh: true)
            check(retained.catalogs.count == 3 && retained.partial, "network failure retains three usable categories")
            check(restarted.lastFailure?.localizedDescription == expected.localizedDescription, "network failures mapped to a useful message")
            check(service("catalogs").cachedCatalogs(books: books)?.catalogs.count == 3, "failed refresh does not overwrite persistent rows")
        }
        CatalogProtocol.handler = { _ in (429, Data()) }
        let limited = try await restarted.catalogs(books: books, forceRefresh: true)
        check(limited.catalogs.count == 3, "rate limits preserve saved results")
        check(restarted.lastFailure?.localizedDescription == AutomaticCatalogError.rateLimited.localizedDescription, "rate limit remains distinguishable")
        let noCache = service()
        CatalogProtocol.handler = { _ in throw URLError(.secureConnectionFailed) }
        do { _ = try await noCache.catalogs(books: books); preconditionFailure("uncached TLS failure must not be an empty success") }
        catch AutomaticCatalogError.secureConnection { checks += 1 }

        var partial = original
        partial.catalogs = [original.catalogs[0]]
        partial.partial = true
        partial.categoryStates = ["themes": AutomaticCatalogCategoryState(state: "error", generatedAt: now, refreshAfter: future, expiresAt: future, errorCode: "PROVIDER_UNAVAILABLE")]
        let partialData = try wire(partial)
        CatalogProtocol.handler = { _ in (200, partialData) }
        let merged = try await restarted.catalogs(books: books, forceRefresh: true)
        check(merged.catalogs.count == 3, "one failed category does not erase another")
        partial.categoryStates?["themes"]?.state = "empty"
        let emptyCategoryData = try wire(partial)
        CatalogProtocol.handler = { _ in (200, emptyCategoryData) }
        let withoutEmpty = try await restarted.catalogs(books: books, forceRefresh: true)
        check(withoutEmpty.catalogs.map(\.id) == ["similar", "genres"], "authoritative empty category does not erase other categories")

        var building = original
        building.state = "building"
        building.retryAfter = 1
        building.partial = true
        let buildingData = try wire(building)
        var polls = 0
        var updates = 0
        CatalogProtocol.handler = { _ in polls += 1; return (polls == 1 ? 202 : 200, polls == 1 ? buildingData : originalData) }
        _ = try await restarted.catalogs(books: books, forceRefresh: true) { _ in updates += 1 }
        check(polls == 2 && updates >= 2, "progressive rows remain visible until the complete update")
        var stale = original
        stale.refreshAfter = expired
        AutomaticCatalogPersistence(directory: root.appendingPathComponent("stale")).save(AutomaticCatalogSnapshot(version: 1, sourceFingerprint: AutomaticBookCatalogService.sourceFingerprint(books), requestFingerprint: AutomaticBookCatalogService.fingerprint(books), response: stale, sourceIDs: [signal.id]))
        let preparation = service("stale")
        CatalogProtocol.handler = { _ in (200, originalData) }
        preparation.prepare(books: books)
        check(preparation.response?.catalogs.count == 3 && preparation.isPreparing, "stale startup cache is visible while background preparation begins")
        preparation.prepare(books: books)
        for _ in 0..<200 where preparation.isPreparing { try await Task.sleep(for: .milliseconds(5)) }
        check(!preparation.isPreparing && preparation.response?.catalogs.count == 3, "application preparation completes without a catalog screen")
        preparation.suspendPreparation()
        check(!preparation.isPreparing, "suspending preparation does not require background execution")
        check(preparation.response?.catalogs.count == 3, "suspension preserves prepared rows")
        var expiredResponse = original
        expiredResponse.expiresAt = expired
        let expiredFolder = root.appendingPathComponent("expired")
        AutomaticCatalogPersistence(directory: expiredFolder).save(AutomaticCatalogSnapshot(version: 1, sourceFingerprint: AutomaticBookCatalogService.sourceFingerprint(books), requestFingerprint: AutomaticBookCatalogService.fingerprint(books), response: expiredResponse))
        check(service("expired").cachedCatalogs(books: books) == nil, "hard-expired catalogs are not displayed")
        check(!FileManager.default.fileExists(atPath: expiredFolder.appendingPathComponent("catalogs.json").path), "expired feature data is removed from disk")

        let context = CGContext(data: nil, width: 4, height: 6, bitsPerComponent: 8, bytesPerRow: 16, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 6))
        let imageData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(imageData, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(destination))
        let png = imageData as Data
        check(CatalogCoverLoader.isImage(png), "image bytes are decoded and validated")
        check(!CatalogCoverLoader.isImage(Data("not an image".utf8)), "corrupt cover data rejected")
        var imageCalls = 0
        CatalogProtocol.handler = { request in
            imageCalls += 1
            precondition(request.value(forHTTPHeaderField: "X-API-Key") == nil)
            return (200, png)
        }
        let coverFolder = root.appendingPathComponent("covers")
        let covers = CatalogCoverLoader(session: session(), cacheDirectory: coverFolder, resolve: { _ in URL(string: "https://images.example.test/provider.png") })
        _ = try await covers.load(urlString: nil, imageID: "stable-provider-image")
        check(imageCalls == 1, "correct provider image resolves without a placeholder")
        let restartedCovers = CatalogCoverLoader(session: session(), cacheDirectory: coverFolder, resolve: { _ in preconditionFailure("cached image must not re-resolve an expired signed URL") })
        _ = try await restartedCovers.load(urlString: nil, imageID: "stable-provider-image")
        check(imageCalls == 1, "cover bytes survive a restart and signed URL expiration")
        let fallback = CatalogCoverLoader(session: session(), resolve: { _ in throw URLError(.secureConnectionFailed) })
        _ = try await fallback.load(urlString: "https://images.example.test/fallback.png", imageID: "missing-image")
        check(imageCalls == 2, "a provider image failure uses only its associated legitimate cover fallback")
        var fallbackPaths: [String] = []
        CatalogProtocol.handler = { request in
            fallbackPaths.append(request.url!.path)
            if request.url?.path == "/hardcover.png" { throw URLError(.secureConnectionFailed) }
            return (200, png)
        }
        let multiCover = CatalogCoverLoader(session: session(), resolve: { _ in nil })
        _ = try await multiCover.load(urlString: "https://images.example.test/hardcover.png", imageID: nil, fallbackURLs: ["https://images.example.test/openlibrary.png"])
        check(fallbackPaths == ["/hardcover.png", "/openlibrary.png"], "a TLS failure on one provider's cover uses the next associated provider cover")
        check(multiCover.cachedData(urlString: "https://images.example.test/hardcover.png", imageID: nil) != nil, "successful fallback image bytes use the persistent card cache")
        CatalogProtocol.handler = { _ in (200, png) }
        let genericMIME = CatalogCoverLoader(session: session(), resolve: { _ in nil })
        let decodedGenericMIME = try await genericMIME.load(URL(string: "https://images.example.test/raw")!)
        check(CatalogCoverLoader.isImage(decodedGenericMIME), "valid image bytes are accepted even when a CDN reports a generic MIME type")
        CatalogProtocol.handler = { _ in throw URLError(.secureConnectionFailed) }
        let broken = CatalogCoverLoader(session: session(), resolve: { _ in nil })
        do { _ = try await broken.load(URL(string: "https://images.example.test/broken.png")!); preconditionFailure("broken image must fail independently") }
        catch { checks += 1 }
        check(restarted.cachedCatalogs(books: books)?.catalogs.count == 3, "cover TLS failure cannot invalidate catalog metadata")
        do { _ = try await restarted.imageURL(id: "missing-cover"); preconditionFailure("resolver TLS failure must fail independently") }
        catch AutomaticCatalogError.secureConnection { checks += 1 }
        check(restarted.cachedCatalogs(books: books)?.catalogs.count == 3, "image resolver failure also preserves catalog metadata")
        CatalogProtocol.handler = { _ in (200, Data("not an image".utf8)) }
        let invalidCover = CatalogCoverLoader(session: session(), resolve: { _ in nil })
        do { _ = try await invalidCover.load(URL(string: "https://images.example.test/invalid.png")!); preconditionFailure("malformed image must not be cached") }
        catch { checks += 1 }
        check(invalidCover.cachedData(urlString: "https://images.example.test/invalid.png", imageID: nil) == nil, "invalid image bytes do not poison the cache")
        check(CatalogNetworkPolicy.safeURL("http://images.example.test/cover.png") == nil, "HTTP downgrade rejected")
        check(CatalogNetworkPolicy.safeURL("https://images.example.test/cover.png?APIKEY=secret") == nil, "provider credentials rejected")
        check(CatalogNetworkPolicy.safeURL("https://user:secret@images.example.test/cover.png") == nil, "credential-bearing image URL rejected")
        let policy = CatalogNetworkPolicy(origin: URL(string: "https://example.test/catalogs")!)
        let task = session().dataTask(with: URL(string: "https://example.test/catalogs")!)
        var redirected: URLRequest?
        policy.urlSession(session(), task: task, willPerformHTTPRedirection: HTTPURLResponse(url: URL(string: "https://example.test/catalogs")!, statusCode: 302, httpVersion: nil, headerFields: nil)!, newRequest: URLRequest(url: URL(string: "http://example.test/catalogs")!)) { redirected = $0 }
        check(redirected == nil, "catalog redirect cannot weaken HTTPS")

        let empty = AutomaticCatalogResponse(catalogs: [], generatedAt: now, expiresAt: future, partial: false)
        let emptyData = try wire(empty)
        CatalogProtocol.handler = { _ in (200, emptyData) }
        let emptyResult = try await service().catalogs(books: [])
        check(emptyResult.catalogs.isEmpty, "empty catalog is an explicit success, not an error")
        let deniedData = Data(#"{"error":"PROVIDER_ACCESS_DENIED"}"#.utf8)
        CatalogProtocol.handler = { _ in (503, deniedData) }
        let retainedAfterDenial = try await restarted.catalogs(books: books, forceRefresh: true)
        check(retainedAfterDenial.catalogs.count == 3, "one provider's access denial does not erase independent recommendations")
        check(service("catalogs").cachedCatalogs(books: books)?.catalogs.count == 3, "provider errors preserve persistent multi-source catalogs")
        let jobDenied = service("job-denied")
        CatalogProtocol.handler = { _ in (200, originalData) }
        _ = try await jobDenied.catalogs(books: books)
        jobDenied.prepare(books: books)
        var deniedJob = original
        deniedJob.state = "failed"
        deniedJob.errorCode = "PROVIDER_ACCESS_DENIED"
        let deniedJobData = try wire(deniedJob)
        CatalogProtocol.handler = { _ in (200, deniedJobData) }
        let deniedResult = try await jobDenied.catalogs(books: books, forceRefresh: true)
        check(deniedResult.catalogs.count == 3, "job-level provider failure preserves independently sourced rows")
        var revoked = original
        revoked.catalogs[0].books.append(try book("licensed", source: "bookdatabase.io"))
        revoked.disabledSources = ["bookdatabase.io"]
        let revokedData = try wire(revoked)
        CatalogProtocol.handler = { _ in (200, revokedData) }
        let scopedResult = try await jobDenied.catalogs(books: books, forceRefresh: true)
        check(scopedResult.catalogs.count == 3 && scopedResult.catalogs.flatMap(\.books).allSatisfy { !$0.source.contains("bookdatabase.io") }, "subscription revocation removes only licensed records, not independent categories")
        check(service("job-denied").cachedCatalogs(books: books)?.catalogs.count == 3, "scoped provider removal persists without deleting other sources")
        var expiredMetadata = original
        var expiredBook = try book("expired-licensed", source: "bookdatabase.io")
        expiredBook.metadataExpiresAt = expired
        expiredMetadata.catalogs[0].books.append(expiredBook)
        check(expiredMetadata.validated(for: books).catalogs.flatMap(\.books).count == 6, "temporary licensed metadata expires independently of valid multi-source records")
        let unconfiguredPayload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(AutomaticCatalogRequest(books: books))) as! [String: Any]
        check(unconfiguredPayload["preferences"] == nil, "unconfigured readers send the original wire contract without fabricated preferences")
        let preferences = ReadingPreferencesConfiguration(preferredCategory: .fiction, favoriteFictionGenres: ["Fantasy", "Romance"], currentlyInterestedIn: ["Found family"], recommendationStyle: .followPreferences)
        check(AutomaticBookCatalogService.fingerprint(books, preferences: preferences) != AutomaticBookCatalogService.fingerprint(books), "explicit preferences invalidate recommendation freshness")
        var reordered = preferences
        reordered.favoriteFictionGenres.reverse()
        check(AutomaticBookCatalogService.fingerprint(books, preferences: preferences) == AutomaticBookCatalogService.fingerprint(books, preferences: reordered), "selection ordering does not trigger duplicate network preparations")
        var currentInterestChanged = preferences
        currentInterestChanged.currentlyInterestedIn = ["Time travel"]
        check(AutomaticBookCatalogService.fingerprint(books, preferences: preferences) != AutomaticBookCatalogService.fingerprint(books, preferences: currentInterestChanged), "current reading interests invalidate freshness independently of favorites")
        var preferenceCalls = 0
        CatalogProtocol.handler = { request in
            preferenceCalls += 1
            let payload = try JSONDecoder().decode(AutomaticCatalogRequest.self, from: request.httpBody!)
            precondition(payload.preferences == preferences.normalized())
            precondition(payload.books.first { $0.status == "Reading" }?.genres.isEmpty == true)
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            return (200, originalData)
        }
        let personalized = service("personalized")
        let preferredResult = try await personalized.catalogs(books: books, preferences: preferences)
        check(preferredResult.catalogs.count == 3, "the existing three independent sections survive preference-aware loading")
        let personalizedRestarted = service("personalized")
        personalizedRestarted.prepare(books: books, preferences: preferences)
        check(personalizedRestarted.response?.catalogs.count == 3 && !personalizedRestarted.isPreparing, "preference-aware catalogs display synchronously after restart")
        _ = try await personalizedRestarted.catalogs(books: books, preferences: preferences)
        check(preferenceCalls == 1, "unchanged persisted preferences reuse catalogs without another request")
        let typedSnapshot = AutomaticCatalogPersistence(directory: root.appendingPathComponent("personalized")).load()
        check(typedSnapshot?.requestFingerprint == AutomaticBookCatalogService.fingerprint(books, preferences: preferences), "the saved cache records the explicit preference fingerprint")
        var changedStyle = preferences
        changedStyle.recommendationStyle = .surpriseMe
        CatalogProtocol.handler = { request in
            let payload = try JSONDecoder().decode(AutomaticCatalogRequest.self, from: request.httpBody!)
            precondition(payload.preferences?.recommendationStyle == .surpriseMe)
            throw URLError(.secureConnectionFailed)
        }
        let afterPreferenceFailure = try await personalizedRestarted.catalogs(books: books, preferences: changedStyle)
        check(afterPreferenceFailure.catalogs.count == 3, "a preference refresh failing TLS preserves already-prepared matching categories")
        check(personalizedRestarted.lastFailure == .secureConnection, "preference refresh errors remain distinguishable from empty results")
        var nonfictionPreferences = preferences
        nonfictionPreferences.preferredCategory = .nonfiction
        check(personalizedRestarted.cachedCatalogs(books: books, preferences: nonfictionPreferences)?.catalogs.isEmpty == true, "cached fiction does not violate a newly selected nonfiction category")
        check(ReadingPreferencesConfiguration.default.allows(genres: ["Nonfiction"], subjects: []), "Both preserves unrestricted cached category matching")
        check(!preferences.allows(genres: ["Horror"], subjects: ["Ghosts"]), "Follow My Preferences never retains history-only cached books that contradict explicit interests")
        var preferenceOnlyCalls = 0
        CatalogProtocol.handler = { request in
            preferenceOnlyCalls += 1
            let payload = try JSONDecoder().decode(AutomaticCatalogRequest.self, from: request.httpBody!)
            precondition(payload.books.isEmpty && payload.preferences != nil)
            return (200, originalData)
        }
        let preferenceOnly = service("preference-only")
        preferenceOnly.prepare(books: [], preferences: preferences)
        check(preferenceOnly.hasRecommendationSources && !preferenceOnly.hasFinishedSources, "the homepage can show preference-only discovery without pretending the user has Finished books")
        while preferenceOnly.isPreparing { try await Task.sleep(for: .milliseconds(5)) }
        check(preferenceOnlyCalls == 1 && preferenceOnly.response?.catalogs.count == 3, "startup prepares explicit preferences before any Finished history exists")
        let resetPayload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(AutomaticCatalogRequest(books: books))) as! [String: Any]
        check(resetPayload["preferences"] == nil, "reset returns to the backward-compatible history-only wire format")
        print("Automatic catalog contracts: \(checks) checks passed; mocked networking and temporary storage only")
    }
}
