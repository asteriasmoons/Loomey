import Foundation
import SwiftData

enum ReadingPreferencesStore {
    static func preferredRecord(in records: [UserSettings]) -> UserSettings? {
        records.max {
            let lhs = $0.readingPreferencesUpdatedAt ?? .distantPast
            let rhs = $1.readingPreferencesUpdatedAt ?? .distantPast
            if lhs != rhs { return lhs < rhs }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.readingPreferencesJSON < $1.readingPreferencesJSON
        }
    }

    static func configuration(in records: [UserSettings]) -> ReadingPreferencesConfiguration? {
        guard let record = preferredRecord(in: records),
              let data = record.readingPreferencesJSON.data(using: .utf8),
              let value = try? JSONDecoder().decode(ReadingPreferencesConfiguration.self, from: data),
              value.version == 1 else { return nil }
        return value.normalized()
    }

    @MainActor
    static func save(_ configuration: ReadingPreferencesConfiguration?, in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<UserSettings>())
        if self.configuration(in: records) == configuration?.normalized() { return }
        let encoded = try configuration.map { try JSONEncoder().encode($0.normalized()) }
        let record = preferredRecord(in: records) ?? UserSettings()
        let inserted = records.isEmpty
        let previous = (record.readingPreferencesJSON, record.readingPreferencesUpdatedAt, record.updatedAt, record.needsSync)
        if inserted { context.insert(record) }
        record.readingPreferencesJSON = encoded.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        record.readingPreferencesUpdatedAt = Date()
        record.updatedAt = Date()
        record.needsSync = true
        do { try context.save() }
        catch {
            // Do not roll back unrelated library edits in the shared context.
            record.readingPreferencesJSON = previous.0
            record.readingPreferencesUpdatedAt = previous.1
            record.updatedAt = previous.2
            record.needsSync = previous.3
            if inserted { context.delete(record) }
            throw error
        }
    }
}
