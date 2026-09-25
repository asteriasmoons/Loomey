//
//  GoalIconPickerRow.swift
//  Lumey
//

import SwiftUI

struct GoalIconPickerRow: View {
    @Environment(\.appTheme) private var theme

    @Binding var iconName: String
    var tint: Color? = nil
    let onPickIcon: () -> Void

    private var resolvedTint: Color {
        tint ?? theme.palette.primaryAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Icon")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            Button(action: onPickIcon) {
                HStack(spacing: 12) {
                    LumeyIconView(
                        iconId: iconName,
                        size: 24
                    )
                    .foregroundStyle(resolvedTint)
                    .bubblyIconMaterial(tint: resolvedTint)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(theme.palette.raisedSurface)
                    )
                    .overlay {
                        BubblyIconMaterial(tint: resolvedTint)
                            .mask { Circle().strokeBorder(lineWidth: 1) }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose Icon")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                        
                        Text(iconName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.textSecondary)
                        .bubblyIconMaterial(tint: resolvedTint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .fill(LColors.surface.nested)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .strokeBorder(
                        resolvedTint,
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
