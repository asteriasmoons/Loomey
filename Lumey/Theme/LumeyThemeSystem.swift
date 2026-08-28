//
//  LumeyThemeSystem.swift
//  Lumey
//
//  Semantic multi-color theme system.
//
//  A theme is defined by FIVE base colors (LumeyBasePalette) named by their
//  role in the visual system: foundation, structure, support, accent, contrast.
//  Universal derivation rules then generate rich semantic families
//  (Surface, Accent, Text, Border, IconContainer, State, Progress) so that
//  ALL FIVE base colors participate throughout the interface — not just one
//  dominant surface + one dominant accent.
//
//  Backward-compat: every previously exposed LColors / LGradients token
//  still resolves. New views should prefer the family accessors
//  (LColors.surface.primary, LColors.accents.contrast, LColors.text.secondary,
//  LColors.border.tertiary, etc.).
//

import Foundation
import Combine
import SwiftUI
import UIKit

// MARK: - Theme enum

enum LumeyAppTheme: String, CaseIterable, Identifiable, Codable {
    case defaultTheme = "default"
    case fairy = "fairy"
    case romance
    case classicDefault = "classic_default"
    case berryNight = "berry_night"
    case darkAcademia
    case electricDark = "electric_dark"
    case emberNight = "ember_night"
    case paperback

    static var selectableThemes: [LumeyAppTheme] {
        [.defaultTheme, .fairy, .darkAcademia, .electricDark, .emberNight]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultTheme:  return "Default"
        case .fairy:         return "Fairy"
        case .romance:       return "Berry Night"
        case .classicDefault:return "Default"
        case .berryNight:    return "Berry Night"
        case .darkAcademia:  return "Dark Academia"
        case .electricDark:  return "Electric Dark"
        case .emberNight:    return "Ember Night"
        case .paperback:     return "Ember Night"
        }
    }

    var subtitle: String {
        switch self {
        case .defaultTheme, .classicDefault:
            return "Periwinkle, steel blue, orchid magenta, and dark ink."
        case .fairy:
            return "Deep plum, royal purple, muted violet, earthy shadow, and pink light."
        case .romance, .berryNight:
            return "Berry pink, aubergine, lilac, and dusky violet."
        case .darkAcademia:   return "Olive stone, inky navy, mauve plum, and weathered purple."
        case .electricDark:   return "Teal current, cobalt, electric violet, and smoky purple."
        case .emberNight, .paperback:
            return "Burnt orange, ember gold, wine, and dark cocoa."
        }
    }

    /// Five base colors that define the theme's identity.
    var basePalette: LumeyBasePalette {
        switch self {
        case .defaultTheme, .classicDefault:
            // DEFAULT
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#1F1726"),
                structure:  Color(lumeyHex: "#2D2237"),
                support:    Color(lumeyHex: "#7659C5"),
                accent:     Color(lumeyHex: "#851F6D"),
                contrast:   Color(lumeyHex: "#5B94CA")
            )
        case .fairy:
            // FAIRY
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#180F2C"),
                structure:  Color(lumeyHex: "#3F1A53"),
                support:    Color(lumeyHex: "#4E3F70"),
                accent:     Color(lumeyHex: "#D2347C"),
                contrast:   Color(lumeyHex: "#5B2B78")
            )
        case .romance, .berryNight:
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#2F2350"),
                structure:  Color(lumeyHex: "#5A1E52"),
                support:    Color(lumeyHex: "#936DEA"),
                accent:     Color(lumeyHex: "#B60A7E"),
                contrast:   Color(lumeyHex: "#720062")
            )
        case .darkAcademia:
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#2A3147"),
                structure:  Color(lumeyHex: "#D2AE69"),
                support:    Color(lumeyHex: "#5A604E"),
                accent:     Color(lumeyHex: "#5A604E"),
                contrast:   Color(lumeyHex: "#D2AE69")
            )
        case .electricDark:
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#17192A"),
                structure:  Color(lumeyHex: "#684899"),
                support:    Color(lumeyHex: "#8B5CF6"),
                accent:     Color(lumeyHex: "#2297AC"),
                contrast:   Color(lumeyHex: "#3E57A0")
            )
        case .emberNight, .paperback:
            return LumeyBasePalette(
                foundation: Color(lumeyHex: "#1C1415"),
                structure:  Color(lumeyHex: "#332627"),
                support:    Color(lumeyHex: "#5A403D"),
                accent:     Color(lumeyHex: "#C65D32"),
                contrast:   Color(lumeyHex: "#C18B3F")
            )
        }
    }

    var palette: LumeyThemePalette {
        LumeyThemePalette(base: basePalette)
    }
}

// MARK: - Base palette (5 named colors)

/// The five colors that define a theme's identity.
/// Every semantic family in the theme system is derived from these.
struct LumeyBasePalette: Equatable {
    let foundation: Color   // darkest — app background
    let structure:  Color   // dark surface — cards, primary structure
    let support:    Color   // mid — secondary surfaces, borders
    let accent:     Color   // dominant bright — primary accent, actions
    let contrast:   Color   // the "pop" — highlights, special, tertiary
}

// MARK: - Semantic families

struct LumeySurfaceScale {
    let primary:   Color
    let secondary: Color
    let tertiary:  Color
    let elevated:  Color
    let featured:  Color
    let subtle:    Color
    let nestedSoft: Color
    let nested: Color
    let nestedStrong: Color
}

struct LumeyAccentScale {
    let primary:   Color
    let secondary: Color
    let tertiary:  Color
    let contrast:  Color
    let special:   Color
}

struct LumeyTextScale {
    let primary:   Color   // near-white
    let secondary: Color   // support-tinted light
    let tertiary:  Color   // accent-tinted light
    let muted:     Color   // low-emphasis gray-tinted
    let heading:   Color   // section / page headings
    let cardTitle: Color   // card titles and strong labels
    let accent:    Color   // accent, brightened for readability
    let contrast:  Color   // contrast color, readable on dark surfaces
    let special:   Color   // contrast at max pop
}

struct LumeyBorderScale {
    let primary:   Color
    let secondary: Color
    let tertiary:  Color
    let subtle:    Color
    let nested: Color
    let nestedStrong: Color
}

struct LumeyIconContainerScale {
    let primary:   Color
    let secondary: Color
    let tertiary:  Color
    let contrast:  Color
}

struct LumeyStateScale {
    let selectedFill:     Color
    let selectedBorder:   Color
    let selectedText:     Color
    let completionFill:   Color
    let completionBorder: Color
    let completionText:   Color
    let informationFill:  Color
    let informationBorder: Color
    let informationText:  Color
}

struct LumeyProgressScale {
    let primary:  Color
    let secondary: Color
    let tertiary: Color
    let contrast: Color
    let track:    Color
}

// MARK: - LumeyThemePalette (derived from base)

/// Central theme palette. All family accessors and backward-compat flat
/// properties resolve from the five base colors via universal rules.
struct LumeyThemePalette {
    let base: LumeyBasePalette

    private var isEmberNightPalette: Bool {
        base.support.toHex()?.uppercased() == "#65303B"
        && base.accent.toHex()?.uppercased() == "#C65D32"
        && base.contrast.toHex()?.uppercased() == "#C18B3F"
    }

    // MARK: Family accessors (preferred for new views)

    // MARK: - Surfaces
    //
    // All six surface variants are DARK. They are derivatives of the theme's
    // foundation (near-black background) with only subtle lightness differences
    // so cards read as a cohesive dark family. Cards are NOT painted with
    // accent colors — palette variety appears elsewhere (borders, text, icons,
    // progress, badges, controls, small decorative details).

    var surface: LumeySurfaceScale {
        let bg = base.foundation
        return LumeySurfaceScale(
            primary:    bg.lightened(by: 0.060),
            secondary:  bg.lightened(by: 0.072),
            tertiary:   bg.lightened(by: 0.082),
            elevated:   bg.lightened(by: 0.094),
            featured:   bg.lightened(by: 0.102),
            subtle:     bg.lightened(by: 0.050),
            nestedSoft: bg.lightened(by: 0.118),
            nested:     bg.lightened(by: 0.132),
            nestedStrong: bg.lightened(by: 0.148)
        )
    }

    // MARK: - Accents
    //
    // Accent colors are for DETAILS (icons, borders, values, small controls,
    // progress fills, selected states). They should never be used to fill
    // large card backgrounds.

    var accents: LumeyAccentScale {
        LumeyAccentScale(
            primary:   base.accent,
            secondary: base.support,
            tertiary:  base.accent.mixed(with: base.support, amount: 0.5),
            contrast:  base.contrast,
            special:   base.contrast.mixed(with: base.accent, amount: 0.5)
        )
    }

    // MARK: - Text
    //
    // Primary text stays high-contrast off-white for readability.
    // Secondary/tertiary/muted are palette-derived neutrals with only a whisper
    // of tint so typography actively participates in the theme without becoming
    // colorful.

    var text: LumeyTextScale {
        // A near-white primary derived from the theme's contrast color — keeps
        // major titles readable while carrying a hair of theme personality.
        let primaryNearWhite = base.contrast
            .lightened(by: 0.55)
            .mixed(with: .white, amount: 0.85)
        let secondaryTextColor = isEmberNightPalette
            ? base.support
            : base.support.lightened(by: 0.55).mixed(with: .white, amount: 0.20)

        return LumeyTextScale(
            primary:   primaryNearWhite,
            secondary: secondaryTextColor,
            tertiary:  base.accent.lightened(by: 0.55).mixed(with: .white, amount: 0.20),
            muted:     base.foundation.lightened(by: 0.35).mixed(with: .white, amount: 0.05),
            heading:   base.accent.lightened(by: 0.12).mixed(with: .white, amount: 0.10),
            cardTitle: base.accent.mixed(with: base.contrast, amount: 0.22).lightened(by: 0.10),
            accent:    base.accent.lightened(by: 0.30),
            contrast:  base.contrast,
            special:   base.contrast.lightened(by: 0.10)
        )
    }

    // MARK: - Borders
    //
    // Borders are one of the primary places palette color appears. Values are
    // palette hues MIXED with the foundation so they read as solid, restrained
    // strokes instead of transparent tints.

    var borders: LumeyBorderScale {
        LumeyBorderScale(
            primary:   base.support.mixed(with: base.foundation, amount: 0.55),   // subtle support-tinted
            secondary: base.accent.mixed(with: base.foundation, amount: 0.35),    // stronger accent
            tertiary:  base.contrast.mixed(with: base.foundation, amount: 0.35),  // contrast pop
            subtle:    base.foundation.lightened(by: 0.10),                       // near-neutral
            nested:    base.support.lightened(by: 0.18).mixed(with: base.foundation, amount: 0.48),
            nestedStrong: base.accent.lightened(by: 0.16).mixed(with: base.foundation, amount: 0.52)
        )
    }

    // MARK: - Icon containers
    //
    // Icon container fills are DARK and near-neutral — they should never
    // register as giant saturated circles behind icons. The colored icon
    // itself and its stroke carry the palette instead.

    var iconContainers: LumeyIconContainerScale {
        let bg = base.foundation
        return LumeyIconContainerScale(
            primary:   bg.lightened(by: 0.06),
            secondary: base.support.mixed(with: bg, amount: 0.88),
            tertiary:  base.accent.mixed(with: bg, amount: 0.88),
            contrast:  base.contrast.mixed(with: bg, amount: 0.88)
        )
    }

    // MARK: - States
    //
    // Selected/completion/information fills stay dark with a palette-hint;
    // their borders and text carry the accent so the visual stays restrained.

    var states: LumeyStateScale {
        let bg = base.foundation
        let informationTextColor = isEmberNightPalette
            ? base.support
            : base.support.lightened(by: 0.30)
        return LumeyStateScale(
            selectedFill:      base.accent.mixed(with: bg, amount: 0.82),
            selectedBorder:    base.accent,
            selectedText:      base.accent.lightened(by: 0.30),
            completionFill:    base.contrast.mixed(with: bg, amount: 0.84),
            completionBorder:  base.contrast,
            completionText:    base.contrast,
            informationFill:   base.support.mixed(with: bg, amount: 0.85),
            informationBorder: base.support,
            informationText:   informationTextColor
        )
    }

    // MARK: - Progress

    var progressScale: LumeyProgressScale {
        LumeyProgressScale(
            primary:   base.accent,
            secondary: base.support,
            tertiary:  base.contrast,
            contrast:  base.contrast,
            track:     base.foundation.lightened(by: 0.06)
        )
    }

    // MARK: Backward-compat flat properties
    //
    // These preserve every token previously exposed on LumeyThemePalette so
    // existing call sites continue to compile. New code should prefer the
    // family accessors above.

    var appBackground: Color        { base.foundation }
    var elevatedBackground: Color   { base.foundation }
    var primarySurface: Color       { surface.primary }
    var secondarySurface: Color     { surface.secondary }
    var elevatedSurface: Color      { surface.elevated }
    var selectedSurface: Color      { states.selectedFill }
    var border: Color               { borders.primary }
    var strongBorder: Color         { borders.secondary }
    var primaryText: Color          { text.primary }
    var secondaryText: Color        { text.secondary }
    var mutedText: Color            { text.muted }
    var primaryAccent: Color        { accents.primary }
    var secondaryAccent: Color      { accents.secondary }
    var tertiaryAccent: Color       { accents.contrast }
    var progressTrack: Color        { progressScale.track }
    var success: Color              { accents.contrast }
    var warning: Color              { accents.primary }
    var destructive: Color          { accents.secondary }
    // Ambient roles neutralized — background is a flat dark; radial glows are
    // rendered as no-op single-color layers.
    var ambientPrimary: Color       { base.foundation }
    var ambientSecondary: Color     { base.foundation }
    var ambientTertiary: Color      { base.foundation }

    // MARK: Backward-compat gradient stops
    //
    // Gradients stay restrained: usually two related theme colors, never
    // five-color rainbows.

    var accentGradientColors: [Color]      { [text.heading, text.heading] }
    var supportGradientColors: [Color]     { [accents.secondary, accents.secondary] }
    var specialGradientColors: [Color]     { [accents.special, accents.special] }
    var completionGradientColors: [Color]  { [states.completionBorder, states.completionBorder] }
    var cardFillColors: [Color]            { [surface.primary,  surface.primary]  }
    var selectedCardFillColors: [Color]    { [states.selectedFill, states.selectedFill] }
    var progressFillColors: [Color]        { [progressScale.primary, progressScale.primary] }

    var accentGradient: LinearGradient {
        LinearGradient(colors: accentGradientColors, startPoint: .leading, endPoint: .trailing)
    }
    var supportGradient: LinearGradient {
        LinearGradient(colors: supportGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var specialGradient: LinearGradient {
        LinearGradient(colors: specialGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var completionGradient: LinearGradient {
        LinearGradient(colors: completionGradientColors, startPoint: .leading, endPoint: .trailing)
    }
    var cardFill: LinearGradient {
        LinearGradient(colors: cardFillColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var selectedCardFill: LinearGradient {
        LinearGradient(colors: selectedCardFillColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var progressFill: LinearGradient {
        LinearGradient(colors: progressFillColors, startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Theme controller

@MainActor
final class LumeyThemeController: ObservableObject {
    static let shared = LumeyThemeController()
    private static let storageKey = "lumey.app.theme"

    @Published private(set) var selectedTheme: LumeyAppTheme

    private init() {
        let storedValue = UserDefaults.standard.string(forKey: Self.storageKey)
        let storedTheme = LumeyAppTheme(rawValue: storedValue ?? "") ?? .defaultTheme
        switch storedTheme {
        case .classicDefault:
            selectedTheme = .defaultTheme
        case .romance, .berryNight:
            selectedTheme = .fairy
        case .paperback:
            selectedTheme = .emberNight
        default:
            selectedTheme = storedTheme
        }

        applySystemAppearance()
    }

    var palette: LumeyThemePalette { selectedTheme.palette }

    func select(_ theme: LumeyAppTheme) {
        guard theme != selectedTheme else { return }
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
        applySystemAppearance()
    }

    private func applySystemAppearance() {
        let palette = selectedTheme.palette
        let backgroundColor = UIColor(palette.appBackground)
        let textColor = UIColor(palette.primaryText)
        let accentColor = UIColor(palette.primaryAccent)
        let borderColor = UIColor(palette.border)

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = backgroundColor
        navigationAppearance.shadowColor = borderColor.withAlphaComponent(0.35)
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: textColor
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: textColor
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = accentColor

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundColor
        tabAppearance.shadowColor = borderColor.withAlphaComponent(0.22)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = accentColor

        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.tintColor = accentColor
                refreshAppearance(in: window.rootViewController, navigationAppearance: navigationAppearance, tabAppearance: tabAppearance, tintColor: accentColor)
                window.rootViewController?.view.setNeedsLayout()
                window.rootViewController?.view.layoutIfNeeded()
            }
        }
    }

    private func refreshAppearance(
        in viewController: UIViewController?,
        navigationAppearance: UINavigationBarAppearance,
        tabAppearance: UITabBarAppearance,
        tintColor: UIColor
    ) {
        guard let viewController else { return }

        viewController.view.tintColor = tintColor

        if let navigationController = viewController as? UINavigationController {
            navigationController.navigationBar.standardAppearance = navigationAppearance
            navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance
            navigationController.navigationBar.compactAppearance = navigationAppearance
            navigationController.navigationBar.compactScrollEdgeAppearance = navigationAppearance
            navigationController.navigationBar.tintColor = tintColor
            navigationController.navigationBar.setNeedsLayout()
            navigationController.navigationBar.layoutIfNeeded()
        }

        if let tabBarController = viewController as? UITabBarController {
            tabBarController.tabBar.standardAppearance = tabAppearance
            tabBarController.tabBar.scrollEdgeAppearance = tabAppearance
            tabBarController.tabBar.tintColor = tintColor
            tabBarController.tabBar.setNeedsLayout()
            tabBarController.tabBar.layoutIfNeeded()
        }

        for child in viewController.children {
            refreshAppearance(
                in: child,
                navigationAppearance: navigationAppearance,
                tabAppearance: tabAppearance,
                tintColor: tintColor
            )
        }

        if let presented = viewController.presentedViewController {
            refreshAppearance(
                in: presented,
                navigationAppearance: navigationAppearance,
                tabAppearance: tabAppearance,
                tintColor: tintColor
            )
        }
    }
}

enum LTheme {
    static var currentTheme: LumeyAppTheme { LumeyThemeController.shared.selectedTheme }
    static var palette: LumeyThemePalette { LumeyThemeController.shared.palette }
}

// MARK: - LColors (public token surface)

enum LColors {
    // MARK: Family accessors (new — preferred)
    static var surface: LumeySurfaceScale         { LTheme.palette.surface }
    static var accents: LumeyAccentScale          { LTheme.palette.accents }
    static var text: LumeyTextScale               { LTheme.palette.text }
    static var border: LumeyBorderScale           { LTheme.palette.borders }
    static var iconContainer: LumeyIconContainerScale { LTheme.palette.iconContainers }
    static var state: LumeyStateScale             { LTheme.palette.states }
    static var progressScale: LumeyProgressScale  { LTheme.palette.progressScale }

    // MARK: Backward-compat flat tokens
    //
    // Preserved so ~230+ existing call sites keep compiling. Each is a thin
    // alias to a semantic family member so behavior is now palette-aware.

    static var appBackground: Color     { LTheme.palette.appBackground }
    static var elevatedBackground: Color { LTheme.palette.elevatedBackground }
    static var primarySurface: Color    { LTheme.palette.primarySurface }
    static var secondarySurface: Color  { LTheme.palette.secondarySurface }
    static var elevatedSurface: Color   { LTheme.palette.elevatedSurface }
    static var selectedSurface: Color   { LTheme.palette.selectedSurface }
    static var strongBorder: Color      { LTheme.palette.strongBorder }
    static var primaryText: Color       { LTheme.palette.primaryText }
    static var secondaryText: Color     { LTheme.palette.secondaryText }
    static var mutedText: Color         { LTheme.palette.mutedText }
    static var primaryAccent: Color     { LTheme.palette.primaryAccent }
    static var secondaryAccent: Color   { LTheme.palette.secondaryAccent }
    static var tertiaryAccent: Color    { LTheme.palette.tertiaryAccent }
    static var progressTrack: Color     { LTheme.palette.progressTrack }
    static var success: Color           { LTheme.palette.success }
    static var warning: Color           { LTheme.palette.warning }
    static var destructive: Color       { LTheme.palette.destructive }

    static var bg: Color                { appBackground }
    static var bgSoft: Color            { elevatedBackground }
    static var textPrimary: Color       { primaryText }
    static var textSecondary: Color     { secondaryText }
    static var headingPrimary: Color    { text.heading }
    static var cardTitle: Color         { text.cardTitle }
    static var accent: Color            { primaryAccent }
    static var accentHover: Color       { secondaryAccent }
    static var danger: Color            { destructive }
    static var glassSurface: Color      { surface.nestedSoft }
    static var glassSurface2: Color     { surface.nested }
    static var glassBorder: Color       { border.nested }
    static var glassBorderStrong: Color { border.nestedStrong }

    static var accentGradient: LinearGradient { LTheme.palette.accentGradient }

    // Legacy "gradient*" tokens map to distinct palette roles so callers that
    // reference them keep some semantic variety. NOTE: these are SOLID colors —
    // Loomey's theme system has no gradients.
    static var gradientPurple: Color     { accents.primary }
    static var gradientBlue: Color       { accents.secondary }
    static var gradientCyan: Color       { accents.contrast }
    static var gradientDeepPurple: Color { accents.tertiary }
    static var gradientPink: Color       { accents.special }
    static var gradientYellow: Color     { accents.contrast }
    static var gradientGreen: Color      { accents.tertiary }

    static var badgeOnce: Color         { accents.secondary }
    static var badgeDaily: Color        { accents.primary }
    static var badgeWeekly: Color       { accents.contrast }
    static var badgeInterval: Color     { accents.tertiary }
}

// MARK: - LGradients
//
// NO ACTUAL GRADIENTS. Kept only for backward-compat with call sites that
// pass `LGradients.header` / `.blue` / etc. into `.foregroundStyle`, `.fill`,
// or `.strokeBorder`. Each property returns a LinearGradient with identical
// stops so it renders as a solid palette color.
//
// Radial ambient glow properties return no-op layers (clear→clear) so the
// background is a flat dark surface — no colored halos.

enum LGradients {
    static var blue: LinearGradient       { LTheme.palette.supportGradient }
    static var header: LinearGradient     { LTheme.palette.accentGradient }
    static var tag: LinearGradient        { LTheme.palette.specialGradient }
    static var completion: LinearGradient { LTheme.palette.completionGradient }
    static var progress: LinearGradient   { LTheme.palette.progressFill }

    static var bgPurple: RadialGradient {
        RadialGradient(colors: [.clear, .clear], center: .center, startRadius: 0, endRadius: 1)
    }
    static var bgCyan: RadialGradient {
        RadialGradient(colors: [.clear, .clear], center: .center, startRadius: 0, endRadius: 1)
    }
    static var bgYellow: RadialGradient {
        RadialGradient(colors: [.clear, .clear], center: .center, startRadius: 0, endRadius: 1)
    }
}

// MARK: - LSpacing

enum LSpacing {
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999
    static let pageHorizontal: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

// MARK: - Color derivation

extension Color {
    /// Initialize from a hex string.
    init(lumeyHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    // MARK: Derivation

    /// Linear-RGB mix of this color with another. `amount` is the fraction of `other`.
    func mixed(with other: Color, amount: Double) -> Color {
        let t = max(0.0, min(1.0, amount))
        let (r1, g1, b1, a1) = rgbaComponents()
        let (r2, g2, b2, a2) = other.rgbaComponents()
        return Color(
            .sRGB,
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            opacity: a1 + (a2 - a1) * t
        )
    }

    /// Adjust brightness in HSB space by delta (-1...1). Positive lightens.
    func adjustedBrightness(by delta: Double) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &br, alpha: &a) else { return self }
        let newB = max(0.0, min(1.0, Double(br) + delta))
        return Color(UIColor(hue: h, saturation: s, brightness: CGFloat(newB), alpha: a))
    }

    func darkened(by amount: Double) -> Color { adjustedBrightness(by: -abs(amount)) }
    func lightened(by amount: Double) -> Color { adjustedBrightness(by: abs(amount)) }

    /// Reduce saturation by amount (0...1).
    func desaturated(by amount: Double) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &br, alpha: &a) else { return self }
        let newS = max(0.0, min(1.0, Double(s) * (1.0 - max(0.0, min(1.0, amount)))))
        return Color(UIColor(hue: h, saturation: CGFloat(newS), brightness: br, alpha: a))
    }

    func muted(by amount: Double) -> Color { desaturated(by: amount) }

    /// Palette-tinted overlay usable as low-emphasis fill on a dark surface.
    func onSurface(alpha: Double) -> Color {
        self.opacity(alpha)
    }

    // MARK: Internal RGBA helpers

    fileprivate func rgbaComponents() -> (Double, Double, Double, Double) {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
