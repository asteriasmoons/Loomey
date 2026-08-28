//
//  ReleaseNotesCatalog.swift
//  Lumey
//

import Foundation

struct LumeyReleaseNote: Identifiable, Hashable {
    let id: String
    let versionTitle: String
    let releaseDate: String
    let headline: String
    let bullets: [String]
}

enum ReleaseNotesCatalog {
    static let notes: [LumeyReleaseNote] = [
        LumeyReleaseNote(
            id: "v1_10",
            versionTitle: "Version 1.10",
            releaseDate: "August 2026",
            headline: "Welcome to the next feature in Loomey. Release notes! Here is everything in the 1.10 update.",
            bullets: [
                "Loomey themes have been added. There is a new default theme plus four others",
                "Fairy Theme is for all Fae loving bookies",
                "Electric Dark is just a nice little theme for those with more accentric tastes",
                "Dark Academia is for readers who are fans of Dark Academia genre books",
                "Ember Night is for those who want a more comfy and cozy experience in the reading app"
            ]
        ),
        LumeyReleaseNote(
            id: "v1_9",
            versionTitle: "Version 1.9",
            releaseDate: "August 2026",
            headline: "Reading life became more layered with missions, Bingos, and richer session reflection.",
            bullets: [
                "Reading Missions now live inside the Books experience with generation, progress, scoring, and history.",
                "Reading Bingos introduced curated themed boards with real 5x5 Bingo tracking and blackout completion.",
                "Session Insights added deeper post-reading reflection tied directly to books and logged sessions.",
                "Stats and profile areas were expanded so reading progress feels more alive across the app."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_8",
            versionTitle: "Version 1.8",
            releaseDate: "July 2026",
            headline: "Challenges became more social, more visual, and easier to revisit.",
            bullets: [
                "Challenge bookmarking was added so favorite challenges are easier to find again.",
                "Profile challenge areas were expanded with clearer completion tracking and dedicated follow-up pages.",
                "Featured challenge rotation and filtering were refined so challenge browsing feels more intentional.",
                "Challenge proof and validation flows were tightened across submissions and review states.",
                "Challenge pages picked up cleaner organization across feeds, detail views, and progress surfaces."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_7",
            versionTitle: "Version 1.7",
            releaseDate: "June 2026",
            headline: "Reading progression became more rewarding with XP, levels, and title unlocks.",
            bullets: [
                "Reading XP and leveling were added as a progression system outside the existing points economy.",
                "Level titles now unlock as readers move through their long-term progress.",
                "XP hooks were connected to qualifying reading activity without backfilling old history.",
                "Progress displays were refined so growth feels visible across stats and profile surfaces."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_6",
            versionTitle: "Version 1.6",
            releaseDate: "May 2026",
            headline: "Reading streaks became more flexible and more personal.",
            bullets: [
                "Daily, weekend, weekly, and monthly reading streaks were introduced as independent tracking systems.",
                "Weekend, weekly, and monthly streak preferences became configurable from Settings.",
                "Streak calculations now rely on real reading history instead of timer-based scheduling.",
                "Reading stats gained a fuller streak picture without redesigning the existing stats experience."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_5",
            versionTitle: "Version 1.5",
            releaseDate: "April 2026",
            headline: "The library grew smarter with richer book details and stronger metadata support.",
            bullets: [
                "Book detail enrichment now helps fill in metadata more accurately from external sources and AI.",
                "Library records picked up better handling for summaries, genres, tags, moods, topics, and tropes.",
                "Add and edit flows were refined so book identity and details feel more structured.",
                "Library organization stayed familiar while the underlying data became much richer."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_4",
            versionTitle: "Version 1.4",
            releaseDate: "March 2026",
            headline: "Goals and reading sessions became more connected throughout the app.",
            bullets: [
                "Reading sessions can now tie more naturally into the goals they support.",
                "Goal detail and history areas were refined to make progress easier to follow.",
                "Logging flows became more cohesive across sessions, pages, and reading time.",
                "Reading momentum and goal tracking picked up clearer daily context."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_3",
            versionTitle: "Version 1.3",
            releaseDate: "February 2026",
            headline: "Reader and library flows were polished for a smoother everyday reading rhythm.",
            bullets: [
                "Book notes, quotes, reviews, and detail pages were refined into a more cohesive reading space.",
                "Reading lists became easier to manage and revisit.",
                "Reader-adjacent pages were polished to feel calmer and more consistent.",
                "Small interaction updates helped the app feel more fluid while keeping the same structure."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_2",
            versionTitle: "Version 1.2",
            releaseDate: "January 2026",
            headline: "Stats and profile started feeling more like a living record of your reading life.",
            bullets: [
                "Profile and stats sections gained stronger structure around reading habits and activity.",
                "Favorite trends, writing activity, and reading momentum became easier to scan.",
                "Shared cards and stat layouts were polished for cleaner hierarchy across dark themes.",
                "More of the app began speaking the same visual language across sections."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_1",
            versionTitle: "Version 1.1",
            releaseDate: "December 2025",
            headline: "Loomey’s reading core became steadier, tidier, and easier to use every day.",
            bullets: [
                "General reading, goal, and library flows were smoothed out across the app.",
                "The interface became more consistent across cards, text, and navigation patterns.",
                "Key reading actions were clarified so common workflows take less effort.",
                "Early rough edges were cleaned up throughout the core experience."
            ]
        ),
        LumeyReleaseNote(
            id: "v1_0",
            versionTitle: "Version 1.0",
            releaseDate: "November 2025",
            headline: "Welcome to Loomey: a cozy reading space for tracking books, goals, and your reading life.",
            bullets: [
                "Build your personal library and keep your reading life organized in one place.",
                "Track sessions, pages, and time so progress feels visible and motivating.",
                "Set reading goals and start building momentum through everyday reading.",
                "Capture notes, quotes, and reviews as you move through each book."
            ]
        )
    ]
}
