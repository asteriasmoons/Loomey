import CryptoKit
import Foundation
import ImageIO

@MainActor
final class CatalogCoverLoader {
    static let shared = CatalogCoverLoader()
    private final class Entry {
        let data: Data
        let expiresAt: Date
        init(_ data: Data, expiresAt: Date = Date().addingTimeInterval(86400)) { self.data = data; self.expiresAt = expiresAt }
    }
    private struct SavedCover: Codable { let data: Data; let expiresAt: Date }
    private let cache = NSCache<NSString, Entry>()
    private var inFlight: [String: Task<Data, Error>] = [:]
    private var failedUntil: [String: Date] = [:]
    private let session: URLSession
    private let directory: URL?
    private let resolve: (String) async throws -> URL?

    init(session: URLSession? = nil, cacheDirectory: URL? = nil, resolve: ((String) async throws -> URL?)? = nil) {
        cache.countLimit = 80
        cache.totalCostLimit = 24 * 1024 * 1024
        self.directory = cacheDirectory ?? (session == nil ? AutomaticCatalogPersistence.directory.appendingPathComponent("Covers", isDirectory: true) : nil)
        self.resolve = resolve ?? { try await AutomaticBookCatalogService.shared.imageURL(id: $0) }
        if let session { self.session = session }
        else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            self.session = URLSession(configuration: configuration, delegate: CatalogNetworkPolicy(), delegateQueue: nil)
        }
        trimDisk()
    }

    static func clearCache() { shared.clear() }

    func remove(imageID: String) {
        let key = "image:" + imageID
        cache.removeObject(forKey: key as NSString)
        inFlight[key]?.cancel()
        inFlight[key] = nil
        failedUntil[key] = nil
        if let file = file(key) { try? FileManager.default.removeItem(at: file) }
    }

    private func clear() {
        cache.removeAllObjects()
        inFlight.values.forEach { $0.cancel() }
        inFlight.removeAll()
        failedUntil.removeAll()
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func key(_ urlString: String?, _ imageID: String?) -> String? {
        if let imageID, !imageID.isEmpty { return "image:" + imageID }
        return CatalogNetworkPolicy.safeURL(urlString).map { "url:" + $0.absoluteString }
    }

    private func file(_ key: String) -> URL? {
        directory?.appendingPathComponent(SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined() + ".json")
    }

    func cachedData(urlString: String?, imageID: String?, fallbackURLs: [String] = []) -> Data? {
        guard let key = key(urlString ?? fallbackURLs.first, imageID) else { return nil }
        if let entry = cache.object(forKey: key as NSString), entry.expiresAt > Date() { return entry.data }
        guard let file = file(key), let data = try? Data(contentsOf: file),
              let saved = try? JSONDecoder().decode(SavedCover.self, from: data) else { return nil }
        guard saved.expiresAt > Date(), Self.isImage(saved.data) else { try? FileManager.default.removeItem(at: file); return nil }
        cache.setObject(Entry(saved.data, expiresAt: saved.expiresAt), forKey: key as NSString, cost: saved.data.count)
        return saved.data
    }

    func load(_ url: URL) async throws -> Data { try await load(urlString: url.absoluteString, imageID: nil) }

    func load(urlString: String?, imageID: String?, fallbackURLs: [String] = []) async throws -> Data {
        guard let key = key(urlString ?? fallbackURLs.first, imageID) else { throw URLError(.badURL) }
        if let data = cachedData(urlString: urlString, imageID: imageID, fallbackURLs: fallbackURLs) { return data }
        if let until = failedUntil[key], until > Date() { throw URLError(.resourceUnavailable) }
        if let task = inFlight[key] { return try await task.value }
        let task = Task { () throws -> Data in
            if let imageID, !imageID.isEmpty {
                do {
                    if let url = try await resolve(imageID) { return try await fetch(url) }
                } catch is CancellationError { throw CancellationError() }
                catch { CatalogDiagnostics.log("cover.provider_failed", ["imageID": imageID, "code": (error as NSError).code]) }
            }
            var attempted = Set<URL>()
            var failure: Error = URLError(.badURL)
            for value in ([urlString].compactMap { $0 } + fallbackURLs).prefix(6) {
                try Task.checkCancellation()
                guard let url = CatalogNetworkPolicy.safeURL(value), attempted.insert(url).inserted else { continue }
                do { return try await fetch(url) }
                catch is CancellationError { throw CancellationError() }
                catch { failure = error }
            }
            throw failure
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        do {
            let data = try await task.value
            let entry = Entry(data)
            cache.setObject(entry, forKey: key as NSString, cost: data.count)
            if let directory, let file = file(key) {
                do {
                    try AutomaticCatalogPersistence.prepare(directory)
                    try AutomaticCatalogPersistence.write(JSONEncoder().encode(SavedCover(data: data, expiresAt: entry.expiresAt)), to: file)
                    trimDisk()
                } catch { CatalogDiagnostics.log("cover.disk_write_failed", ["code": (error as NSError).code]) }
            }
            return data
        } catch {
            if !(error is CancellationError) { failedUntil[key] = Date().addingTimeInterval(60) }
            CatalogDiagnostics.log("cover.failed", ["code": (error as NSError).code])
            throw error
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        guard CatalogNetworkPolicy.safeURL(url.absoluteString) != nil else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        CatalogDiagnostics.log("cover.request", ["host": url.host ?? "unknown", "stage": "image_bytes"])
        do {
            let (data, response) = try await session.data(for: request)
            let http = response as? HTTPURLResponse
            CatalogDiagnostics.log("cover.response", ["host": response.url?.host ?? "unknown", "status": http?.statusCode ?? 0, "bytes": data.count, "mime": response.mimeType ?? "unknown"])
            guard CatalogNetworkPolicy.safeURL(response.url?.absoluteString) != nil, http?.statusCode == 200,
                  data.count <= 5 * 1024 * 1024, Self.isImage(data) else { throw URLError(.cannotDecodeContentData) }
            return data
        } catch {
            CatalogDiagnostics.log("cover.network_failed", ["host": url.host ?? "unknown", "stage": "image_bytes", "code": (error as NSError).code])
            throw error
        }
    }

    static func isImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int, let height = properties[kCGImagePropertyPixelHeight] as? Int else { return false }
        return width > 1 && height > 1 && width <= 8192 && height <= 8192 && width * height <= 40_000_000
    }

    func prefetch(_ books: [AutomaticCatalogBook]) async {
        await withTaskGroup(of: Void.self) { group in
            var iterator = books.makeIterator()
            for _ in 0..<3 {
                if let book = iterator.next() { group.addTask { _ = try? await self.load(urlString: book.coverUrl, imageID: book.imageID, fallbackURLs: book.coverUrls ?? []) } }
            }
            while await group.next() != nil {
                if Task.isCancelled { group.cancelAll(); break }
                if let book = iterator.next() { group.addTask { _ = try? await self.load(urlString: book.coverUrl, imageID: book.imageID, fallbackURLs: book.coverUrls ?? []) } }
            }
        }
    }

    private func trimDisk() {
        guard let directory, let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }
        let sorted = files.compactMap { url -> (URL, Date, Int)? in
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else { return nil }
            return (url, values.contentModificationDate ?? .distantPast, values.fileSize ?? 0)
        }.sorted { $0.1 > $1.1 }
        var bytes = 0
        for (index, file) in sorted.enumerated() {
            bytes += file.2
            if index >= 80 || bytes > 64 * 1024 * 1024 || file.1 < Date().addingTimeInterval(-86400) { try? FileManager.default.removeItem(at: file.0) }
        }
    }
}
