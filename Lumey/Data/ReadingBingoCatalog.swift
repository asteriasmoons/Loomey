//
//  ReadingBingoCatalog.swift
//  Lumey
//

import Foundation
import SwiftUI

struct ReadingBingoBoardDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let accent: ReadingBingoAccentIdentity
    let squares: [ReadingBingoSquareDefinition]
}

struct ReadingBingoSquareDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let row: Int
    let column: Int
    let allowsBookSelection: Bool
    let isFreeSpace: Bool
}

struct ReadingBingoAccentIdentity: Hashable {
    let primaryHex: String
    let secondaryHex: String
    let tertiaryHex: String

    var primaryColor: Color { Color(lumeyHex: primaryHex) }
    var secondaryColor: Color { Color(lumeyHex: secondaryHex) }
    var tertiaryColor: Color { Color(lumeyHex: tertiaryHex) }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor, tertiaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var softGradient: LinearGradient {
        LinearGradient(
            colors: [
                primaryColor.opacity(0.26),
                secondaryColor.opacity(0.20),
                tertiaryColor.opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum ReadingBingoCatalog {
    static let boardSize = 5
    static let centerPosition = (row: 2, column: 2)

    static let allBoards: [ReadingBingoBoardDefinition] = [
        makeBoard(
            id: "reading-bingo",
            title: "Reading Bingo",
            description: "A broad reading variety board built to nudge your next picks in fresh directions.",
            iconName: "openbook",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#6F8462",
                secondaryHex: "#8CA17E",
                tertiaryHex: "#B1C0A2"
            ),
            challenges: [
                seed("Debut Novel", "Complete this square with a debut novel and link the book you used."),
                seed("Under 300 Pages", "Choose a book under 300 pages and link it here when you complete the square."),
                seed("Multiple POVs", "Use a book told through more than one point of view for this square."),
                seed("New-to-You Author", "Read a book by an author you have never tried before and link it here."),
                seed("Backlist Book", "Pick a backlist title that has been out for a while and use it for this square."),
                seed("Published This Year", "Use a book published this year and link it when you complete the challenge."),
                seed("Genre Detour", "Choose a genre you do not read often and use that book for this square."),
                seed("Cold Setting", "Use a book set somewhere cold, wintry, or icy and link it here."),
                seed("Forty-Plus Lead", "Pick a book with a main character older than forty and use it for this square."),
                seed("Audiobook Read", "Use an audiobook for this square and link the title you listened to."),
                seed("Blue Cover", "Choose a book with a clearly blue cover and link it when you mark this square complete."),
                seed("Series Starter", "Use the first book in a series for this square."),
                seed("Standalone", "Pick a standalone book with no sequel required and link it here."),
                seed("Recommended Read", "Use a book somebody recommended to you for this square."),
                seed("Library Borrow", "Choose a library book and link it when you finish this square."),
                seed("One-Word Title", "Use a book with a one-word title for this square."),
                seed("Nonfiction Pick", "Choose a nonfiction book and link it here."),
                seed("Award Buzz", "Use a book that won or was nominated for an award for this square."),
                seed("Favorite Trope", "Pick a book with one of your favorite tropes and use it for this square."),
                seed("Translated Work", "Choose a book translated into English and link it here."),
                seed("Friendship Focus", "Use a book where friendship is a major part of the story."),
                seed("Book Club Worthy", "Pick a book you think would make a strong book club discussion title."),
                seed("Mood Read", "Choose a book because it matched your mood and use it for this square."),
                seed("Unexpected Five-Star", "Use a book you did not expect to love as much as you did for this square.")
            ]
        ),
        makeBoard(
            id: "of-the-tropes",
            title: "Of the Tropes",
            description: "A full board of beloved, messy, dramatic, and irresistible literary tropes.",
            iconName: "starmark",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#71445F",
                secondaryHex: "#8E5B79",
                tertiaryHex: "#B483A0"
            ),
            challenges: [
                seed("Enemies to Lovers", "Use a book featuring enemies to lovers for this square."),
                seed("Found Family", "Choose a book with a found family dynamic and link it here."),
                seed("Slow Burn", "Use a book with a true slow-burn relationship or arc for this square."),
                seed("Chosen One", "Pick a book centered on a chosen one storyline."),
                seed("Only One Bed", "Use a book with the only-one-bed trope for this square."),
                seed("Morally Gray", "Choose a book led by a morally gray character and link it here."),
                seed("Second Chance", "Use a book with a second-chance relationship or reunion arc."),
                seed("Forced Proximity", "Pick a book where the characters are forced into close quarters."),
                seed("Hidden Identity", "Use a book with a secret identity or concealed truth at its core."),
                seed("Fake Dating", "Choose a book featuring fake dating for this square."),
                seed("Unreliable Narrator", "Use a book with an unreliable narrator and link it here."),
                seed("Friends to Lovers", "Pick a book built around friends to lovers."),
                seed("Forbidden Love", "Use a book with a forbidden relationship or impossible attachment."),
                seed("Grumpy Sunshine", "Choose a grumpy-sunshine dynamic for this square."),
                seed("Time Loop", "Use a book with a time loop or repeating-day element."),
                seed("Quest Story", "Pick a book built around a quest or mission."),
                seed("Secret Society", "Use a book featuring a secret society, hidden order, or exclusive group."),
                seed("Marriage Deal", "Choose a marriage of convenience or arranged marriage story."),
                seed("Fish Out of Water", "Use a book where a character is badly out of their element."),
                seed("Childhood Friends", "Pick a book featuring childhood friends or a shared past."),
                seed("Revenge Plot", "Use a book driven by revenge and link it here."),
                seed("Mentor Bond", "Choose a book with a strong mentor-student relationship."),
                seed("Locked Room", "Use a locked-room mystery or trapped-setting story for this square."),
                seed("Shadow World", "Pick a book where a hidden magical or secret world exists alongside the normal one.")
            ]
        ),
        makeBoard(
            id: "romance-special",
            title: "Romance Special",
            description: "A romance-only board filled with subgenres, setups, and chemistry-forward prompts.",
            iconName: "openlovebook",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#A45D76",
                secondaryHex: "#C47993",
                tertiaryHex: "#E0A8BB"
            ),
            challenges: [
                seed("Small-Town Romance", "Use a small-town romance for this square."),
                seed("Sports Romance", "Choose a sports romance and link it here."),
                seed("Fantasy Romance", "Use a fantasy romance for this square."),
                seed("Historical Romance", "Choose a historical romance and link it here."),
                seed("Second-Chance Romance", "Use a second-chance romance for this square."),
                seed("Workplace Romance", "Choose a workplace romance and link it here."),
                seed("Rivals to Lovers", "Use a romance with a rivals-to-lovers setup."),
                seed("Slow Burn Romance", "Pick a romance with a true slow burn for this square."),
                seed("Fake Dating Romance", "Use a fake dating romance and link it here."),
                seed("One Bed Romance", "Choose a romance with an only-one-bed moment."),
                seed("Paranormal Romance", "Use a paranormal romance for this square."),
                seed("Queer Romance", "Choose a queer romance and link it here."),
                seed("Romantic Suspense", "Use a romantic suspense title for this square."),
                seed("Marriage of Convenience", "Choose a marriage-of-convenience romance and link it here."),
                seed("Friends to Lovers", "Use a friends-to-lovers romance for this square."),
                seed("Holiday Romance", "Choose a holiday romance and link it here."),
                seed("Dark Romance", "Use a dark romance for this square."),
                seed("Billionaire Romance", "Choose a billionaire romance and link it here."),
                seed("Road Trip Romance", "Use a road trip romance for this square."),
                seed("Cozy Romance", "Choose a soft, cozy romance and link it here."),
                seed("Single Parent Romance", "Use a single-parent romance for this square."),
                seed("Forbidden Romance", "Choose a forbidden romance and link it here."),
                seed("Series Romance", "Use a romance that belongs to a series for this square."),
                seed("Bookish Romance", "Choose a romance with a bookish character, setting, or reading-centered vibe.")
            ]
        ),
        makeBoard(
            id: "reading-slump-cure",
            title: "Reading Slump Cure",
            description: "A recovery board designed to make reading feel easier, lighter, faster, or simply more fun again.",
            iconName: "sparklebrush",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#6C648C",
                secondaryHex: "#857DA5",
                tertiaryHex: "#ACA2C8"
            ),
            challenges: [
                seed("Under 250 Pages", "Use a book under 250 pages for a low-pressure win."),
                seed("Comfort Reread", "Choose a comfort reread and link it here."),
                seed("Audiobook Rescue", "Use an audiobook to help restart your reading momentum."),
                seed("Graphic Novel", "Choose a graphic novel, manga, or illustrated format for this square."),
                seed("Fast-Paced Thriller", "Use a quick, fast-paced thriller for this square."),
                seed("Easy Romance", "Choose a romance that feels easy to fall into and link it here."),
                seed("Cozy Fantasy", "Use a cozy fantasy or gentle speculative read for this square."),
                seed("Short Nonfiction", "Choose short nonfiction, essays, or a compact factual read."),
                seed("Favorite Author", "Use a book by an author you already trust."),
                seed("Short Chapters", "Choose a book with short chapters for this square."),
                seed("Standalone Ease", "Use a standalone so you do not have to commit to a series."),
                seed("Most Anticipated", "Choose a book you were genuinely excited about before the slump."),
                seed("Buddy Read", "Use a buddy read or shared read for accountability."),
                seed("Beautiful Writing", "Choose a book known for prose that pulls you in quickly."),
                seed("Essay Collection", "Use essays, stories, or a collection format for this square."),
                seed("Current List Pick", "Choose a book already sitting on one of your reading lists."),
                seed("Makes You Laugh", "Use a book likely to make you laugh or grin."),
                seed("Already Started", "Choose a book you already began and use it to get moving again."),
                seed("Young Adult", "Use a YA book for this square."),
                seed("Twisty Mystery", "Choose a mystery with enough momentum to keep you turning pages."),
                seed("Strong Opening", "Use a book famous for hooking readers immediately."),
                seed("Library Hold", "Choose a library book with a due date for built-in urgency."),
                seed("Weekend Finish", "Use a book you believe you can finish in a weekend."),
                seed("Tiny Win", "Choose a book that feels like a manageable, confidence-building win.")
            ]
        ),
        makeBoard(
            id: "physical-does-matter",
            title: "Physical Does Matter",
            description: "A tactile board focused on covers, editions, thickness, formats, and shelf-worthy physical details.",
            iconName: "linedpages",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#A9643B",
                secondaryHex: "#C57D4F",
                tertiaryHex: "#DEA26F"
            ),
            challenges: [
                seed("Sprayed Edges", "Use a book with sprayed, painted, or decorated edges for this square."),
                seed("Floppy Paperback", "Choose a floppy paperback and link it here."),
                seed("Hardcover Jacket", "Use a hardcover with a dust jacket for this square."),
                seed("Illustrated Cover", "Choose a book with an illustrated cover and link it here."),
                seed("One-Word Title", "Use a physical book with a one-word title for this square."),
                seed("Long Title", "Choose a book with a long or dramatic title and link it here."),
                seed("Pocket-Sized", "Use a small-format physical book for this square."),
                seed("Chunky Book", "Choose a thick physical book that feels substantial in your hands."),
                seed("Special Edition", "Use a special, deluxe, collector, or subscription edition."),
                seed("Signed Copy", "Choose a signed book for this square."),
                seed("Textured Cover", "Use a book with textured, embossed, or patterned cover details."),
                seed("Pretty Spine", "Choose a book with a spine you genuinely love."),
                seed("Deckled Pages", "Use a book with deckled edges or visibly uneven page edges."),
                seed("Foil Details", "Choose a book with foil, metallic, or reflective cover details."),
                seed("Annotated Copy", "Use a physical book you have already annotated or want to annotate."),
                seed("Face-Out Worthy", "Choose a book you would display face-out on a shelf."),
                seed("New Purchase", "Use a physical book you recently bought."),
                seed("Old Favorite Copy", "Choose a worn or well-loved physical copy for this square."),
                seed("Library Hardcover", "Use a physical library book for this square."),
                seed("Minimal Cover", "Choose a book with a simple or minimalist physical design."),
                seed("Gorgeous Endpapers", "Use a book with endpapers, interior art, or beautiful inside details."),
                seed("Color Match", "Choose a book whose cover color matches your mood or current setup."),
                seed("Shelf Surprise", "Use a physical book you forgot you owned until you spotted it on your shelf."),
                seed("Judged by the Cover", "Choose a physical book mainly because the cover pulled you in.")
            ]
        ),
        makeBoard(
            id: "destroy-your-tbr",
            title: "Destroy Your TBR",
            description: "A backlog board dedicated to the books already waiting on your shelves, devices, and lists.",
            iconName: "bookstack",
            accent: ReadingBingoAccentIdentity(
                primaryHex: "#9F565C",
                secondaryHex: "#BC6D71",
                tertiaryHex: "#DB9796"
            ),
            challenges: [
                seed("Oldest TBR Book", "Choose one of the oldest unread books on your TBR and use it here."),
                seed("Gifted and Unread", "Use a book you were gifted but still have not read."),
                seed("Owned Sequel", "Choose a sequel you already own and have been avoiding."),
                seed("Impulse Buy", "Use an impulse purchase that has been sitting on your TBR."),
                seed("Under 300 TBR", "Choose a short TBR book under 300 pages."),
                seed("Over 500 TBR", "Use a longer TBR book over 500 pages for this square."),
                seed("Forgot I Owned It", "Choose a TBR book you forgot was even in your collection."),
                seed("Preorder Finally Read", "Use a once-preordered book that still made it onto the backlog."),
                seed("Backlist TBR", "Choose an older backlist title from your TBR."),
                seed("Shelf Sitter", "Use a book that has physically sat on your shelf for ages."),
                seed("Digital TBR", "Choose an unread ebook or audiobook already waiting in your library."),
                seed("Bought for the Cover", "Use a TBR book you bought mainly because it looked good."),
                seed("Author You Meant to Try", "Choose a long-delayed first read from an author you meant to get to."),
                seed("Recommended Then Shelved", "Use a recommendation that somehow still ended up buried on your TBR."),
                seed("Unread Nonfiction", "Choose an unread nonfiction title from your TBR."),
                seed("Standalone TBR", "Use a standalone already waiting on your TBR."),
                seed("Series Starter TBR", "Choose an unread first-in-series already sitting in your stack."),
                seed("Highest Rated TBR", "Use one of the TBR books you expect to rate highly."),
                seed("Seasonal TBR", "Choose a TBR book that fits the current season or vibe."),
                seed("Moved House With It", "Use a book you have hauled from one place to another without reading."),
                seed("Current List Backlog", "Choose an unread book already sitting on one of your Loomey lists."),
                seed("Friend-Hyped TBR", "Use a TBR book a friend keeps telling you to read."),
                seed("Scared to Start", "Choose a TBR book you have been intimidated to begin."),
                seed("Finish the Wait", "Pick any long-delayed TBR and finally give it this square.")
            ]
        )
    ]

    static func definition(for boardID: String) -> ReadingBingoBoardDefinition? {
        allBoards.first { $0.id == boardID }
    }

    private static func seed(
        _ title: String,
        _ description: String,
        allowsBookSelection: Bool = true
    ) -> ReadingBingoSeed {
        ReadingBingoSeed(
            title: title,
            description: description,
            allowsBookSelection: allowsBookSelection
        )
    }

    private static func makeBoard(
        id: String,
        title: String,
        description: String,
        iconName: String,
        accent: ReadingBingoAccentIdentity,
        challenges: [ReadingBingoSeed]
    ) -> ReadingBingoBoardDefinition {
        precondition(challenges.count == 24, "\(title) must contain exactly 24 challenges.")

        var squares: [ReadingBingoSquareDefinition] = []
        var challengeIndex = 0

        for row in 0..<boardSize {
            for column in 0..<boardSize {
                if row == centerPosition.row && column == centerPosition.column {
                    squares.append(
                        ReadingBingoSquareDefinition(
                            id: "\(id)-free-space",
                            title: "FREE",
                            description: "This center space starts completed automatically.",
                            row: row,
                            column: column,
                            allowsBookSelection: false,
                            isFreeSpace: true
                        )
                    )
                    continue
                }

                let challenge = challenges[challengeIndex]
                squares.append(
                    ReadingBingoSquareDefinition(
                        id: "\(id)-square-\(challengeIndex)",
                        title: challenge.title,
                        description: challenge.description,
                        row: row,
                        column: column,
                        allowsBookSelection: challenge.allowsBookSelection,
                        isFreeSpace: false
                    )
                )
                challengeIndex += 1
            }
        }

        return ReadingBingoBoardDefinition(
            id: id,
            title: title,
            description: description,
            iconName: iconName,
            accent: accent,
            squares: squares
        )
    }
}

private struct ReadingBingoSeed {
    let title: String
    let description: String
    let allowsBookSelection: Bool
}
