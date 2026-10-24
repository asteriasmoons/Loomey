import Foundation

enum PreferredReadingCategory: String, Codable, CaseIterable, Identifiable {
    case fiction, nonfiction, both

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fiction: return "Fiction"
        case .nonfiction: return "Nonfiction"
        case .both: return "Both"
        }
    }
}

enum ReadingRecommendationStyle: String, Codable, CaseIterable, Identifiable {
    case followPreferences = "follow_preferences"
    case blendInterests = "blend_interests"
    case surpriseMe = "surprise_me"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .followPreferences: return "Follow My Preferences"
        case .blendInterests: return "Blend My Interests"
        case .surpriseMe: return "Surprise Me"
        }
    }
}

struct ReadingPreferencesConfiguration: Codable, Equatable {
    var version = 1
    var preferredCategory: PreferredReadingCategory = .both
    var favoriteFictionGenres: [String] = []
    var favoriteNonfictionGenres: [String] = []
    var currentlyInterestedIn: [String] = []
    var recommendationStyle: ReadingRecommendationStyle = .blendInterests

    static let `default` = Self()

    var activeFavoriteGenres: [String] {
        switch preferredCategory {
        case .fiction: return favoriteFictionGenres
        case .nonfiction: return favoriteNonfictionGenres
        case .both: return favoriteFictionGenres + favoriteNonfictionGenres
        }
    }

    var hasDiscoveryInputs: Bool {
        preferredCategory != .both || !activeFavoriteGenres.isEmpty || !currentlyInterestedIn.isEmpty
    }

    func allows(genres: [String], subjects: [String]) -> Bool {
        func key(_ value: String) -> String {
            value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"\b(?:sci fi|scifi)\b"#, with: "science fiction", options: .regularExpression)
        }
        let labels = (genres + subjects).map(key)
        let fiction = ["fiction", "fantasy", "romance", "mystery", "thriller", "horror", "science fiction", "novel", "novels", "young adult", "dark academia", "adventure", "paranormal", "mythology", "folklore", "manga", "graphic novel", "graphic", "comic", "dystopian", "magical realism", "litrpg"]
        let nonfiction = ["nonfiction", "non fiction", "history", "biography", "autobiography", "memoir", "psychology", "science", "spirituality", "self help", "personal development", "productivity", "philosophy", "politics", "technology", "wellness", "writing craft", "art design", "art and design", "mindfulness", "trauma recovery", "habit building"]
        func matches(_ term: String, in values: [String]) -> Bool {
            values.contains { label in
                if term == "science", label.contains("science fiction") { return false }
                if term == "fiction", label.contains("nonfiction") || label.contains("non fiction") { return false }
                return (" " + label + " ").contains(" " + term + " ")
            }
        }
        func classify(_ values: [String]) -> (fiction: Bool, nonfiction: Bool) {
            let explicitFiction = matches("fiction", in: values)
            let explicitNonfiction = matches("nonfiction", in: values) || matches("non fiction", in: values)
            if explicitFiction != explicitNonfiction { return (explicitFiction, explicitNonfiction) }
            return (fiction.contains { matches($0, in: values) }, nonfiction.contains { matches($0, in: values) })
        }
        let primary = classify(genres.map(key))
        let classification = primary.fiction || primary.nonfiction ? primary : classify(labels)
        guard preferredCategory == .both || (preferredCategory == .fiction ? classification.fiction : classification.nonfiction) else { return false }
        let interests = activeFavoriteGenres + currentlyInterestedIn
        return recommendationStyle != .followPreferences || interests.isEmpty || interests.map(key).contains { matches($0, in: labels) }
    }

    func normalized() -> Self {
        var value = self
        value.version = 1
        value.favoriteFictionGenres = Self.clean(favoriteFictionGenres, limit: 64)
        value.favoriteNonfictionGenres = Self.clean(favoriteNonfictionGenres, limit: 64)
        value.currentlyInterestedIn = Self.clean(currentlyInterestedIn, limit: 20)
        return value
    }

    private static func clean(_ values: [String], limit: Int) -> [String] {
        var selected: [String: String] = [:]
        for value in values {
            let text = String(value.replacingOccurrences(of: #"[\p{C}\s]+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines).prefix(96))
            guard !text.isEmpty else { continue }
            let key = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            if selected[key] == nil { selected[key] = text }
        }
        return selected.keys.sorted().prefix(limit).compactMap { selected[$0] }
    }
}
