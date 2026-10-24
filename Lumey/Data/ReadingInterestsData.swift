import Foundation

enum ReadingInterestsData {
    static let genres = ReadingGenresData.fictionPreferenceGenres + ReadingGenresData.nonfictionPreferenceGenres

    static let themes = [
        "Ambition", "Belonging", "Betrayal", "Coming of Age", "Courage",
        "Family", "Forgiveness", "Freedom", "Friendship", "Grief", "Healing",
        "Hope", "Identity", "Justice", "Love", "Loyalty", "Memory",
        "Mental Health", "Morality", "Personal Growth", "Power", "Redemption",
        "Resilience", "Revenge", "Self-Discovery", "Survival", "Transformation"
    ]

    static let tropes = [
        "Academic Rivals", "Arranged Marriage", "Childhood Friends",
        "Enemies to Lovers", "Fake Dating", "Forbidden Love", "Forced Proximity",
        "Found Family", "Friends to Lovers", "Grumpy and Sunshine",
        "He Falls First", "Hidden Identity", "Love Triangle", "Marriage of Convenience",
        "Morally Gray Characters", "Only One Bed", "Opposites Attract",
        "Reluctant Allies", "Rivals to Lovers", "Second Chance Romance",
        "Secret Relationship", "Slow Burn", "Soulmates", "Star-Crossed Lovers",
        "Touch Her and Die", "Unlikely Friendship", "Villain Redemption",
        "Who Did This to You", "Workplace Romance"
    ]

    static let subjects = [
        "Ancient Civilizations", "Ancient Egypt", "Animal Behavior", "Anthropology",
        "Archaeology", "Architecture", "Art History", "Artificial Intelligence",
        "Astronomy", "Astrology", "Biology", "Climate Change", "Conservation",
        "Creativity", "Criminal Investigation", "Cultures and Traditions",
        "Dark Academia", "Dragons", "Dreams", "Ecology", "Economics",
        "Education", "Emotional Intelligence", "Entrepreneurship", "Ethics",
        "Evolution", "Fae", "Feminism", "Folklore", "Food and Cooking",
        "Ghosts", "Habit Building", "Herbalism", "Historical Figures",
        "Human Behavior", "Indigenous History", "Leadership", "Linguistics",
        "Magic", "Meditation", "Mindfulness", "Mythology", "Nature",
        "Neuroscience", "Nutrition", "Ocean Life", "Parenting", "Philosophy",
        "Political Intrigue", "Politics", "Psychology", "Relationships",
        "Religion", "Rituals", "Science", "Secret Societies", "Social Justice",
        "Space Exploration", "Spirituality", "Technology", "Time Travel",
        "Trauma Recovery", "Travel", "True Crime", "Vampires", "Wellness",
        "Werewolves", "Witchcraft", "Witches", "Women's History", "Writing"
    ]

    static let all = Array(Set(genres + themes + tropes + subjects)).sorted()
}
