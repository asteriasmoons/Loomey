import SwiftData
import SwiftUI

struct ReadingPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @State private var draft: ReadingPreferencesConfiguration
    @State private var preferenceSelection: PreferenceSelection?
    @State private var saveFailed = false
    @State private var confirmReset = false

    private enum PreferenceSelection: String, Identifiable {
        case fiction, nonfiction, interests
        var id: String { rawValue }
    }

    init(configuration: ReadingPreferencesConfiguration?) {
        _draft = State(initialValue: configuration ?? .default)
    }

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                ReadingPreferencesHeader(title: "Reading Preferences") { dismiss() }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        section("Preferred Reading Categories") {
                            ReadingCategorySliderPicker(selection: $draft.preferredCategory)
                        }

                        section("Favorite Genres") {
                            ReadingPreferenceSelectionCard(title: "Favorite Fiction Genres", selected: draft.favoriteFictionGenres, tint: theme.palette.primaryAction) {
                                preferenceSelection = .fiction
                            }
                            ReadingPreferenceSelectionCard(title: "Favorite Nonfiction Genres", selected: draft.favoriteNonfictionGenres, tint: theme.palette.primaryAction) {
                                preferenceSelection = .nonfiction
                            }
                        }

                        section("Currently Interested In") {
                            ReadingPreferenceSelectionCard(title: "Current Interests", selected: draft.currentlyInterestedIn, tint: theme.palette.secondaryAccent) {
                                preferenceSelection = .interests
                            }
                        }

                        section("Recommendation Style") { recommendationStyles }

                        ReadingPreferenceActionButton("Use Reading History Only", tint: theme.palette.primaryAction) {
                            confirmReset = true
                        }
                        .accessibilityIdentifier("reading-history-only")

                        if saveFailed {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Couldn't Save Preferences")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                Text("Your changes are still here. Please try saving again.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(theme.palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(theme.palette.indicators, lineWidth: 1.2)
                            }
                            .accessibilityIdentifier("reading-preferences-save-error")
                        }

                        ReadingPreferenceActionButton("Save Preferences", tint: theme.palette.secondaryAccent) {
                            save(draft)
                        }
                        .accessibilityIdentifier("reading-preferences-save")
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .disabled(confirmReset)
            .accessibilityHidden(confirmReset)

            if confirmReset { resetConfirmation }
        }
        .sheet(item: $preferenceSelection) { selection in
            switch selection {
            case .fiction:
                ReadingPreferenceGenrePicker(title: "Fiction Genres", options: ReadingGenresData.fictionPreferenceGenres,
                    selected: $draft.favoriteFictionGenres, tint: theme.palette.primaryAction)
            case .nonfiction:
                ReadingPreferenceGenrePicker(title: "Nonfiction Genres", options: ReadingGenresData.nonfictionPreferenceGenres,
                    selected: $draft.favoriteNonfictionGenres, tint: theme.palette.primaryAction)
            case .interests:
                ReadingPreferenceGenrePicker(title: "Reading Interests", options: ReadingInterestsData.all,
                    selected: $draft.currentlyInterestedIn, tint: theme.palette.secondaryAccent,
                    searchPrompt: "Search Interests", emptyMessage: "No Matching Interests")
            }
        }
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(confirmReset)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }

    private var recommendationStyles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                recommendationStyleButton(.followPreferences)
                recommendationStyleButton(.blendInterests)
            }
            recommendationStyleButton(.surpriseMe)
        }
    }

    private func recommendationStyleButton(_ style: ReadingRecommendationStyle) -> some View {
        let isSelected = draft.recommendationStyle == style
        let label: String
        switch style {
        case .followPreferences: label = "Follow\nPreferences"
        case .blendInterests: label = "Blend\nInterests"
        case .surpriseMe: label = "Surprise Me"
        }

        return Button { draft.recommendationStyle = style } label: {
            Text(label)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(style == .surpriseMe ? 1 : 2)
                .lineSpacing(2)
                .minimumScaleFactor(0.85)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.horizontal, 12)
                .frame(height: 64, alignment: .center)
                .background {
                    if isSelected {
                        BubblyTileSurface(tint: theme.palette.indicators, cornerRadius: 18)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.palette.indicators, lineWidth: 1.4)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 0, maxWidth: .infinity)
        .accessibilityLabel(style.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("reading-style-\(style.rawValue)")
    }

    private var resetConfirmation: some View {
        ZStack {
            theme.palette.background.opacity(0.85).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    Text("Use Reading History Only?")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ReadingPreferenceIconButton(asset: "xmarkwavy", tint: theme.palette.primaryAction, label: "Keep reading preferences") {
                        confirmReset = false
                    }
                }

                Text("Clear your reading preferences and use your finished books for recommendations. Your library stays unchanged.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)

                ReadingPreferenceActionButton("Use Reading History Only", tint: theme.palette.primaryAction) {
                    confirmReset = false
                    save(nil)
                }

                Button { confirmReset = false } label: {
                    Text("Keep My Preferences")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(theme.palette.secondaryAccent, lineWidth: 1.4)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(theme.palette.textPrimary)
            .padding(22)
            .frame(maxWidth: 420)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.palette.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1.2)
            }
            .padding(LSpacing.pageHorizontal)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func save(_ value: ReadingPreferencesConfiguration?) {
        do { try ReadingPreferencesStore.save(value, in: modelContext); dismiss() }
        catch { saveFailed = true }
    }
}

private struct ReadingPreferenceSelectionCard: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let selected: [String]
    let tint: Color
    let onChoose: () -> Void
    @State private var isExpanded = false
    @State private var chipContentHeight: CGFloat = 0
    @ScaledMetric(relativeTo: .caption) private var chipHeight: CGFloat = 32
    @ScaledMetric(relativeTo: .caption) private var chipFontSize: CGFloat = 12

    private let chipSpacing: CGFloat = 8
    private var dropdownHeight: CGFloat {
        min(max(chipContentHeight, chipHeight), chipHeight * 4 + chipSpacing * 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(selected.count) Selected")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        Spacer(minLength: 0)
                        Image(isExpanded ? "chevup" : "chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .bubblyIconMaterial(tint: theme.palette.textPrimary)
                            .frame(width: 32, height: 44)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title), \(selected.count) selected")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                .accessibilityHint(isExpanded ? "Collapse selected items" : "Expand selected items")

                ReadingPreferenceIconButton(asset: "addwavy", tint: tint, label: "Choose \(title)", action: onChoose)
            }

            if isExpanded {
                if selected.isEmpty {
                    Text("None Selected")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: true) {
                            FlowLayout(spacing: chipSpacing) {
                                ForEach(selected, id: \.self) { value in
                                    Text(value)
                                        .font(.system(size: chipFontSize, weight: .black, design: .rounded))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .padding(.horizontal, 10)
                                        .frame(height: chipHeight)
                                        .frame(maxWidth: geometry.size.width, alignment: .center)
                                        .background {
                                            BubblyIconMaterial(tint: tint)
                                                .clipShape(Capsule())
                                        }
                                        .accessibilityLabel(value)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                GeometryReader { content in
                                    Color.clear.preference(key: ReadingPreferenceChipHeightKey.self, value: content.size.height)
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    .frame(height: dropdownHeight)
                    .onPreferenceChange(ReadingPreferenceChipHeightKey.self) { chipContentHeight = $0 }
                }
            }
        }
        .foregroundStyle(theme.palette.textPrimary)
        .padding(16)
        .background { BubblyTileSurface(tint: tint, cornerRadius: 20) }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint, lineWidth: 1.2)
                .allowsHitTesting(false)
        }
    }
}

private struct ReadingPreferenceChipHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ReadingPreferenceGenrePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let title: String
    let options: [String]
    @Binding var selected: [String]
    let tint: Color
    var searchPrompt = "Search Genres"
    var emptyMessage = "No Matching Genres"
    @State private var search = ""

    private var filtered: [String] {
        var labels: [String: String] = [:]
        // Keep saved custom interests, including their original spelling, selectable.
        for value in selected + options {
            let key = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            if labels[key] == nil { labels[key] = value }
        }
        let values = labels.values.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        return search.isEmpty ? values : values.filter { $0.localizedStandardContains(search) }
    }

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                ReadingPreferencesHeader(title: title) { dismiss() }

                searchField
                    .padding(.horizontal, LSpacing.pageHorizontal)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered, id: \.self) { genre in
                            genreButton(genre)
                        }
                        if filtered.isEmpty {
                            Text(emptyMessage)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.palette.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)

                ReadingPreferenceActionButton("Done", tint: tint) { dismiss() }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.bottom, 20)
            }
        }
        .presentationDragIndicator(.hidden)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .bubblyIconMaterial(tint: tint)

            TextField(searchPrompt, text: $search)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .tint(tint)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .accessibilityIdentifier("reading-genre-search")

            if !search.isEmpty {
                ReadingPreferenceIconButton(asset: "xmarkwavy", tint: tint, label: "Clear search") { search = "" }
            }
        }
        .frame(minHeight: 44)
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint, lineWidth: 1.2)
        }
    }

    private func genreButton(_ genre: String) -> some View {
        let isSelected = selected.contains(genre)

        return Button {
            if isSelected { selected.removeAll { $0 == genre } }
            else { selected.append(genre) }
        } label: {
            HStack(spacing: 14) {
                Text(genre)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)

                ZStack {
                    if isSelected {
                        BubblyIconMaterial(tint: tint)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .bubblyIconMaterial(tint: theme.palette.textPrimary)
                    } else {
                        BubblyIconMaterial(tint: tint)
                            .mask {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(lineWidth: 1.5)
                            }
                    }
                }
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(14)
            .background {
                if isSelected {
                    BubblyTileSurface(tint: tint, cornerRadius: 18)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tint, lineWidth: isSelected ? 1.8 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ReadingPreferencesHeader: View {
    let title: String
    let onClose: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            ReadingPreferenceIconButton(asset: "xmarkwavy", tint: theme.palette.primaryAction, label: "Close \(title)", action: onClose)
        }
        .padding(.horizontal, LSpacing.pageHorizontal)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

private struct ReadingPreferenceIconButton: View {
    @Environment(\.appTheme) private var theme
    let asset: String
    let tint: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .bubblyIconMaterial(tint: tint)
                .frame(width: 44, height: 44)
                .background {
                    Circle().fill(theme.palette.background)
                    BubblyIconMaterial(tint: tint)
                        .mask { Circle().strokeBorder(lineWidth: 1.35) }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct ReadingPreferenceActionButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let tint: Color
    let action: () -> Void

    init(_ title: String, tint: Color, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 24)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background { BubblyTileSurface(tint: tint, cornerRadius: 18) }
                .bubblyTileLift()
        }
        .buttonStyle(.plain)
    }
}
