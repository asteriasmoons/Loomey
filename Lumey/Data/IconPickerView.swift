//
//  IconPickerView.swift
//  Lumey
//

import SwiftUI

// MARK: - Icon Picker Sheet

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory = ""
    
    private var filteredIcons: [LumeyIconItem] {
        LumeyIconLibrary.search(searchText)
    }
    
    private var groupedIcons: [(category: String, icons: [LumeyIconItem])] {
        let grouped = Dictionary(grouping: filteredIcons) { $0.category }
        
        return grouped
            .map { category, icons in
                (
                    category: category,
                    icons: icons.sorted { $0.name < $1.name }
                )
            }
            .sorted { $0.category < $1.category }
    }

    private var selectedCategoryName: String {
        if groupedIcons.contains(where: { $0.category == selectedCategory }) {
            return selectedCategory
        }

        return groupedIcons.first?.category ?? ""
    }

    private var selectedIcons: [LumeyIconItem] {
        groupedIcons.first { $0.category == selectedCategoryName }?.icons ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        searchField

                        categoryTabs

                        if selectedIcons.isEmpty {
                            emptyState
                        } else {
                            selectedCategoryGrid
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(LColors.textPrimary)
                }
            }
            .onAppear {
                ensureSelectedCategory(preferSelectedIcon: true)
            }
            .onChange(of: searchText) { _ in
                ensureSelectedCategory()
            }
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groupedIcons, id: \.category) { group in
                    Button {
                        selectedCategory = group.category
                    } label: {
                        categoryTab(
                            title: group.category,
                            count: group.icons.count,
                            isSelected: selectedCategoryName == group.category
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var selectedCategoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(selectedCategoryName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("\(selectedIcons.count)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.75))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface)
                    )

                Spacer(minLength: 0)
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: 6
                ),
                spacing: 10
            ) {
                ForEach(selectedIcons) { icon in
                    Button {
                        selectedIcon = icon.name
                    } label: {
                        iconCell(icon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(LColors.textSecondary.opacity(0.75))

            Text("No icons found")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }

    private func categoryTab(title: String, count: Int, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)

            Text("\(count)")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? LColors.bg.opacity(0.72) : LColors.textSecondary.opacity(0.8))
        }
        .foregroundStyle(isSelected ? LColors.bg : LColors.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.glassSurface))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(isSelected ? Color.white.opacity(0.18) : LColors.glassBorder, lineWidth: 1)
        }
    }

    private func ensureSelectedCategory(preferSelectedIcon: Bool = false) {
        guard !groupedIcons.isEmpty else {
            selectedCategory = ""
            return
        }

        if preferSelectedIcon,
           let selectedIconCategory = groupedIcons.first(where: { group in
               group.icons.contains { $0.name == selectedIcon }
           })?.category {
            selectedCategory = selectedIconCategory
            return
        }

        if !groupedIcons.contains(where: { $0.category == selectedCategory }) {
            selectedCategory = groupedIcons.first?.category ?? ""
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LColors.textSecondary.opacity(0.7))
            
            TextField("Search icons", text: $searchText)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(LColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LColors.glassSurface,
            in: RoundedRectangle(cornerRadius: LSpacing.inputRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: LSpacing.inputRadius)
                .strokeBorder(LColors.glassBorder, lineWidth: 1)
        }
    }
    
    private func iconCell(_ icon: LumeyIconItem) -> some View {
        let isSelected = selectedIcon == icon.name
        
        return LumeyIconView(iconId: icon.name, size: 24)
            .foregroundStyle(
                isSelected
                ? AnyShapeStyle(LGradients.header)
                : AnyShapeStyle(LColors.textPrimary)
            )
            .frame(width: 48, height: 48)
            .background(
                isSelected ? LColors.glassSurface2 : LColors.glassSurface,
                in: RoundedRectangle(cornerRadius: LSpacing.inputRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: LSpacing.inputRadius)
                    .strokeBorder(
                        isSelected ? LColors.glassBorderStrong : LColors.glassBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Inline Icon Renderer

struct LumeyIconView: View {
    let iconId: String
    var size: CGFloat = 22
    
    private var icon: LumeyIconItem? {
        LumeyIconLibrary.allIcons.first { $0.name == iconId }
    }
    
    var body: some View {
        Group {
            if let icon {
                switch icon.source {
                case .asset:
                    Image(icon.name)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    
                case .sfSymbol:
                    Image(systemName: icon.name)
                        .font(.system(size: size, weight: .semibold))
                }
            } else if UIImage(named: iconId) != nil {
                Image(iconId)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: iconId)
                    .font(.system(size: size, weight: .semibold))
            }
        }
        .frame(width: size, height: size)
    }
}
