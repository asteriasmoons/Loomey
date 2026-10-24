import Foundation
import SwiftData

@main
private struct ReadingPreferencesContracts {
    @MainActor
    static func main() throws {
        var checks = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message); checks += 1 }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("loomey-preferences-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("preferences.store")
        func withContext<T>(_ action: (ModelContext) throws -> T) throws -> T {
            try autoreleasepool {
                let schema = Schema([UserSettings.self])
                let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                context.autosaveEnabled = false
                return try action(context)
            }
        }
        check(ReadingPreferencesStore.configuration(in: []) == nil, "unconfigured readers keep history-only recommendations")
        check(!ReadingPreferencesConfiguration.default.hasDiscoveryInputs, "defaults do not invent interests")
        var preferences = ReadingPreferencesConfiguration(preferredCategory: .fiction, favoriteFictionGenres: ["Fantasy", " Fantasy ", "fantasy", "Romance"], favoriteNonfictionGenres: ["History"], currentlyInterestedIn: ["Found family", " Found   family ", "\n"], recommendationStyle: .followPreferences)
        preferences = preferences.normalized()
        check(preferences.favoriteFictionGenres == ["Fantasy", "Romance"], "favorite genres normalize whitespace and case duplicates")
        check(preferences.currentlyInterestedIn == ["Found family"], "current interests normalize independently")
        check(preferences.activeFavoriteGenres == ["Fantasy", "Romance"], "nonfiction favorites stay stored without influencing a fiction-only request")
        check(preferences.hasDiscoveryInputs, "preferences can start discovery before the first Finished book")
        for name in ["Fantasy", "Romance", "Mystery", "Thriller", "Horror", "Science Fiction", "Historical Fiction", "Contemporary Fiction", "Paranormal Romance"] {
            check(ReadingGenresData.fictionPreferenceGenres.contains(name), "required fiction genre: \(name)")
        }
        for name in ["History", "Biography", "Psychology", "Science", "Spirituality", "Witchcraft"] {
            check(ReadingGenresData.nonfictionPreferenceGenres.contains(name), "required nonfiction genre: \(name)")
        }
        for name in ["Fantasy", "Paranormal Romance", "Found Family", "Slow Burn", "Political Intrigue", "Witchcraft"] {
            check(ReadingInterestsData.all.contains(name), "structured interest choice: \(name)")
        }
        check(Set(ReadingInterestsData.all).count == ReadingInterestsData.all.count, "interest catalog has no duplicate options")
        check(preferences.allows(genres: ["Fantasy"], subjects: []), "fiction selection admits classified fiction")
        check(!preferences.allows(genres: ["Nonfiction", "Science"], subjects: []), "fiction selection rejects nonfiction")
        var nonfiction = preferences
        nonfiction.preferredCategory = .nonfiction
        nonfiction.recommendationStyle = .blendInterests
        check(!nonfiction.allows(genres: ["Science Fiction"], subjects: []), "Science Fiction is not Science nonfiction")
        check(nonfiction.allows(genres: ["Science"], subjects: []), "Science nonfiction is recognized")
        var witchcraft = nonfiction
        witchcraft.favoriteNonfictionGenres = ["Witchcraft"]
        witchcraft.recommendationStyle = .followPreferences
        check(witchcraft.allows(genres: ["Witchcraft"], subjects: []), "Witchcraft matches the nonfiction preference and category")
        check(!witchcraft.allows(genres: ["Fiction"], subjects: ["Witchcraft"]), "a novel about Witchcraft is not reclassified as nonfiction")
        check(!nonfiction.allows(genres: ["Fiction"], subjects: ["History", "Science"]), "a novel with historical subjects cannot appear in nonfiction")
        check(nonfiction.allows(genres: ["Nonfiction"], subjects: ["Fantasy", "Science"]), "explicit nonfiction classification wins over a fictional subject")
        check(nonfiction.activeFavoriteGenres == ["History"], "switching category restores the independent nonfiction favorites")
        var both = preferences
        both.preferredCategory = .both
        both.recommendationStyle = .blendInterests
        check(both.allows(genres: [], subjects: []), "Both does not require inferred classifications")
        for style in ReadingRecommendationStyle.allCases {
            var value = preferences
            value.recommendationStyle = style
            let restored = try JSONDecoder().decode(ReadingPreferencesConfiguration.self, from: JSONEncoder().encode(value))
            check(restored == value, "every style survives the wire/storage round trip")
        }
        try withContext { context in
            let settings = UserSettings(readingDefaultStatusFilter: "Reading", hasSeenWelcome: true)
            settings.notesDefaultTab = "Existing Tab"
            context.insert(settings)
            try context.save()
            check(ReadingPreferencesStore.configuration(in: [settings]) == nil, "existing settings start unconfigured")
            try ReadingPreferencesStore.save(preferences, in: context)
            let records = try context.fetch(FetchDescriptor<UserSettings>())
            check(records.count == 1, "save reuses the existing account settings record")
            check(ReadingPreferencesStore.configuration(in: records) == preferences, "preferences save into the existing model")
            check(settings.readingDefaultStatusFilter == "Reading" && settings.hasSeenWelcome && settings.notesDefaultTab == "Existing Tab", "unrelated user settings remain intact")
            let timestamp = settings.readingPreferencesUpdatedAt
            try ReadingPreferencesStore.save(preferences, in: context)
            check(settings.readingPreferencesUpdatedAt == timestamp, "identical saves do not trigger repeated refreshes or sync writes")
        }
        try withContext { context in
            let records = try context.fetch(FetchDescriptor<UserSettings>())
            check(ReadingPreferencesStore.configuration(in: records) == preferences, "preferences survive closing and reopening the persistent store")
            let duplicate = UserSettings()
            duplicate.readingPreferencesJSON = String(data: try JSONEncoder().encode(nonfiction), encoding: .utf8)!
            duplicate.readingPreferencesUpdatedAt = .distantPast
            duplicate.updatedAt = .distantFuture
            context.insert(duplicate)
            try context.save()
            let merged = try context.fetch(FetchDescriptor<UserSettings>())
            check(ReadingPreferencesStore.configuration(in: merged) == preferences, "an unrelated settings update cannot replace the newer preference record")
            try ReadingPreferencesStore.save(nil, in: context)
        }
        try withContext { context in
            let records = try context.fetch(FetchDescriptor<UserSettings>())
            check(ReadingPreferencesStore.configuration(in: records) == nil, "reset persists and wins over an older configured sync duplicate")
            check(records.count == 2, "reset never deletes synced user records")
            check(records.contains { $0.readingDefaultStatusFilter == "Reading" && $0.notesDefaultTab == "Existing Tab" }, "reset preserves existing saved settings")
        }
        var oversized = preferences
        oversized.favoriteFictionGenres = ReadingGenresData.fictionPreferenceGenres
        oversized.favoriteNonfictionGenres = (0..<100).map { "Nonfiction Genre \($0)" } + ["Witchcraft"]
        oversized.currentlyInterestedIn = ReadingInterestsData.all + ["An Older Custom Interest"]
        let normalized = oversized.normalized()
        check(normalized.favoriteFictionGenres.count > 64 && normalized.favoriteFictionGenres.count == oversized.favoriteFictionGenres.count, "all fiction genres survive normalization without a selection cap")
        check(normalized.favoriteNonfictionGenres.count == 101, "nonfiction selections are not capped at 64")
        check(normalized.currentlyInterestedIn.count > 20 && normalized.currentlyInterestedIn.count == oversized.currentlyInterestedIn.count, "all structured and legacy interests survive normalization")
        let decoded = try JSONDecoder().decode(ReadingPreferencesConfiguration.self, from: JSONEncoder().encode(normalized))
        check(decoded == normalized, "uncapped selections survive the existing API JSON format")
        try withContext { context in
            try ReadingPreferencesStore.save(normalized, in: context)
        }
        try withContext { context in
            let records = try context.fetch(FetchDescriptor<UserSettings>())
            let restored = ReadingPreferencesStore.configuration(in: records)
            check(restored == normalized, "all selections survive saving and reopening the persistent store")
            check(restored?.currentlyInterestedIn.contains("An Older Custom Interest") == true, "a saved interest outside the structured catalog is preserved")
            check(restored?.favoriteNonfictionGenres.contains("Witchcraft") == true, "Witchcraft survives account-settings persistence")
            check(records.contains { $0.readingDefaultStatusFilter == "Reading" && $0.notesDefaultTab == "Existing Tab" }, "uncapped preferences preserve unrelated account settings")
        }
        print("Reading preferences contracts: \(checks) checks passed; isolated SwiftData store only, no CloudKit or application launch")
    }
}
