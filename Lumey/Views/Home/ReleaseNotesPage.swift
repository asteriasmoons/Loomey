//
//  ReleaseNotesPage.swift
//  Lumey
//

import SwiftUI

struct ReleaseNotesPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var expandedIDs: Set<String> = [ReleaseNotesCatalog.notes.first?.id ?? ""]

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    introCard

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(ReleaseNotesCatalog.notes.enumerated()), id: \.element.id) { index, note in
                            releaseNoteCard(note, accentIndex: index)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, horizontalSizeClass == .regular ? 36 : 120)
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Release Notes")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Everything new in Loomey, collected in one place.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.primary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.accents.primary, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var introCard: some View {
        GlassCard(variant: .featured) {
            HStack(spacing: 14) {
                Image("timebook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LColors.accents.contrast)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LColors.iconContainer.primary))
                    .overlay(Circle().strokeBorder(LColors.accents.contrast, lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text("What changed")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)

                    Text("Open any update to see the highlights in a cleaner, theme-aware format.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func releaseNoteCard(_ note: LumeyReleaseNote, accentIndex: Int) -> some View {
        let isExpanded = expandedIDs.contains(note.id)
        let tint = accentColor(for: accentIndex)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                toggle(note.id)
            }
        } label: {
            GlassCard(cornerRadius: 20, padding: 16, variant: isExpanded ? .featured : .primary) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.versionTitle)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text(note.releaseDate)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(tint)

                            Text(note.headline)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(isExpanded ? "chevup" : "chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(tint)
                    }

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 10) {
                            fullWidthDivider

                            ForEach(Array(note.bullets.enumerated()), id: \.offset) { index, bullet in
                                bulletRow(
                                    bullet,
                                    tint: bulletTint(
                                        baseTint: tint,
                                        index: index
                                    )
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private var fullWidthDivider: some View {
        GeometryReader { proxy in
            let dotCount = max(Int(proxy.size.width / 8), 1)

            HStack(spacing: 4) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .strokeBorder(LColors.border.nestedStrong, lineWidth: 1)
                        .background(Circle().fill(LColors.surface.nested))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 4)
    }

    private func bulletRow(_ text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.text.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func accentColor(for index: Int) -> Color {
        switch index % 4 {
        case 0: return LColors.accents.primary
        case 1: return LColors.accents.contrast
        case 2: return LColors.accents.secondary
        default: return LColors.accents.special
        }
    }

    private func bulletTint(baseTint: Color, index: Int) -> Color {
        switch index % 3 {
        case 0: return baseTint
        case 1: return LColors.accents.secondary
        default: return LColors.accents.contrast
        }
    }

    private func toggle(_ id: String) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }
}
