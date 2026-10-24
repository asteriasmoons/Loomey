import SwiftData
import SwiftUI

struct ReadingPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @State private var draft: ReadingPreferencesConfiguration
    @State private var newInterest = ""
    @State private var genreSelection: GenreSelection?
    @State private var saveFailed = false
    @State private var confirmReset = false

    private enum GenreSelection: String, Identifiable {
        case fiction, nonfiction
        var id: String { rawValue }
    }

    init(configuration: ReadingPreferencesConfiguration?) {
        _draft = State(initialValue: configuration ?? .default)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        section("Preferred Reading Categories", index: 0) {
                            Picker("Preferred Reading Categories", selection: $draft.preferredCategory) {
                                ForEach(PreferredReadingCategory.allCases) { category in
                                    Text(category.title).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("reading-preferred-category")
                        }
                        section("Favorite Genres", index: 1) {
                            genreRow("Favorite Fiction Genres", selected: draft.favoriteFictionGenres) { genreSelection = .fiction }
                            Divider().overlay(LColors.border.subtle)
                            genreRow("Favorite Nonfiction Genres", selected: draft.favoriteNonfictionGenres) { genreSelection = .nonfiction }
                        }
                        section("Currently Interested In", index: 2) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    TextField("Topic, theme, or genre", text: $newInterest)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(LColors.textPrimary)
                                        .submitLabel(.done)
                                        .onSubmit(addInterest)
                                        .accessibilityIdentifier("reading-current-interest")
                                    Button(action: addInterest) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundStyle(theme.palette.indicators)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.currentlyInterestedIn.count >= 20)
                                    .accessibilityLabel("Add current reading interest")
                                }
                                ForEach(draft.currentlyInterestedIn, id: \.self) { interest in
                                    HStack(spacing: 12) {
                                        Text(interest)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 0)
                                        Button { draft.currentlyInterestedIn.removeAll { $0 == interest } } label: {
                                            Image("xmarkwavy").renderingMode(.template).resizable().scaledToFit()
                                                .frame(width: 16, height: 16).frame(width: 44, height: 44)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Remove \(interest)")
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textPrimary)
                                }
                            }
                        }
                        section("Recommendation Style", index: 3) {
                            VStack(spacing: 0) {
                                ForEach(ReadingRecommendationStyle.allCases) { style in
                                    Button { draft.recommendationStyle = style } label: {
                                        HStack(spacing: 12) {
                                            Text(style.title)
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer(minLength: 0)
                                            Image(systemName: draft.recommendationStyle == style ? "largecircle.fill.circle" : "circle")
                                                .font(.system(size: 24))
                                                .foregroundStyle(theme.palette.secondaryAccent)
                                        }
                                        .foregroundStyle(LColors.textPrimary)
                                        .frame(minHeight: 48)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityAddTraits(draft.recommendationStyle == style ? .isSelected : [])
                                    .accessibilityIdentifier("reading-style-\(style.rawValue)")
                                }
                            }
                        }
                        Button("Use Reading History Only", role: .destructive) { confirmReset = true }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Reading Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { addInterest(); save(draft) }.fontWeight(.bold) }
            }
            .sheet(item: $genreSelection) { selection in
                ReadingPreferenceGenrePicker(
                    title: selection == .fiction ? "Fiction Genres" : "Nonfiction Genres",
                    options: selection == .fiction ? ReadingGenresData.fictionPreferenceGenres : ReadingGenresData.nonfictionPreferenceGenres,
                    selected: selection == .fiction ? $draft.favoriteFictionGenres : $draft.favoriteNonfictionGenres
                )
            }
            .alert("Couldn't Save Preferences", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Your changes are still here. Please try saving again.") }
            .confirmationDialog("Use Reading History Only?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset Reading Preferences", role: .destructive) { save(nil) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func section<Content: View>(_ title: String, index: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            GlassCard(cornerRadius: 20, padding: 16, variant: .primary, borderColor: theme.palette.rotation[index % theme.palette.rotation.count], content: content)
        }
    }

    private func genreRow(_ title: String, selected: [String], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(selected.isEmpty ? "None Selected" : selected.joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image("chevright").renderingMode(.template).resizable().scaledToFit().frame(width: 13, height: 13)
            }
            .foregroundStyle(LColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addInterest() {
        guard draft.currentlyInterestedIn.count < 20 else { return }
        draft.currentlyInterestedIn += [newInterest]
        draft = draft.normalized()
        newInterest = ""
    }

    private func save(_ value: ReadingPreferencesConfiguration?) {
        do { try ReadingPreferencesStore.save(value, in: modelContext); dismiss() }
        catch { saveFailed = true }
    }
}

private struct ReadingPreferenceGenrePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let title: String
    let options: [String]
    @Binding var selected: [String]
    @State private var search = ""

    private var filtered: [String] {
        let values = Array(Set(options + selected)).sorted()
        return search.isEmpty ? values : values.filter { $0.localizedStandardContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground().ignoresSafeArea()
                List(filtered, id: \.self) { genre in
                    Button {
                        if selected.contains(genre) { selected.removeAll { $0 == genre } }
                        else if selected.count < 64 { selected.append(genre) }
                    } label: {
                        HStack(spacing: 14) {
                            Text(genre)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: selected.contains(genre) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 23))
                                .foregroundStyle(theme.palette.secondaryAccent)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .accessibilityAddTraits(selected.contains(genre) ? .isSelected : [])
                }
                .scrollContentBackground(.hidden)
            }
            .searchable(text: $search, prompt: "Search Genres")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
