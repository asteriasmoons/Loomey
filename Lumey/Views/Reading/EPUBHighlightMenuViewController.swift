//
//  EPUBHighlightMenuViewController.swift
//  Lumey
//

import UIKit
import SwiftUI
import ReadiumNavigator

enum AnnotationSheetMode {
    case highlight, quote, note
}

final class EPUBHighlightMenuViewController: UIViewController {

    private let selectedText: String
    private let theme: ReaderTheme
    private let initialMode: AnnotationSheetMode
    private let onHighlight: (HighlightColor) -> Void
    private let onQuote: (HighlightColor) -> Void
    private let onNote: (HighlightColor, String) -> Void

    private var chosenColor: HighlightColor = .yellow
    private let noteTextView = UITextView()
    private var colorCircles: [UIView] = []
    private weak var noteSection: UIView?

    init(
        selectedText: String,
        theme: ReaderTheme,
        initialMode: AnnotationSheetMode = .highlight,
        onHighlight: @escaping (HighlightColor) -> Void,
        onQuote: @escaping (HighlightColor) -> Void,
        onNote: @escaping (HighlightColor, String) -> Void
    ) {
        self.selectedText = selectedText
        self.theme = theme
        self.initialMode = initialMode
        self.onHighlight = onHighlight
        self.onQuote = onQuote
        self.onNote = onNote
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("[AnnotationSheet] viewDidLayoutSubviews — view.frame: \(view.frame)")
        for (i, circle) in colorCircles.enumerated() {
            print("[AnnotationSheet] Circle \(i) frame: \(circle.frame), bg: \(circle.backgroundColor ?? .clear), hidden: \(circle.isHidden), alpha: \(circle.alpha), superview: \(circle.superview != nil)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("[AnnotationSheet] viewDidLoad fired")
        print("[AnnotationSheet] theme: \(theme)")
        print("[AnnotationSheet] selectedText: \(selectedText.prefix(50))")
        print("[AnnotationSheet] initialMode: \(initialMode)")

        view.backgroundColor = theme.chromeBackgroundColor
        navigationController?.setNavigationBarHidden(true, animated: false)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -44)
        ])

        stack.addArrangedSubview(buildHeader())

        if !selectedText.isEmpty {
            stack.addArrangedSubview(buildPreviewCard())
        }

        // Color circles — added directly to the main stack, no container
        let colorLabel = UILabel()
        colorLabel.text = "HIGHLIGHT COLOR"
        colorLabel.textColor = theme.chromeTextColor.withAlphaComponent(0.5)
        colorLabel.font = UIFont.rounded(size: 11, weight: .black)
        stack.addArrangedSubview(colorLabel)

        let colorRow = UIView()
        colorRow.translatesAutoresizingMaskIntoConstraints = false
        colorRow.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let circleColors: [UIColor] = [
            UIColor(red: 1.00, green: 0.88, blue: 0.40, alpha: 1),
            UIColor(red: 1.00, green: 0.52, blue: 0.63, alpha: 1),
            UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1),
            UIColor(red: 1.00, green: 0.65, blue: 0.32, alpha: 1),
            UIColor(red: 0.49, green: 0.87, blue: 0.69, alpha: 1),
            UIColor(red: 0.70, green: 0.53, blue: 1.00, alpha: 1)
        ]

        colorCircles.removeAll()
        let circleSize: CGFloat = 40
        let circleSpacing: CGFloat = 12

        print("[AnnotationSheet] Creating \(circleColors.count) color circles")

        for (i, bgColor) in circleColors.enumerated() {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = bgColor
            btn.layer.cornerRadius = circleSize / 2
            btn.clipsToBounds = true
            btn.tag = i
            btn.layer.borderWidth = i == 0 ? 3 : 1.5
            btn.layer.borderColor = i == 0 ? UIColor.white.cgColor : bgColor.withAlphaComponent(0.4).cgColor
            btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            colorRow.addSubview(btn)

            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: circleSize),
                btn.heightAnchor.constraint(equalToConstant: circleSize),
                btn.centerYAnchor.constraint(equalTo: colorRow.centerYAnchor),
                btn.leadingAnchor.constraint(equalTo: colorRow.leadingAnchor, constant: CGFloat(i) * (circleSize + circleSpacing))
            ])

            colorCircles.append(btn)
            print("[AnnotationSheet] Circle \(i): bg=\(bgColor), added to colorRow")
        }

        print("[AnnotationSheet] colorRow subviews: \(colorRow.subviews.count)")

        stack.addArrangedSubview(colorRow)
        stack.addArrangedSubview(buildActionsSection())

        print("[AnnotationSheet] stack arranged subviews count: \(stack.arrangedSubviews.count)")

        let noteSectionView = buildNoteSection()
        noteSectionView.isHidden = initialMode != .note
        self.noteSection = noteSectionView
        stack.addArrangedSubview(noteSectionView)

        if initialMode == .note {
            noteTextView.becomeFirstResponder()
        }
    }

    // MARK: - Header

    private func buildHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Annotate"
        titleLabel.textColor = theme.chromeTextColor
        titleLabel.font = UIFont.rounded(size: 24, weight: .black)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = LumeyGradientIconButton(assetName: "xmarkwavy")
        closeButton.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(closeButton)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        return container
    }

    // MARK: - Preview Card

    private func buildPreviewCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = theme.chromeTextColor.withAlphaComponent(0.055)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = theme.chromeBorderColor.cgColor

        let quoteIcon = LumeyGradientIconImageView(assetName: "quote")
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = selectedText
        textLabel.textColor = theme.chromeTextColor.withAlphaComponent(0.8)
        textLabel.font = UIFont(name: "Georgia-Italic", size: 14) ?? .italicSystemFont(ofSize: 14)
        textLabel.numberOfLines = 4
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(quoteIcon)
        card.addSubview(textLabel)

        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            quoteIcon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            quoteIcon.widthAnchor.constraint(equalToConstant: 16),
            quoteIcon.heightAnchor.constraint(equalToConstant: 16),

            textLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textLabel.leadingAnchor.constraint(equalTo: quoteIcon.trailingAnchor, constant: 10),
            textLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    // MARK: - Color Picker

    private func buildColorSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "HIGHLIGHT COLOR"
        label.textColor = theme.chromeTextColor.withAlphaComponent(0.5)
        label.font = UIFont.rounded(size: 11, weight: .black)
        label.translatesAutoresizingMaskIntoConstraints = false

        let colorStack = UIStackView()
        colorStack.axis = .horizontal
        colorStack.spacing = 12
        colorStack.alignment = .center
        colorStack.distribution = .equalSpacing
        colorStack.translatesAutoresizingMaskIntoConstraints = false

        colorCircles.removeAll()

        let rawColors: [(HighlightColor, UIColor)] = [
            (.yellow,  UIColor(red: 1.00, green: 0.88, blue: 0.40, alpha: 1)),
            (.pink,    UIColor(red: 1.00, green: 0.52, blue: 0.63, alpha: 1)),
            (.teal,    UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1)),
            (.orange,  UIColor(red: 1.00, green: 0.65, blue: 0.32, alpha: 1)),
            (.mint,    UIColor(red: 0.49, green: 0.87, blue: 0.69, alpha: 1)),
            (.purple,  UIColor(red: 0.70, green: 0.53, blue: 1.00, alpha: 1))
        ]

        for (index, (hlColor, uiColor)) in rawColors.enumerated() {
            let circle = UIButton(type: .custom)
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.backgroundColor = uiColor
            circle.layer.cornerRadius = 20
            circle.clipsToBounds = true
            circle.layer.borderWidth = hlColor == chosenColor ? 3 : 1.5
            circle.layer.borderColor = hlColor == chosenColor
                ? UIColor.white.cgColor
                : uiColor.withAlphaComponent(0.4).cgColor
            circle.tag = index
            circle.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)

            circle.widthAnchor.constraint(equalToConstant: 40).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 40).isActive = true

            colorStack.addArrangedSubview(circle)
            colorCircles.append(circle)
        }

        container.addSubview(label)
        container.addSubview(colorStack)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            colorStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            colorStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            colorStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            colorStack.heightAnchor.constraint(equalToConstant: 40),
            colorStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Action Buttons

    private func buildActionsSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let highlightBtn = actionButton(iconName: "paintdrop", title: "Highlight", action: #selector(highlightTapped))
        let quoteBtn = actionButton(iconName: "quote", title: "Quote", action: #selector(quoteTapped))
        let noteBtn = actionButton(iconName: "pencil", title: "Note", action: #selector(noteTapped))

        stack.addArrangedSubview(highlightBtn)
        stack.addArrangedSubview(quoteBtn)
        stack.addArrangedSubview(noteBtn)

        return stack
    }

    private func actionButton(iconName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = theme.chromeTextColor.withAlphaComponent(0.08)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = theme.chromeBorderColor.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)

        let icon = LumeyGradientIconImageView(assetName: iconName)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.isUserInteractionEnabled = false

        let label = UILabel()
        label.text = title
        label.textColor = theme.chromeTextColor
        label.font = UIFont.rounded(size: 13, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false

        let innerStack = UIStackView(arrangedSubviews: [icon, label])
        innerStack.axis = .vertical
        innerStack.alignment = .center
        innerStack.spacing = 6
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.isUserInteractionEnabled = false
        button.addSubview(innerStack)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 72),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            innerStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerStack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        return button
    }

    // MARK: - Note Input

    private func buildNoteSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "YOUR NOTE"
        label.textColor = theme.chromeTextColor.withAlphaComponent(0.5)
        label.font = UIFont.rounded(size: 11, weight: .black)
        label.translatesAutoresizingMaskIntoConstraints = false

        noteTextView.backgroundColor = theme.chromeTextColor.withAlphaComponent(0.06)
        noteTextView.textColor = theme.chromeTextColor
        noteTextView.font = .systemFont(ofSize: 15, weight: .medium)
        noteTextView.layer.cornerRadius = 14
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = theme.chromeBorderColor.cgColor
        noteTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        noteTextView.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Note", for: .normal)
        saveButton.titleLabel?.font = UIFont.rounded(size: 15, weight: .black)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(LColors.accents.primary)
        saveButton.layer.cornerRadius = 14
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveNoteTapped), for: .touchUpInside)

        container.addSubview(label)
        container.addSubview(noteTextView)
        container.addSubview(saveButton)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            noteTextView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            noteTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            noteTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            noteTextView.heightAnchor.constraint(equalToConstant: 100),

            saveButton.topAnchor.constraint(equalTo: noteTextView.bottomAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func colorTapped(_ sender: UIButton) {
        let index = sender.tag
        print("[AnnotationSheet] colorTapped index: \(index)")
        guard index < HighlightColor.allCases.count else {
            print("[AnnotationSheet] index out of range")
            return
        }
        chosenColor = HighlightColor.allCases[index]
        print("[AnnotationSheet] chosenColor now: \(chosenColor)")

        let buttonColors: [UIColor] = [
            UIColor(red: 1.00, green: 0.88, blue: 0.40, alpha: 1),
            UIColor(red: 1.00, green: 0.52, blue: 0.63, alpha: 1),
            UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1),
            UIColor(red: 1.00, green: 0.65, blue: 0.32, alpha: 1),
            UIColor(red: 0.49, green: 0.87, blue: 0.69, alpha: 1),
            UIColor(red: 0.70, green: 0.53, blue: 1.00, alpha: 1)
        ]

        for (i, circle) in colorCircles.enumerated() {
            let isSelected = i == index
            circle.layer.borderWidth = isSelected ? 3 : 1.5
            circle.layer.borderColor = isSelected
                ? UIColor.white.cgColor
                : buttonColors[i].withAlphaComponent(0.4).cgColor
        }
    }

    @objc private func highlightTapped() {
        print("[AnnotationSheet] highlightTapped — chosenColor: \(chosenColor)")
        onHighlight(chosenColor)
    }

    @objc private func quoteTapped() {
        print("[AnnotationSheet] quoteTapped — chosenColor: \(chosenColor)")
        onQuote(chosenColor)
    }

    @objc private func noteTapped() {
        print("[AnnotationSheet] noteTapped")
        if let ns = noteSection {
            ns.isHidden.toggle()
            print("[AnnotationSheet] noteSection isHidden: \(ns.isHidden)")
            if !ns.isHidden {
                noteTextView.becomeFirstResponder()
            }
        } else {
            print("[AnnotationSheet] noteSection is nil!")
        }
    }

    @objc private func saveNoteTapped() {
        let text = noteTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("[AnnotationSheet] saveNoteTapped — noteText: '\(text.prefix(30))', chosenColor: \(chosenColor)")
        onNote(chosenColor, text)
    }

    @objc private func dismissSheet() {
        print("[AnnotationSheet] dismissSheet")
        dismiss(animated: true)
    }
}
