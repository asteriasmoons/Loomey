//
//  ChallengeSeedData.swift
//  Lumey
//

import Foundation

// MARK: - Challenge Seed Data

enum ChallengeSeedData {

    /// Returns all seeded Lumey challenge definitions.
    static func allChallenges() -> [ReadingChallenge] {
        var all: [ReadingChallenge] = []
        all.append(contentsOf: readingHabitChallenges)
        all.append(contentsOf: oneDaySpotlightChallenges)
        all.append(contentsOf: pagesChallenges)
        all.append(contentsOf: bookCompletionChallenges)
        all.append(contentsOf: genreChallenges)
        all.append(contentsOf: reviewChallenges)
        all.append(contentsOf: ratingChallenges)
        all.append(contentsOf: seriesChallenges)
        all.append(contentsOf: authorChallenges)
        all.append(contentsOf: seasonalChallenges)
        all.append(contentsOf: bookLengthChallenges)
        all.append(contentsOf: collectionChallenges)
        all.append(contentsOf: photoProofChallenges)
        all.append(contentsOf: funChallenges)
        return all
    }

    // MARK: - Reading Habit Challenges

    static let readingHabitChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "First Chapter",
            challengeDescription: "Every book begins with a single chapter. Open a new book and read the first chapter to officially begin a new reading adventure.",
            iconName: "openbook",
            category: .readingHabit,
            points: 25,
            durationDays: 1,
            requirementText: "Read the first chapter of a new book.",
            validationType: .readingSession,
            requiredSessionCount: 1
        ),
        ReadingChallenge(
            title: "Daily Reader",
            challengeDescription: "Set aside time for reading today and complete at least one reading session. A simple challenge designed to keep books part of your day.",
            iconName: "openbook",
            category: .readingHabit,
            points: 30,
            durationDays: 1,
            requirementText: "Complete at least one reading session today.",
            validationType: .readingSession,
            requiredSessionCount: 1
        ),
        ReadingChallenge(
            title: "Weekend Reader",
            challengeDescription: "Spend part of your weekend getting lost in a book. Read on both Saturday and Sunday to complete the challenge.",
            iconName: "openbook",
            category: .readingHabit,
            points: 75,
            durationDays: 2,
            requirementText: "Complete reading sessions on both Saturday and Sunday.",
            validationType: .readingSession,
            requiredSessionCount: 2,
            requiredDaysStreak: 2,
            isWeekly: true
        ),
        ReadingChallenge(
            title: "Consistent Reader",
            challengeDescription: "Reading isn't about speed—it's about showing up. Complete at least one reading session each day and build a steady reading rhythm.",
            iconName: "openbook",
            category: .readingHabit,
            points: 150,
            durationDays: 7,
            requirementText: "Read every day for 7 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 7,
            requiredDaysStreak: 7
        ),
        ReadingChallenge(
            title: "Early Bird Reader",
            challengeDescription: "Start your day with a story. Complete a reading session during the morning hours before the day fully gets underway.",
            iconName: "sun",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete a morning reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Night Owl Reader",
            challengeDescription: "Wind down with a good book before bed. Complete a reading session during the evening and end your day with a chapter or two.",
            iconName: "moonzs",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete an evening reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Lunch Break Reader",
            challengeDescription: "Turn a lunch break into reading time. Complete a reading session during the middle of your day instead of scrolling.",
            iconName: "openbook",
            category: .readingHabit,
            points: 40,
            durationDays: 1,
            requirementText: "Complete a midday reading session.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Read 3 Days",
            challengeDescription: "Read on three separate days without breaking your streak. A great starting point for building consistency.",
            iconName: "openbook",
            category: .readingHabit,
            points: 75,
            durationDays: 3,
            requirementText: "Read on 3 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 3,
            requiredDaysStreak: 3
        ),
        ReadingChallenge(
            title: "Read 7 Days",
            challengeDescription: "Spend an entire week showing up for your reading habit. Read every day for seven consecutive days.",
            iconName: "openbook",
            category: .readingHabit,
            points: 175,
            durationDays: 7,
            requirementText: "Read every day for 7 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 7,
            requiredDaysStreak: 7
        ),
        ReadingChallenge(
            title: "Read 14 Days",
            challengeDescription: "Two weeks of consistent reading can transform a habit. Read every day and keep the momentum alive.",
            iconName: "openbook",
            category: .readingHabit,
            points: 350,
            durationDays: 14,
            requirementText: "Read every day for 14 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 14,
            requiredDaysStreak: 14
        ),
        ReadingChallenge(
            title: "Read 30 Days",
            challengeDescription: "Commit to a full month of reading. Complete a reading session every day for thirty consecutive days.",
            iconName: "openbook",
            category: .readingHabit,
            points: 800,
            durationDays: 30,
            requirementText: "Read every day for 30 consecutive days.",
            validationType: .readingSession,
            requiredSessionCount: 30,
            requiredDaysStreak: 30
        ),
        ReadingChallenge(
            title: "Read Every Day",
            challengeDescription: "Challenge yourself to make reading a non-negotiable part of your routine. Read daily and prove that consistency beats motivation.",
            iconName: "flame",
            category: .readingHabit,
            points: 500,
            durationDays: 21,
            requirementText: "Read every day for 21 days.",
            validationType: .readingSession,
            requiredSessionCount: 21,
            requiredDaysStreak: 21
        ),
        ReadingChallenge(
            title: "Build Momentum",
            challengeDescription: "Sometimes the hardest part is getting started. Complete reading sessions throughout the week and rebuild your reading flow one day at a time.",
            iconName: "sparkbolt",
            category: .readingHabit,
            points: 125,
            durationDays: 5,
            requirementText: "Complete reading sessions on 5 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 5
        ),
        ReadingChallenge(
            title: "Reading Routine",
            challengeDescription: "Create a reading schedule and stick to it. Complete a reading session during your chosen reading window each day.",
            iconName: "clockfill",
            category: .readingHabit,
            points: 250,
            durationDays: 10,
            requirementText: "Complete reading sessions on 10 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 10,
            requiredDaysStreak: 10
        ),
        ReadingChallenge(
            title: "Reading Comeback",
            challengeDescription: "Been away from books for a while? This challenge is all about returning to a habit you once enjoyed and rediscovering the joy of reading.",
            iconName: "openbook",
            category: .readingHabit,
            points: 100,
            durationDays: 5,
            requirementText: "Complete reading sessions on 5 separate days.",
            validationType: .readingSession,
            requiredSessionCount: 5
        ),
    ]

    // MARK: - One Day Spotlight Challenges

    static let oneDaySpotlightChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Velvet Bookmark Hour",
            challengeDescription: "Give one book a full, uninterrupted hour of attention. No sampling, no drifting between titles - just one clean block of story momentum.",
            iconName: "clockfill",
            category: .readingHabit,
            points: 110,
            durationDays: 1,
            requirementText: "Complete one reading session lasting at least 60 minutes.",
            validationType: .readingSession,
            requiredSessionCount: 1,
            requiredSessionMinutes: 60,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Deep Focus Doorway",
            challengeDescription: "Step fully into a book and stay there long enough for the world to take over. This is a focused, sit-down-and-vanish kind of session.",
            iconName: "sparkbolt",
            category: .readingHabit,
            points: 135,
            durationDays: 1,
            requirementText: "Complete one reading session lasting at least 75 minutes.",
            validationType: .readingSession,
            requiredSessionCount: 1,
            requiredSessionMinutes: 75,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "One-Sitting Spell",
            challengeDescription: "Pick a book that can hold you still and let it work on you. A single ninety-minute session proves you really sank into the pages.",
            iconName: "wand",
            category: .readingHabit,
            points: 160,
            durationDays: 1,
            requirementText: "Complete one reading session lasting at least 90 minutes.",
            validationType: .readingSession,
            requiredSessionCount: 1,
            requiredSessionMinutes: 90,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Double Session Switch",
            challengeDescription: "Read once, leave the book alone, then come back for a second intentional pass. Two separate sessions in one day makes the habit feel lived-in.",
            iconName: "openbook",
            category: .readingHabit,
            points: 85,
            durationDays: 1,
            requirementText: "Complete 2 reading sessions in one day.",
            validationType: .readingSession,
            requiredSessionCount: 2,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Triple Bookmark Relay",
            challengeDescription: "Thread reading through your day in three distinct bursts. It is a challenge for readers who can keep returning to the story instead of letting the day swallow it.",
            iconName: "bookstack",
            category: .readingHabit,
            points: 135,
            durationDays: 1,
            requirementText: "Complete 3 reading sessions in one day.",
            validationType: .readingSession,
            requiredSessionCount: 3,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Chapter Heat Check",
            challengeDescription: "Give your current read enough pages to prove whether it has a pulse. Thirty-five pages is enough to move past setup and into actual momentum.",
            iconName: "linedpages",
            category: .pages,
            points: 45,
            durationDays: 1,
            requirementText: "Read 35 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 35,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Secret Passage Sprint",
            challengeDescription: "Push through a solid fifty-page stretch and see what hidden turn opens up next. This is short enough to chase, but real enough to matter.",
            iconName: "linedpages",
            category: .pages,
            points: 60,
            durationDays: 1,
            requirementText: "Read 50 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 50,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Plot Twist Pursuit",
            challengeDescription: "Read far enough that the book has to show you something. Sixty-five pages gives the story room to surprise you.",
            iconName: "linedpages",
            category: .pages,
            points: 85,
            durationDays: 1,
            requirementText: "Read 65 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 65,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Cliffhanger Chase",
            challengeDescription: "Follow the tension past the easy stopping points. Ninety pages in a day means the book had you moving.",
            iconName: "linedpages",
            category: .pages,
            points: 125,
            durationDays: 1,
            requirementText: "Read 90 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 90,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Hundred Page Holiday",
            challengeDescription: "Clear space for a real reading holiday, even if the rest of the day is normal. One hundred pages makes the book feel like the main event.",
            iconName: "linedpages",
            category: .pages,
            points: 145,
            durationDays: 1,
            requirementText: "Read 100 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 100,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Doorstop Dent",
            challengeDescription: "Take a visible bite out of a heavier read. One hundred twenty-five pages is not casual browsing - it leaves a mark.",
            iconName: "linedpages",
            category: .pages,
            points: 180,
            durationDays: 1,
            requirementText: "Read 125 pages in one day.",
            validationType: .pageCount,
            requiredPageCount: 125,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Last Page Ceremony",
            challengeDescription: "Finish the book and give the final page its moment. This is for the satisfying click of moving a story from active read to completed memory.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 180,
            durationDays: 1,
            requirementText: "Finish 1 book in one day.",
            validationType: .bookCompletion,
            requiredBookCount: 1,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Tiny Tome Takedown",
            challengeDescription: "Choose a compact book and make today the day it gets crossed off. Short does not mean disposable - it means sharp, fast, and complete.",
            iconName: "flatbook",
            category: .bookLength,
            points: 130,
            durationDays: 1,
            requirementText: "Finish a book under 180 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMaxPages: 180,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Slim Spine Sweep",
            challengeDescription: "Go after a quick but meaningful finish from the slimmer side of your shelf. The win is in choosing something finishable and actually finishing it.",
            iconName: "flatbook",
            category: .bookLength,
            points: 150,
            durationDays: 1,
            requirementText: "Finish a book under 250 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMaxPages: 250,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Big Book Bite",
            challengeDescription: "Finish a book with real heft and let the page count speak for itself. This one is for a serious close-out, not a quick tap-through.",
            iconName: "flatbook",
            category: .bookLength,
            points: 260,
            durationDays: 1,
            requirementText: "Finish a book with 400 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 400,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Series Signal Flare",
            challengeDescription: "Keep a larger story alive by finishing one installment from a series. It is a clean daily win that still feeds a bigger reading arc.",
            iconName: "books",
            category: .series,
            points: 190,
            durationDays: 1,
            requirementText: "Finish 1 book that belongs to a series.",
            validationType: .series,
            requiredBookCount: 1,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Fantasy Doorway",
            challengeDescription: "Finish a fantasy book and walk out with proof that you spent the day somewhere impossible. Magic, quests, courts, curses - bring back a completed title.",
            iconName: "sparklybook",
            category: .genre,
            points: 180,
            durationDays: 1,
            requirementText: "Finish 1 Fantasy book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Fantasy",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Romance Spark",
            challengeDescription: "Close out a love story today, whether it is sweet, aching, chaotic, or all of the above. The finished book and its genre are the proof.",
            iconName: "heartfill",
            category: .genre,
            points: 175,
            durationDays: 1,
            requirementText: "Finish 1 Romance book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Romance",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Mystery Receipts",
            challengeDescription: "Finish the case and bring the receipts. A mystery or thriller only counts when the last clue has been read and the book is marked finished.",
            iconName: "searchsparkle",
            category: .genre,
            points: 185,
            durationDays: 1,
            requirementText: "Finish 1 Mystery or Thriller book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Thriller & Mystery",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Horror Lights-On",
            challengeDescription: "Finish a horror book and make it back from the unsettling part of the shelf. The challenge is complete when the book is finished and the genre matches.",
            iconName: "moonzs",
            category: .genre,
            points: 185,
            durationDays: 1,
            requirementText: "Finish 1 Horror book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Horror",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Sci-Fi Signal",
            challengeDescription: "Close the loop on a science fiction read and send the signal home. Future tech, distant worlds, strange systems - finish one today.",
            iconName: "planet",
            category: .genre,
            points: 185,
            durationDays: 1,
            requirementText: "Finish 1 Science Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Science Fiction",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Nonfiction Spark",
            challengeDescription: "Finish something that leaves you knowing more than you did this morning. Memoir, science, history, craft, essays - bring back one completed nonfiction read.",
            iconName: "handbook",
            category: .genre,
            points: 190,
            durationDays: 1,
            requirementText: "Finish 1 Nonfiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Nonfiction",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "History Window",
            challengeDescription: "Spend the day peering into another era and finish the book that opened the window. Historical fiction and history reads both fit the spirit.",
            iconName: "timebook",
            category: .genre,
            points: 185,
            durationDays: 1,
            requirementText: "Finish 1 Historical Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Historical Fiction",
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "No-Spoiler Dispatch",
            challengeDescription: "Write a tight dispatch that captures the vibe without giving the game away. Enough detail to be useful, restrained enough to stay spoiler-clean.",
            iconName: "writenote",
            category: .review,
            points: 75,
            durationDays: 1,
            requirementText: "Write 1 review with at least 80 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 80,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Character Witness Statement",
            challengeDescription: "Put one character on the stand and explain what made them work, fail, shine, or haunt the book. The review needs enough room to say something real.",
            iconName: "pagepencil",
            category: .review,
            points: 110,
            durationDays: 1,
            requirementText: "Write 1 review with at least 120 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 120,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Theme Trace",
            challengeDescription: "Follow one idea through the book and write down what it changed. This is a review challenge for readers who like finding the thread beneath the plot.",
            iconName: "pagepencil",
            category: .review,
            points: 135,
            durationDays: 1,
            requirementText: "Write 1 review with at least 150 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 150,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Final Page Debrief",
            challengeDescription: "After the ending lands, write the kind of review future-you will actually understand. Capture what worked, what stayed with you, and whether it earned the time.",
            iconName: "writenote",
            category: .review,
            points: 175,
            durationDays: 1,
            requirementText: "Write 1 review with at least 200 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 200,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Five-Star Lightning",
            challengeDescription: "When a book hits hard, mark it before the glow fades. Finish your verdict by linking a book you rated five stars.",
            iconName: "starfill",
            category: .rating,
            points: 150,
            durationDays: 1,
            requirementText: "Rate 1 book 5 stars.",
            validationType: .rating,
            requiredBookCount: 1,
            requiredRating: 5,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Four-Star Seal",
            challengeDescription: "Not every favorite needs to be perfect. Give a strong read its official seal by rating one book four stars or higher.",
            iconName: "starfill",
            category: .rating,
            points: 95,
            durationDays: 1,
            requirementText: "Rate 1 book 4 stars or higher.",
            validationType: .rating,
            requiredBookCount: 1,
            requiredRating: 4,
            recurrence: .daily
        ),
        ReadingChallenge(
            title: "Fresh Verdict",
            challengeDescription: "Do not leave the book floating in rating limbo. Pick a finished read, make the call, and record the score while the reaction is still fresh.",
            iconName: "starfill",
            category: .rating,
            points: 65,
            durationDays: 1,
            requirementText: "Rate 1 book.",
            validationType: .rating,
            requiredBookCount: 1,
            recurrence: .daily
        ),
    ]

    // MARK: - Pages Challenges

    static let pagesChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Read 50 Pages",
            challengeDescription: "Small progress is still progress. Read a total of 50 pages and take another meaningful step toward finishing your current book.",
            iconName: "linedpages",
            category: .pages,
            points: 50,
            durationDays: 7,
            requirementText: "Read 50 pages total.",
            validationType: .pageCount,
            requiredPageCount: 50
        ),
        ReadingChallenge(
            title: "Read 100 Pages",
            challengeDescription: "Settle into your story and make real progress. Read 100 pages across one or more reading sessions.",
            iconName: "linedpages",
            category: .pages,
            points: 100,
            durationDays: 7,
            requirementText: "Read 100 pages total.",
            validationType: .pageCount,
            requiredPageCount: 100
        ),
        ReadingChallenge(
            title: "Read 250 Pages",
            challengeDescription: "Dedicate yourself to consistent reading and work your way through 250 pages. A challenge that rewards persistence over time.",
            iconName: "linedpages",
            category: .pages,
            points: 250,
            durationDays: 14,
            requirementText: "Read 250 pages total.",
            validationType: .pageCount,
            requiredPageCount: 250
        ),
        ReadingChallenge(
            title: "Read 500 Pages",
            challengeDescription: "Half a thousand pages is no small accomplishment. Read 500 pages and prove your commitment to your reading goals.",
            iconName: "linedpages",
            category: .pages,
            points: 500,
            durationDays: 30,
            requirementText: "Read 500 pages total.",
            validationType: .pageCount,
            requiredPageCount: 500
        ),
        ReadingChallenge(
            title: "Read 1,000 Pages",
            challengeDescription: "Take on a major reading milestone. Complete 1,000 pages across your books and celebrate a truly impressive achievement.",
            iconName: "linedpages",
            category: .pages,
            points: 1000,
            durationDays: 60,
            requirementText: "Read 1,000 pages total.",
            validationType: .pageCount,
            requiredPageCount: 1000
        ),
        ReadingChallenge(
            title: "Page Turner",
            challengeDescription: "Find a book that keeps you hooked from beginning to end. Complete a longer-than-usual reading session and watch the pages fly by.",
            iconName: "linedpages",
            category: .pages,
            points: 75,
            durationDays: 1,
            requirementText: "Read 75 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 75
        ),
        ReadingChallenge(
            title: "Marathon Reader",
            challengeDescription: "Set aside dedicated reading time and immerse yourself in a book for an extended session. This challenge is all about endurance and focus.",
            iconName: "linedpages",
            category: .pages,
            points: 200,
            durationDays: 1,
            requirementText: "Read 120 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 120
        ),
        ReadingChallenge(
            title: "Power Reader",
            challengeDescription: "Push yourself beyond your normal reading pace. Read a substantial number of pages and show what focused reading can accomplish.",
            iconName: "linedpages",
            category: .pages,
            points: 300,
            durationDays: 1,
            requirementText: "Read 210 pages in a single day.",
            validationType: .pageCount,
            requiredPageCount: 210
        ),
        ReadingChallenge(
            title: "Chapter Crusher",
            challengeDescription: "Some chapters are short, some are long, but every chapter completed moves the story forward. Finish multiple chapters and build momentum.",
            iconName: "linedpages",
            category: .pages,
            points: 100,
            durationDays: 1,
            requirementText: "Complete 4 chapters in a single day.",
            validationType: .experience,
            requiredSessionCount: 1,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "One Sitting Wonder",
            challengeDescription: "Lose yourself in a book and keep reading until you're ready to put it down. Complete a substantial reading session in a single sitting.",
            iconName: "linedpages",
            category: .pages,
            points: 150,
            durationDays: 1,
            requirementText: "Read for at least 90 consecutive minutes in one session.",
            validationType: .readingSession,
            requiredSessionCount: 1,
            requiredSessionMinutes: 90
        ),
    ]

    // MARK: - Book Completion Challenges

    static let bookCompletionChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Finish One Book",
            challengeDescription: "Every finished book is an accomplishment worth celebrating. Read all the way to the final page and complete a book from your library.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 150,
            durationDays: 30,
            requirementText: "Finish 1 book.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish Three Books",
            challengeDescription: "Build momentum and keep turning pages. Finish three books and enjoy the satisfaction of multiple completed reading journeys.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 3 books.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Finish Five Books",
            challengeDescription: "Commit to a season of reading and make serious progress through your library. Finish five books and strengthen your reading habit.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 900,
            durationDays: 120,
            requirementText: "Finish 5 books.",
            validationType: .bookCompletion,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Finish Ten Books",
            challengeDescription: "A challenge for dedicated readers. Complete ten books and celebrate a major reading milestone that reflects consistency and commitment.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 2000,
            durationDays: 180,
            requirementText: "Finish 10 books.",
            validationType: .bookCompletion,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Finish a Duology",
            challengeDescription: "Some stories are best experienced from beginning to end. Finish both books in a duology and complete the full narrative arc.",
            iconName: "books",
            category: .bookCompletion,
            points: 400,
            durationDays: 90,
            requirementText: "Finish both books in a duology.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Finish a Trilogy",
            challengeDescription: "Follow a story across three books and see it through to its conclusion. Complete an entire trilogy from start to finish.",
            iconName: "books",
            category: .bookCompletion,
            points: 750,
            durationDays: 120,
            requirementText: "Finish all 3 books in a trilogy.",
            validationType: .series,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Complete a Series",
            challengeDescription: "Take on a larger reading adventure and finish every book in a series. Whether it's four books or fourteen, reach the final volume and complete the journey.",
            iconName: "books",
            category: .bookCompletion,
            points: 1500,
            durationDays: 365,
            requirementText: "Finish every book in a series.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Backlist Buster",
            challengeDescription: "That book has been waiting long enough. Finish a book that has been sitting in your library or TBR longer than most.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 250,
            durationDays: 30,
            requirementText: "Finish a book added to your library at least 6 months ago.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish Your Oldest Book",
            challengeDescription: "Everyone has that one neglected book they've been meaning to finish. Return to your oldest unfinished book and finally cross it off the list.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 300,
            durationDays: 45,
            requirementText: "Finish the oldest unfinished book currently in your library.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "TBR Slayer",
            challengeDescription: "Your to-be-read pile doesn't stand a chance. Finish multiple books from your TBR and make meaningful progress through your backlog.",
            iconName: "bookstand",
            category: .bookCompletion,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 books marked as TBR.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
        ReadingChallenge(
            title: "Last Page Club",
            challengeDescription: "Join the club of readers who finish what they start. Complete a book and officially reach the last page.",
            iconName: "bookstack",
            category: .bookCompletion,
            points: 150,
            durationDays: 30,
            requirementText: "Finish any book.",
            validationType: .bookCompletion,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Series Finisher",
            challengeDescription: "You've come this far—don't stop now. Finish the final unread book in a series and bring the story to its proper conclusion.",
            iconName: "books",
            category: .bookCompletion,
            points: 500,
            durationDays: 60,
            requirementText: "Complete the last remaining book in a series.",
            validationType: .series,
            requiredBookCount: 1
        ),
    ]

    // MARK: - Genre Challenges

    static let genreChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Fantasy Explorer",
            challengeDescription: "Step into worlds filled with magic, adventure, and wonder. Complete a fantasy book and immerse yourself in an unforgettable journey beyond reality.",
            iconName: "sparklybook",
            category: .genre,
            points: 150,
            durationDays: 30,
            requirementText: "Finish a Fantasy book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Fantasy"
        ),
        ReadingChallenge(
            title: "Romance Reader",
            challengeDescription: "Follow stories of connection, longing, and love. Finish a romance book and experience a heartfelt journey from beginning to end.",
            iconName: "heartfill",
            category: .genre,
            points: 150,
            durationDays: 30,
            requirementText: "Finish a Romance book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Romance"
        ),
        ReadingChallenge(
            title: "Mystery Hunter",
            challengeDescription: "Gather clues, uncover secrets, and solve the puzzle. Finish a mystery novel and see if you can piece everything together before the final reveal.",
            iconName: "searchsparkle",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Mystery or Thriller book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Thriller & Mystery"
        ),
        ReadingChallenge(
            title: "Horror Seeker",
            challengeDescription: "Face the unknown and embrace the eerie. Complete a horror book and survive every chilling twist along the way.",
            iconName: "moonzs",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Horror book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Horror"
        ),
        ReadingChallenge(
            title: "Sci-Fi Traveler",
            challengeDescription: "Explore distant futures, advanced technology, and worlds beyond imagination. Finish a science fiction book and venture into the possibilities of tomorrow.",
            iconName: "planet",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Science Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Science Fiction"
        ),
        ReadingChallenge(
            title: "Historical Journey",
            challengeDescription: "Travel to another place and time through the pages of a book. Complete a historical fiction or history title and experience the past through a new perspective.",
            iconName: "timebook",
            category: .genre,
            points: 175,
            durationDays: 30,
            requirementText: "Finish a Historical Fiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Historical Fiction"
        ),
        ReadingChallenge(
            title: "Nonfiction Explorer",
            challengeDescription: "Expand your knowledge and discover something new. Finish a nonfiction book focused on learning, growth, history, science, or real-world experiences.",
            iconName: "handbook",
            category: .genre,
            points: 200,
            durationDays: 45,
            requirementText: "Finish a Nonfiction book.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredGenre: "Nonfiction"
        ),
        ReadingChallenge(
            title: "Genre Hopper",
            challengeDescription: "Break out of your usual reading patterns and try something different. Finish a book from a genre you haven't read recently.",
            iconName: "sparklybook",
            category: .genre,
            points: 250,
            durationDays: 30,
            requirementText: "Complete a book from a genre not read within the last 60 days.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredThemes: ["genre variety", "comfort zone"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Five Genre Challenge",
            challengeDescription: "Broaden your reading horizons and experience a variety of storytelling styles. Complete books from five different genres during the challenge period.",
            iconName: "sparklybook",
            category: .genre,
            points: 750,
            durationDays: 180,
            requirementText: "Finish books from 4 unique genres.",
            validationType: .genre,
            requiredBookCount: 4
        ),
        ReadingChallenge(
            title: "Read Outside Your Comfort Zone",
            challengeDescription: "Growth often starts with something unfamiliar. Choose a genre you rarely read and give it a genuine chance from first page to last.",
            iconName: "crossroads",
            category: .genre,
            points: 300,
            durationDays: 45,
            requirementText: "Finish a book from one of your least-read genres.",
            validationType: .genre,
            requiredBookCount: 1,
            requiredThemes: ["comfort zone", "unfamiliar genre"],
            requiresAIValidation: true,
            isWeekly: true
        ),
    ]

    // MARK: - Review Challenges

    static let reviewChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "First Review",
            challengeDescription: "Every opinion matters. Write your first book review and share your thoughts, reactions, and overall experience with a completed read.",
            iconName: "writenote",
            category: .review,
            points: 50,
            durationDays: 7,
            requirementText: "Write 1 book review.",
            validationType: .review,
            requiredReviewCount: 1
        ),
        ReadingChallenge(
            title: "Review Writer",
            challengeDescription: "Turn your reading experience into reflection. Write reviews for multiple books and build the habit of capturing your thoughts after finishing a story.",
            iconName: "writenote",
            category: .review,
            points: 150,
            durationDays: 30,
            requirementText: "Write 3 book reviews.",
            validationType: .review,
            requiredReviewCount: 3
        ),
        ReadingChallenge(
            title: "Five Reviews",
            challengeDescription: "Become a consistent reviewer by sharing your thoughts on multiple books. Complete five reviews and start building your personal reading archive.",
            iconName: "writenote",
            category: .review,
            points: 300,
            durationDays: 60,
            requirementText: "Write 5 book reviews.",
            validationType: .review,
            requiredReviewCount: 5
        ),
        ReadingChallenge(
            title: "Ten Reviews",
            challengeDescription: "Develop a strong review-writing habit and document your reading journey in detail. Complete ten reviews and become a trusted voice in your own library.",
            iconName: "writenote",
            category: .review,
            points: 750,
            durationDays: 120,
            requirementText: "Write 10 book reviews.",
            validationType: .review,
            requiredReviewCount: 10
        ),
        ReadingChallenge(
            title: "Honest Critic",
            challengeDescription: "Not every book becomes a favorite, and that's okay. Write a thoughtful review that honestly reflects both the strengths and weaknesses of a book.",
            iconName: "writenote",
            category: .review,
            points: 100,
            durationDays: 14,
            requirementText: "Complete a review with both positive and constructive feedback.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredThemes: ["honest", "balanced", "constructive"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Thoughtful Reviewer",
            challengeDescription: "Go beyond a star rating and dig deeper into your reading experience. Write a detailed review that explores characters, plot, themes, or personal takeaways.",
            iconName: "writenote",
            category: .review,
            points: 150,
            durationDays: 14,
            requirementText: "Write a review containing at least 250 words.",
            validationType: .review,
            requiredReviewCount: 1,
            requiredWordCount: 250
        ),
        ReadingChallenge(
            title: "Review Marathon",
            challengeDescription: "You've got opinions and it's time to share them. Write several reviews in a short period and catch up on books you've already finished.",
            iconName: "writenote",
            category: .review,
            points: 400,
            durationDays: 7,
            requirementText: "Write 5 reviews within one week.",
            validationType: .review,
            requiredReviewCount: 5
        ),
        ReadingChallenge(
            title: "Book Blogger",
            challengeDescription: "Create a substantial collection of reviews and reflections. This challenge celebrates readers who consistently document and preserve their thoughts about what they read.",
            iconName: "writenote",
            category: .review,
            points: 1000,
            durationDays: 180,
            requirementText: "Write 13 book reviews.",
            validationType: .review,
            requiredReviewCount: 13
        ),
    ]

    // MARK: - Rating Challenges

    static let ratingChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Five Star Finder",
            challengeDescription: "Every reader is searching for that unforgettable book. Read and rate a book five stars after finding a story that truly earns your highest praise.",
            iconName: "starfill",
            category: .rating,
            points: 150,
            durationDays: 60,
            requirementText: "Give one book a 5-star rating.",
            validationType: .rating,
            requiredBookCount: 1,
            requiredRating: 5
        ),
        ReadingChallenge(
            title: "Rating Collector",
            challengeDescription: "Keep your library complete by rating every book you finish. Build a collection of thoughtful ratings that reflects your reading journey.",
            iconName: "starfill",
            category: .rating,
            points: 300,
            durationDays: 60,
            requirementText: "Rate 10 completed books.",
            validationType: .rating,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Critical Reader",
            challengeDescription: "Look beyond whether you simply liked a book. Rate multiple books thoughtfully and develop the habit of evaluating each reading experience.",
            iconName: "starfill",
            category: .rating,
            points: 250,
            durationDays: 45,
            requirementText: "Rate 5 completed books.",
            validationType: .rating,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Star Giver",
            challengeDescription: "Every finished book deserves your final verdict. Rate books consistently and build a library where every completed read has a score.",
            iconName: "starfill",
            category: .rating,
            points: 150,
            durationDays: 30,
            requirementText: "Rate 5 books.",
            validationType: .rating,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Perfect Book Hunt",
            challengeDescription: "Search for the stories that stay with you long after you've turned the final page. Find and award five stars to several books that truly become favorites.",
            iconName: "starfill",
            category: .rating,
            points: 500,
            durationDays: 180,
            requirementText: "Award 5-star ratings to 5 different books.",
            validationType: .rating,
            requiredBookCount: 5,
            requiredRating: 5
        ),
    ]

    // MARK: - Series Challenges

    static let seriesChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Kingdom Conqueror",
            challengeDescription: "Some fictional worlds are worth exploring from beginning to end. Complete an entire fantasy series and earn your place among the kingdom's greatest readers.",
            iconName: "books",
            category: .series,
            points: 1000,
            durationDays: 180,
            requirementText: "Finish every book in a fantasy series.",
            validationType: .series,
            requiredBookCount: 2,
            requiredGenre: "Fantasy"
        ),
        ReadingChallenge(
            title: "Complete a Series",
            challengeDescription: "See a story through to its true ending. Read every book in a series and experience the complete journey from the first page to the final chapter.",
            iconName: "books",
            category: .series,
            points: 1000,
            durationDays: 365,
            requirementText: "Finish every book in any series.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Read a Quartet",
            challengeDescription: "Four books, one unforgettable adventure. Complete all four books in a quartet and enjoy the full story as it was meant to be experienced.",
            iconName: "books",
            category: .series,
            points: 900,
            durationDays: 180,
            requirementText: "Finish all four books in a single quartet.",
            validationType: .series,
            requiredBookCount: 4
        ),
        ReadingChallenge(
            title: "Read a Saga",
            challengeDescription: "Take on an epic reading journey spanning multiple books. Complete a long-running saga and celebrate an achievement that requires true dedication.",
            iconName: "books",
            category: .series,
            points: 1500,
            durationDays: 365,
            requirementText: "Finish a series containing at least 5 books.",
            validationType: .series,
            requiredBookCount: 5
        ),
        ReadingChallenge(
            title: "Continue the Story",
            challengeDescription: "Don't leave a great story unfinished. Return to a series you've already started and complete the next book in the sequence.",
            iconName: "books",
            category: .series,
            points: 250,
            durationDays: 45,
            requirementText: "Finish the next unread book in an existing series.",
            validationType: .series,
            requiredBookCount: 1
        ),
        ReadingChallenge(
            title: "Finish What You Started",
            challengeDescription: "Revisit a series that's been waiting on your shelf and bring it to a satisfying conclusion. Every unfinished adventure deserves an ending.",
            iconName: "books",
            category: .series,
            points: 750,
            durationDays: 180,
            requirementText: "Complete a series you've already begun.",
            validationType: .series,
            requiredBookCount: 2
        ),
        ReadingChallenge(
            title: "Series Marathon",
            challengeDescription: "Stay immersed in one fictional world by reading several books from the same series back-to-back. Build momentum and keep the adventure going without switching stories.",
            iconName: "books",
            category: .series,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 3 consecutive books from the same series.",
            validationType: .series,
            requiredBookCount: 3
        ),
    ]

    // MARK: - Author Challenges

    static let authorChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Author Loyalist",
            challengeDescription: "When you find an author you love, one book is rarely enough. Read multiple books by the same author and explore more of their storytelling.",
            iconName: "pencilfill",
            category: .author,
            points: 300,
            durationDays: 90,
            requirementText: "Finish 3 books by the same author.",
            validationType: .author,
            requiredBookCount: 3,
            requiredSameAuthorCount: 3
        ),
        ReadingChallenge(
            title: "Read Three Authors",
            challengeDescription: "Expand your reading horizons by experiencing different writing styles and perspectives. Finish books by three different authors.",
            iconName: "pencilfill",
            category: .author,
            points: 250,
            durationDays: 60,
            requirementText: "Finish books by 3 unique authors.",
            validationType: .author,
            requiredBookCount: 3,
            requiredUniqueAuthorCount: 3
        ),
        ReadingChallenge(
            title: "Read Five Authors",
            challengeDescription: "Discover a wider variety of voices, worlds, and storytelling styles. Complete books by five different authors and broaden your library.",
            iconName: "pencilfill",
            category: .author,
            points: 500,
            durationDays: 120,
            requirementText: "Finish books by 5 unique authors.",
            validationType: .author,
            requiredBookCount: 5,
            requiredUniqueAuthorCount: 5
        ),
        ReadingChallenge(
            title: "Favorite Author Deep Dive",
            challengeDescription: "Spend time with the author whose stories you can't get enough of. Read several of their books and experience the depth of their work beyond a single title.",
            iconName: "pencilfill",
            category: .author,
            points: 600,
            durationDays: 180,
            requirementText: "Finish 5 books by the same author.",
            validationType: .author,
            requiredBookCount: 5,
            requiredSameAuthorCount: 5
        ),
        ReadingChallenge(
            title: "Author Explorer",
            challengeDescription: "Every new author offers a fresh perspective. Discover unfamiliar voices by reading books from authors you've never read before.",
            iconName: "pencilfill",
            category: .author,
            points: 350,
            durationDays: 90,
            requirementText: "Finish books by 3 new authors.",
            validationType: .author,
            requiredBookCount: 3,
            requiresAIValidation: false,
            requiredUniqueAuthorCount: 3
        ),
        ReadingChallenge(
            title: "New Voice",
            challengeDescription: "Take a chance on someone new. Step outside your usual favorites and discover an author making their first impression on your reading journey.",
            iconName: "pencilfill",
            category: .author,
            points: 100,
            durationDays: 30,
            requirementText: "Finish a book by an author you've never read before.",
            validationType: .author,
            requiredBookCount: 1,
            requiredUniqueAuthorCount: 1
        ),
    ]

    // MARK: - Seasonal Challenges

    static let seasonalChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Spring Reading Challenge",
            challengeDescription: "Celebrate renewal, growth, soft magic, blooming settings, fresh starts, and stories that feel alive with possibility. Complete spring-themed books that capture the feeling of new beginnings, nature returning, or life opening back up.",
            iconName: "flower",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 spring-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["spring", "renewal", "growth", "blooming", "fresh starts", "new beginnings"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Summer Reading Challenge",
            challengeDescription: "Dive into books filled with sunshine, travel, beaches, vacations, warm weather, adventure, freedom, or bright seasonal energy. Complete summer-themed books that feel like long days, golden light, and stories made for getting swept away.",
            iconName: "sun",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 summer-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["summer", "sunshine", "beach", "vacation", "adventure", "travel"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Autumn Reading Challenge",
            challengeDescription: "Settle into books with crisp air, cozy settings, falling leaves, harvest magic, school-year energy, witchy atmosphere, or reflective seasonal moods. Complete autumn-themed books that feel rich, moody, nostalgic, or deeply atmospheric.",
            iconName: "flower",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 autumn-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["autumn", "fall", "cozy", "harvest", "witchy", "atmospheric", "leaves"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Winter Reading Challenge",
            challengeDescription: "Curl up with books full of snow, cold weather, frost, isolation, winter magic, cozy interiors, survival, quiet reflection, or frozen landscapes. Complete winter-themed books that capture the stillness, beauty, danger, or comfort of the season.",
            iconName: "moonzs",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 winter-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["winter", "snow", "frost", "cozy", "cold", "frozen", "holiday"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Spooky Season Challenge",
            challengeDescription: "Embrace eerie, unsettling, haunted, witchy, gothic, monstrous, mysterious, or Halloween-coded stories. Complete books that feel made for candlelight, shadows, strange noises, and the delicious little thrill of being creeped out.",
            iconName: "moonzs",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 spooky, gothic, horror, paranormal, witchy, or Halloween-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["spooky", "gothic", "horror", "haunted", "witchy", "halloween", "paranormal"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Holiday Reading Challenge",
            challengeDescription: "Read books filled with winter holidays, festive traditions, family gatherings, seasonal romance, cozy celebration, holiday magic, or end-of-year warmth. Complete holiday-themed books that feel comforting, nostalgic, joyful, dramatic, or sparkling with seasonal charm.",
            iconName: "stargift",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 holiday-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["holiday", "christmas", "festive", "celebration", "seasonal warmth"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "February Romance Challenge",
            challengeDescription: "Celebrate love in all its forms with books centered on romance, emotional connection, longing, devotion, second chances, slow burns, or happily-ever-afters. Complete romance-themed books that make February feel sweeter, softer, or beautifully dramatic.",
            iconName: "heartfill",
            category: .seasonal,
            points: 750,
            durationDays: 90,
            requirementText: "Finish 3 romance-themed books.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["romance", "love", "devotion", "connection", "slow burn"],
            requiresAIValidation: true
        ),
    ]

    // MARK: - Book Length Challenges

    static let bookLengthChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Quick Read",
            challengeDescription: "Not every great book needs hundreds of pages. Pick up a shorter read and enjoy the satisfaction of finishing a complete story in less time.",
            iconName: "flatbook",
            category: .bookLength,
            points: 100,
            durationDays: 30,
            requirementText: "Finish a book under 250 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMaxPages: 250
        ),
        ReadingChallenge(
            title: "Medium Read",
            challengeDescription: "The perfect balance between a quick read and an epic adventure. Complete a medium-length book and enjoy a story with plenty of room to unfold.",
            iconName: "flatbook",
            category: .bookLength,
            points: 200,
            durationDays: 45,
            requirementText: "Finish a book between 250–499 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 250,
            requiredMaxPages: 499
        ),
        ReadingChallenge(
            title: "Big Book Energy",
            challengeDescription: "Some stories demand a little more commitment. Finish a substantial novel and prove you're ready to tackle books that take readers on a longer journey.",
            iconName: "flatbook",
            category: .bookLength,
            points: 400,
            durationDays: 60,
            requirementText: "Finish a book between 500–699 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 500,
            requiredMaxPages: 699
        ),
        ReadingChallenge(
            title: "Epic Length",
            challengeDescription: "Accept the challenge of an unforgettable epic. Complete a massive book filled with rich world-building, unforgettable characters, and a story that rewards every page.",
            iconName: "flatbook",
            category: .bookLength,
            points: 700,
            durationDays: 90,
            requirementText: "Finish a book between 700–999 pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 700,
            requiredMaxPages: 999
        ),
        ReadingChallenge(
            title: "Doorstopper Reader",
            challengeDescription: "The biggest books can be the most rewarding. Take on a truly enormous read and prove that no novel is too intimidating when you keep turning pages.",
            iconName: "flatbook",
            category: .bookLength,
            points: 1000,
            durationDays: 120,
            requirementText: "Finish a book with 800 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 800
        ),
        ReadingChallenge(
            title: "500 Page Club",
            challengeDescription: "Welcome to the club where bigger books become the norm. Complete a book that's at least 500 pages long and celebrate your growing reading endurance.",
            iconName: "flatbook",
            category: .bookLength,
            points: 500,
            durationDays: 60,
            requirementText: "Finish a book with 500 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 500,
            isFeatured: true
        ),
        ReadingChallenge(
            title: "700 Page Club",
            challengeDescription: "Only dedicated readers make it here. Finish a book with more than 700 pages and earn your place among readers who embrace lengthy adventures.",
            iconName: "flatbook",
            category: .bookLength,
            points: 800,
            durationDays: 90,
            requirementText: "Finish a book with 700 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 700
        ),
        ReadingChallenge(
            title: "1,000 Page Monster",
            challengeDescription: "Few books reach four digits, but the ones that do promise an unforgettable journey. Conquer a literary giant and complete a book with one thousand pages or more.",
            iconName: "flatbook",
            category: .bookLength,
            points: 1500,
            durationDays: 180,
            requirementText: "Finish a book with 1,000 or more pages.",
            validationType: .bookLength,
            requiredBookCount: 1,
            requiredMinPages: 1000
        ),
    ]

    // MARK: - Collection Challenges

    static let collectionChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Library Builder",
            challengeDescription: "Every great reading journey begins with a library worth exploring. Add books to your collection and build a personal library filled with stories you'll be excited to read for years to come.",
            iconName: "bookstand",
            category: .collection,
            points: 250,
            durationDays: 30,
            requirementText: "Add 25 books to your library.",
            validationType: .collection,
            requiredBookCount: 25
        ),
        ReadingChallenge(
            title: "Build Your TBR",
            challengeDescription: "Give your future self something to look forward to. Create a thoughtfully stocked To Be Read list filled with books that genuinely excite and inspire you.",
            iconName: "bookstand",
            category: .collection,
            points: 200,
            durationDays: 30,
            requirementText: "Add 20 books to your TBR.",
            validationType: .collection,
            requiredBookCount: 20
        ),
        ReadingChallenge(
            title: "Curated Collection",
            challengeDescription: "A meaningful library is more than a random assortment of books—it's a reflection of your interests. Organize and grow a collection that feels intentional, personal, and uniquely yours.",
            iconName: "bookstand",
            category: .collection,
            points: 400,
            durationDays: 60,
            requirementText: "Create 10 Reading Lists and add books to each one.",
            validationType: .collection,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Genre Collection",
            challengeDescription: "Celebrate the stories you love most by building a dedicated collection around a favorite genre.",
            iconName: "bookstand",
            category: .collection,
            points: 300,
            durationDays: 45,
            requirementText: "Add 20 books from the same genre to your library.",
            validationType: .collection,
            requiredBookCount: 20
        ),
        ReadingChallenge(
            title: "Author Collection",
            challengeDescription: "When one book isn't enough, build a collection around an author whose stories keep drawing you back.",
            iconName: "bookstand",
            category: .collection,
            points: 350,
            durationDays: 60,
            requirementText: "Add 10 books by the same author.",
            validationType: .collection,
            requiredBookCount: 10
        ),
        ReadingChallenge(
            title: "Series Collection",
            challengeDescription: "Some adventures deserve an entire shelf of their own. Build a complete collection for a book series and keep every installment together.",
            iconName: "bookstand",
            category: .collection,
            points: 500,
            durationDays: 90,
            requirementText: "Add every available book from one series to your library.",
            validationType: .collection,
            requiredBookCount: 3
        ),
    ]

    // MARK: - Photo Proof Challenges

    static let photoProofChallenges: [ReadingChallenge] = [
        photoProofChallenge(
            title: "Cozy Corner",
            challengeDescription: "Capture a cozy reading nook or reading space that looks ready for a quiet chapter.",
            iconName: "openlovebook",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a cozy reading nook or reading space.",
            requiredThemes: ["cozy reading nook", "reading space", "comfortable spot", "cozy corner"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Reading Sanctuary",
            challengeDescription: "Show the place that feels like your personal reading sanctuary.",
            iconName: "heartfill",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of your favorite place to read.",
            requiredThemes: ["favorite reading place", "reading sanctuary", "reading spot"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Window Seat Escape",
            challengeDescription: "Place a book beside a window and capture that page-and-daylight feeling.",
            iconName: "starwindow",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book beside a window.",
            requiredThemes: ["book", "window", "window seat", "daylight"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Blanket Burrito",
            challengeDescription: "Pair a book with a blanket and make the reading setup visibly cozy.",
            iconName: "openbook",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with a blanket.",
            requiredThemes: ["book", "blanket", "cozy blanket", "soft textile"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Pillow Fortress",
            challengeDescription: "Build a soft little reading base with pillows or cushions and a book.",
            iconName: "pillows",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with pillows or cushions.",
            requiredThemes: ["book", "pillows", "cushions", "reading comfort"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Outdoor Escape",
            challengeDescription: "Take a book outside and show it in open air, sun, shade, or scenery.",
            iconName: "sun",
            category: .seasonal,
            points: 65,
            requirementText: "Submit a photo of a book outdoors.",
            requiredThemes: ["book", "outdoors", "outside", "natural light"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Garden Chapters",
            challengeDescription: "Show a book surrounded by plants, greenery, or garden life.",
            iconName: "flower",
            category: .seasonal,
            points: 70,
            requirementText: "Submit a photo of a book surrounded by plants or in a garden.",
            requiredThemes: ["book", "plants", "garden", "greenery"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Park Bench Pages",
            challengeDescription: "Bring a book to a bench and capture a simple public reading moment.",
            iconName: "lovelocation",
            category: .seasonal,
            points: 70,
            requirementText: "Submit a photo of a book on a park bench.",
            requiredThemes: ["book", "park bench", "bench", "park"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Beach Book Day",
            challengeDescription: "Take a book to the beach and show sand, shoreline, waves, or a clear beach setting.",
            iconName: "sun",
            category: .seasonal,
            points: 85,
            requirementText: "Submit a photo of a book at the beach.",
            requiredThemes: ["book", "beach", "sand", "shoreline", "water"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Lake Day Reader",
            challengeDescription: "Show a book beside calm water, whether it is a lake, river, pond, or similar spot.",
            iconName: "lovelocation",
            category: .seasonal,
            points: 85,
            requirementText: "Submit a photo of a book beside a lake, river, or pond.",
            requiredThemes: ["book", "lake", "river", "pond", "water"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Hammock Hideaway",
            challengeDescription: "Capture a book resting in or near a hammock-ready reading hideaway.",
            iconName: "openbook",
            category: .fun,
            points: 85,
            requirementText: "Submit a photo of a book in a hammock.",
            requiredThemes: ["book", "hammock", "outdoor reading", "resting spot"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Campfire Chapters",
            challengeDescription: "Show a book near a campfire, firepit, or safely visible firelight setup.",
            iconName: "3candles",
            category: .seasonal,
            points: 90,
            requirementText: "Submit a photo of a book near a campfire.",
            requiredThemes: ["book", "campfire", "firepit", "firelight"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Tea & Tales",
            challengeDescription: "Pair a book with tea and capture the calm little ritual.",
            iconName: "lovecup",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with a cup of tea.",
            requiredThemes: ["book", "tea", "cup", "mug"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Snack Break Stories",
            challengeDescription: "Show a book with a snack close enough to prove the page break.",
            iconName: "lovecup",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with a snack.",
            requiredThemes: ["book", "snack", "food", "treat"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Sweet Chapters",
            challengeDescription: "Put dessert and a book in the same frame for a sweeter reading break.",
            iconName: "heartfill",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with a dessert.",
            requiredThemes: ["book", "dessert", "sweet", "treat"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Breakfast Book Club",
            challengeDescription: "Show your book sharing space with breakfast, from coffee and toast to a full plate.",
            iconName: "sun",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with breakfast.",
            requiredThemes: ["book", "breakfast", "morning meal", "food"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Book Picnic",
            challengeDescription: "Capture a book on a picnic blanket or clearly picnic-style setup.",
            iconName: "flower",
            category: .fun,
            points: 75,
            requirementText: "Submit a photo of a book on a picnic blanket.",
            requiredThemes: ["book", "picnic blanket", "picnic", "outdoor blanket"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Hydrated Reader",
            challengeDescription: "Show a book with a water bottle, tumbler, or reusable drink container.",
            iconName: "lovecup",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a book with a water bottle or reusable drink container.",
            requiredThemes: ["book", "water bottle", "reusable bottle", "drink container", "tumbler"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Café Chapters",
            challengeDescription: "Capture a book on a cafe table or in a clearly cafe-like setting.",
            iconName: "coffeemaker",
            category: .fun,
            points: 70,
            requirementText: "Submit a photo of a book on a cafe table.",
            requiredThemes: ["book", "cafe table", "coffee shop", "cafe"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Beautiful Cover",
            challengeDescription: "Let a book cover take center stage in a clear, readable photo.",
            iconName: "starbook",
            category: .fun,
            points: 55,
            requirementText: "Submit a photo clearly showing a book cover.",
            requiredThemes: ["book cover", "cover", "front cover"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Color Splash",
            challengeDescription: "Find a bright, bold, or colorful cover and make the color impossible to miss.",
            iconName: "sparklybook",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a brightly colored book cover.",
            requiredThemes: ["book cover", "bright color", "colorful cover", "bold cover"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Minimalist Cover",
            challengeDescription: "Show a cover with clean, simple, or intentionally minimal design.",
            iconName: "flatbook",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a minimalist book cover.",
            requiredThemes: ["book cover", "minimalist cover", "simple design", "clean cover"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Gorgeous Spine",
            challengeDescription: "Highlight the spine of a book as the main visible detail.",
            iconName: "books",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo highlighting a book's spine.",
            requiredThemes: ["book spine", "spine", "side of book"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Open Book Beauty",
            challengeDescription: "Open a book and photograph the visible pages as the subject.",
            iconName: "openbook",
            category: .fun,
            points: 55,
            requirementText: "Submit a photo of an open book.",
            requiredThemes: ["open book", "pages", "book spread"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Favorite Quote",
            challengeDescription: "Capture a page that contains a quote or passage you want to remember.",
            iconName: "quote",
            category: .review,
            points: 65,
            requirementText: "Submit a photo of a page containing a favorite quote.",
            requiredThemes: ["book page", "quote", "passage", "text"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Chapter Snapshot",
            challengeDescription: "Show an open chapter page or chapter opening inside a book.",
            iconName: "linedpages",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of an open chapter in a book.",
            requiredThemes: ["open chapter", "chapter page", "book pages"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Tiny Details",
            challengeDescription: "Zoom in on a small but interesting visual detail from a book.",
            iconName: "searchsparkle",
            category: .fun,
            points: 65,
            requirementText: "Submit a close-up photo of an interesting detail on a book.",
            requiredThemes: ["book detail", "close-up", "cover detail", "page detail"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Pretty Endpapers",
            challengeDescription: "Open a book to decorative endpapers and show the design clearly.",
            iconName: "sparklybook",
            category: .collection,
            points: 85,
            requirementText: "Submit a photo of decorative book endpapers.",
            requiredThemes: ["decorative endpapers", "endpapers", "inside cover", "book design"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Edge Art",
            challengeDescription: "Show painted, sprayed, stenciled, or otherwise decorated page edges.",
            iconName: "starbook",
            category: .collection,
            points: 90,
            requirementText: "Submit a photo of painted or decorated page edges.",
            requiredThemes: ["painted edges", "decorated edges", "sprayed edges", "page edges"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Shelf Refresh",
            challengeDescription: "Show an organized bookshelf that looks intentionally arranged.",
            iconName: "bookstand",
            category: .collection,
            points: 70,
            requirementText: "Submit a photo of an organized bookshelf.",
            requiredThemes: ["organized bookshelf", "bookshelf", "arranged books"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Rainbow Shelf",
            challengeDescription: "Arrange books by color and capture the rainbow shelf effect.",
            iconName: "sparklybook",
            category: .collection,
            points: 80,
            requirementText: "Submit a photo of books arranged by color.",
            requiredThemes: ["books arranged by color", "rainbow shelf", "color order", "bookshelf"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Favorite Shelf",
            challengeDescription: "Show one shelf you especially like, whether it is neat, themed, or full of favorites.",
            iconName: "bookstand",
            category: .collection,
            points: 65,
            requirementText: "Submit a photo of one bookshelf.",
            requiredThemes: ["bookshelf", "shelf", "books"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Current Reads Shelf",
            challengeDescription: "Show a shelf or display area holding books you want visible right now.",
            iconName: "books",
            category: .collection,
            points: 70,
            requirementText: "Submit a photo of a shelf displaying books.",
            requiredThemes: ["shelf", "displayed books", "bookshelf"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Mini Library",
            challengeDescription: "Capture a home book collection, small or large, in one clear photo.",
            iconName: "bookstack",
            category: .collection,
            points: 75,
            requirementText: "Submit a photo of a home book collection.",
            requiredThemes: ["home book collection", "mini library", "multiple books", "bookshelf"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Overflowing Shelf",
            challengeDescription: "Show a bookshelf that is visibly full, stacked, packed, or overflowing.",
            iconName: "bookstack",
            category: .collection,
            points: 75,
            requirementText: "Submit a photo of a full bookshelf.",
            requiredThemes: ["full bookshelf", "packed shelf", "many books"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Shelf Styling",
            challengeDescription: "Capture a decorated bookshelf with books plus visual styling or objects.",
            iconName: "starmark",
            category: .collection,
            points: 75,
            requirementText: "Submit a photo of a decorated bookshelf.",
            requiredThemes: ["decorated bookshelf", "styled shelf", "books and decor"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Floating Books",
            challengeDescription: "Show a creative book display that is not just a plain stack.",
            iconName: "sparklesstarflag",
            category: .collection,
            points: 80,
            requirementText: "Submit a photo of a creative book display.",
            requiredThemes: ["creative book display", "displayed books", "floating shelf", "book arrangement"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Fantasy Collection",
            challengeDescription: "Gather several fantasy books and show them together.",
            iconName: "sparklybook",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple fantasy books.",
            requiredThemes: ["multiple books", "fantasy books", "fantasy covers", "fantasy titles"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Romance Collection",
            challengeDescription: "Gather several romance books and show them together.",
            iconName: "heartfill",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple romance books.",
            requiredThemes: ["multiple books", "romance books", "romance covers", "romance titles"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Horror Collection",
            challengeDescription: "Gather several horror books and show them together.",
            iconName: "moonzs",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple horror books.",
            requiredThemes: ["multiple books", "horror books", "horror covers", "horror titles"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Mystery Collection",
            challengeDescription: "Gather several mystery or thriller books and show them together.",
            iconName: "searchsparkle",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple mystery or thriller books.",
            requiredThemes: ["multiple books", "mystery books", "thriller books", "mystery titles"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Sci-Fi Collection",
            challengeDescription: "Gather several science fiction books and show them together.",
            iconName: "galaxysparkle",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple science fiction books.",
            requiredThemes: ["multiple books", "science fiction books", "sci-fi books", "space books"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Classic Collection",
            challengeDescription: "Gather several classics and show the collection together.",
            iconName: "starbook",
            category: .genre,
            points: 90,
            requirementText: "Submit a photo of multiple classic books.",
            requiredThemes: ["multiple books", "classic books", "classics", "literary classics"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Special Edition Shelf",
            challengeDescription: "Show one or more special edition books, deluxe editions, collector editions, or visually premium copies.",
            iconName: "startrophy",
            category: .collection,
            points: 95,
            requirementText: "Submit a photo of one or more special edition books.",
            requiredThemes: ["special edition book", "collector edition", "deluxe edition", "premium book"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Signed Treasure",
            challengeDescription: "Show a signed book, signature page, bookplate, or visible author signature.",
            iconName: "pencilfill",
            category: .collection,
            points: 100,
            requirementText: "Submit a photo of a signed book.",
            requiredThemes: ["signed book", "signature", "author signature", "bookplate"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Illustrated Beauty",
            challengeDescription: "Show a book with illustrations, art, panels, plates, or visibly illustrated pages.",
            iconName: "image",
            category: .collection,
            points: 90,
            requirementText: "Submit a photo of an illustrated book.",
            requiredThemes: ["illustrated book", "illustration", "book art", "illustrated pages"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Tiny Book Haul",
            challengeDescription: "Show a small haul of two or three newly acquired books.",
            iconName: "bookstack",
            category: .collection,
            points: 75,
            requirementText: "Submit a photo of 2-3 recently acquired books.",
            requiredThemes: ["2-3 books", "book haul", "recently acquired books", "new books"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Weekend Book Haul",
            challengeDescription: "Show multiple recently acquired books together as a book haul.",
            iconName: "stargift",
            category: .collection,
            points: 80,
            requirementText: "Submit a photo of multiple recently acquired books.",
            requiredThemes: ["multiple books", "book haul", "recently acquired books", "new books"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Book Receipt",
            challengeDescription: "Show a book alongside its purchase receipt without needing private details to be readable.",
            iconName: "lovereceipt",
            category: .collection,
            points: 80,
            requirementText: "Submit a photo of a book alongside its purchase receipt.",
            requiredThemes: ["book", "receipt", "purchase receipt", "new book"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Single Treasure",
            challengeDescription: "Show one newly acquired book as the star of the photo.",
            iconName: "starbook",
            category: .collection,
            points: 70,
            requirementText: "Submit a photo of one newly acquired book.",
            requiredThemes: ["one book", "newly acquired book", "new book", "book haul"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Lunch Companion",
            challengeDescription: "Show a book keeping your lunch company.",
            iconName: "lovecup",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book with your lunch.",
            requiredThemes: ["book", "lunch", "meal", "food"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Reading Buddy",
            challengeDescription: "Capture a pet sharing space with a book.",
            iconName: "petpaw",
            category: .fun,
            points: 75,
            requirementText: "Submit a photo of a pet beside a book.",
            requiredThemes: ["pet", "book", "animal", "reading buddy"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Cat Approved",
            challengeDescription: "Show a cat with a book, even if the cat is clearly in charge of the scene.",
            iconName: "catface",
            category: .fun,
            points: 75,
            requirementText: "Submit a photo of a cat with a book.",
            requiredThemes: ["cat", "book", "pet"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Dog Approved",
            challengeDescription: "Show a dog with a book in the same photo.",
            iconName: "dogface",
            category: .fun,
            points: 75,
            requirementText: "Submit a photo of a dog with a book.",
            requiredThemes: ["dog", "book", "pet"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Under A Tree",
            challengeDescription: "Show a book beneath or directly beside a tree.",
            iconName: "foldertreefill",
            category: .seasonal,
            points: 70,
            requirementText: "Submit a photo of a book beneath a tree.",
            requiredThemes: ["book", "tree", "beneath a tree", "outdoors"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Flower Chapters",
            challengeDescription: "Show a book beside flowers, plants, or blooming greenery.",
            iconName: "flower",
            category: .seasonal,
            points: 70,
            requirementText: "Submit a photo of a book beside flowers or plants.",
            requiredThemes: ["book", "flowers", "plants", "blooming greenery"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Mountain Reader",
            challengeDescription: "Capture a book with mountains, hills, cliffs, or a clear mountain view behind it.",
            iconName: "lovelocation",
            category: .seasonal,
            points: 95,
            requirementText: "Submit a photo of a book with mountains visible in the background.",
            requiredThemes: ["book", "mountains", "mountain background", "scenic view"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Autumn Leaves",
            challengeDescription: "Show a book surrounded by fall leaves or clear autumn foliage.",
            iconName: "flower",
            category: .seasonal,
            points: 90,
            requirementText: "Submit a photo of a book surrounded by autumn leaves.",
            requiredThemes: ["book", "autumn leaves", "fall leaves", "foliage"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Snowy Chapters",
            challengeDescription: "Show a book in a snowy scene, near snow, or against a clearly wintery setting.",
            iconName: "sparkletimeglass",
            category: .seasonal,
            points: 90,
            requirementText: "Submit a photo of a book in a snowy setting.",
            requiredThemes: ["book", "snow", "snowy setting", "winter"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Spring Bloom Reader",
            challengeDescription: "Show a book among blooming flowers or visible spring blooms.",
            iconName: "sunflower",
            category: .seasonal,
            points: 90,
            requirementText: "Submit a photo of a book among blooming flowers.",
            requiredThemes: ["book", "blooming flowers", "spring blooms", "flowers"],
            recurring: false
        ),
        photoProofChallenge(
            title: "Bookmark Beauty",
            challengeDescription: "Show a bookmark placed inside a book.",
            iconName: "bookmark",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a bookmark inside a book.",
            requiredThemes: ["bookmark", "inside a book", "book pages"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Reading Accessories",
            challengeDescription: "Show reading accessories such as bookmarks, tabs, book lights, annotation tools, sleeves, stands, or similar items.",
            iconName: "starmark",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of one or more reading accessories.",
            requiredThemes: ["reading accessories", "bookmark", "tabs", "book light", "annotation tools"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Annotation Station",
            challengeDescription: "Show book pages with visible annotations, marks, underlines, notes, or highlights.",
            iconName: "pagepencil",
            category: .review,
            points: 70,
            requirementText: "Submit a photo of annotated pages.",
            requiredThemes: ["annotated pages", "annotations", "highlights", "notes", "underlines"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Sticky Note Forest",
            challengeDescription: "Show pages marked with sticky notes, tabs, flags, or visible note markers.",
            iconName: "starnote",
            category: .review,
            points: 70,
            requirementText: "Submit a photo of pages covered with sticky notes.",
            requiredThemes: ["sticky notes", "book pages", "tabs", "flags", "annotations"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Reading Journal",
            challengeDescription: "Show a reading journal, notebook, spread, tracker, or handwritten book notes.",
            iconName: "lovejournal",
            category: .review,
            points: 70,
            requirementText: "Submit a photo of a reading journal.",
            requiredThemes: ["reading journal", "book journal", "notebook", "reading tracker"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Book & Candle Flatlay",
            challengeDescription: "Create a flat-lay photo that clearly includes both a book and a candle.",
            iconName: "3candles",
            category: .fun,
            points: 75,
            requirementText: "Submit a flat-lay photo featuring a book and a candle.",
            requiredThemes: ["book", "candle", "flat lay", "styled photo"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Bookstagram Shot",
            challengeDescription: "Style a book photo with intentional composition, props, background, or visual setup.",
            iconName: "instagram",
            category: .fun,
            points: 75,
            requirementText: "Submit a styled photo of a book.",
            requiredThemes: ["styled book photo", "book", "props", "composition", "bookstagram"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Share Your Current Read",
            challengeDescription: "Show the book you are currently reading in a clear photo.",
            iconName: "openbook",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of the book you're currently reading.",
            requiredThemes: ["current read", "book", "currently reading"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Recommend A Book",
            challengeDescription: "Show a book you would recommend to someone else.",
            iconName: "starbook",
            category: .fun,
            points: 60,
            requirementText: "Submit a photo of a book you'd recommend.",
            requiredThemes: ["recommended book", "book", "recommendation"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Lend A Book",
            challengeDescription: "Show a book ready to lend, gift, hand off, or set aside for someone else.",
            iconName: "handbook",
            category: .fun,
            points: 65,
            requirementText: "Submit a photo of a book ready to lend.",
            requiredThemes: ["book", "ready to lend", "gift", "hand off"],
            recurring: true
        ),
        photoProofChallenge(
            title: "Book Club Night",
            challengeDescription: "Show a book club meeting, table, stack, notes, snacks, chairs, or another clear book club setup.",
            iconName: "groupfill",
            category: .fun,
            points: 80,
            requirementText: "Submit a photo of a book club meeting or setup.",
            requiredThemes: ["book club", "meeting setup", "books", "group reading", "discussion setup"],
            recurring: true
        ),
    ]

    private static func photoProofChallenge(
        title: String,
        challengeDescription: String,
        iconName: String,
        category: ChallengeCategory,
        points: Int,
        requirementText: String,
        requiredThemes: [String],
        recurring: Bool
    ) -> ReadingChallenge {
        ReadingChallenge(
            title: title,
            challengeDescription: challengeDescription,
            iconName: iconName,
            category: category,
            points: points,
            durationDays: 1,
            requirementText: requirementText,
            validationType: .experience,
            requiredThemes: requiredThemes,
            requiresAIValidation: true,
            recurrence: recurring ? .daily : .oneTime
        )
    }

    // MARK: - Fun Challenges

    static let funChallenges: [ReadingChallenge] = [
        ReadingChallenge(
            title: "Coffee & Chapters",
            challengeDescription: "Brew your favorite drink or fill a bottle. A visible cup, mug, tumbler, bottle, thermos, or beverage container counts as proof.",
            iconName: "lovecup",
            category: .fun,
            points: 100,
            durationDays: 1,
            requirementText: "Submit photo proof of a cup, mug, tumbler, bottle, thermos, or beverage container.",
            validationType: .experience,
            requiredSessionCount: 5,
            requiredThemes: ["coffee", "tea", "beverage", "cup", "mug", "bottle", "tumbler", "thermos", "beverage container"],
            requiresAIValidation: true,
            isWeekly: true
        ),
        ReadingChallenge(
            title: "Rainy Day Reader",
            challengeDescription: "There's something magical about reading while the world slows down outside. Whether it's rain tapping on the windows or simply a quiet afternoon, embrace the cozy atmosphere.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 30,
            requirementText: "Complete 3 reading sessions on rainy days.",
            validationType: .experience,
            requiredSessionCount: 3,
            requiredThemes: ["rain", "rainy day", "cozy", "atmosphere"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Cozy Reading Night",
            challengeDescription: "Blankets, pillows, soft lighting, and a great story—create the ultimate cozy reading experience and enjoy an evening that's impossible to rush.",
            iconName: "lovecup",
            category: .fun,
            points: 150,
            durationDays: 14,
            requirementText: "Complete 3 evening reading sessions lasting at least 45 minutes each.",
            validationType: .readingSession,
            requiredSessionCount: 3,
            requiredSessionMinutes: 45
        ),
        ReadingChallenge(
            title: "Candlelight Reader",
            challengeDescription: "Dim the lights, light a candle, and let the atmosphere become part of the story. Turn an ordinary reading session into something unforgettable.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 14,
            requirementText: "Complete 3 reading sessions with a cozy candlelight mood.",
            validationType: .experience,
            requiredSessionCount: 3,
            requiredThemes: ["candlelight", "candle", "cozy", "atmosphere"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Before Bed Reader",
            challengeDescription: "Trade late-night scrolling for a few peaceful chapters. End your evenings with stories instead of screens and create a relaxing bedtime ritual.",
            iconName: "moonzs",
            category: .fun,
            points: 200,
            durationDays: 14,
            requirementText: "Complete 10 bedtime reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 10
        ),
        ReadingChallenge(
            title: "Screen Free Reader",
            challengeDescription: "Disconnect from notifications and reconnect with stories. Give yourself uninterrupted reading time without the distractions of your digital world.",
            iconName: "openbook",
            category: .fun,
            points: 250,
            durationDays: 21,
            requirementText: "Complete 7 reading sessions with Focus Mode enabled.",
            validationType: .experience,
            requiredSessionCount: 7,
            requiresAIValidation: false
        ),
        ReadingChallenge(
            title: "Read With Music",
            challengeDescription: "The right soundtrack can make every page feel cinematic. Pair your reading with music that enhances the mood and disappear into another world.",
            iconName: "lovecup",
            category: .fun,
            points: 125,
            durationDays: 14,
            requirementText: "Complete 5 reading sessions while using a reading playlist.",
            validationType: .experience,
            requiredSessionCount: 5,
            requiredThemes: ["music", "playlist", "soundtrack", "reading music"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Dragon Rider",
            challengeDescription: "Only the bold earn the trust of dragons. Venture into worlds filled with legendary beasts, ancient kingdoms, magical battles, and unforgettable adventures.",
            iconName: "sparklybook",
            category: .fun,
            points: 300,
            durationDays: 60,
            requirementText: "Finish 3 fantasy books featuring dragons.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["dragons", "dragon rider", "dragon fantasy"],
            requiresAIValidation: true,
            isFeatured: true
        ),
        ReadingChallenge(
            title: "Fantasy Apprentice",
            challengeDescription: "Every great mage starts somewhere. Begin your magical education with stories full of spells, enchanted worlds, magical creatures, and impossible adventures.",
            iconName: "wand",
            category: .fun,
            points: 250,
            durationDays: 45,
            requirementText: "Finish 2 fantasy books centered around magic.",
            validationType: .seasonalTheme,
            requiredBookCount: 2,
            requiredThemes: ["magic", "spells", "enchantment", "wizardry"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Royal Reader",
            challengeDescription: "Walk among queens, kings, princes, princesses, and noble houses. Read stories filled with courts, kingdoms, politics, power, and unforgettable rulers.",
            iconName: "sparklybook",
            category: .fun,
            points: 250,
            durationDays: 45,
            requirementText: "Finish 3 books featuring royalty or noble courts.",
            validationType: .seasonalTheme,
            requiredBookCount: 3,
            requiredThemes: ["royalty", "kings", "queens", "court", "kingdom", "noble"],
            requiresAIValidation: true
        ),
        ReadingChallenge(
            title: "Story Collector",
            challengeDescription: "Every finished book becomes another story you'll carry with you forever. Build a growing collection of completed adventures, unforgettable characters, and memorable worlds.",
            iconName: "bookstack",
            category: .fun,
            points: 500,
            durationDays: 90,
            requirementText: "Finish 10 books from 10 different authors.",
            validationType: .author,
            requiredBookCount: 10,
            requiredUniqueAuthorCount: 10
        ),
        ReadingChallenge(
            title: "Bookworm",
            challengeDescription: "You don't just enjoy books—you live among them. Read consistently, explore new stories, and proudly embrace your inner bookworm.",
            iconName: "bookstack",
            category: .fun,
            points: 750,
            durationDays: 90,
            requirementText: "Complete 30 reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 30
        ),
        ReadingChallenge(
            title: "Bookworm In Training",
            challengeDescription: "Every lifelong reader starts with a single page. Build the habit one reading session at a time and watch your love of books continue to grow.",
            iconName: "bookstack",
            category: .fun,
            points: 200,
            durationDays: 60,
            requirementText: "Complete 15 reading sessions.",
            validationType: .readingSession,
            requiredSessionCount: 15
        ),
        ReadingChallenge(
            title: "Shelf Explorer",
            challengeDescription: "Hidden among your shelves are books waiting patiently for their turn. Rediscover forgotten titles and give overlooked stories the attention they deserve.",
            iconName: "bookstand",
            category: .fun,
            points: 300,
            durationDays: 90,
            requirementText: "Finish 3 books that have been in your library for over one year.",
            validationType: .bookCompletion,
            requiredBookCount: 3
        ),
    ]
}
