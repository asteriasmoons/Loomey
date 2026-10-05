//
//  ReadingAchievementDefinition.swift
//  Lumey
//

import Foundation

struct ReadingAchievementDefinition {
    let title: String
    let description: String
    let type: AchievementType
    let targetValue: Int
    let iconName: String
    let sortOrder: Int

    static let shipped: [ReadingAchievementDefinition] = [

        // MARK: - Books Finished

        .init(
            title: "First Book Finished",
            description: "Finish your first book in Loomey.",
            type: .booksFinished,
            targetValue: 1,
            iconName: "startrophy",
            sortOrder: 0
        ),

        .init(
            title: "Book Collector",
            description: "Finish 10 books.",
            type: .booksFinished,
            targetValue: 10,
            iconName: "books",
            sortOrder: 1
        ),

        .init(
            title: "Dedicated Reader",
            description: "Finish 25 books.",
            type: .booksFinished,
            targetValue: 25,
            iconName: "books",
            sortOrder: 2
        ),

        .init(
            title: "Master Reader",
            description: "Finish 50 books.",
            type: .booksFinished,
            targetValue: 50,
            iconName: "bookstack",
            sortOrder: 3
        ),

        .init(
            title: "Library Legend",
            description: "Finish 100 books.",
            type: .booksFinished,
            targetValue: 100,
            iconName: "bookstack",
            sortOrder: 4
        ),

        // MARK: - Pages Read

        .init(
            title: "100 Pages Read",
            description: "Read 100 pages.",
            type: .pagesRead,
            targetValue: 100,
            iconName: "openbook",
            sortOrder: 100
        ),

        .init(
            title: "1,000 Pages Read",
            description: "Read 1,000 pages.",
            type: .pagesRead,
            targetValue: 1_000,
            iconName: "books",
            sortOrder: 101
        ),

        .init(
            title: "5,000 Pages Read",
            description: "Read 5,000 pages.",
            type: .pagesRead,
            targetValue: 5_000,
            iconName: "books",
            sortOrder: 102
        ),

        .init(
            title: "10,000 Pages Read",
            description: "Read 10,000 pages.",
            type: .pagesRead,
            targetValue: 10_000,
            iconName: "bookstack",
            sortOrder: 103
        ),

        // MARK: - Reviews

        .init(
            title: "First Review Written",
            description: "Write your first review.",
            type: .reviewsWritten,
            targetValue: 1,
            iconName: "starnote",
            sortOrder: 200
        ),

        .init(
            title: "Book Critic",
            description: "Write 10 reviews.",
            type: .reviewsWritten,
            targetValue: 10,
            iconName: "starnote",
            sortOrder: 201
        ),

        .init(
            title: "Literary Reviewer",
            description: "Write 25 reviews.",
            type: .reviewsWritten,
            targetValue: 25,
            iconName: "starnote",
            sortOrder: 202
        ),

        // MARK: - Notes

        .init(
            title: "First Note",
            description: "Save your first note.",
            type: .notesWritten,
            targetValue: 1,
            iconName: "linedpages",
            sortOrder: 300
        ),

        .init(
            title: "Thought Collector",
            description: "Write 50 notes.",
            type: .notesWritten,
            targetValue: 50,
            iconName: "cloudmind",
            sortOrder: 301
        ),

        // MARK: - Quotes

        .init(
            title: "First Quote",
            description: "Save your first quote.",
            type: .quotesSaved,
            targetValue: 1,
            iconName: "quote",
            sortOrder: 400
        ),

        .init(
            title: "Quote Keeper",
            description: "Save 25 quotes.",
            type: .quotesSaved,
            targetValue: 25,
            iconName: "folderfill",
            sortOrder: 401
        ),

        .init(
            title: "Quote Archive",
            description: "Save 100 quotes.",
            type: .quotesSaved,
            targetValue: 100,
            iconName: "archivefill",
            sortOrder: 402
        ),

        // MARK: - Reading Streaks

        .init(
            title: "3 Day Streak",
            description: "Read 3 days in a row.",
            type: .readingStreak,
            targetValue: 3,
            iconName: "flame",
            sortOrder: 500
        ),

        .init(
            title: "7 Day Streak",
            description: "Read 7 days in a row.",
            type: .readingStreak,
            targetValue: 7,
            iconName: "flame",
            sortOrder: 501
        ),

        .init(
            title: "30 Day Streak",
            description: "Read 30 days in a row.",
            type: .readingStreak,
            targetValue: 30,
            iconName: "flame",
            sortOrder: 502
        ),

        .init(
            title: "100 Day Streak",
            description: "Read 100 days in a row.",
            type: .readingStreak,
            targetValue: 100,
            iconName: "flame",
            sortOrder: 503
        ),

        // MARK: - Series

        .init(
            title: "Series Finisher",
            description: "Finish your first series.",
            type: .seriesFinished,
            targetValue: 1,
            iconName: "sparkbolt",
            sortOrder: 600
        ),

        .init(
            title: "Series Collector",
            description: "Finish 5 series.",
            type: .seriesFinished,
            targetValue: 5,
            iconName: "sparkbolt",
            sortOrder: 601
        ),

        .init(
            title: "Series Master",
            description: "Finish 10 series.",
            type: .seriesFinished,
            targetValue: 10,
            iconName: "sparkbolt",
            sortOrder: 602
        )
    ]
}
