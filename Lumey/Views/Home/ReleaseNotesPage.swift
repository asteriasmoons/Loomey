//
//  ReleaseNotesPage.swift
//  Lumey
//

import SwiftUI

struct ReleaseNotesPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appTheme) private var theme
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
                ZStack {
                    Circle()
                        .fill(theme.palette.background)

                    BubblyIconMaterial(tint: accentColor(for: 0))
                        .mask {
                            Circle()
                                .strokeBorder(lineWidth: 1.2)
                        }

                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .bubblyReleaseMaterial(tint: accentColor(for: 0))
                }
                .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
        }
    }

    private var introCard: some View {
        let tint = accentColor(for: 0)

        return GlassCard(variant: .featured, borderColor: tint) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.palette.surface)

                    BubblyIconMaterial(tint: tint)
                        .mask {
                            Circle()
                                .strokeBorder(lineWidth: 1)
                        }

                    BubblyIconMaterial(tint: tint)
                        .mask {
                            Image("timebook")
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: 20, height: 20)
                }
                .frame(width: 42, height: 42)

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
        .bubblyReleaseBorder(tint: tint, cornerRadius: 24)
    }

    private func releaseNoteCard(_ note: LumeyReleaseNote, accentIndex: Int) -> some View {
        let isExpanded = expandedIDs.contains(note.id)
        let tint = accentColor(for: accentIndex + 1)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                toggle(note.id)
            }
        } label: {
            GlassCard(
                cornerRadius: 20,
                padding: 16,
                variant: isExpanded ? .featured : .primary,
                borderColor: tint
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.versionTitle)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)

                            Text(note.releaseDate)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .bubblyReleaseMaterial(tint: tint)

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
                            .bubblyReleaseMaterial(tint: tint)
                    }

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 10) {
                            fullWidthDivider(tint: tint)

                            ForEach(Array(note.bullets.enumerated()), id: \.offset) { index, bullet in
                                bulletRow(
                                    bullet,
                                    tint: accentColor(for: accentIndex + 1 + index)
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .bubblyReleaseBorder(tint: tint, cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private func fullWidthDivider(tint: Color) -> some View {
        GeometryReader { proxy in
            let dotCount = max(Int(proxy.size.width / 8), 1)

            HStack(spacing: 4) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    BubblyIconMaterial(tint: tint)
                        .mask { Circle() }
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 4)
    }

    private func bulletRow(_ text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BubblyIconMaterial(tint: tint)
                .mask { Circle() }
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
        let rotation = theme.palette.rotation
        return rotation[index % rotation.count]
    }

    private func toggle(_ id: String) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }
}

private extension View {
    func bubblyReleaseMaterial(tint: Color) -> some View {
        foregroundStyle(.clear)
            .overlay {
                BubblyIconMaterial(tint: tint)
                    .mask { self }
                    .allowsHitTesting(false)
            }
    }

    func bubblyReleaseBorder(tint: Color, cornerRadius: CGFloat) -> some View {
        overlay {
            BubblyIconMaterial(tint: tint)
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(lineWidth: 1)
                }
                .allowsHitTesting(false)
        }
    }
}
