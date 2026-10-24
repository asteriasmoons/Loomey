import Foundation

struct AutomaticCatalogSnapshot: Codable {
    let version: Int
    let sourceFingerprint: String
    let requestFingerprint: String
    let response: AutomaticCatalogResponse
    var sourceIDs: [String]? = nil
}

final class AutomaticCatalogPersistence {
    let directory: URL?

    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("AutomaticBookCatalogs", isDirectory: true)
    }

    init(directory: URL?) { self.directory = directory }

    func load() -> AutomaticCatalogSnapshot? {
        guard let url = directory?.appendingPathComponent("catalogs.json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(AutomaticCatalogSnapshot.self, from: data) else { return nil }
        guard value.version == 1, value.response.expirationDate > Date() else { clear(); return nil }
        return value
    }

    func save(_ value: AutomaticCatalogSnapshot) {
        guard let directory else { return }
        do {
            try Self.prepare(directory)
            try Self.write(JSONEncoder().encode(value), to: directory.appendingPathComponent("catalogs.json"))
        } catch { CatalogDiagnostics.log("cache.disk_write_failed", ["code": (error as NSError).code]) }
    }

    func clear() {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent("catalogs.json"))
    }

    static func prepare(_ directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var directory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }

    static func write(_ data: Data, to url: URL) throws {
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
