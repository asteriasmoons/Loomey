//
//  LumeyIconLibrary.swift
//  Lumey
//

import SwiftUI

// MARK: - Icon Source

enum LumeyIconSource: String, Codable, CaseIterable {
    case asset
    case sfSymbol
}

// MARK: - Icon Item

struct LumeyIconItem: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let source: LumeyIconSource
    let category: String

    init(
        name: String,
        source: LumeyIconSource,
        category: String
    ) {
        self.id = "\(source.rawValue)-\(name)"
        self.name = name
        self.source = source
        self.category = category
    }

    @ViewBuilder
    var image: some View {
        switch source {
        case .asset:
            Image(name)
                .resizable()
                .scaledToFit()

        case .sfSymbol:
            Image(systemName: name)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

// MARK: - Icon Library

enum LumeyIconLibrary {

    // MARK: SF Symbols

    static let sfSymbols: [LumeyIconItem] = [
        .init(name: "bell.fill",                    source: .sfSymbol, category: "Reminders"),
        .init(name: "bell.badge.fill",              source: .sfSymbol, category: "Reminders"),
        .init(name: "calendar",                     source: .sfSymbol, category: "Schedule"),
        .init(name: "calendar.badge.clock",         source: .sfSymbol, category: "Schedule"),
        .init(name: "clock.fill",                   source: .sfSymbol, category: "Time"),
        .init(name: "timer",                        source: .sfSymbol, category: "Time"),
        .init(name: "hourglass",                    source: .sfSymbol, category: "Time"),
        .init(name: "checkmark.circle.fill",        source: .sfSymbol, category: "Tasks"),
        .init(name: "checklist",                    source: .sfSymbol, category: "Tasks"),
        .init(name: "list.bullet.clipboard.fill",   source: .sfSymbol, category: "Tasks"),
        .init(name: "sparkles",                     source: .sfSymbol, category: "Magic"),
        .init(name: "wand.and.stars",               source: .sfSymbol, category: "Magic"),
        .init(name: "moon.stars.fill",              source: .sfSymbol, category: "Magic"),
        .init(name: "star.fill",                    source: .sfSymbol, category: "Favorites"),
        .init(name: "heart.fill",                   source: .sfSymbol, category: "Care"),
        .init(name: "heart.text.square.fill",       source: .sfSymbol, category: "Care"),
        .init(name: "house.fill",                   source: .sfSymbol, category: "Home"),
        .init(name: "book.fill",                    source: .sfSymbol, category: "Reading"),
        .init(name: "bookmark.fill",                source: .sfSymbol, category: "Reading"),
        .init(name: "paintbrush.fill",              source: .sfSymbol, category: "Creative"),
        .init(name: "pencil.and.outline",           source: .sfSymbol, category: "Creative"),
        .init(name: "plus.circle.fill",             source: .sfSymbol, category: "Actions"),
        .init(name: "xmark.circle.fill",            source: .sfSymbol, category: "Actions"),
        .init(name: "trash.fill",                   source: .sfSymbol, category: "Actions"),
        .init(name: "square.and.pencil",            source: .sfSymbol, category: "Writing"),
        .init(name: "note.text",                    source: .sfSymbol, category: "Notes"),
        .init(name: "doc.text.fill",                source: .sfSymbol, category: "Documents"),
        .init(name: "folder.fill",                  source: .sfSymbol, category: "Documents"),
        .init(name: "tag.fill",                     source: .sfSymbol, category: "Tags"),
        .init(name: "link",                         source: .sfSymbol, category: "Links"),
        .init(name: "magnifyingglass",              source: .sfSymbol, category: "Search"),
        .init(name: "person.fill",                  source: .sfSymbol, category: "Profile"),
        .init(name: "gearshape.fill",               source: .sfSymbol, category: "Settings"),
        .init(name: "chart.bar.fill",               source: .sfSymbol, category: "Stats"),
        .init(name: "chart.line.uptrend.xyaxis",    source: .sfSymbol, category: "Stats"),
        .init(name: "flame.fill",                   source: .sfSymbol, category: "Energy"),
        .init(name: "bolt.fill",                    source: .sfSymbol, category: "Energy"),
        .init(name: "gift.fill",                    source: .sfSymbol, category: "Rewards"),
    ]

    // MARK: Asset Icons

    static let assetIcons: [LumeyIconItem] = [

        // Numbers
        .init(name: "0wavy",            source: .asset, category: "Numbers"),
        .init(name: "1wavy",            source: .asset, category: "Numbers"),
        .init(name: "2wavy",            source: .asset, category: "Numbers"),
        .init(name: "3wavy",            source: .asset, category: "Numbers"),
        .init(name: "4wavy",            source: .asset, category: "Numbers"),
        .init(name: "5wavy",            source: .asset, category: "Numbers"),
        .init(name: "6wavy",            source: .asset, category: "Numbers"),
        .init(name: "7wavy",            source: .asset, category: "Numbers"),
        .init(name: "8wavy",            source: .asset, category: "Numbers"),
        .init(name: "9wavy",            source: .asset, category: "Numbers"),

        // Actions
        .init(name: "addwavy",          source: .asset, category: "Actions"),
        .init(name: "arrowdownwavy",    source: .asset, category: "Actions"),
        .init(name: "arrowleftwavy",    source: .asset, category: "Actions"),
        .init(name: "arrowrightwavy",   source: .asset, category: "Actions"),
        .init(name: "arrowupwavy",      source: .asset, category: "Actions"),
        .init(name: "copy",             source: .asset, category: "Actions"),
        .init(name: "downloadfill",      source: .asset, category: "Actions"),
        .init(name: "exit",             source: .asset, category: "Actions"),
        .init(name: "exportfill",       source: .asset, category: "Actions"),
        .init(name: "minuswavy",        source: .asset, category: "Actions"),
        .init(name: "pausewavy",        source: .asset, category: "Actions"),
        .init(name: "play",             source: .asset, category: "Actions"),
        .init(name: "playwavy",         source: .asset, category: "Actions"),
        .init(name: "repeat",           source: .asset, category: "Actions"),
        .init(name: "reset",            source: .asset, category: "Actions"),
        .init(name: "skipwavy",         source: .asset, category: "Actions"),
        .init(name: "stopwavy",         source: .asset, category: "Actions"),
        .init(name: "switch",           source: .asset, category: "Actions"),
        .init(name: "switchleft",       source: .asset, category: "Actions"),
        .init(name: "switchright",      source: .asset, category: "Actions"),
        .init(name: "tap",              source: .asset, category: "Actions"),
        .init(name: "togglesettings",   source: .asset, category: "Actions"),
        .init(name: "trash",            source: .asset, category: "Actions"),
        .init(name: "upload",           source: .asset, category: "Actions"),
        .init(name: "xmarkwavy",        source: .asset, category: "Actions"),

        // Astrology & Spirituality
        .init(name: "3candles",         source: .asset, category: "Spirituality"),
        .init(name: "cauldron",         source: .asset, category: "Spirituality"),
        .init(name: "crystalball",      source: .asset, category: "Spirituality"),
        .init(name: "grimoire",         source: .asset, category: "Spirituality"),
        .init(name: "lovelixir",        source: .asset, category: "Spirituality"),
        .init(name: "moonstar",         source: .asset, category: "Spirituality"),
        .init(name: "moonzs",           source: .asset, category: "Spirituality"),
        .init(name: "planet",           source: .asset, category: "Spirituality"),
        .init(name: "potionbottle",     source: .asset, category: "Spirituality"),
        .init(name: "seefuture",        source: .asset, category: "Spirituality"),
        .init(name: "sparklespotion",   source: .asset, category: "Spirituality"),
        .init(name: "tarot",            source: .asset, category: "Spirituality"),
        .init(name: "tarotcards",       source: .asset, category: "Spirituality"),
        .init(name: "wand",             source: .asset, category: "Spirituality"),

        // Beauty & Skincare
        .init(name: "beautystation",    source: .asset, category: "Beauty"),
        .init(name: "blowdryer",        source: .asset, category: "Beauty"),
        .init(name: "creambottle",      source: .asset, category: "Beauty"),
        .init(name: "creamjar",         source: .asset, category: "Beauty"),
        .init(name: "daycream",         source: .asset, category: "Beauty"),
        .init(name: "fingernail",       source: .asset, category: "Beauty"),
        .init(name: "flatiron",         source: .asset, category: "Beauty"),
        .init(name: "hairbrush",        source: .asset, category: "Beauty"),
        .init(name: "lovebottle",       source: .asset, category: "Beauty"),
        .init(name: "lovedropper",      source: .asset, category: "Beauty"),
        .init(name: "lovedryer",        source: .asset, category: "Beauty"),
        .init(name: "mirrorbottle",     source: .asset, category: "Beauty"),
        .init(name: "nailpolish",       source: .asset, category: "Beauty"),
        .init(name: "nightcream",       source: .asset, category: "Beauty"),
        .init(name: "perfume",          source: .asset, category: "Beauty"),
        .init(name: "razor",            source: .asset, category: "Beauty"),
        .init(name: "stickscara",       source: .asset, category: "Beauty"),
        .init(name: "vanity",           source: .asset, category: "Beauty"),

        // Care & Hearts
        .init(name: "fingersheart",     source: .asset, category: "Care"),
        .init(name: "halfheart",        source: .asset, category: "Care"),
        .init(name: "heartballoon",     source: .asset, category: "Care"),
        .init(name: "heartblockscal",   source: .asset, category: "Care"),
        .init(name: "heartbox",         source: .asset, category: "Care"),
        .init(name: "heartcircle",      source: .asset, category: "Care"),
        .init(name: "hearteye",         source: .asset, category: "Care"),
        .init(name: "heartfill",        source: .asset, category: "Care"),
        .init(name: "hearthand",        source: .asset, category: "Care"),
        .init(name: "heartlinescal",    source: .asset, category: "Care"),
        .init(name: "heartoutline",     source: .asset, category: "Care"),
        .init(name: "heartpulse",       source: .asset, category: "Care"),
        .init(name: "heartsparkle",     source: .asset, category: "Care"),
        .init(name: "heartsum",         source: .asset, category: "Care"),
        .init(name: "hearttag",         source: .asset, category: "Care"),
        .init(name: "heartwavy",        source: .asset, category: "Care"),
        .init(name: "lovebandaid",      source: .asset, category: "Care"),
        .init(name: "lovecards",        source: .asset, category: "Care"),
        .init(name: "lovepills",        source: .asset, category: "Care"),
        .init(name: "lovetarget",       source: .asset, category: "Care"),
        .init(name: "paperhearts",      source: .asset, category: "Care"),
        .init(name: "plusheart",        source: .asset, category: "Care"),
        .init(name: "starshand",        source: .asset, category: "Care"),
        .init(name: "twinheartpage",    source: .asset, category: "Care"),
        .init(name: "twinhearts",       source: .asset, category: "Care"),
        .init(name: "lovegoal",         source: .asset, category: "Care"),

        // Celebration
        .init(name: "batcake",          source: .asset, category: "Celebration"),
        .init(name: "bdaycake",         source: .asset, category: "Celebration"),
        .init(name: "cake",             source: .asset, category: "Celebration"),
        .init(name: "dotcake",          source: .asset, category: "Celebration"),
        .init(name: "goodiebag",        source: .asset, category: "Celebration"),
        .init(name: "heartcal",         source: .asset, category: "Celebration"),
        .init(name: "loveairballoon",   source: .asset, category: "Celebration"),
        .init(name: "partyinvitation",  source: .asset, category: "Celebration"),
        .init(name: "starballoons",     source: .asset, category: "Celebration"),
        .init(name: "starryballoons",   source: .asset, category: "Celebration"),

        // Communication & Social
        .init(name: "bellfill",         source: .asset, category: "Reminders"),
        .init(name: "bells",            source: .asset, category: "Reminders"),
        .init(name: "batmail",          source: .asset, category: "Communication"),
        .init(name: "chatbubble",       source: .asset, category: "Communication"),
        .init(name: "bookchat",         source: .asset, category: "Communication"),
        .init(name: "lovechat",         source: .asset, category: "Communication"),
        .init(name: "pagechat",         source: .asset, category: "Communication"),
        .init(name: "socialchat",       source: .asset, category: "Communication"),
        .init(name: "starchat",         source: .asset, category: "Communication"),
        .init(name: "starchats",        source: .asset, category: "Communication"),
        .init(name: "chatfolder",       source: .asset, category: "Communication"),
        .init(name: "chatlinesfill",    source: .asset, category: "Communication"),
        .init(name: "chatsparkle",      source: .asset, category: "Communication"),
        .init(name: "dotschat",         source: .asset, category: "Communication"),
        .init(name: "webchat",          source: .asset, category: "Communication"),
        .init(name: "announcement",     source: .asset, category: "Communication"),
        .init(name: "megaphone",        source: .asset, category: "Communication"),
        .init(name: "circlemedia",      source: .asset, category: "Social"),
        .init(name: "discord",          source: .asset, category: "Social"),
        .init(name: "facebook",         source: .asset, category: "Social"),
        .init(name: "github",           source: .asset, category: "Social"),
        .init(name: "groupfill",        source: .asset, category: "People"),
        .init(name: "hashtag",          source: .asset, category: "Tags"),
        .init(name: "hashtagcircle",    source: .asset, category: "Tags"),
        .init(name: "hashtagwavy",      source: .asset, category: "Tags"),
        .init(name: "heartphone",       source: .asset, category: "Communication"),
        .init(name: "inbox",            source: .asset, category: "Communication"),
        .init(name: "instagram",        source: .asset, category: "Social"),
        .init(name: "linkcircle",       source: .asset, category: "Links"),
        .init(name: "lovelineschat",    source: .asset, category: "Communication"),
        .init(name: "lovemail",         source: .asset, category: "Communication"),
        .init(name: "luvemail",         source: .asset, category: "Communication"),
        .init(name: "luvmail",          source: .asset, category: "Communication"),
        .init(name: "mailbox",          source: .asset, category: "Communication"),
        .init(name: "micfill",          source: .asset, category: "Communication"),
        .init(name: "profilewavy",      source: .asset, category: "Profile"),
        .init(name: "sendbutton",       source: .asset, category: "Communication"),
        .init(name: "socialeye",        source: .asset, category: "Social"),
        .init(name: "socialicon",       source: .asset, category: "Social"),
        .init(name: "starphone",        source: .asset, category: "Communication"),
        .init(name: "threads",          source: .asset, category: "Social"),

        // Developer & Tech
        .init(name: "bugpillar",        source: .asset, category: "Developer"),
        .init(name: "buggy",            source: .asset, category: "Developer"),
        .init(name: "cellphone",        source: .asset, category: "Tech"),
        .init(name: "cloudsync",        source: .asset, category: "Tech"),
        .init(name: "codewindow",       source: .asset, category: "Developer"),
        .init(name: "device",           source: .asset, category: "Tech"),
        .init(name: "devwavy",          source: .asset, category: "Developer"),
        .init(name: "lovelaptop",       source: .asset, category: "Tech"),
        .init(name: "tools",            source: .asset, category: "Developer"),
        .init(name: "toolsfilled",      source: .asset, category: "Developer"),

        // Documents & Writing
        .init(name: "archivefill",      source: .asset, category: "Documents"),
        .init(name: "blankpages",       source: .asset, category: "Documents"),
        .init(name: "bulletlovenote",   source: .asset, category: "Documents"),
        .init(name: "cardlines",        source: .asset, category: "Documents"),
        .init(name: "decksparkle",      source: .asset, category: "Documents"),
        .init(name: "document",         source: .asset, category: "Documents"),
        .init(name: "filebin",          source: .asset, category: "Documents"),
        .init(name: "files",            source: .asset, category: "Documents"),
        .init(name: "folderfill",       source: .asset, category: "Documents"),
        .init(name: "foldertreefill",   source: .asset, category: "Documents"),
        .init(name: "image",            source: .asset, category: "Documents"),
        .init(name: "imagefill",        source: .asset, category: "Documents"),
        .init(name: "imagesign",        source: .asset, category: "Documents"),
        .init(name: "linedpages",       source: .asset, category: "Documents"),
        .init(name: "lineimagepage",    source: .asset, category: "Documents"),
        .init(name: "linenotepage",     source: .asset, category: "Notes"),
        .init(name: "linescard",        source: .asset, category: "Documents"),
        .init(name: "linespencil",      source: .asset, category: "Writing"),
        .init(name: "lovedocs",         source: .asset, category: "Documents"),
        .init(name: "lovedocslines",    source: .asset, category: "Documents"),
        .init(name: "lovedocument",     source: .asset, category: "Documents"),
        .init(name: "lovelinescard",    source: .asset, category: "Documents"),
        .init(name: "lovelist",         source: .asset, category: "Documents"),
        .init(name: "lovepage",         source: .asset, category: "Documents"),
        .init(name: "lovereceipt",      source: .asset, category: "Documents"),
        .init(name: "pagefold",         source: .asset, category: "Documents"),
        .init(name: "pagepencil",       source: .asset, category: "Writing"),
        .init(name: "outlinelovedocs",  source: .asset, category: "Documents"),
        .init(name: "paintbrush",       source: .asset, category: "Creative"),
        .init(name: "paintdrop",        source: .asset, category: "Creative"),
        .init(name: "pbrush",           source: .asset, category: "Creative"),
        .init(name: "pencil",           source: .asset, category: "Writing"),
        .init(name: "pencilcircle",     source: .asset, category: "Writing"),
        .init(name: "pencilfill",       source: .asset, category: "Writing"),
        .init(name: "pin",              source: .asset, category: "Documents"),
        .init(name: "pinlinednote",     source: .asset, category: "Notes"),
        .init(name: "pinnednote",       source: .asset, category: "Notes"),
        .init(name: "plainpencil",      source: .asset, category: "Writing"),
        .init(name: "sign",             source: .asset, category: "Documents"),
        .init(name: "starlinesdoc",     source: .asset, category: "Documents"),
        .init(name: "sticknote",        source: .asset, category: "Notes"),
        .init(name: "quote",            source: .asset, category: "Notes"),
        .init(name: "starnote",         source: .asset, category: "Notes"),
        .init(name: "writenote",        source: .asset, category: "Writing"),
        .init(name: "writepencil",      source: .asset, category: "Writing"),

        // Energy
        .init(name: "bolt",             source: .asset, category: "Energy"),
        .init(name: "boltsparkle",      source: .asset, category: "Energy"),
        .init(name: "energydrink",      source: .asset, category: "Energy"),
        .init(name: "flame",            source: .asset, category: "Energy"),
        .init(name: "loveflame",        source: .asset, category: "Energy"),
        .init(name: "sparkbolt",        source: .asset, category: "Energy"),

        // Entertainment
        .init(name: "movietix",         source: .asset, category: "Entertainment"),

        // Favorites & Stars
        .init(name: "galaxy",           source: .asset, category: "Favorites"),
        .init(name: "galaxysparkle",    source: .asset, category: "Favorites"),
        .init(name: "loveflag",         source: .asset, category: "Favorites"),
        .init(name: "starcal",          source: .asset, category: "Favorites"),
        .init(name: "starcard",         source: .asset, category: "Favorites"),
        .init(name: "starchart",        source: .asset, category: "Favorites"),
        .init(name: "starcircle",       source: .asset, category: "Favorites"),
        .init(name: "starfill",         source: .asset, category: "Favorites"),
        .init(name: "starhand",         source: .asset, category: "Favorites"),
        .init(name: "starmailing",      source: .asset, category: "Favorites"),
        .init(name: "starsparklesbox",  source: .asset, category: "Favorites"),
        .init(name: "startag",          source: .asset, category: "Favorites"),
        .init(name: "startrophyfill",   source: .asset, category: "Favorites"),
        .init(name: "startrophyhand",   source: .asset, category: "Favorites"),
        .init(name: "startrophyhands",  source: .asset, category: "Favorites"),
        .init(name: "starwavy",         source: .asset, category: "Favorites"),
        .init(name: "starlines",        source: .asset, category: "Favorites"),
        .init(name: "starmark",         source: .asset, category: "Favorites"),
        .init(name: "staroutline",      source: .asset, category: "Favorites"),
        .init(name: "starry",           source: .asset, category: "Favorites"),
        .init(name: "starwindow",       source: .asset, category: "Favorites"),
        .init(name: "stargoal",         source: .asset, category: "Favorites"),
        .init(name: "starskey",         source: .asset, category: "Favorites"),
        .init(name: "sparkletrophy",    source: .asset, category: "Favorites"),
        .init(name: "starstack",        source: .asset, category: "Favorites"),
        .init(name: "circlestarwavy",   source: .asset, category: "Favorites"),
        .init(name: "achievement",      source: .asset, category: "Favorites"),
        .init(name: "sparklesstarflag", source: .asset, category: "Favorites"),

        // Food & Drink
        .init(name: "bottle",           source: .asset, category: "Hydration"),
        .init(name: "bubbles",          source: .asset, category: "Food & Drink"),
        .init(name: "coffeemaker",      source: .asset, category: "Food & Drink"),
        .init(name: "dropfill",         source: .asset, category: "Hydration"),
        .init(name: "dropper",          source: .asset, category: "Hydration"),
        .init(name: "glass",            source: .asset, category: "Hydration"),
        .init(name: "groceries",        source: .asset, category: "Food & Drink"),
        .init(name: "jug",              source: .asset, category: "Hydration"),
        .init(name: "lovecup",          source: .asset, category: "Food & Drink"),
        .init(name: "loveglass",        source: .asset, category: "Hydration"),
        .init(name: "lovesmokes",       source: .asset, category: "Food & Drink"),
        .init(name: "sunflower",        source: .asset, category: "Nature"),
        .init(name: "teapot",           source: .asset, category: "Food & Drink"),

        // Health & Medical
        .init(name: "bandaidheart",     source: .asset, category: "Health"),
        .init(name: "health",           source: .asset, category: "Health"),
        .init(name: "healthicon",       source: .asset, category: "Health"),
        .init(name: "medhand",          source: .asset, category: "Health"),
        .init(name: "medhouse",         source: .asset, category: "Health"),
        .init(name: "medical",          source: .asset, category: "Health"),
        .init(name: "medication",       source: .asset, category: "Health"),
        .init(name: "meditate",         source: .asset, category: "Wellness"),
        .init(name: "medsymbol",        source: .asset, category: "Health"),
        .init(name: "petmeds",          source: .asset, category: "Pets"),
        .init(name: "pilldrop",         source: .asset, category: "Health"),
        .init(name: "pillhand",         source: .asset, category: "Health"),
        .init(name: "pillows",          source: .asset, category: "Home"),
        .init(name: "pillsleeve",       source: .asset, category: "Health"),
        .init(name: "rxbottle",         source: .asset, category: "Health"),
        .init(name: "stethoscope",      source: .asset, category: "Health"),
        .init(name: "tooth",            source: .asset, category: "Health"),
        .init(name: "toothhand",        source: .asset, category: "Health"),
        .init(name: "toothsparklehands", source: .asset, category: "Health"),
        .init(name: "vet",              source: .asset, category: "Pets"),
        .init(name: "zenrocks",         source: .asset, category: "Wellness"),

        // Home & Household
        .init(name: "armchair",         source: .asset, category: "Home"),
        .init(name: "artboard",         source: .asset, category: "Home"),
        .init(name: "bed",              source: .asset, category: "Home"),
        .init(name: "blackwindow",      source: .asset, category: "Home"),
        .init(name: "bucket",           source: .asset, category: "Home"),
        .init(name: "drawers",          source: .asset, category: "Home"),
        .init(name: "fireplace",        source: .asset, category: "Home"),
        .init(name: "flatscreen",       source: .asset, category: "Home"),
        .init(name: "houseoutline",     source: .asset, category: "Home"),
        .init(name: "laundry",          source: .asset, category: "Home"),
        .init(name: "lovehouse",        source: .asset, category: "Home"),
        .init(name: "loveiron",         source: .asset, category: "Home"),
        .init(name: "lovetv",           source: .asset, category: "Home"),
        .init(name: "lovewindow",       source: .asset, category: "Home"),
        .init(name: "shower",           source: .asset, category: "Home"),
        .init(name: "sofa",             source: .asset, category: "Home"),
        .init(name: "spraybottle",      source: .asset, category: "Home"),
        .init(name: "television",       source: .asset, category: "Home"),
        .init(name: "toiletpaper",      source: .asset, category: "Home"),
        .init(name: "towel",            source: .asset, category: "Home"),
        .init(name: "tproll",           source: .asset, category: "Home"),
        .init(name: "washer",           source: .asset, category: "Home"),
        .init(name: "window",           source: .asset, category: "Home"),
        .init(name: "windowheart",      source: .asset, category: "Home"),

        // Journal & Reading
        .init(name: "blankpages",       source: .asset, category: "Reading"),
        .init(name: "bcoll1",           source: .asset, category: "Reading"),
        .init(name: "bcoll2",           source: .asset, category: "Reading"),
        .init(name: "bcoll3",           source: .asset, category: "Reading"),
        .init(name: "bcoll4",           source: .asset, category: "Reading"),
        .init(name: "bcoll5",           source: .asset, category: "Reading"),
        .init(name: "books",            source: .asset, category: "Reading"),
        .init(name: "bookstack",        source: .asset, category: "Reading"),
        .init(name: "bookstand",        source: .asset, category: "Reading"),
        .init(name: "bookmark",         source: .asset, category: "Reading"),
        .init(name: "flatbook",         source: .asset, category: "Reading"),
        .init(name: "flipnotebook",     source: .asset, category: "Reading"),
        .init(name: "handbook",         source: .asset, category: "Reading"),
        .init(name: "linedpages",       source: .asset, category: "Reading"),
        .init(name: "linespiralbook",   source: .asset, category: "Reading"),
        .init(name: "lockheartjournal", source: .asset, category: "Journal"),
        .init(name: "lockhearts",       source: .asset, category: "Security"),
        .init(name: "lovejournal",      source: .asset, category: "Journal"),
        .init(name: "openbook",         source: .asset, category: "Reading"),
        .init(name: "openlovebook",     source: .asset, category: "Reading"),
        .init(name: "sparklybook",      source: .asset, category: "Reading"),
        .init(name: "stackedboxes",     source: .asset, category: "Reading"),
        .init(name: "starbook",         source: .asset, category: "Reading"),
        .init(name: "timebook",         source: .asset, category: "Reading"),

        // Mind & Wellness
        .init(name: "balancewavy",      source: .asset, category: "Wellness"),
        .init(name: "beardoll",         source: .asset, category: "Mood"),
        .init(name: "cloudmind",        source: .asset, category: "Mind"),
        .init(name: "spiralmind",       source: .asset, category: "Mind"),
        .init(name: "xsmile",           source: .asset, category: "Mood"),

        // Movement & Fitness
        .init(name: "dumbbell",         source: .asset, category: "Movement"),
        .init(name: "shoe",             source: .asset, category: "Movement"),

        // Nature
        .init(name: "flower",           source: .asset, category: "Nature"),
        .init(name: "rainbow",          source: .asset, category: "Nature"),
        .init(name: "sun",              source: .asset, category: "Nature"),

        // Navigation & UI
        .init(name: "chevdown",         source: .asset, category: "Navigation"),
        .init(name: "chevleft",         source: .asset, category: "Navigation"),
        .init(name: "chevright",        source: .asset, category: "Navigation"),
        .init(name: "chevup",           source: .asset, category: "Navigation"),
        .init(name: "controls",         source: .asset, category: "Settings"),
        .init(name: "crossroads",       source: .asset, category: "Navigation"),
        .init(name: "dotswavy",         source: .asset, category: "Navigation"),
        .init(name: "eye",              source: .asset, category: "Navigation"),
        .init(name: "eyeslash",         source: .asset, category: "Navigation"),
        .init(name: "incomingurl",      source: .asset, category: "Navigation"),
        .init(name: "indicator",        source: .asset, category: "Navigation"),
        .init(name: "leftbutton",       source: .asset, category: "Navigation"),
        .init(name: "questionwavy",     source: .asset, category: "Navigation"),
        .init(name: "rightbutton",      source: .asset, category: "Navigation"),
        .init(name: "settingswavy",     source: .asset, category: "Settings"),
        .init(name: "slider",           source: .asset, category: "Settings"),

        // Pets
        .init(name: "bat",              source: .asset, category: "Pets"),
        .init(name: "catbowl",          source: .asset, category: "Pets"),
        .init(name: "catface",          source: .asset, category: "Pets"),
        .init(name: "catsleep",         source: .asset, category: "Pets"),
        .init(name: "catstretch",       source: .asset, category: "Pets"),
        .init(name: "deadcat",          source: .asset, category: "Pets"),
        .init(name: "dogface",          source: .asset, category: "Pets"),
        .init(name: "dogstore",         source: .asset, category: "Pets"),
        .init(name: "ghostie",          source: .asset, category: "Pets"),
        .init(name: "handbuggy",        source: .asset, category: "Pets"),
        .init(name: "kennel",           source: .asset, category: "Pets"),
        .init(name: "paw",              source: .asset, category: "Pets"),
        .init(name: "petfeedbottle",    source: .asset, category: "Pets"),
        .init(name: "petfood",          source: .asset, category: "Pets"),
        .init(name: "petmedbottle",     source: .asset, category: "Pets"),
        .init(name: "petpillpack",      source: .asset, category: "Pets"),
        .init(name: "petpaw",           source: .asset, category: "Pets"),

        // Rewards & Goals
        .init(name: "goalsparkle",      source: .asset, category: "Goals"),
        .init(name: "goaltarget",       source: .asset, category: "Goals"),
        .init(name: "award",            source: .asset, category: "Rewards"),
        .init(name: "baraward",         source: .asset, category: "Rewards"),
        .init(name: "levelup",          source: .asset, category: "Rewards"),
        .init(name: "ribbonaward",      source: .asset, category: "Rewards"),
        .init(name: "loveinfinity",     source: .asset, category: "Goals"),
        .init(name: "savesparkle",      source: .asset, category: "Rewards"),
        .init(name: "stargift",         source: .asset, category: "Rewards"),
        .init(name: "starpopgift",      source: .asset, category: "Rewards"),
        .init(name: "startrophy",       source: .asset, category: "Rewards"),
        .init(name: "trophycircle",     source: .asset, category: "Rewards"),
        .init(name: "trophystar",       source: .asset, category: "Rewards"),
        .init(name: "puzzlehand",       source: .asset, category: "Goals"),
        .init(name: "puzzlepiece",      source: .asset, category: "Goals"),

        // Schedule & Calendar
        .init(name: "batcal",           source: .asset, category: "Schedule"),
        .init(name: "blackcal",         source: .asset, category: "Schedule"),
        .init(name: "boocal",           source: .asset, category: "Schedule"),
        .init(name: "calheart",         source: .asset, category: "Schedule"),
        .init(name: "calhearts",        source: .asset, category: "Schedule"),
        .init(name: "circlescal",       source: .asset, category: "Schedule"),
        .init(name: "dotscal",          source: .asset, category: "Schedule"),
        .init(name: "heartcal",         source: .asset, category: "Schedule"),
        .init(name: "lovecalendar",     source: .asset, category: "Schedule"),
        .init(name: "lovedate",         source: .asset, category: "Schedule"),
        .init(name: "numcal",           source: .asset, category: "Schedule"),
        .init(name: "ringstarcal",      source: .asset, category: "Schedule"),
        .init(name: "starcalrings",     source: .asset, category: "Schedule"),
        .init(name: "xoxocal",          source: .asset, category: "Schedule"),

        // Search
        .init(name: "searchsparkle",    source: .asset, category: "Search"),
        .init(name: "searchwavy",       source: .asset, category: "Search"),
        .init(name: "sparklesearch",    source: .asset, category: "Search"),

        // Security
        .init(name: "circlefingerprint",source: .asset, category: "Security"),
        .init(name: "fingerprint",      source: .asset, category: "Security"),
        .init(name: "handkey",          source: .asset, category: "Security"),
        .init(name: "heartlock",        source: .asset, category: "Security"),
        .init(name: "lockwavy",         source: .asset, category: "Security"),

        // Shopping & Money
        .init(name: "groceries",        source: .asset, category: "Shopping"),
        .init(name: "lovemoney",        source: .asset, category: "Money"),
        .init(name: "lovelocation",     source: .asset, category: "Shopping"),
        .init(name: "market",           source: .asset, category: "Shopping"),
        .init(name: "moneybaghands",    source: .asset, category: "Money"),
        .init(name: "moneybills",       source: .asset, category: "Money"),
        .init(name: "monies",           source: .asset, category: "Money"),
        .init(name: "pigbank",          source: .asset, category: "Money"),
        .init(name: "shopbasket",       source: .asset, category: "Shopping"),
        .init(name: "store",            source: .asset, category: "Shopping"),
        .init(name: "threecoins",       source: .asset, category: "Money"),
        .init(name: "trinket",          source: .asset, category: "Shopping"),
        .init(name: "walletfill",       source: .asset, category: "Money"),

        // Sparkles & Whimsy
        .init(name: "cuteslippers",      source: .asset, category: "Whimsy"),
        .init(name: "seedling",         source: .asset, category: "Nature"),
        .init(name: "sparkle",          source: .asset, category: "Whimsy"),
        .init(name: "sparklebrush",     source: .asset, category: "Whimsy"),
        .init(name: "sparklecircle",    source: .asset, category: "Whimsy"),
        .init(name: "sparkletimeglass", source: .asset, category: "Whimsy"),
        .init(name: "starshield",       source: .asset, category: "Whimsy"),
        .init(name: "starry",           source: .asset, category: "Whimsy"),

        // Stats & Charts
        .init(name: "chartboard",       source: .asset, category: "Stats"),
        .init(name: "chartcircle",      source: .asset, category: "Stats"),
        .init(name: "infinity",         source: .asset, category: "Stats"),

        // Tags & Labels
        .init(name: "circledothashtag", source: .asset, category: "Tags"),
        .init(name: "tagsparkle",       source: .asset, category: "Tags"),
        .init(name: "tagstar",          source: .asset, category: "Tags"),
        .init(name: "lovetag",          source: .asset, category: "Tags"),
        .init(name: "markcircle",       source: .asset, category: "Tags"),

        // Time
        .init(name: "clockfill",        source: .asset, category: "Time"),
        .init(name: "clockwavy",        source: .asset, category: "Time"),
        .init(name: "hourglassfill",    source: .asset, category: "Time"),
        .init(name: "timehand",         source: .asset, category: "Time"),

        // Wardrobe & Clothing
        .init(name: "lovecase",         source: .asset, category: "Wardrobe"),
        .init(name: "loveshirt",        source: .asset, category: "Wardrobe"),
        .init(name: "magiccase",        source: .asset, category: "Wardrobe"),

        // Zodiac
        .init(name: "aquarius",         source: .asset, category: "Zodiac"),
        .init(name: "aries",            source: .asset, category: "Zodiac"),
        .init(name: "cancer",           source: .asset, category: "Zodiac"),
        .init(name: "capricorn",        source: .asset, category: "Zodiac"),
        .init(name: "gemini",           source: .asset, category: "Zodiac"),
        .init(name: "leo",              source: .asset, category: "Zodiac"),
        .init(name: "libra",            source: .asset, category: "Zodiac"),
        .init(name: "pisces",           source: .asset, category: "Zodiac"),
        .init(name: "sagittarius",      source: .asset, category: "Zodiac"),
        .init(name: "scorpio",          source: .asset, category: "Zodiac"),
        .init(name: "taurus",           source: .asset, category: "Zodiac"),
        .init(name: "virgo",            source: .asset, category: "Zodiac"),

        // Misc Symbols
        .init(name: "artboard",         source: .asset, category: "Creative"),
        .init(name: "blocks",           source: .asset, category: "Misc"),
        .init(name: "blocksfill",       source: .asset, category: "Misc"),
        .init(name: "checkwavy",        source: .asset, category: "Tasks"),
        .init(name: "infowavy",         source: .asset, category: "Misc"),
        .init(name: "listcircle",       source: .asset, category: "Tasks"),
        .init(name: "objects",          source: .asset, category: "Misc"),
        .init(name: "tombstone",        source: .asset, category: "Misc"),
    ]

    // MARK: - Accessors

    static let allIcons: [LumeyIconItem] = assetIcons + sfSymbols

    static var categories: [String] {
        Array(Set(allIcons.map(\.category))).sorted()
    }

    static func icons(in category: String) -> [LumeyIconItem] {
        allIcons.filter { $0.category == category }
    }

    static func search(_ query: String) -> [LumeyIconItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allIcons }
        return allIcons.filter {
            $0.name.localizedCaseInsensitiveContains(q)
            || $0.category.localizedCaseInsensitiveContains(q)
        }
    }
}
