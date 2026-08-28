//
//  FormattingTextEditor.swift
//  Lumey
//

import SwiftUI
import UIKit

// MARK: - Custom Attribute Keys

extension NSAttributedString.Key {
    static let mdBold          = NSAttributedString.Key("lumey.md.bold")
    static let mdItalic        = NSAttributedString.Key("lumey.md.italic")
    static let mdStrikethrough = NSAttributedString.Key("lumey.md.strikethrough")
    static let mdUnderline     = NSAttributedString.Key("lumey.md.underline")
    static let mdCode          = NSAttributedString.Key("lumey.md.code")
    static let mdIcon          = NSAttributedString.Key("lumey.md.icon")
    static let mdQuote         = NSAttributedString.Key("lumey.md.quote")
    static let mdCallout       = NSAttributedString.Key("lumey.md.callout")
}

// MARK: - Font Helpers

private enum RichFonts {
    static func rounded(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let d = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: d, size: size)
        }
        return base
    }

    static func roundedItalic(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)

        var traits = base.fontDescriptor.symbolicTraits
        traits.insert(.traitItalic)

        if let italicDescriptor = base.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: italicDescriptor, size: size)
        }

        return UIFont.italicSystemFont(ofSize: size)
    }

    static func mono(_ size: CGFloat) -> UIFont {
        UIFont.monospacedSystemFont(ofSize: size, weight: .medium)
    }
}

// MARK: - FormattingTextEditor

struct FormattingTextEditor: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Body"
    var minHeight: CGFloat = 100
    var fontSize: CGFloat = 13
    var onIconPickerTapped: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = FormattingUITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.tintColor = UIColor.white.withAlphaComponent(0.7)
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.isScrollEnabled = true
        tv.keyboardAppearance = .dark
        tv.typingAttributes = context.coordinator.baseAttrs

        // Set initial content from markdown binding
        tv.attributedText = RichMarkdownConverter.markdownToAttributed(
            text, fontSize: fontSize
        )

        tv.inputAccessoryView = context.coordinator.buildToolbar(textView: tv)

        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        guard !context.coordinator.isInternalEdit else { return }

        let current = RichMarkdownConverter.attributedToMarkdown(tv.attributedText)
        if current != text {
            let sel = tv.selectedRange
            tv.attributedText = RichMarkdownConverter.markdownToAttributed(
                text, fontSize: fontSize
            )
            if sel.location <= tv.attributedText.length {
                tv.selectedRange = sel
            }

            tv.typingAttributes = context.coordinator.baseAttrs
            tv.textColor = .white
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FormattingTextEditor
        var isInternalEdit = false
        var lastSelectedRange: NSRange = NSRange(location: 0, length: 0)

        var baseAttrs: [NSAttributedString.Key: Any] {
            [
                .font: RichFonts.rounded(parent.fontSize, weight: .semibold),
                .foregroundColor: UIColor.white,
            ]
        }

        init(_ parent: FormattingTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ tv: UITextView) {
            isInternalEdit = true
            parent.text = RichMarkdownConverter.attributedToMarkdown(tv.attributedText)
            tv.setNeedsDisplay()
            isInternalEdit = false
        }
        
        func textViewDidChangeSelection(_ tv: UITextView) {
            if tv.selectedRange.length > 0 {
                lastSelectedRange = tv.selectedRange
            }
        }
        
        private final class GradientPillButton: UIButton {
            private let gradient = CAGradientLayer()

            override init(frame: CGRect) {
                super.init(frame: frame)
                setupGradient()
            }

            required init?(coder: NSCoder) {
                super.init(coder: coder)
                setupGradient()
            }

            private func setupGradient() {
                gradient.colors = [
                    UIColor(LColors.gradientBlue).cgColor,
                    UIColor(LColors.gradientPurple).cgColor
                ]
                gradient.startPoint = CGPoint(x: 0, y: 0)
                gradient.endPoint = CGPoint(x: 1, y: 1)
                layer.insertSublayer(gradient, at: 0)
                clipsToBounds = true
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                gradient.frame = bounds
                gradient.cornerRadius = bounds.height / 2
                layer.cornerRadius = bounds.height / 2
            }
        }

        // MARK: Toolbar

        func buildToolbar(textView: UITextView) -> UIView {
            let bar = UIView()
            bar.backgroundColor = .clear
            bar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52)

            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 10
            stack.alignment = .center
            stack.translatesAutoresizingMaskIntoConstraints = false
            bar.addSubview(stack)

            let formatButton = makeGradientPillButton(title: "Add Format")
            formatButton.menu = UIMenu(title: "", children: [
                UIAction(title: "Bold") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.toggleInline(.mdBold, on: tv)
                },
                UIAction(title: "Italic") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.toggleInline(.mdItalic, on: tv)
                },
                UIAction(title: "Strikethrough") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.toggleInline(.mdStrikethrough, on: tv)
                },
                UIAction(title: "Underline") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.toggleInline(.mdUnderline, on: tv)
                },
                UIAction(title: "Code") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.toggleInline(.mdCode, on: tv)
                },
                UIAction(title: "Quote") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.insertLinePrefix("> ", on: tv)
                },
                UIAction(title: "Callout") { [weak self, weak textView] _ in
                    guard let tv = textView else { return }
                    self?.insertLinePrefix(">> ", on: tv)
                },
                UIAction(title: "Insert Icon") { [weak self] _ in
                    self?.parent.onIconPickerTapped?()
                }
            ])
            formatButton.showsMenuAsPrimaryAction = true
            stack.addArrangedSubview(formatButton)

            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            stack.addArrangedSubview(spacer)

            let done = makeGradientPillButton(title: "Done")
            done.addAction(UIAction { [weak textView] _ in
                textView?.resignFirstResponder()
            }, for: .touchUpInside)
            stack.addArrangedSubview(done)

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12),
                stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
                stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 6),
                stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -6)
            ])

            return bar
        }
        
        private func makeGradientPillButton(title: String) -> UIButton {
            let btn = GradientPillButton(type: .system)
            btn.accessibilityLabel = title
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            return btn
        }

        // MARK: Toggle Inline Formatting

        func toggleInline(_ key: NSAttributedString.Key, on tv: UITextView) {
            let fs = parent.fontSize

            let activeRange = tv.selectedRange.length > 0 ? tv.selectedRange : lastSelectedRange

            if activeRange.length > 0 {
                // Has selection — toggle on the selected range
                let ms = NSMutableAttributedString(attributedString: tv.attributedText)
                let range = activeRange
                let sel = activeRange

                // Check if first character already has this attribute
                let existing = ms.attribute(key, at: range.location, effectiveRange: nil)
                let isOn = existing != nil

                ms.enumerateAttributes(in: range, options: []) { attrs, subRange, _ in
                    var newAttrs = attrs
                    if isOn {
                        newAttrs.removeValue(forKey: key)
                    } else {
                        newAttrs[key] = true
                    }
                    let visual = Self.visualAttrs(from: newAttrs, fontSize: fs)
                    ms.setAttributes(visual, range: subRange)
                }

                tv.attributedText = ms
                tv.selectedRange = sel
                lastSelectedRange = sel
            } else {
                // No selection — toggle typing attributes for next typed character
                var typing = tv.typingAttributes
                let isOn = typing[key] != nil
                if isOn {
                    typing.removeValue(forKey: key)
                } else {
                    typing[key] = true
                }
                tv.typingAttributes = Self.visualAttrs(from: typing, fontSize: fs)
            }

            textViewDidChange(tv)
        }

        /// Given a dictionary that may contain custom md keys,
        /// produce the full visual attribute set.
        static func visualAttrs(from raw: [NSAttributedString.Key: Any], fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
            let isBold   = raw[.mdBold] != nil
            let isItalic = raw[.mdItalic] != nil
            let isStrike    = raw[.mdStrikethrough] != nil
            let isUnderline = raw[.mdUnderline] != nil
            let isCode      = raw[.mdCode] != nil
            let iconName    = raw[.mdIcon] as? String

            var attrs: [NSAttributedString.Key: Any] = [:]

            // Carry forward custom keys
            if isBold   { attrs[.mdBold] = true }
            if isItalic { attrs[.mdItalic] = true }
            if isStrike    { attrs[.mdStrikethrough] = true }
            if isUnderline { attrs[.mdUnderline] = true }
            if isCode      { attrs[.mdCode] = true }
            if let icon = iconName { attrs[.mdIcon] = icon }

            // Font
            if isCode {
                attrs[.font] = RichFonts.mono(fontSize)
                attrs[.baselineOffset] = 0
                attrs[.foregroundColor] = UIColor.white.withAlphaComponent(0.92)
                attrs[.backgroundColor] = UIColor.white.withAlphaComponent(0.1)
            } else {
                let weight: UIFont.Weight = isBold ? .black : .semibold
                let font = isItalic
                    ? RichFonts.roundedItalic(fontSize, weight: weight)
                    : RichFonts.rounded(fontSize, weight: weight)
                attrs[.font] = font
                attrs[.foregroundColor] = UIColor.white
            }

            // Strikethrough
            if isStrike {
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                attrs[.strikethroughColor] = UIColor.white.withAlphaComponent(0.5)
            }
            
            // Underline
            if isUnderline {
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attrs[.underlineColor] = UIColor.white.withAlphaComponent(0.85)
            }

            return attrs
        }

        // MARK: Block-Level Insert

        func insertLinePrefix(_ prefix: String, on tv: UITextView) {
            let full = tv.attributedText.string as NSString
            let lineRange = full.lineRange(for: tv.selectedRange)
            let loc = lineRange.location

            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            let insert = NSAttributedString(string: prefix, attributes: baseAttrs)
            ms.insert(insert, at: loc)
            tv.attributedText = ms
            tv.selectedRange = NSRange(location: loc + prefix.count, length: 0)

            textViewDidChange(tv)
        }

        // MARK: Icon Insert

        func insertIcon(named iconName: String, into tv: UITextView) {
            let size = parent.fontSize + 2
            guard let img = Self.renderIconImage(named: iconName, size: size) else { return }

            let attachment = NSTextAttachment()
            attachment.image = img
            attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)

            let iconStr = NSMutableAttributedString(attachment: attachment)
            iconStr.addAttribute(.mdIcon, value: iconName,
                                 range: NSRange(location: 0, length: iconStr.length))

            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            let loc = tv.selectedRange.location
            ms.insert(iconStr, at: loc)

            // Add a zero-width space after so cursor isn't stuck on the attachment
            let spacer = NSAttributedString(
                string: "\u{200B}",
                attributes: [
                    .font: RichFonts.rounded(parent.fontSize, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
            )
            ms.insert(spacer, at: loc + iconStr.length)

            tv.attributedText = ms
            tv.selectedRange = NSRange(location: loc + iconStr.length + 1, length: 0)
            print(tv.typingAttributes)
            tv.typingAttributes = [
                .font: RichFonts.rounded(parent.fontSize, weight: .semibold),
                .foregroundColor: UIColor.white
            ]

            textViewDidChange(tv)
        }

        @MainActor
        static func renderIconImage(named iconName: String, size: CGFloat) -> UIImage? {
            let icon = LumeyIconLibrary.allIcons.first { $0.name == iconName }
            let view: AnyView

            if let icon {
                switch icon.source {
                case .asset:
                    view = AnyView(
                        Image(icon.name).renderingMode(.template).resizable().scaledToFit()
                            .foregroundStyle(LColors.accents.primary)
                            .frame(width: size, height: size)
                    )
                case .sfSymbol:
                    view = AnyView(
                        Image(systemName: icon.name)
                            .font(.system(size: size * 0.75, weight: .semibold))
                            .foregroundStyle(LColors.accents.contrast)
                            .frame(width: size, height: size)
                    )
                }
            } else if UIImage(named: iconName) != nil {
                view = AnyView(
                    Image(iconName).renderingMode(.template).resizable().scaledToFit()
                        .foregroundStyle(LColors.accents.secondary)
                        .frame(width: size, height: size)
                )
            } else {
                return nil
            }

            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }

        // MARK: Button Factory

        private func makeBtn(_ title: String, a11y: String,
                             isBold: Bool, isItalic: Bool, isStrike: Bool,
                             action: @escaping () -> Void) -> UIButton {
            let btn = UIButton(type: .system)
            btn.accessibilityLabel = a11y

            var weight: UIFont.Weight = .semibold
            if isBold { weight = .black }
            var font = UIFont.systemFont(ofSize: 14, weight: weight)
            if isItalic, let d = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
                font = UIFont(descriptor: d, size: 14)
            }

            let attr = NSMutableAttributedString(string: title, attributes: [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            ])
            if isStrike {
                attr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue,
                                  range: NSRange(location: 0, length: title.count))
            }
            btn.setAttributedTitle(attr, for: .normal)
            btn.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            btn.layer.cornerRadius = 8
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
            return btn
        }
    }
}

private final class FormattingUITextView: UITextView {
    override func draw(_ rect: CGRect) {
        guard let attributedText else {
            super.draw(rect)
            return
        }

        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        let textOrigin = CGPoint(
            x: textContainerInset.left,
            y: textContainerInset.top
        )

        attributedText.enumerateAttribute(
            .mdCallout,
            in: NSRange(location: 0, length: attributedText.length),
            options: []
        ) { value, range, _ in
            guard value != nil else { return }

            layoutManager.enumerateLineFragments(
                forGlyphRange: layoutManager.glyphRange(
                    forCharacterRange: range,
                    actualCharacterRange: nil
                )
            ) { _, usedRect, _, _, _ in
                let drawRect = CGRect(
                    x: 0,
                    y: usedRect.minY + textOrigin.y - 4,
                    width: self.bounds.width,
                    height: usedRect.height + 8
                )
                .insetBy(dx: 8, dy: 0)

                let path = UIBezierPath(
                    roundedRect: drawRect,
                    cornerRadius: 8
                )

                UIColor.white.withAlphaComponent(0.045).setFill()
                path.fill()
            }
        }

        super.draw(rect)
    }
}

// MARK: - Markdown ↔ Attributed String Converter

enum RichMarkdownConverter {

    // MARK: Attributed → Markdown

    static func attributedToMarkdown(_ attrStr: NSAttributedString) -> String {
        var md = ""

        attrStr.enumerateAttributes(
            in: NSRange(location: 0, length: attrStr.length),
            options: []
        ) { attrs, range, _ in
            // Icon attachment
            if let iconName = attrs[.mdIcon] as? String {
                md += "{{\(iconName)}}"
                return
            }

            let text = (attrStr.string as NSString).substring(with: range)

            // Skip zero-width spaces used as cursor spacers
            if text == "\u{200B}" { return }

            let isBold = attrs[.mdBold] != nil
            let isItalic = attrs[.mdItalic] != nil
            let isStrike = attrs[.mdStrikethrough] != nil
            let isUnderline = attrs[.mdUnderline] != nil
            let isCode = attrs[.mdCode] != nil
            let isQuote = attrs[.mdQuote] != nil
            let isCallout = attrs[.mdCallout] != nil

            var chunk = text
            if isCode      { chunk = "`\(chunk)`" }
            if isStrike    { chunk = "~~\(chunk)~~" }
            if isUnderline { chunk = "<u>\(chunk)</u>" }
            if isBold      { chunk = "**\(chunk)**" }
            if isItalic    { chunk = "*\(chunk)*" }

            if isCallout {
                chunk = ">> \(chunk)"
            } else if isQuote {
                chunk = "> \(chunk)"
            }

            md += chunk
        }

        return md
    }

    // MARK: Markdown → Attributed

    static func markdownToAttributed(_ markdown: String, fontSize: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")

        for (i, line) in lines.enumerated() {
            if i > 0 {
                let nl = NSAttributedString(string: "\n", attributes: baseAttrs(fontSize))
                result.append(nl)
            }

            // Block-level prefixes stay as plain text (quote >, callout >>)
            // They're visible but not styled differently in the editor
            let isCallout = line.hasPrefix(">> ")
            let isQuote = !isCallout && line.hasPrefix("> ")

            let displayLine: String
            if isCallout {
                displayLine = String(line.dropFirst(3))
            } else if isQuote {
                displayLine = String(line.dropFirst(2))
            } else {
                displayLine = line
            }

            let segments = parseInline(displayLine)

            for seg in segments {
                switch seg {
                case .plain(let s):
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                baseAttrs(fontSize),
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .bold(let s):
                    var a = baseAttrs(fontSize)
                    a[.font] = RichFonts.rounded(fontSize, weight: .black)
                    a[.mdBold] = true
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                a,
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .italic(let s):
                    var a = baseAttrs(fontSize)
                    a[.font] = RichFonts.roundedItalic(fontSize, weight: .semibold)
                    a[.mdItalic] = true
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                a,
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .strikethrough(let s):
                    var a = baseAttrs(fontSize)
                    a[.mdStrikethrough] = true
                    a[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                    a[.strikethroughColor] = UIColor.white.withAlphaComponent(0.5)
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                a,
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .underline(let s):
                    var a = baseAttrs(fontSize)
                    a[.mdUnderline] = true
                    a[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    a[.underlineColor] = UIColor.white.withAlphaComponent(0.85)
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                a,
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .code(let s):
                    var a: [NSAttributedString.Key: Any] = [
                        .font: RichFonts.mono(fontSize),
                        .baselineOffset: 0,
                        .foregroundColor: UIColor.white.withAlphaComponent(0.92),
                        .backgroundColor: UIColor.white.withAlphaComponent(0.1),
                        .mdCode: true,
                    ]
                    _ = a // silence warning
                    result.append(
                        NSAttributedString(
                            string: s,
                            attributes: blockAttrs(
                                a,
                                isQuote: isQuote,
                                isCallout: isCallout
                            )
                        )
                    )

                case .icon(let name):
                    let size = fontSize + 2
                    if let img = FormattingTextEditor.Coordinator.renderIconImage(named: name, size: size) {
                        let attachment = NSTextAttachment()
                        attachment.image = img
                        attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)
                        let iconStr = NSMutableAttributedString(attachment: attachment)

                        iconStr.addAttributes(
                            [
                                .mdIcon: name,
                                .font: RichFonts.rounded(fontSize, weight: .semibold),
                                .foregroundColor: UIColor.white
                            ],
                            range: NSRange(location: 0, length: iconStr.length)
                        )

                        result.append(iconStr)
                    } else {
                        result.append(NSAttributedString(string: "{{\(name)}}", attributes: baseAttrs(fontSize)))
                    }
                }
            }
        }

        return result
    }

    // MARK: Helpers

    private static func baseAttrs(_ fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        [
            .font: RichFonts.rounded(fontSize, weight: .semibold),
            .foregroundColor: UIColor.white,
        ]
    }
    
    private static func blockAttrs(
        _ attrs: [NSAttributedString.Key: Any],
        isQuote: Bool,
        isCallout: Bool
    ) -> [NSAttributedString.Key: Any] {
        var attrs = attrs

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        paragraph.paragraphSpacing = 4

        if isCallout {
            attrs[.mdCallout] = true
            attrs[.backgroundColor] = UIColor.white.withAlphaComponent(0.035)
            attrs[.paragraphStyle] = paragraph
        } else if isQuote {
            attrs[.mdQuote] = true
            attrs[.foregroundColor] = UIColor.white.withAlphaComponent(0.68)
            attrs[.paragraphStyle] = paragraph
        }

        return attrs
    }

    // MARK: Inline Parser (reused from AnnouncementRichBodyView logic)

    private enum Segment {
        case plain(String)
        case bold(String)
        case italic(String)
        case strikethrough(String)
        case underline(String)
        case code(String)
        case icon(String)
    }

    private static func parseInline(_ input: String) -> [Segment] {
        var segments: [Segment] = []
        var remaining = input[...]

        while !remaining.isEmpty {
            let candidates: [(range: Range<Substring.Index>, type: MType)] = [
                findMarker(in: remaining, open: "{{", close: "}}", type: .icon),
                findMarker(in: remaining, open: "`", close: "`", type: .code),
                findMarker(in: remaining, open: "**", close: "**", type: .bold),
                findMarker(in: remaining, open: "~~", close: "~~", type: .strikethrough),
                findMarker(in: remaining, open: "<u>", close: "</u>", type: .underline),
                findMarker(in: remaining, open: "*", close: "*", type: .italic),
            ].compactMap { $0 }

            guard let earliest = candidates.min(by: { $0.range.lowerBound < $1.range.lowerBound }) else {
                segments.append(.plain(String(remaining)))
                break
            }

            let before = remaining[remaining.startIndex..<earliest.range.lowerBound]
            if !before.isEmpty { segments.append(.plain(String(before))) }

            let openLen = earliest.type.open.count
            let closeLen = earliest.type.close.count
            let cStart = remaining.index(earliest.range.lowerBound, offsetBy: openLen)
            let cEnd = remaining.index(earliest.range.upperBound, offsetBy: -closeLen)

            if cStart < cEnd {
                let content = String(remaining[cStart..<cEnd])
                switch earliest.type {
                case .icon:          segments.append(.icon(content))
                case .code:          segments.append(.code(content))
                case .bold:          segments.append(.bold(content))
                case .strikethrough: segments.append(.strikethrough(content))
                case .underline:     segments.append(.underline(content))
                case .italic:        segments.append(.italic(content))
                }
            }

            remaining = remaining[earliest.range.upperBound...]
        }

        return segments
    }

    private enum MType {
        case icon, code, bold, strikethrough, underline, italic

        var open: String {
            switch self {
            case .icon: "{{"  case .code: "`"
            case .bold: "**"  case .strikethrough: "~~"  case .underline: "<u>"  case .italic: "*"
            }
        }
        var close: String {
            switch self {
            case .icon: "}}"  case .code: "`"
            case .bold: "**"  case .strikethrough: "~~"  case .underline: "</u>"  case .italic: "*"
            }
        }
    }

    private static func findMarker(
        in text: Substring, open: String, close: String, type: MType
    ) -> (range: Range<Substring.Index>, type: MType)? {
        guard let openR = text.range(of: open) else { return nil }
        let after = text[openR.upperBound...]

        if type == .italic, openR.upperBound < text.endIndex, text[openR.upperBound] == "*" { return nil }

        guard let closeR = after.range(of: close) else { return nil }

        if type == .italic {
            if closeR.upperBound < text.endIndex, text[closeR.upperBound] == "*" { return nil }
            if closeR.lowerBound > after.startIndex {
                let prev = text.index(before: closeR.lowerBound)
                if text[prev] == "*" { return nil }
            }
        }

        if openR.upperBound == closeR.lowerBound { return nil }
        return (openR.lowerBound..<closeR.upperBound, type)
    }
}
