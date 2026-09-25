//
//  AppThemeSettingsSection.swift
//  Lumey
//

import SwiftUI

struct AppThemeSettingsSection: View {
    @EnvironmentObject private var themeController: LumeyThemeController
    @Environment(\.appTheme) private var appTheme

    let borderColor: Color

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App Theme")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)

            GlassCard(cornerRadius: 20, padding: 16, variant: .featured, borderColor: borderColor) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Switch Loomey's overall palette without changing the structure of the app.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(LumeyAppTheme.selectableThemes.enumerated()), id: \.element.id) { index, theme in
                            themeOption(theme, borderColor: accent(at: index))
                        }
                    }
                }
            }
        }
    }

    private func themeOption(_ theme: LumeyAppTheme, borderColor: Color) -> some View {
        let isSelected = themeController.selectedTheme == theme
        let palette = theme.palette

        return Button {
            themeController.select(theme)
        } label: {
            GlassCard(
                cornerRadius: 18,
                padding: 14,
                selected: isSelected,
                contentAlignment: .leading,
                variant: .primary,
                borderColor: borderColor
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        themeSwatch(palette.appBackground)
                        themeSwatch(palette.secondarySurface)
                        themeSwatch(palette.primaryAccent)
                        themeSwatch(palette.secondaryAccent)
                        themeSwatch(palette.tertiaryAccent)

                        Spacer(minLength: 0)

                        if isSelected {
                            Image("checkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(borderColor)
                        }
                    }

                    Text(theme.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textPrimary)

                    Text(theme.subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Capsule(style: .continuous)
                        .fill(palette.progressFill)
                        .frame(height: 8)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LColors.border.primary, lineWidth: 0.8)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func themeSwatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .strokeBorder(LColors.border.nested, lineWidth: 0.8)
            )
    }

    private func accent(at index: Int) -> Color {
        let rotation = appTheme.palette.rotation
        return rotation[index % rotation.count]
    }
}
