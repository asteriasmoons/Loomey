//
//  ReadingGenresData.swift
//  Lumey
//

import Foundation

struct ReadingGenreCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subgenres: [String]
}

enum ReadingGenresData {
    
    static let all: [ReadingGenreCategory] = [
        
        ReadingGenreCategory(
            name: "Fantasy",
            subgenres: [
                "Romantasy",
                "Epic Fantasy",
                "High Fantasy",
                "Low Fantasy",
                "Dark Fantasy",
                "Cozy Fantasy",
                "Grimdark",
                "Heroic Fantasy",
                "Sword and Sorcery",
                "Portal Fantasy",
                "Urban Fantasy",
                "Historical Fantasy",
                "Gaslamp Fantasy",
                "Steampunk Fantasy",
                "Mythic Fantasy",
                "Fairy Tale Fantasy",
                "Gothic Fantasy",
                "Whimsical Fantasy",
                "Academy Fantasy",
                "Political Fantasy",
                "Military Fantasy",
                "Pirate Fantasy",
                "Desert Fantasy",
                "Quest Fantasy",
                "Dragon Rider Fantasy",
                "Fae Fantasy",
                "Witch Fantasy",
                "Vampire Fantasy",
                "Demon Fantasy",
                "Celestial Fantasy",
                "Divine Fantasy",
                "Dungeon Fantasy",
                "LitRPG Fantasy",
                "Progression Fantasy",
                "Cottagecore Fantasy",
                "Nature Fantasy",
                "Royal Fantasy",
                "Villainess Fantasy",
                "Reincarnation Fantasy",
                "Time Loop Fantasy",
                "Post-Apocalyptic Fantasy",
                "Space Fantasy",
                "Science Fantasy"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Romance",
            subgenres: [
                "Contemporary Romance",
                "Dark Romance",
                "Sports Romance",
                "Small Town Romance",
                "Billionaire Romance",
                "Mafia Romance",
                "Cowboy Romance",
                "Western Romance",
                "Rockstar Romance",
                "Celebrity Romance",
                "Royal Romance",
                "Workplace Romance",
                "College Romance",
                "Holiday Romance",
                "Paranormal Romance",
                "Fantasy Romance",
                "Gothic Romance",
                "Historical Romance",
                "Regency Romance",
                "Victorian Romance",
                "Monster Romance",
                "Alien Romance",
                "Sci-Fi Romance",
                "LGBTQ+ Romance",
                "Sapphic Romance",
                "Gay Romance",
                "Poly Romance",
                "Erotic Romance",
                "Sweet Romance",
                "Clean Romance",
                "Christian Romance",
                "New Adult Romance",
                "Romantic Suspense",
                "Romantic Comedy",
                "Angst Romance",
                "Emotional Romance",
                "Slow Burn Romance",
                "Spicy Romance"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Horror",
            subgenres: [
                "Psychological Horror",
                "Cosmic Horror",
                "Gothic Horror",
                "Folk Horror",
                "Body Horror",
                "Paranormal Horror",
                "Occult Horror",
                "Religious Horror",
                "Survival Horror",
                "Slasher Horror",
                "Extreme Horror",
                "Splatterpunk",
                "Haunted House Horror",
                "Monster Horror",
                "Creature Horror",
                "Vampire Horror",
                "Zombie Horror",
                "Small Town Horror",
                "Arctic Horror",
                "Ocean Horror",
                "Wilderness Horror",
                "Sci-Fi Horror",
                "Apocalypse Horror",
                "Medical Horror",
                "Southern Gothic Horror",
                "Atmospheric Horror",
                "Analog Horror",
                "Existential Horror",
                "Cozy Horror"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Science Fiction",
            subgenres: [
                "Space Opera",
                "Hard Sci-Fi",
                "Soft Sci-Fi",
                "Cyberpunk",
                "Biopunk",
                "Solarpunk",
                "Steampunk",
                "Dieselpunk",
                "Atompunk",
                "Alien Invasion",
                "First Contact",
                "Military Sci-Fi",
                "Time Travel Sci-Fi",
                "Dystopian Sci-Fi",
                "Utopian Sci-Fi",
                "Post-Apocalyptic Sci-Fi",
                "AI Sci-Fi",
                "Robotics Sci-Fi",
                "Climate Sci-Fi",
                "Multiverse Sci-Fi",
                "Simulation Sci-Fi",
                "Galactic Empire Sci-Fi",
                "Space Exploration",
                "Colony Sci-Fi"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Thriller & Mystery",
            subgenres: [
                "Psychological Thriller",
                "Domestic Thriller",
                "Crime Thriller",
                "Political Thriller",
                "Spy Thriller",
                "Legal Thriller",
                "Medical Thriller",
                "Tech Thriller",
                "Action Thriller",
                "Survival Thriller",
                "Mystery Thriller",
                "Noir Thriller",
                "Cozy Mystery",
                "Detective Mystery",
                "Amateur Sleuth",
                "Locked Room Mystery",
                "Academic Mystery",
                "Historical Mystery",
                "Paranormal Mystery"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Contemporary Fiction",
            subgenres: [
                "Literary Fiction",
                "Women’s Fiction",
                "Coming-of-Age",
                "Family Drama",
                "Slice of Life",
                "Character-Driven Fiction",
                "Emotional Fiction",
                "Relationship Fiction",
                "Mental Health Fiction",
                "Small Town Fiction",
                "Magical Realism",
                "Book Club Fiction",
                "Sad Girl Fiction",
                "Healing Fiction",
                "Trauma Fiction",
                "Feminist Fiction"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Historical Fiction",
            subgenres: [
                "Ancient Historical",
                "Medieval Historical",
                "Renaissance Historical",
                "Regency Historical",
                "Victorian Historical",
                "WWI Fiction",
                "WWII Fiction",
                "Cold War Fiction",
                "Historical Adventure",
                "Historical Fantasy",
                "Historical Mystery",
                "Historical Romance"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Young Adult",
            subgenres: [
                "YA Fantasy",
                "YA Romance",
                "YA Horror",
                "YA Sci-Fi",
                "YA Thriller",
                "YA Contemporary",
                "YA Mystery",
                "YA Dystopian",
                "YA Paranormal",
                "YA Dark Academia",
                "YA Coming-of-Age"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Dark Academia",
            subgenres: [
                "Academic Thriller",
                "Scholarly Mystery",
                "Elite School Fiction",
                "Secret Society Fiction",
                "Occult Academia",
                "Philosophical Academia",
                "Light Academia"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Adventure",
            subgenres: [
                "Survival Adventure",
                "Expedition Adventure",
                "Treasure Hunt",
                "Pirate Adventure",
                "Ocean Adventure",
                "Jungle Adventure",
                "Mountain Adventure",
                "Desert Adventure",
                "Arctic Adventure"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Paranormal",
            subgenres: [
                "Ghost Fiction",
                "Psychic Fiction",
                "Medium Fiction",
                "Supernatural Mystery",
                "Paranormal Romance",
                "Paranormal Horror",
                "Demonology Fiction",
                "Angelic Fiction"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Mythology & Folklore",
            subgenres: [
                "Greek Myth Retelling",
                "Norse Mythology",
                "Celtic Mythology",
                "Slavic Mythology",
                "Egyptian Mythology",
                "Asian Mythology",
                "Arthurian Retelling",
                "Fairy Tale Retelling",
                "Folklore Fiction"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Manga & Graphic",
            subgenres: [
                "Manga",
                "Graphic Novel",
                "Webtoon",
                "Comic Fantasy",
                "Comic Horror",
                "Slice of Life Manga",
                "Shonen",
                "Shojo",
                "Seinen",
                "Josei"
            ]
        ),
        
        ReadingGenreCategory(
            name: "Nonfiction",
            subgenres: [
                "Self-Help",
                "Personal Development",
                "Psychology",
                "Productivity",
                "Mindfulness",
                "Spirituality",
                "Trauma Recovery",
                "Wellness",
                "Habit Building",
                "Philosophy",
                "Science",
                "History",
                "Politics",
                "Technology",
                "Writing Craft",
                "Art & Design",
                "Memoir",
                "Biography",
                "Celebrity Memoir"
            ]
        )
    ]
    
    static let allSubgenres: [String] = all
        .flatMap { $0.subgenres }
        .sorted()

    static let fictionPreferenceGenres: [String] = Array(Set(
        ["Mystery", "Thriller", "Paranormal Romance"]
        + all.filter { $0.name != "Nonfiction" }.flatMap { [$0.name] + $0.subgenres }
    )).sorted()

    static let nonfictionPreferenceGenres: [String] = all.first { $0.name == "Nonfiction" }?.subgenres.sorted() ?? []
}
