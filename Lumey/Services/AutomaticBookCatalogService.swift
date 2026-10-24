import CryptoKit
import Foundation
import Combine

enum CatalogDiagnostics {
    static func log(_ event: String, _ fields: [String: Any] = [:], traceID: String? = nil) {
        var entry = fields
        entry["event"] = event
        entry["traceID"] = traceID ?? "frontend"
        entry["time"] = ISO8601DateFormatter().string(from: Date())
        if let data = try? JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys]), let line = String(data: data, encoding: .utf8) {
            print("[LoomeyCatalog] \(line)")
        }
    }
}

enum AutomaticCatalogError: LocalizedError {
    case unavailable
    case rateLimited
    case timedOut
    case englishUnavailable
    case libraryMetadataUnavailable
    case offline
    case secureConnection

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Book catalogs are unavailable right now."
        case .rateLimited: return "Book catalogs are busy. Please try again later."
        case .timedOut: return "Book catalogs took too long to respond. Please try again."
        case .englishUnavailable: return "No verified English editions were returned. The catalog backend needs to refresh its results."
        case .libraryMetadataUnavailable: return "This book cannot be saved yet because independent library metadata is unavailable."
        case .offline: return "You're offline. Your saved book catalogs are still available."
        case .secureConnection: return "Loomey couldn't securely refresh book catalogs. Saved recommendations are still available. Please try again later."
        }
    }
}

@MainActor
final class AutomaticBookCatalogService: ObservableObject {
    static let shared = AutomaticBookCatalogService()
    private let baseURL: URL
    private let session: URLSession
    @Published private(set) var response: AutomaticCatalogResponse?
    @Published private(set) var isPreparing = false
    @Published private(set) var lastFailure: AutomaticCatalogError?
    @Published private(set) var hasFinishedSources = false
    @Published private(set) var hasReadingPreferences = false
    var hasRecommendationSources: Bool { hasFinishedSources || hasReadingPreferences }
    private let persistence: AutomaticCatalogPersistence
    private let preloadCovers: ([AutomaticCatalogBook]) async -> Void
    private let usesSharedCoverCache: Bool
    private var snapshot: AutomaticCatalogSnapshot?
    private var requests: [String: (id: UUID, task: Task<AutomaticCatalogResponse, Error>)] = [:]
    private var preparation: Task<Void, Never>?
    private var preparationKey: String?
    private var preparationID = UUID()
    private var nextAttempt = Date.distantPast
    private var library: [AutomaticCatalogLibraryBook] = []
    private var readingPreferences: ReadingPreferencesConfiguration?

    private struct Failure: Decodable {
        let error: String
    }

    init(baseURL: URL = URL(string: "https://appapi.voxiverse.ink/api/books/automatic-catalogs")!, session: URLSession? = nil, cacheDirectory: URL? = nil, coverPreloader: (([AutomaticCatalogBook]) async -> Void)? = nil) {
        self.baseURL = baseURL
        persistence = AutomaticCatalogPersistence(directory: cacheDirectory ?? (session == nil ? AutomaticCatalogPersistence.directory : nil))
        snapshot = persistence.load()
        usesSharedCoverCache = session == nil
        preloadCovers = coverPreloader ?? { books in
            if session == nil { await CatalogCoverLoader.shared.prefetch(books) }
        }
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.timeoutIntervalForRequest = 45
            configuration.timeoutIntervalForResource = 50
            self.session = URLSession(configuration: configuration, delegate: CatalogNetworkPolicy(origin: baseURL), delegateQueue: nil)
        }
    }

    static func requestSignals(_ books: [AutomaticCatalogLibraryBook]) -> [AutomaticCatalogLibraryBook] {
        books.map { book -> AutomaticCatalogLibraryBook in
            let finished = book.status == "Finished"
            return AutomaticCatalogLibraryBook(id: book.id, title: AutomaticCatalogIdentity.cleanTitle(book.title), author: book.author, isbn: book.isbn,
                genres: finished ? Array(Set(book.genres)).sorted() : [], subjects: finished ? Array(Set(book.subjects)).sorted() : [],
                rating: finished ? book.rating : 0, favorite: finished && book.favorite, status: book.status, activity: finished ? book.activity : 0, providerBookID: book.providerBookID,
                seriesName: finished ? book.seriesName : nil, seriesNumber: finished ? book.seriesNumber : nil, subtitle: book.subtitle)
        }.sorted { $0.id < $1.id }
    }

    static func fingerprint(_ books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration? = nil) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let signals = requestSignals(books).map { book -> AutomaticCatalogLibraryBook in
            var book = book
            if book.status != "Finished" {
                book = AutomaticCatalogLibraryBook(id: book.id, title: book.title, author: book.author, isbn: book.isbn, genres: [], subjects: [], rating: 0, favorite: false, status: "Excluded", activity: 0, providerBookID: book.providerBookID, subtitle: book.subtitle)
            }
            return book
        }
        var data = (try? encoder.encode(signals)) ?? Data()
        if let preferences { data.append((try? encoder.encode(preferences.normalized())) ?? Data()) }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func sourceFingerprint(_ books: [AutomaticCatalogLibraryBook]) -> String {
        fingerprint(books.filter { $0.status == "Finished" })
    }

    func cachedCatalogs(books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration? = nil) -> AutomaticCatalogResponse? {
        guard let snapshot, snapshot.response.expirationDate > Date() else { return nil }
        let finishedIDs = Set(books.filter { $0.status == "Finished" }.map(\.id))
        let previousIDs = Set(snapshot.sourceIDs ?? [])
        guard snapshot.sourceFingerprint == Self.sourceFingerprint(books) || (!previousIDs.isEmpty && previousIDs.isSubset(of: finishedIDs)) else { return nil }
        return snapshot.response.validated(for: books, preferences: preferences)
    }

    // Owned by the application lifecycle, not by the catalog screen's task.
    func prepare(books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration? = nil, forceRefresh: Bool = false) {
        library = books
        readingPreferences = preferences?.normalized()
        hasFinishedSources = books.contains { $0.status == "Finished" }
        hasReadingPreferences = readingPreferences?.hasDiscoveryInputs == true
        let key = Self.fingerprint(books, preferences: readingPreferences)
        if preparationKey == key, preparation != nil { return }
        let cached = cachedCatalogs(books: books, preferences: readingPreferences)
        // Keep the visible shelves stable while a background refresh runs.
        // A new snapshot is presented only when the server has finished building it.
        if response == nil { response = cached }
        // Existing shelves remain visible. Only fetch more when the catalog's
        // refresh window is due; incoming results are append-only.
        if !forceRefresh, snapshot?.requestFingerprint == key, let cached, cached.engineVersion == "loomey-1", cached.refreshDate > Date() {
            if preparationKey != key {
                preparationKey = key
                Task { await preloadCovers(cached.catalogs.flatMap(\.books)) }
            }
            return
        }
        if !forceRefresh, preparationKey == key, nextAttempt > Date() { return }
        preparation?.cancel()
        preparationKey = key
        let id = UUID()
        preparationID = id
        guard hasRecommendationSources else { response = nil; isPreparing = false; return }
        isPreparing = true
        preparation = Task { [weak self] in
            guard let self else { return }
            defer { if self.preparationID == id { self.isPreparing = false; self.preparation = nil } }
            do {
                let loaded = try await self.catalogs(books: books, preferences: preferences, forceRefresh: forceRefresh)
                try Task.checkCancellation()
                if self.preparationID == id, self.snapshot != nil {
                    self.response = loaded
                    self.lastFailure = nil
                    await self.preloadCovers(loaded.catalogs.flatMap(\.books))
                }
            } catch is CancellationError { }
            catch {
                if self.preparationID == id {
                    self.lastFailure = (error as? AutomaticCatalogError) ?? .unavailable
                    self.nextAttempt = Date().addingTimeInterval(300)
                }
            }
        }
    }

    func retry() { prepare(books: library, preferences: readingPreferences, forceRefresh: true) }

    func suspendPreparation() {
        // The backend's already-dispatched job continues even when iOS suspends this process.
        preparation?.cancel()
        preparation = nil
        preparationID = UUID()
        preparationKey = nil
        isPreparing = false
    }

    func catalogs(books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration? = nil, forceRefresh: Bool = false, onUpdate: ((AutomaticCatalogResponse) async -> Void)? = nil) async throws -> AutomaticCatalogResponse {
        let key = Self.fingerprint(books, preferences: preferences)
        if let cached = cachedCatalogs(books: books, preferences: preferences) {
            if let onUpdate { await onUpdate(cached) }
            if !forceRefresh, snapshot?.requestFingerprint == key, cached.engineVersion == "loomey-1", cached.refreshDate > Date() { return cached }
        }
        if let existing = requests[key], !existing.task.isCancelled { return try await existing.task.value }
        let id = UUID()
        let task = Task { try await self.fetchCatalogs(books: books, preferences: preferences, forceRefresh: forceRefresh, onUpdate: onUpdate) }
        requests[key] = (id, task)
        defer { if requests[key]?.id == id { requests[key] = nil } }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: { task.cancel() }
    }

    private func fetchCatalogs(books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration?, forceRefresh: Bool, onUpdate: ((AutomaticCatalogResponse) async -> Void)?) async throws -> AutomaticCatalogResponse {
        let traceID = UUID().uuidString
        let finished = books.filter { $0.status == "Finished" }
        CatalogDiagnostics.log("load.start", ["libraryBooks": books.count, "finishedBooks": finished.count, "genres": Set(finished.flatMap(\.genres)).count, "subjects": Set(finished.flatMap(\.subjects)).count, "forceRefresh": forceRefresh], traceID: traceID)
        do {
            let deadline = Date().addingTimeInterval(330)
            var firstRequest = true
            var polls = 0
            while Date() < deadline {
                try Task.checkCancellation()
                let payload = AutomaticCatalogRequest(books: Self.requestSignals(books), forceRefresh: forceRefresh && firstRequest, preferences: preferences?.normalized())
                firstRequest = false
                var response: AutomaticCatalogResponse = try await request(path: "", method: "POST", body: JSONEncoder().encode(payload), timeout: 25, traceID: traceID)
                polls += 1
                try Task.checkCancellation()
                CatalogDiagnostics.log("load.progress", ["poll": polls, "state": response.state ?? "ready", "serverTraceID": response.traceID ?? "missing", "sections": response.catalogs.map { ["id": $0.id, "books": $0.books.count] as [String: Any] }, "partial": response.partial], traceID: traceID)
                if (response.disabledSources ?? []).contains("bookdatabase.io"), usesSharedCoverCache {
                    let licensed = snapshot?.response.catalogs.flatMap(\.books).filter { $0.source.contains("bookdatabase.io") } ?? []
                    for book in licensed { if let imageID = book.imageID { CatalogCoverLoader.shared.remove(imageID: imageID) } }
                }
                let originalCount = response.catalogs.flatMap(\.books).count
                response = response.validated(for: books, preferences: preferences)
                if originalCount > response.catalogs.flatMap(\.books).count { response.partial = true }
                if response.state == "failed" {
                    lastFailure = response.errorCode == "PROVIDER_QUOTA_EXHAUSTED" ? .rateLimited : response.errorCode == "CATALOG_TIMED_OUT" ? .timedOut : response.errorCode == "PROVIDER_TLS_FAILED" ? .secureConnection : .unavailable
                    if response.catalogs.isEmpty { throw lastFailure! }
                }
                if response.state != "building", response.partial, response.catalogs.isEmpty, cachedCatalogs(books: books, preferences: preferences)?.catalogs.isEmpty != false { throw AutomaticCatalogError.unavailable }
                response = retainAndSave(response, books: books, preferences: preferences)
                if let onUpdate, !response.catalogs.isEmpty { await onUpdate(response) }
                if response.state != "building" {
                    if response.state != "failed" { lastFailure = nil }
                    CatalogDiagnostics.log("load.complete", ["catalogs": response.catalogs.count, "books": response.catalogs.flatMap(\.books).count, "polls": polls, "partial": response.partial], traceID: traceID)
                    return response
                }
                try await Task.sleep(for: .seconds(Double(min(10, max(1, response.retryAfter ?? 4)))))
            }
            CatalogDiagnostics.log("load.deadline", ["polls": polls], traceID: traceID)
            throw AutomaticCatalogError.timedOut
        } catch is CancellationError { throw CancellationError() }
        catch {
            if Task.isCancelled { throw CancellationError() }
            lastFailure = (error as? AutomaticCatalogError) ?? .unavailable
            if var retained = cachedCatalogs(books: books, preferences: preferences) {
                retained.partial = true
                nextAttempt = Date().addingTimeInterval(300)
                CatalogDiagnostics.log("load.retained_after_failure", ["sections": retained.catalogs.count], traceID: traceID)
                return retained
            }
            throw lastFailure!
        }
    }

    private func retainAndSave(_ incoming: AutomaticCatalogResponse, books: [AutomaticCatalogLibraryBook], preferences: ReadingPreferencesConfiguration?) -> AutomaticCatalogResponse {
        var value = incoming
        if let previous = cachedCatalogs(books: books, preferences: preferences) {
            // Preserve existing sections and every book's position. The backend
            // can contribute new books, but cannot reshuffle or replace old ones.
            var sections = previous.catalogs
            var positions = Dictionary(uniqueKeysWithValues: sections.enumerated().map { ($0.element.id, $0.offset) })
            var seen = Set(sections.flatMap(\.books).flatMap { AutomaticCatalogIdentity.tokens($0) })
            for section in incoming.catalogs {
                var additions: [AutomaticCatalogBook] = []
                for book in section.books {
                    let identity = AutomaticCatalogIdentity.tokens(book)
                    guard seen.isDisjoint(with: identity) else { continue }
                    seen.formUnion(identity)
                    additions.append(book)
                }
                if let index = positions[section.id] {
                    sections[index].books.append(contentsOf: additions)
                    sections[index].expiresAt = section.expiresAt ?? sections[index].expiresAt
                } else if !additions.isEmpty {
                    var newSection = section
                    newSection.books = additions
                    positions[section.id] = sections.count
                    sections.append(newSection)
                }
            }
            value.catalogs = sections
        }
        value = value.validated(for: books, preferences: preferences)
        var saved = value
        saved.state = nil
        if incoming.state == "building" { saved.refreshAfter = "1970-01-01T00:00:00Z" }
        let snapshot = AutomaticCatalogSnapshot(version: 1, sourceFingerprint: Self.sourceFingerprint(books), requestFingerprint: Self.fingerprint(books, preferences: preferences), response: saved, sourceIDs: books.filter { $0.status == "Finished" }.map(\.id))
        self.snapshot = snapshot
        persistence.save(snapshot)
        return value
    }

    func detail(id: String) async throws -> AutomaticCatalogBook {
        try await request(path: "books/\(id)")
    }

    func libraryDetail(id: String, book: AutomaticCatalogBook? = nil) async throws -> RecommendationBookDetail {
        try await request(path: "books/\(id)/library-metadata", method: book == nil ? "GET" : "POST", body: book.map { try JSONEncoder().encode($0) })
    }

    func imageURL(id: String) async throws -> URL? {
        struct ImageResponse: Decodable { let url: String }
        let value: ImageResponse = try await request(path: "images/\(id)")
        return CatalogNetworkPolicy.safeURL(value.url)
    }

    private func request<T: Decodable>(path: String, method: String = "GET", body: Data? = nil, timeout: TimeInterval = 45, traceID: String = UUID().uuidString) async throws -> T {
        var request = URLRequest(url: path.isEmpty ? baseURL : baseURL.appendingPathComponent(path))
        guard CatalogNetworkPolicy.safeURL(request.url?.absoluteString) != nil else { throw AutomaticCatalogError.unavailable }
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(traceID, forHTTPHeaderField: "X-Loomey-Catalog-Trace")
        let started = Date()
        CatalogDiagnostics.log("http.send", ["method": method, "host": request.url?.host ?? "unknown", "path": request.url?.path ?? "", "stage": path.hasPrefix("images/") ? "image_resolver" : "catalog_metadata", "bodyBytes": body?.count ?? 0, "timeoutSeconds": timeout], traceID: traceID)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            CatalogDiagnostics.log("http.timeout", ["code": error.code.rawValue], traceID: traceID)
            throw AutomaticCatalogError.timedOut
        } catch let error as URLError {
            CatalogDiagnostics.log("http.network_error", ["host": request.url?.host ?? "unknown", "path": request.url?.path ?? "", "domain": (error as NSError).domain, "code": error.code.rawValue], traceID: traceID)
            if error.code == .cancelled { throw CancellationError() }
            if [.secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted, .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid, .clientCertificateRejected, .clientCertificateRequired].contains(error.code) { throw AutomaticCatalogError.secureConnection }
            if [.notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed].contains(error.code) { throw AutomaticCatalogError.offline }
            throw AutomaticCatalogError.unavailable
        }
        guard let http = response as? HTTPURLResponse else { throw AutomaticCatalogError.unavailable }
        CatalogDiagnostics.log("http.response", ["status": http.statusCode, "bytes": data.count, "elapsedMs": Int(Date().timeIntervalSince(started) * 1000), "serverTraceID": http.value(forHTTPHeaderField: "X-Loomey-Catalog-Trace") ?? "missing"], traceID: traceID)
        switch http.statusCode {
        case 200...299:
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch {
                CatalogDiagnostics.log("http.decode_error", ["message": String(describing: error)], traceID: traceID)
                throw AutomaticCatalogError.unavailable
            }
        case 429: throw AutomaticCatalogError.rateLimited
        case 504: throw AutomaticCatalogError.timedOut
        case 404: throw AutomaticCatalogError.libraryMetadataUnavailable
        default:
            let failure = try? JSONDecoder().decode(Failure.self, from: data)
            CatalogDiagnostics.log("http.backend_error", ["status": http.statusCode, "code": failure?.error ?? "UNKNOWN"], traceID: traceID)
            if failure?.error == "PROVIDER_TLS_FAILED" { throw AutomaticCatalogError.secureConnection }
            throw AutomaticCatalogError.unavailable
        }
    }
}
