//
//  MainTabView.swift
//  Lumey
//

import SwiftUI

enum LumeyTab: CaseIterable {
    case home
    case library
    case bingos
    case stats
    case goals
    case history
    case sprints
    case buddies
    case profile
    case challenges
    case epubLibrary
    case settings

    static let primaryTabs: [LumeyTab] = [
        .home,
        .library,
        .stats,
        .goals
    ]

    static let overflowTabs: [LumeyTab] = [
        .bingos,
        .history,
        .epubLibrary,
        .sprints,
        .buddies,
        .profile,
        .challenges,
        .settings
    ]

    var icon: String {
        switch self {
        case .home:
            return "houseoutline"
        case .library:
            return "searchwavy"
        case .bingos:
            return "starbook"
        case .stats:
            return "levelup"
        case .goals:
            return "achievement"
        case .history:
            return "clockfill"
        case .epubLibrary:
            return "books"
        case .sprints:
            return "sparkbolt"
        case .buddies:
            return "groupfill"
        case .profile:
            return "profilewavy"
        case .challenges:
            return "starwavy"
        case .settings:
            return "togglesettings"
        }
    }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .library:
            return "Books"
        case .bingos:
            return "Bingos"
        case .stats:
            return "Stats"
        case .goals:
            return "Goals"
        case .history:
            return "History"
        case .epubLibrary:
            return "Library"
        case .sprints:
            return "Sprints"
        case .buddies:
            return "Buddies"
        case .profile:
            return "Profile"
        case .challenges:
            return "Challenges"
        case .settings:
            return "Settings"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: LumeyTab = .home
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeController: LumeyThemeController
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LumeyBackground()
                .ignoresSafeArea()

            selectedTabView
                .id("\(selectedTab.title)-\(themeController.selectedTheme.rawValue)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: appState.hideTabBar ? 0 : 120)
                }

            if !appState.hideTabBar {
                LumeyTabBar(selectedTab: $selectedTab)
                    .id("tabbar-\(themeController.selectedTheme.rawValue)")
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: appState.pendingReportConversationID) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                    selectedTab = .settings
                }
            }
        }
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .home:
            ReadingHomeView()
        case .library:
            ReadingLibraryView()
        case .bingos:
            ReadingBingosHubView()
        case .stats:
            ReadingStatsView()
        case .goals:
            ReadingGoalsView()
        case .history:
            ReadingGoalHistoryView()
        case .sprints:
            SprintRoomView()
        case .buddies:
            BuddyReadingView()
        case .profile:
            ProfileView()
        case .challenges:
            ChallengesView()
        case .epubLibrary:
            EPUBLibraryView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Floating Tab Bar

struct LumeyTabBar: View {
    @Binding var selectedTab: LumeyTab

    @State private var showMoreTabs = false

    private var primaryTabs: [LumeyTab] {
        LumeyTab.primaryTabs
    }

    private var overflowTabs: [LumeyTab] {
        LumeyTab.overflowTabs
    }

    private var leadingTabs: [LumeyTab] {
        Array(primaryTabs.prefix(2))
    }

    private var trailingTabs: [LumeyTab] {
        Array(primaryTabs.dropFirst(2))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showMoreTabs && !overflowTabs.isEmpty {
                moreTabsMenu
                    .padding(.bottom, 118)
                    .transition(.opacity)
                    .zIndex(1)
            }

            HStack(spacing: 10) {
                ForEach(leadingTabs, id: \.self) { tab in
                    tabButton(tab)
                }

                centerAddButton

                ForEach(trailingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(LColors.bg.opacity(0.88))

                    GlassCard(cornerRadius: 999, padding: 0, variant: .featured) {
                        Color.clear
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 42)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showMoreTabs)
    }

    /// Each primary tab gets its own palette accent so the nav bar isn't a
    /// single-accent block — home reads as primary, library as contrast, etc.
    private func tabAccent(_ tab: LumeyTab) -> Color {
        switch tab {
        case .home:     return LColors.accents.primary
        case .library:  return LColors.accents.contrast
        case .stats:    return LColors.accents.secondary
        case .goals:    return LColors.accents.special
        default:        return LColors.accents.tertiary
        }
    }

    private func tabButton(_ tab: LumeyTab) -> some View {
        let isSelected = selectedTab == tab
        let accent = tabAccent(tab)

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
                showMoreTabs = false
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(LColors.iconContainer.primary)
                        .frame(width: 34, height: 34)
                }

                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(accent)
                        : AnyShapeStyle(LColors.text.muted)
                    )
            }
            .frame(width: 42, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var centerAddButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                showMoreTabs.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LColors.accents.primary)
                    .frame(width: 44, height: 44)
                    .shadow(color: LColors.accents.contrast.opacity(0.35), radius: 10, x: 0, y: 5)

                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.appBackground)
                    .rotationEffect(.degrees(showMoreTabs ? 45 : 0))
            }
            .frame(width: 54, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(overflowTabs.isEmpty)
        .opacity(overflowTabs.isEmpty ? 0.45 : 1)
    }

    private var moreTabsMenu: some View {
        CurvedDock(
            tabs: overflowTabs,
            selectedTab: $selectedTab,
            isExpanded: $showMoreTabs
        )
    }
}

// MARK: - Curved Dock

private struct CurvedDock: View {

    let tabs: [LumeyTab]
    @Binding var selectedTab: LumeyTab
    @Binding var isExpanded: Bool

    @State private var revealedCount: Int = 0

    private let dockWidth: CGFloat = 344
    private let dockHeight: CGFloat = 116
    private let itemSize: CGFloat = 40
    private let arcHeight: CGFloat = 44

    var body: some View {
        ZStack {
            ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                dockButton(tab, index: index)
                    .position(position(for: index))
                    .opacity(index < revealedCount ? 1 : 0)
                    .scaleEffect(index < revealedCount ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.34, dampingFraction: 0.7),
                        value: revealedCount
                    )
            }
        }
        .frame(width: dockWidth, height: dockHeight)
        .onAppear { revealSequentially() }
        .onDisappear { revealedCount = 0 }
    }

    // MARK: - Reveal Animation

    private func revealSequentially() {
        revealedCount = 0
        for index in tabs.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.055) {
                guard isExpanded else { return }
                revealedCount = index + 1
            }
        }
    }

    // MARK: - Layout

    /// Horizontal inset shared by the arc path and the icon positions.
    private var arcInset: CGFloat { itemSize / 2 + 6 }

    /// Y coordinate of the arc's endpoints.
    private var arcBaseY: CGFloat { (dockHeight / 2) - (arcHeight / 2) }

    /// Point on the arc at normalized position `s` (0...1, left to right).
    private func pointOnArc(_ s: CGFloat) -> CGPoint {
        let x = arcInset + (dockWidth - arcInset * 2) * s
        let y = arcBaseY + 4 * arcHeight * s * (1 - s)
        return CGPoint(x: x, y: y)
    }

    /// Distributes the icons evenly along the arc.
    private func position(for index: Int) -> CGPoint {
        guard tabs.count > 1 else {
            return pointOnArc(0.5)
        }
        return pointOnArc(CGFloat(index) / CGFloat(tabs.count - 1))
    }

    // MARK: - Dock Button

    /// Dock tabs distribute across palette accents by index so the overflow
    /// menu shows the full theme, not one repeated accent.
    private func dockAccent(for index: Int) -> Color {
        switch index % 4 {
        case 0:  return LColors.accents.primary
        case 1:  return LColors.accents.contrast
        case 2:  return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    private func dockButton(_ tab: LumeyTab, index: Int) -> some View {
        let isSelected = selectedTab == tab
        let accent = dockAccent(for: index)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                selectedTab = tab
                isExpanded = false
            }
        } label: {
            Image(tab.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 19, height: 19)
                .foregroundStyle(
                    isSelected
                    ? AnyShapeStyle(accent)
                    : AnyShapeStyle(LColors.text.tertiary)
                )
                .frame(width: itemSize, height: itemSize)
                .background {
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .fill(isSelected ? LColors.surface.elevated : LColors.surface.primary)
                        )
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? accent : LColors.border.primary,
                            lineWidth: isSelected ? 1.4 : 1
                        )
                )
                .shadow(
                    color: isSelected ? accent.opacity(0.35) : .black.opacity(0.25),
                    radius: isSelected ? 10 : 6,
                    y: 4
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    let icon: String
    let title: String
    var isSF: Bool = false
    
    var body: some View {
        ZStack {
            LumeyBackground()
            
            VStack(spacing: 16) {
                if isSF {
                    Image(systemName: icon)
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LColors.gradientBlue
                        )
                } else {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(
                            LColors.gradientBlue
                        )
                }
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                
                Text("Coming soon")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(LColors.text.muted)
            }
        }
    }
}
