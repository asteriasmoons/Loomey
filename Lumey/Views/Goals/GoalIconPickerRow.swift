//
//  GoalIconPickerRow.swift
//  Lumey
//

import SwiftUI

struct GoalIconPickerRow: View {
    @Binding var iconName: String
    let onPickIcon: () -> Void
    
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
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.iconContainer.primary)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LGradients.header,
                                lineWidth: 1
                            )
                    )
                    
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
                        LColors.border.nested,
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
