import SwiftUI

struct ReadingCategorySliderPicker: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @Binding var selection: PreferredReadingCategory
    @GestureState private var dragTranslation: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 64

    private let inset: CGFloat = 6
    private let categories = PreferredReadingCategory.allCases

    private var selectedIndex: Int {
        categories.firstIndex(of: selection) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            let optionWidth = max(0, geometry.size.width - inset * 2) / CGFloat(categories.count)
            let position = min(CGFloat(categories.count - 1), max(0, CGFloat(selectedIndex) + logicalTranslation / max(1, optionWidth)))
            let activeIndex = Int(position.rounded())
            let visualPosition = layoutDirection == .rightToLeft ? CGFloat(categories.count - 1) - position : position

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1.2)

                BubblyTileSurface(tint: theme.palette.rotation[activeIndex], cornerRadius: 16)
                    .frame(width: optionWidth, height: height - inset * 2)
                    .position(x: visualPosition * optionWidth + inset + optionWidth / 2, y: height / 2)
                    .animation(reduceMotion || dragTranslation != 0 ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: position)
                    .allowsHitTesting(false)

                HStack(spacing: 0) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        Button { selection = category } label: {
                            Text(category.title)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .bubblyIconMaterial(tint: index == activeIndex ? theme.palette.textPrimary : theme.palette.rotation[index])
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == category ? .isSelected : [])
                        .accessibilityIdentifier("reading-category-\(category.rawValue)")
                    }
                }
                .padding(inset)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .updating($dragTranslation) { value, translation, _ in
                        // Leave vertical drags to the page's scroll view.
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        translation = value.translation.width
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height), optionWidth > 0 else { return }
                        let translation = layoutDirection == .rightToLeft ? -value.translation.width : value.translation.width
                        let index = min(categories.count - 1, max(0, Int((CGFloat(selectedIndex) + translation / optionWidth).rounded())))
                        selection = categories[index]
                    }
            )
        }
        .frame(height: height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preferred Reading Categories")
        .accessibilityIdentifier("reading-preferred-category")
    }

    private var logicalTranslation: CGFloat {
        layoutDirection == .rightToLeft ? -dragTranslation : dragTranslation
    }
}
