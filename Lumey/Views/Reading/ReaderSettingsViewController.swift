//
//  ReaderSettingsViewController.swift
//  Lumey
//

import UIKit
import SwiftUI
import SwiftData

final class ReaderSettingsViewController: UIViewController {
    
    private let settings: ReaderSettings
    private let modelContext: ModelContext
    private let onPreferencesChanged: (ReaderSettings) -> Void
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var fontButtons: [ReaderFont: UIButton] = [:]
    private var themeViews: [ReaderTheme: UIView] = [:]
    private var titleLabel: UILabel?

    private let themeColumns = 5
    
    init(
        settings: ReaderSettings,
        modelContext: ModelContext,
        onPreferencesChanged: @escaping (ReaderSettings) -> Void
    ) {
        self.settings = settings
        self.modelContext = modelContext
        self.onPreferencesChanged = onPreferencesChanged
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = settings.theme.chromeBackgroundColor
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        buildHeader()
        buildScrollContent()
    }
    
    // MARK: - Header
    
    private func buildHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "Reader Settings"
        titleLabel.textColor = settings.theme.chromeTextColor
        self.titleLabel = titleLabel
        titleLabel.font = UIFont.rounded(size: 24, weight: .black)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = LumeyGradientIconButton(assetName: "xmarkwavy")
        closeButton.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            titleLabel.heightAnchor.constraint(equalToConstant: 36),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    // MARK: - Content
    
    private func buildScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 28
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 66),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -22),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -44)
        ])
        
        contentStack.addArrangedSubview(buildThemeSection())
        contentStack.addArrangedSubview(buildFontSizeSection())
        contentStack.addArrangedSubview(buildFontSection())
        contentStack.addArrangedSubview(buildSpacingSection())
        contentStack.addArrangedSubview(buildJustifySection())
    }
    
    // MARK: - Theme Section
    
    private func buildThemeSection() -> UIView {
        let container = UIView()
        
        let label = sectionLabel("Theme")
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 12
        gridStack.alignment = .fill
        gridStack.distribution = .fillEqually
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(gridStack)
        
        let themes = Array(ReaderTheme.allCases)
        let rows = stride(from: 0, to: themes.count, by: themeColumns).map {
            Array(themes[$0..<min($0 + themeColumns, themes.count)])
        }
        
        for rowThemes in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.alignment = .center
            rowStack.distribution = .fillEqually
            
            for theme in rowThemes {
                let themeView = buildThemeSwatch(theme)
                rowStack.addArrangedSubview(themeView)
                themeViews[theme] = themeView
            }
            
            if rowThemes.count < themeColumns {
                for _ in 0..<(themeColumns - rowThemes.count) {
                    let spacer = UIView()
                    rowStack.addArrangedSubview(spacer)
                }
            }
            
            gridStack.addArrangedSubview(rowStack)
        }
        
        let gridHeight = CGFloat(rows.count) * 70 + CGFloat(max(rows.count - 1, 0)) * 12
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            gridStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 14),
            gridStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            gridStack.heightAnchor.constraint(equalToConstant: gridHeight)
        ])
        
        return container
    }
    
    private func buildThemeSwatch(_ theme: ReaderTheme) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.tag = ReaderTheme.allCases.firstIndex(of: theme) ?? 0
        wrapper.accessibilityLabel = "\(theme.rawValue) reader theme"
        wrapper.accessibilityTraits = theme == settings.theme ? [.button, .selected] : .button
        wrapper.isAccessibilityElement = true
        wrapper.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(themeTapped(_:)))
        wrapper.addGestureRecognizer(tap)
        
        let circle = UIView()
        circle.backgroundColor = theme.swatchColor
        circle.layer.cornerRadius = 22
        circle.layer.borderWidth = theme == settings.theme ? 3 : 1.5
        circle.layer.borderColor = theme == settings.theme
            ? tintGradientColor().cgColor
            : theme.swatchBorderColor.cgColor
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.isUserInteractionEnabled = false
        
        let nameLabel = UILabel()
        nameLabel.text = theme.rawValue
        nameLabel.textColor = theme == settings.theme ? primaryReaderUIColor : secondaryReaderUIColor
        nameLabel.font = UIFont.rounded(size: 11, weight: theme == settings.theme ? .black : .bold)
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.72
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = false
        
        wrapper.addSubview(circle)
        wrapper.addSubview(nameLabel)
        
        if theme == settings.theme {
            let check = LumeyGradientIconImageView(assetName: "checkwavy")
            check.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(check)
            NSLayoutConstraint.activate([
                check.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                check.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                check.widthAnchor.constraint(equalToConstant: 16),
                check.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
        
        NSLayoutConstraint.activate([
            circle.topAnchor.constraint(equalTo: wrapper.topAnchor),
            circle.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            circle.widthAnchor.constraint(equalToConstant: 44),
            circle.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        return wrapper
    }
    
    // MARK: - Font Size Section
    
    private func buildFontSizeSection() -> UIView {
        let container = UIView()
        
        let label = sectionLabel("Size")
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let controlStack = UIStackView()
        controlStack.axis = .horizontal
        controlStack.spacing = 0
        controlStack.alignment = .center
        controlStack.distribution = .fill
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(controlStack)
        
        let decreaseButton = UIButton(type: .system)
        decreaseButton.setTitle("A", for: .normal)
        decreaseButton.titleLabel?.font = UIFont.rounded(size: 14, weight: .black)
        decreaseButton.setTitleColor(primaryReaderUIColor, for: .normal)
        decreaseButton.backgroundColor = softButtonBackground
        decreaseButton.layer.cornerRadius = 18
        decreaseButton.translatesAutoresizingMaskIntoConstraints = false
        decreaseButton.addTarget(self, action: #selector(decreaseFontSize), for: .touchUpInside)
        
        let sizeLabel = UILabel()
        sizeLabel.text = "\(Int(settings.fontSize * 100))%"
        sizeLabel.textColor = primaryReaderUIColor
        sizeLabel.font = UIFont.rounded(size: 15, weight: .black)
        sizeLabel.textAlignment = .center
        sizeLabel.tag = 999
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let increaseButton = UIButton(type: .system)
        increaseButton.setTitle("A", for: .normal)
        increaseButton.titleLabel?.font = UIFont.rounded(size: 22, weight: .black)
        increaseButton.setTitleColor(primaryReaderUIColor, for: .normal)
        increaseButton.backgroundColor = softButtonBackground
        increaseButton.layer.cornerRadius = 18
        increaseButton.translatesAutoresizingMaskIntoConstraints = false
        increaseButton.addTarget(self, action: #selector(increaseFontSize), for: .touchUpInside)
        
        controlStack.addArrangedSubview(decreaseButton)
        controlStack.addArrangedSubview(sizeLabel)
        controlStack.addArrangedSubview(increaseButton)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            controlStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            controlStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            controlStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            controlStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            decreaseButton.widthAnchor.constraint(equalToConstant: 56),
            decreaseButton.heightAnchor.constraint(equalToConstant: 44),
            increaseButton.widthAnchor.constraint(equalToConstant: 56),
            increaseButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    // MARK: - Font Section
    
    private func buildFontSection() -> UIView {
        let container = UIView()
        
        let label = sectionLabel("Font")
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let fontStack = UIStackView()
        fontStack.axis = .vertical
        fontStack.spacing = 6
        fontStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(fontStack)
        
        for font in ReaderFont.allCases {
            let button = buildFontRow(font)
            fontStack.addArrangedSubview(button)
            fontButtons[font] = button
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            fontStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            fontStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            fontStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            fontStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func buildFontRow(_ font: ReaderFont) -> UIButton {
        let isSelected = font == settings.font
        
        let button = UIButton(type: .system)
        button.tag = ReaderFont.allCases.firstIndex(of: font) ?? 0
        button.backgroundColor = isSelected
            ? softSelectedBackground
            : softUnselectedBackground
        button.layer.cornerRadius = 14
        button.layer.borderWidth = isSelected ? 1.5 : 1
        button.layer.borderColor = isSelected
            ? tintGradientColor().cgColor
            : softBorderColor.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(fontTapped(_:)), for: .touchUpInside)
        
        let nameLabel = UILabel()
        nameLabel.text = font.displayName
        nameLabel.textColor = isSelected ? primaryReaderUIColor : secondaryReaderUIColor
        nameLabel.isUserInteractionEnabled = false
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        
        if let uiFontName = font.uiFontName {
            nameLabel.font = UIFont(name: uiFontName, size: 15) ?? UIFont.rounded(size: 15, weight: .semibold)
        } else {
            nameLabel.font = UIFont.rounded(size: 15, weight: .semibold)
        }
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 46),
            nameLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -48),
            nameLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        if isSelected {
            let check = LumeyGradientIconImageView(assetName: "checkwavy")
            check.translatesAutoresizingMaskIntoConstraints = false
            check.isUserInteractionEnabled = false
            button.addSubview(check)
            NSLayoutConstraint.activate([
                check.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
                check.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                check.widthAnchor.constraint(equalToConstant: 16),
                check.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
        
        return button
    }
    
    // MARK: - Spacing Section

    private func buildSpacingSection() -> UIView {
        let container = UIView()

        let label = sectionLabel("Spacing")
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        let spacingStack = UIStackView()
        spacingStack.axis = .vertical
        spacingStack.spacing = 18
        spacingStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spacingStack)

        spacingStack.addArrangedSubview(
            buildSliderRow(
                title: "Letter Spacing",
                value: settings.letterSpacing,
                range: 0.0...0.5,
                tag: 100,
                valueTag: 200,
                action: #selector(letterSpacingChanged(_:)),
                formatter: { String(format: "%.2f", $0) }
            )
        )

        spacingStack.addArrangedSubview(
            buildSliderRow(
                title: "Word Spacing",
                value: settings.wordSpacing,
                range: 0.0...1.0,
                tag: 101,
                valueTag: 201,
                action: #selector(wordSpacingChanged(_:)),
                formatter: { String(format: "%.2f", $0) }
            )
        )

        spacingStack.addArrangedSubview(
            buildSliderRow(
                title: "Line Height",
                value: settings.lineHeight,
                range: 1.0...2.5,
                tag: 102,
                valueTag: 202,
                action: #selector(lineHeightChanged(_:)),
                formatter: { String(format: "%.1f", $0) }
            )
        )

        spacingStack.addArrangedSubview(
            buildSliderRow(
                title: "Paragraph Spacing",
                value: settings.paragraphSpacing,
                range: 0.0...2.0,
                tag: 103,
                valueTag: 203,
                action: #selector(paragraphSpacingChanged(_:)),
                formatter: { String(format: "%.1f", $0) }
            )
        )

        spacingStack.addArrangedSubview(
            buildSliderRow(
                title: "Page Margins",
                value: settings.pageMargins,
                range: 0.5...3.0,
                tag: 104,
                valueTag: 204,
                action: #selector(pageMarginsChanged(_:)),
                formatter: { String(format: "%.1f", $0) }
            )
        )

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            spacingStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 14),
            spacingStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            spacingStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            spacingStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func buildSliderRow(
        title: String,
        value: Double,
        range: ClosedRange<Double>,
        tag: Int,
        valueTag: Int,
        action: Selector,
        formatter: (Double) -> String
    ) -> UIView {
        let row = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = primaryReaderUIColor
        titleLabel.font = UIFont.rounded(size: 14, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = formatter(value)
        valueLabel.textColor = secondaryReaderUIColor
        valueLabel.font = UIFont.rounded(size: 13, weight: .bold)
        valueLabel.textAlignment = .right
        valueLabel.tag = valueTag
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.tag = tag
        slider.tintColor = tintGradientColor()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: action, for: .valueChanged)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(headerStack)
        row.addSubview(slider)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: row.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),

            slider.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 6),
            slider.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }

    // MARK: - Justify Section

    private func buildJustifySection() -> UIView {
        let container = UIView()

        let label = sectionLabel("Alignment")
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = settings.isJustified
        toggle.onTintColor = tintGradientColor()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(justifyToggled(_:)), for: .valueChanged)

        let titleLabel = UILabel()
        titleLabel.text = "Justify Text"
        titleLabel.textColor = primaryReaderUIColor
        titleLabel.font = UIFont.rounded(size: 14, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let row = UIView()
        row.backgroundColor = softButtonBackground
        row.layer.cornerRadius = 14
        row.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(titleLabel)
        row.addSubview(toggle)
        container.addSubview(row)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            row.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            row.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return container
    }

    // MARK: - Slider Actions

    @objc private func letterSpacingChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        settings.letterSpacing = value
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        if let label = view.viewWithTag(200) as? UILabel {
            label.text = String(format: "%.2f", value)
        }
    }

    @objc private func wordSpacingChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        settings.wordSpacing = value
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        if let label = view.viewWithTag(201) as? UILabel {
            label.text = String(format: "%.2f", value)
        }
    }

    @objc private func lineHeightChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        settings.lineHeight = value
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        if let label = view.viewWithTag(202) as? UILabel {
            label.text = String(format: "%.1f", value)
        }
    }

    @objc private func paragraphSpacingChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        settings.paragraphSpacing = value
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        if let label = view.viewWithTag(203) as? UILabel {
            label.text = String(format: "%.1f", value)
        }
    }

    @objc private func pageMarginsChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        settings.pageMargins = value
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        if let label = view.viewWithTag(204) as? UILabel {
            label.text = String(format: "%.1f", value)
        }
    }

    @objc private func justifyToggled(_ sender: UISwitch) {
        settings.isJustified = sender.isOn
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
    }

    // MARK: - Actions

    @objc private func themeTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag,
              tag < ReaderTheme.allCases.count else { return }
        
        let theme = ReaderTheme.allCases[tag]
        settings.theme = theme
        view.backgroundColor = theme.chromeBackgroundColor
        titleLabel?.textColor = theme.chromeTextColor

        try? modelContext.save()
        onPreferencesChanged(settings)
        rebuildContent()
    }
    
    @objc private func fontTapped(_ sender: UIButton) {
        let tag = sender.tag
        guard tag < ReaderFont.allCases.count else { return }
        
        let font = ReaderFont.allCases[tag]
        settings.font = font
        try? modelContext.save()
        onPreferencesChanged(settings)
        rebuildContent()
    }
    
    @objc private func decreaseFontSize() {
        settings.fontSize = max(settings.fontSize - 0.1, 0.5)
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        
        if let sizeLabel = view.viewWithTag(999) as? UILabel {
            sizeLabel.text = "\(Int(settings.fontSize * 100))%"
        }
    }
    
    @objc private func increaseFontSize() {
        settings.fontSize = min(settings.fontSize + 0.1, 3.0)
        settings.updatedAt = Date()
        try? modelContext.save()
        onPreferencesChanged(settings)
        
        if let sizeLabel = view.viewWithTag(999) as? UILabel {
            sizeLabel.text = "\(Int(settings.fontSize * 100))%"
        }
    }
    
    @objc private func dismissSheet() {
        dismiss(animated: true)
    }
    
    // MARK: - Helpers
    
    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        fontButtons.removeAll()
        themeViews.removeAll()
        
        contentStack.addArrangedSubview(buildThemeSection())
        contentStack.addArrangedSubview(buildFontSizeSection())
        contentStack.addArrangedSubview(buildFontSection())
        contentStack.addArrangedSubview(buildSpacingSection())
        contentStack.addArrangedSubview(buildJustifySection())
    }
    
    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = mutedReaderUIColor
        label.font = UIFont.rounded(size: 12, weight: .black)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private var usesDarkText: Bool {
        !settings.theme.isDark
    }
    
    private var primaryReaderUIColor: UIColor {
        settings.theme.chromeTextColor
    }

    private var secondaryReaderUIColor: UIColor {
        settings.theme.chromeTextColor.withAlphaComponent(0.58)
    }

    private var mutedReaderUIColor: UIColor {
        settings.theme.chromeTextColor.withAlphaComponent(0.50)
    }

    private var softButtonBackground: UIColor {
        settings.theme.chromeTextColor.withAlphaComponent(0.06)
    }

    private var softSelectedBackground: UIColor {
        settings.theme.chromeTextColor.withAlphaComponent(0.10)
    }

    private var softUnselectedBackground: UIColor {
        settings.theme.chromeTextColor.withAlphaComponent(0.04)
    }

    private var softBorderColor: UIColor {
        settings.theme.chromeBorderColor
    }
    
    private func tintGradientColor() -> UIColor {
        UIColor(LColors.accents.primary)
    }
}
