//
//  LumeyThemeSystem.swift
//  Lumey
//
//  Selectable-theme persistence and compatibility accessors for AppTheme's
//  strict eight-color palette.
//

import Combine
import Foundation
import SwiftUI
import UIKit

// MARK: - Selectable themes

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
        [.defaultTheme, .electricDark, .darkAcademia, .emberNight]
    }

    var id: String { rawValue }

    var title: String {
        switch normalized {
        case .defaultTheme: return "Default"
        case .electricDark: return "Electric Dark"
        case .darkAcademia: return "Dark Academia"
        case .emberNight: return "Ember Night"
        default: return "Default"
        }
    }

    var subtitle: String {
        switch normalized {
        case .defaultTheme:
            return "Deep plum, violet, steel blue, and berry."
        case .electricDark:
            return "Midnight blue, teal current, electric pink, and violet."
        case .darkAcademia:
            return "Inky navy, olive stone, mauve plum, and antique gold."
        case .emberNight:
            return "Dark cocoa, burnt orange, wine, and ember gold."
        default:
            return "Deep plum, violet, steel blue, and berry."
        }
    }

    var appTheme: AppTheme {
        switch normalized {
        case .defaultTheme: return .default
        case .electricDark: return .electricDark
        case .darkAcademia: return .darkAcademia
        case .emberNight: return .emberNight
        default: return .default
        }
    }

    var palette: AppPalette { appTheme.palette }

    fileprivate var normalized: LumeyAppTheme {
        switch self {
        case .classicDefault, .fairy, .romance, .berryNight:
            return .defaultTheme
        case .paperback:
            return .emberNight
        default:
            return self
        }
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
        selectedTheme = storedTheme.normalized
        applySystemAppearance()
    }

    var appTheme: AppTheme { selectedTheme.appTheme }
    var palette: AppPalette { appTheme.palette }

    func select(_ theme: LumeyAppTheme) {
        let normalizedTheme = theme.normalized
        guard normalizedTheme != selectedTheme else { return }
        selectedTheme = normalizedTheme
        UserDefaults.standard.set(normalizedTheme.rawValue, forKey: Self.storageKey)
        applySystemAppearance()
    }

    private func applySystemAppearance() {
        let palette = selectedTheme.palette
        let backgroundColor = UIColor(palette.background)
        let textColor = UIColor(palette.textPrimary)
        let accentColor = UIColor(palette.primaryAction)
        let borderColor = UIColor(palette.raisedSurface)

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = backgroundColor
        navigationAppearance.shadowColor = borderColor
        navigationAppearance.titleTextAttributes = [.foregroundColor: textColor]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = accentColor

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundColor
        tabAppearance.shadowColor = borderColor
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = accentColor

        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.tintColor = accentColor
                refreshAppearance(
                    in: window.rootViewController,
                    navigationAppearance: navigationAppearance,
                    tabAppearance: tabAppearance,
                    tintColor: accentColor
                )
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
    static var appTheme: AppTheme { LumeyThemeController.shared.appTheme }
    static var palette: AppPalette { appTheme.palette }

    static func categoryColor(for key: String?) -> Color {
        appTheme.categoryColor(for: key)
    }
}

// MARK: - Legacy compatibility families

struct LumeySurfaceScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let elevated: Color
    let featured: Color
    let subtle: Color
    let nestedSoft: Color
    let nested: Color
    let nestedStrong: Color
}

struct LumeyAccentScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let contrast: Color
    let special: Color
}

struct LumeyTextScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let muted: Color
    let heading: Color
    let cardTitle: Color
    let accent: Color
    let contrast: Color
    let special: Color
}

struct LumeyBorderScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let subtle: Color
    let nested: Color
    let nestedStrong: Color
}

struct LumeyIconContainerScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let contrast: Color
}

struct LumeyStateScale {
    let selectedFill: Color
    let selectedBorder: Color
    let selectedText: Color
    let completionFill: Color
    let completionBorder: Color
    let completionText: Color
    let informationFill: Color
    let informationBorder: Color
    let informationText: Color
}

struct LumeyProgressScale {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let contrast: Color
    let track: Color
}

extension AppPalette {
    var legacySurface: LumeySurfaceScale {
        LumeySurfaceScale(
            primary: surface,
            secondary: surface,
            tertiary: raisedSurface,
            elevated: raisedSurface,
            featured: raisedSurface,
            subtle: surface,
            nestedSoft: surface,
            nested: raisedSurface,
            nestedStrong: raisedSurface
        )
    }

    var legacyAccents: LumeyAccentScale {
        LumeyAccentScale(
            primary: primaryAction,
            secondary: secondaryAccent,
            tertiary: indicators,
            contrast: indicators,
            special: indicators
        )
    }

    var legacyText: LumeyTextScale {
        LumeyTextScale(
            primary: textPrimary,
            secondary: textSecondary,
            tertiary: textSecondary,
            muted: textSecondary,
            heading: textPrimary,
            cardTitle: textPrimary,
            accent: primaryAction,
            contrast: secondaryAccent,
            special: indicators
        )
    }

    var legacyBorders: LumeyBorderScale {
        LumeyBorderScale(
            primary: raisedSurface,
            secondary: primaryAction,
            tertiary: indicators,
            subtle: surface,
            nested: raisedSurface,
            nestedStrong: primaryAction
        )
    }

    var legacyIconContainers: LumeyIconContainerScale {
        LumeyIconContainerScale(
            primary: surface,
            secondary: surface,
            tertiary: raisedSurface,
            contrast: raisedSurface
        )
    }

    var legacyStates: LumeyStateScale {
        LumeyStateScale(
            selectedFill: raisedSurface,
            selectedBorder: primaryAction,
            selectedText: primaryAction,
            completionFill: raisedSurface,
            completionBorder: indicators,
            completionText: indicators,
            informationFill: surface,
            informationBorder: secondaryAccent,
            informationText: secondaryAccent
        )
    }

    var legacyProgress: LumeyProgressScale {
        LumeyProgressScale(
            primary: primaryAction,
            secondary: secondaryAccent,
            tertiary: indicators,
            contrast: indicators,
            track: raisedSurface
        )
    }

    var appBackground: Color { background }
    var elevatedBackground: Color { background }
    var primarySurface: Color { surface }
    var secondarySurface: Color { surface }
    var elevatedSurface: Color { raisedSurface }
    var selectedSurface: Color { raisedSurface }
    var border: Color { raisedSurface }
    var strongBorder: Color { primaryAction }
    var primaryText: Color { textPrimary }
    var secondaryText: Color { textSecondary }
    var mutedText: Color { textSecondary }
    var primaryAccent: Color { primaryAction }
    var tertiaryAccent: Color { indicators }
    var progressTrack: Color { raisedSurface }
    var success: Color { indicators }
    var warning: Color { primaryAction }
    var destructive: Color { secondaryAccent }

    private func solidGradient(_ color: Color, from start: UnitPoint, to end: UnitPoint) -> LinearGradient {
        LinearGradient(colors: [color, color], startPoint: start, endPoint: end)
    }

    var accentGradient: LinearGradient {
        solidGradient(primaryAction, from: .leading, to: .trailing)
    }

    var supportGradient: LinearGradient {
        solidGradient(secondaryAccent, from: .topLeading, to: .bottomTrailing)
    }

    var specialGradient: LinearGradient {
        solidGradient(indicators, from: .topLeading, to: .bottomTrailing)
    }

    var completionGradient: LinearGradient {
        solidGradient(indicators, from: .leading, to: .trailing)
    }

    var cardFill: LinearGradient {
        solidGradient(surface, from: .topLeading, to: .bottomTrailing)
    }

    var selectedCardFill: LinearGradient {
        solidGradient(raisedSurface, from: .topLeading, to: .bottomTrailing)
    }

    var progressFill: LinearGradient {
        solidGradient(primaryAction, from: .leading, to: .trailing)
    }
}

// MARK: - LColors compatibility surface

enum LColors {
    static var surface: LumeySurfaceScale { LTheme.palette.legacySurface }
    static var accents: LumeyAccentScale { LTheme.palette.legacyAccents }
    static var text: LumeyTextScale { LTheme.palette.legacyText }
    static var border: LumeyBorderScale { LTheme.palette.legacyBorders }
    static var iconContainer: LumeyIconContainerScale { LTheme.palette.legacyIconContainers }
    static var state: LumeyStateScale { LTheme.palette.legacyStates }
    static var progressScale: LumeyProgressScale { LTheme.palette.legacyProgress }

    static var appBackground: Color { LTheme.palette.background }
    static var elevatedBackground: Color { LTheme.palette.background }
    static var primarySurface: Color { LTheme.palette.surface }
    static var secondarySurface: Color { LTheme.palette.surface }
    static var elevatedSurface: Color { LTheme.palette.raisedSurface }
    static var selectedSurface: Color { LTheme.palette.raisedSurface }
    static var strongBorder: Color { LTheme.palette.primaryAction }
    static var primaryText: Color { LTheme.palette.textPrimary }
    static var secondaryText: Color { LTheme.palette.textSecondary }
    static var mutedText: Color { LTheme.palette.textSecondary }
    static var primaryAccent: Color { LTheme.palette.primaryAction }
    static var secondaryAccent: Color { LTheme.palette.secondaryAccent }
    static var tertiaryAccent: Color { LTheme.palette.indicators }
    static var progressTrack: Color { LTheme.palette.raisedSurface }
    static var success: Color { LTheme.palette.indicators }
    static var warning: Color { LTheme.palette.primaryAction }
    static var destructive: Color { LTheme.palette.secondaryAccent }

    static var bg: Color { appBackground }
    static var bgSoft: Color { elevatedBackground }
    static var textPrimary: Color { primaryText }
    static var textSecondary: Color { secondaryText }
    static var headingPrimary: Color { text.heading }
    static var cardTitle: Color { text.cardTitle }
    static var accent: Color { primaryAccent }
    static var accentHover: Color { secondaryAccent }
    static var danger: Color { destructive }
    static var glassSurface: Color { surface.nestedSoft }
    static var glassSurface2: Color { surface.nested }
    static var glassBorder: Color { border.nested }
    static var glassBorderStrong: Color { border.nestedStrong }

    static var accentGradient: LinearGradient { LTheme.palette.accentGradient }

    static var gradientPurple: Color { accents.primary }
    static var gradientBlue: Color { accents.secondary }
    static var gradientCyan: Color { accents.contrast }
    static var gradientDeepPurple: Color { accents.tertiary }
    static var gradientPink: Color { accents.special }
    static var gradientYellow: Color { accents.contrast }
    static var gradientGreen: Color { accents.tertiary }

    static var badgeOnce: Color { accents.secondary }
    static var badgeDaily: Color { accents.primary }
    static var badgeWeekly: Color { accents.contrast }
    static var badgeInterval: Color { accents.tertiary }
}

// MARK: - LGradients compatibility surface

enum LGradients {
    static var blue: LinearGradient { LTheme.palette.supportGradient }
    static var header: LinearGradient { LTheme.palette.accentGradient }
    static var tag: LinearGradient { LTheme.palette.specialGradient }
    static var completion: LinearGradient { LTheme.palette.completionGradient }
    static var progress: LinearGradient { LTheme.palette.progressFill }

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

// MARK: - Layout compatibility

enum LSpacing {
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999
    static let pageHorizontal: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

// MARK: - Hex compatibility

extension Color {
    init(lumeyHex hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        Scanner(string: value).scanHexInt64(&integer)
        let alpha, red, green, blue: UInt64

        switch value.count {
        case 6:
            (alpha, red, green, blue) = (255, integer >> 16, integer >> 8 & 0xFF, integer & 0xFF)
        case 8:
            (alpha, red, green, blue) = (integer >> 24, integer >> 16, integer >> 8 & 0xFF, integer & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
