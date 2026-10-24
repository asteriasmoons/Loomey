import Combine
import SwiftData
import SwiftUI

struct AutomaticCatalogPreparation: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Book.lastUpdated, order: .reverse) private var books: [Book]
    @Query(sort: \ReadingSession.date, order: .reverse) private var sessions: [ReadingSession]
    @Query private var userSettings: [UserSettings]

    private var preferences: ReadingPreferencesConfiguration? {
        ReadingPreferencesStore.configuration(in: userSettings)
    }

    private var signals: [AutomaticCatalogLibraryBook] {
        let recent = sessions.filter { $0.date > Date().addingTimeInterval(-90 * 86400) }
        let activity = Dictionary(grouping: recent, by: \.linkedBookID)
        return books.filter { $0.deletedAt == nil }.map { book in
            AutomaticCatalogLibraryBook(id: book.id.uuidString, title: book.title, author: book.author, isbn: book.isbn,
                genres: book.genres, subjects: Array(Set(book.topics + book.tags + book.tropes)).sorted(), rating: book.rating, favorite: book.isFavorite,
                status: book.isArchived ? "Archived" : (book.isDNF ? BookStatus.didNotFinish.rawValue : book.statusRawValue),
                activity: (activity[book.id] ?? []).reduce(0) { $0 + $1.pagesRead + $1.durationMinutes },
                seriesName: book.seriesName.isEmpty ? nil : book.seriesName, seriesNumber: book.seriesNumber.isEmpty ? nil : book.seriesNumber,
                subtitle: book.subtitle.isEmpty ? nil : book.subtitle)
        }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: AutomaticBookCatalogService.fingerprint(signals, preferences: preferences), initial: true) {
                if scenePhase == .active { AutomaticBookCatalogService.shared.prepare(books: signals, preferences: preferences) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { AutomaticBookCatalogService.shared.prepare(books: signals, preferences: preferences) }
                else if phase == .background { AutomaticBookCatalogService.shared.suspendPreparation() }
            }
    }
}
