//
//  ChallengeAnnouncementCard.swift
//  Lumey
//

import SwiftUI

// MARK: - Announcement Card

struct ChallengeAnnouncementCard: View {
    let announcement: ChallengeFeedAnnouncementDTO
    let profile: ChallengeUserProfileDTO?
    let onDeleteTapped: (() -> Void)?
    
    @State private var isCollapsed = false
    @Environment(\.appTheme) private var theme
    
    private var resolvedAuthorAvatarURL: String? {
        let announcementURL = announcement.avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !announcementURL.isEmpty {
            return announcementURL
        }

        let profileURL = profile?.avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return profileURL.isEmpty ? nil : profileURL
    }

    private var resolvedAuthorAvatarName: String? {
        let announcementName = announcement.avatarName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !announcementName.isEmpty {
            return announcementName
        }

        let profileName = profile?.avatarName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return profileName.isEmpty ? nil : profileName
    }

    var body: some View {
        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image("megaphone")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)

                    Text("ANNOUNCEMENT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)

                    Spacer()

                    if let date = announcement.createdDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(isCollapsed ? "chevdown" : "chevup")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(LColors.glassSurface)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                    Text(announcement.title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                   if !isCollapsed {
                    AnnouncementRichBodyView(
                        bodyText: announcement.body,
                        fontSize: 14,
                        color: LColors.textSecondary,
                        iconSize: 16
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 6) {
                    UserAvatarView(
                        avatarURL: resolvedAuthorAvatarURL,
                        avatarName: resolvedAuthorAvatarName,
                        size: 32,
                        iconSize: 18
                    )

                    Text(announcement.username)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Spacer()

                    if let onDeleteTapped {
                        Button {
                            onDeleteTapped()
                        } label: {
                            Image("trash")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .bubblyIconMaterial(tint: theme.palette.primaryAction)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(LColors.iconContainer.primary)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Rich Body Renderer

/// Parses announcement body text with support for:
/// - `**bold**`  `*italic*`  `~~strikethrough~~`  `` `inline code` ``  `{{iconName}}`
/// - `> quote text`  (gradient strip on left)
/// - `>> callout text`  (GlassCard, no icon)
struct AnnouncementRichBodyView: View {
    let bodyText: String
    var fontSize: CGFloat = 14
    var color: Color = LColors.textSecondary
    var iconSize: CGFloat = 16
    @Environment(\.appTheme) private var theme

    private var blocks: [RichBlock] {
        Self.parseBlocks(bodyText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let segments):
                    renderInline(segments)

                case .quote(let segments):
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .bubblyIconMaterial(tint: theme.palette.primaryAction)
                            .frame(width: 3)

                        renderInline(segments)
                    }
                    .padding(.vertical, 4)

                case .callout(let segments):
                    renderInline(segments)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LColors.glassSurface2)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(
                                            LColors.gradientBlue.opacity(0.18)
                                        )
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            LColors.gradientBlue.opacity(0.92),
                                            lineWidth: 1.05
                                        )
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Inline Renderer

    private func renderInline(_ segments: [InlineSegment]) -> some View {
        var iconIndex = 0

        return segments.reduce(Text("")) { result, segment in
            switch segment {
            case .plain(let str):
                return result + Text(str)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(color)

            case .bold(let str):
                return result + Text(str)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)

            case .italic(let str):
                return result + Text(str)
                    .font(Font(UIFont.italicSystemFont(ofSize: fontSize)))
                    .foregroundColor(color)

            case .strikethrough(let str):
                return result + Text(str)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .strikethrough(true, color: color.opacity(0.6))
                    .foregroundColor(color.opacity(0.5))

            case .underline(let str):
                return result + Text(str)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .underline(true, color: color.opacity(0.85))
                    .foregroundColor(color)

            case .code(let str):
                if let img = Self.renderCodePill(str, fontSize: fontSize) {
                    return result + Text(Image(uiImage: img))
                        .baselineOffset(-6)
                } else {
                    return result + Text(str)
                        .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .baselineOffset(-4)
                }

            case .icon(let name):
                defer { iconIndex += 1 }
                if let img = Self.renderIcon(named: name, size: iconSize, accentIndex: iconIndex) {
                    return result + Text(Image(uiImage: img))
                } else {
                    return result + Text("{{\(name)}}")
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            }
        }
        // .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Block Parser

    private enum RichBlock {
        case paragraph([InlineSegment])
        case quote([InlineSegment])
        case callout([InlineSegment])
    }

    private static func parseBlocks(_ input: String) -> [RichBlock] {
        let lines = input.components(separatedBy: "\n")
        var blocks: [RichBlock] = []

        for line in lines {
            if line.hasPrefix(">> ") {
                let content = String(line.dropFirst(3))
                blocks.append(.callout(parseInline(content)))
            } else if line.hasPrefix("> ") {
                let content = String(line.dropFirst(2))
                blocks.append(.quote(parseInline(content)))
            } else {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    // Preserve blank lines as empty paragraphs for spacing
                    blocks.append(.paragraph([.plain(" ")]))
                } else {
                    blocks.append(.paragraph(parseInline(line)))
                }
            }
        }

        return blocks
    }

    // MARK: - Inline Parser

    enum InlineSegment {
        case plain(String)
        case bold(String)
        case italic(String)
        case strikethrough(String)
        case underline(String)
        case code(String)
        case icon(String)
    }

    /// Scans text for inline markers in priority order:
    /// `{{icon}}` → `` `code` `` → `**bold**` → `~~strike~~` → `*italic*`
    private static func parseInline(_ input: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        var remaining = input[...]

        while !remaining.isEmpty {
            // Find the earliest marker
            let candidates: [(range: Range<Substring.Index>, type: MarkerType)] = [
                findMarker(in: remaining, open: "{{", close: "}}", type: .icon),
                findMarker(in: remaining, open: "`", close: "`", type: .code),
                findMarker(in: remaining, open: "**", close: "**", type: .bold),
                findMarker(in: remaining, open: "~~", close: "~~", type: .strikethrough),
                findMarker(in: remaining, open: "<u>", close: "</u>", type: .underline),
                findMarker(in: remaining, open: "*", close: "*", type: .italic),
            ].compactMap { $0 }

            guard let earliest = candidates.min(by: { $0.range.lowerBound < $1.range.lowerBound }) else {
                // No more markers — rest is plain text
                segments.append(.plain(String(remaining)))
                break
            }

            // Text before the marker
            let before = remaining[remaining.startIndex..<earliest.range.lowerBound]
            if !before.isEmpty {
                segments.append(.plain(String(before)))
            }

            // Extract content between open/close markers
            let openLen = earliest.type.openMarker.count
            let closeLen = earliest.type.closeMarker.count
            let contentStart = remaining.index(earliest.range.lowerBound, offsetBy: openLen)
            let contentEnd = remaining.index(earliest.range.upperBound, offsetBy: -closeLen)

            if contentStart < contentEnd {
                let content = String(remaining[contentStart..<contentEnd])
                    .trimmingCharacters(in: .whitespaces)

                if !content.isEmpty {
                    switch earliest.type {
                    case .icon: segments.append(.icon(content))
                    case .code: segments.append(.code(content))
                    case .bold: segments.append(.bold(content))
                    case .strikethrough: segments.append(.strikethrough(content))
                    case .underline: segments.append(.underline(content))
                    case .italic: segments.append(.italic(content))
                    }
                }
            }

            remaining = remaining[earliest.range.upperBound...]
        }

        return segments
    }

    private enum MarkerType {
        case icon, code, bold, strikethrough, underline, italic

        var openMarker: String {
            switch self {
            case .icon: return "{{"
            case .code: return "`"
            case .bold: return "**"
            case .strikethrough: return "~~"
            case .underline: return "<u>"
            case .italic: return "*"
            }
        }

        var closeMarker: String {
            switch self {
            case .icon: return "}}"
            case .code: return "`"
            case .bold: return "**"
            case .strikethrough: return "~~"
            case .underline: return "</u>"
            case .italic: return "*"
            }
        }
    }

    /// Finds a matched open/close marker pair in the substring.
    /// Returns the full range from open start to close end, or nil.
    private static func findMarker(
        in text: Substring,
        open: String,
        close: String,
        type: MarkerType
    ) -> (range: Range<Substring.Index>, type: MarkerType)? {
        guard let openRange = text.range(of: open) else { return nil }

        let afterOpen = text[openRange.upperBound...]

        // For italic (*), skip if it's actually a bold marker (**)
        if type == .italic, openRange.upperBound < text.endIndex {
            let nextChar = text[openRange.upperBound]
            if nextChar == "*" { return nil }
        }

        guard let closeRange = afterOpen.range(of: close) else { return nil }

        // For italic close, make sure we're not consuming a bold close (**)
        if type == .italic, closeRange.upperBound < text.endIndex {
            let nextChar = text[closeRange.upperBound]
            if nextChar == "*" { return nil }
        }
        if type == .italic, closeRange.lowerBound > afterOpen.startIndex {
            let prevIndex = text.index(before: closeRange.lowerBound)
            if text[prevIndex] == "*" { return nil }
        }

        // Content must not be empty
        if openRange.upperBound == closeRange.lowerBound { return nil }

        let fullRange = openRange.lowerBound..<closeRange.upperBound
        return (range: fullRange, type: type)
    }

    // MARK: - Image Renderers

    @MainActor
    private static func renderIcon(named iconName: String, size: CGFloat, accentIndex: Int) -> UIImage? {
        let icon = LumeyIconLibrary.allIcons.first { $0.name == iconName }
        let tint = accentIndex.isMultiple(of: 2)
            ? LColors.accents.primary
            : LColors.accents.contrast

        let view: AnyView
        if let icon {
            switch icon.source {
            case .asset:
                view = AnyView(
                    Image(icon.name)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .bubblyIconMaterial(tint: tint)
                        .frame(width: size, height: size)
                )
            case .sfSymbol:
                view = AnyView(
                    Image(systemName: icon.name)
                        .font(.system(size: size * 0.75, weight: .semibold))
                        .bubblyIconMaterial(tint: tint)
                        .frame(width: size, height: size)
                )
            }
        } else if UIImage(named: iconName) != nil {
            view = AnyView(
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .bubblyIconMaterial(tint: tint)
                    .frame(width: size, height: size)
            )
        } else {
            return nil
        }

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    /// Renders inline code as a polished pill with monospaced text
    /// on a subtle glass background, returned as a UIImage for
    /// embedding in Text via `Text(Image(uiImage:))`.
    @MainActor
    private static func renderCodePill(_ code: String, fontSize: CGFloat) -> UIImage? {
        let pill = Text(code)
            .font(.system(size: fontSize - 1.5, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LColors.border.nestedStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(LColors.border.subtle, lineWidth: 0.5)
            )

        let renderer = ImageRenderer(content: pill)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else {
            return nil
        }

        let scale = image.scale
        let topInset: CGFloat = 5
        let canvasSize = CGSize(
            width: image.size.width,
            height: image.size.height + topInset
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let canvasRenderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return canvasRenderer.image { _ in
            image.draw(
                in: CGRect(
                    x: 0,
                    y: topInset,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
    }
}

// MARK: - Icon Insert Picker (for composer)

/// A sheet that displays the full icon library. Tapping an icon
/// fires `onInsert` with the icon name — the caller appends
/// `{{iconName}}` to the text field.
struct AnnouncementIconInsertPicker: View {
    @Environment(\.dismiss) private var dismiss

    let onInsert: (String) -> Void

    @State private var searchText = ""

    private var filteredIcons: [LumeyIconItem] {
        LumeyIconLibrary.search(searchText)
    }

    private var groupedIcons: [(category: String, icons: [LumeyIconItem])] {
        Dictionary(grouping: filteredIcons) { $0.category }
            .map { (category: $0.key, icons: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Insert Icon")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.headingPrimary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LColors.accents.special)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LColors.accents.contrast, lineWidth: 1.2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .safeAreaPadding(.top)

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary.opacity(0.7))

                    TextField("Search icons", text: $searchText)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LColors.glassSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Grid
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(groupedIcons, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.category)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)

                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                                    spacing: 10
                                ) {
                                    ForEach(group.icons) { icon in
                                        Button {
                                            onInsert(icon.name)
                                        } label: {
                                            LumeyIconView(iconId: icon.name, size: 24)
                                                .foregroundStyle(LColors.textPrimary)
                                                .frame(width: 48, height: 48)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(LColors.glassSurface)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
