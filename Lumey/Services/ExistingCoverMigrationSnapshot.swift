import Foundation
import SwiftData

// One-time, non-destructive snapshot of covers already saved in SwiftData.
// No upload credentials, new interface, or modifications to existing books.
@MainActor
enum ExistingCoverMigrationSnapshot {
    private struct Cover: Codable {
        let title: String
        let author: String
        let isbn: String
        let imageBase64: String
    }

    // Keep a separate incremental queue for newly saved covers.
    // The Mac uploader holds the admin token; the iPhone never does.
    static func queueSavedCover(_ book: Book) {
        guard let image = book.coverImageData, !image.isEmpty,
              !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !book.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let destination = documents.appendingPathComponent("Loomey-Pending-Covers.json")
        do {
            var covers: [Cover] = []
            if let data = try? Data(contentsOf: destination) {
                covers = (try? JSONDecoder().decode([Cover].self, from: data)) ?? []
            }
            let item = Cover(title: book.title, author: book.author, isbn: book.isbn,
                             imageBase64: image.base64EncodedString())
            // Replace a previous queued cover for this same book; never alter the book itself.
            covers.removeAll { $0.title == item.title && $0.author == item.author && $0.isbn == item.isbn }
            covers.append(item)
            try JSONEncoder().encode(covers).write(to: destination, options: .atomic)
        } catch {
            print("Could not queue Loomey cover for library sync: \(error)")
        }
    }

    static func saveIfNeeded(context: ModelContext) {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destination = documents.appendingPathComponent("Loomey-Existing-Covers.json")
        // A successful snapshot is kept; don't replace it with a partial CloudKit sync.
        guard !fileManager.fileExists(atPath: destination.path) else { return }
        do {
            let books = try context.fetch(FetchDescriptor<Book>())
            let covers: [Cover] = books.compactMap { book in
                guard let data = book.coverImageData, !data.isEmpty,
                      !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !book.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return Cover(title: book.title, author: book.author, isbn: book.isbn,
                             imageBase64: data.base64EncodedString())
            }
            guard !covers.isEmpty else { return }
            let data = try JSONEncoder().encode(covers)
            try data.write(to: destination, options: .atomic)
            print("📚 Saved migration snapshot for \(covers.count) existing Loomey covers.")
        } catch {
            print("Could not prepare Loomey cover migration snapshot: \(error)")
        }
    }
}
