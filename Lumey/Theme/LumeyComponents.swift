//
//  LumeyComponents.swift
//  Lumey
//

import SwiftUI
import UIKit

// MARK: - Alternative Lumey Background

struct LumeyBackgroundAlt: View {
    var body: some View {
        ZStack {
            LColors.appBackground
                .ignoresSafeArea()
            
            LGradients.bgPurple
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LGradients.bgCyan
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LGradients.bgYellow
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(Color.white.opacity(0.01))
                .ignoresSafeArea()
        }
    }
}

// MARK: - DELETE CONFIRMATION DIALOGUE

struct LumeyAlertConfirm: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmRole) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func lumeyAlertConfirm(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Delete",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(
            LumeyAlertConfirm(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmRole: confirmRole,
                onConfirm: onConfirm
            )
        )
    }
}

// MARK: - Gradient Title

struct GradientTitle: View {
    let text: String
    var size: CGFloat = 28
    var fontName: String = "LilyScriptOne-Regular"

    var body: some View {
        Text(text)
            .font(.custom(fontName, size: size))
            .foregroundStyle(LGradients.header)
    }
}

// MARK: - Lumey Popup (Reusable)

struct LumeyPopup<Header: View, Content: View, Footer: View>: View {
    let onClose: () -> Void
    let width: CGFloat
    let heightRatio: CGFloat
    
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            onClose()
                        }
                    }

                VStack(alignment: .leading, spacing: 18) {
                    header()

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 14) {
                            content()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollBounceBehavior(.basedOnSize)

                    footer()
                }
                .padding(22)
                .frame(
                    width: max(
                        0,
                        min(
                            proxy.size.width.isFinite
                            ? proxy.size.width - 40
                            : width,
                            width
                        )
                    ),
                    alignment: .topLeading
                )
                .frame(
                    maxHeight: proxy.size.height * heightRatio,
                    alignment: .topLeading
                )
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LTheme.palette.cardFill)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(LColors.border.primary, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.30),
                    radius: 18,
                    y: 10
                )
                .transition(
                    .opacity.combined(with: .scale(scale: 0.96))
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Lumey Background

struct LumeyBackground: View {
    var body: some View {
        LumeyBackgroundAlt()
    }
}

// MARK: - Gradient Time Drum Picker

struct LumeyGradientTimeDrumPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    @State private var displayHour: Int = 9
    @State private var meridiem: String = "AM"
    @State private var isSyncingFromStoredHour = false
    
    private let meridiems = ["AM", "PM"]
    
    private var formattedPreview: String {
        String(format: "%d:%02d %@", displayHour, minute, meridiem)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image("clockfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(LGradients.header)
                
                Text(formattedPreview)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LColors.secondarySurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LColors.border.primary, lineWidth: 1)
            )
            
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LColors.primarySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(LColors.border.primary, lineWidth: 1)
                    )
                
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LColors.selectedSurface)
                        .frame(height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LColors.strongBorder, lineWidth: 1)
                        )
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                HStack(spacing: 6) {
                    Picker("Hour", selection: $displayHour) {
                        ForEach(1...12, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    
                    Text(":")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    
                    Picker("Minute", selection: $minute) {
                        ForEach(0..<60, id: \.self) { value in
                            Text(String(format: "%02d", value))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    
                    Picker("AM PM", selection: $meridiem) {
                        ForEach(meridiems, id: \.self) { value in
                            Text(value)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 138)
        }
        .onAppear { syncDisplayValuesFromStoredHour() }
        .onChange(of: displayHour) { syncStoredHour() }
        .onChange(of: meridiem) { syncStoredHour() }
        .onChange(of: hour) { syncDisplayValuesFromStoredHour() }
    }
    
    private func syncDisplayValuesFromStoredHour() {
        isSyncingFromStoredHour = true
        let normalizedHour = max(0, min(23, hour))
        if normalizedHour == 0 {
            displayHour = 12; meridiem = "AM"
        } else if normalizedHour < 12 {
            displayHour = normalizedHour; meridiem = "AM"
        } else if normalizedHour == 12 {
            displayHour = 12; meridiem = "PM"
        } else {
            displayHour = normalizedHour - 12; meridiem = "PM"
        }
        isSyncingFromStoredHour = false
    }
    
    private func syncStoredHour() {
        guard !isSyncingFromStoredHour else { return }
        if meridiem == "AM" {
            hour = displayHour == 12 ? 0 : displayHour
        } else {
            hour = displayHour == 12 ? 12 : displayHour + 12
        }
    }
}

// MARK: - Gradient Date Drum Picker

struct LumeyGradientDateDrumPicker: View {
    @Binding var date: Date

    var yearRange: ClosedRange<Int> = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (currentYear - 20)...(currentYear + 1)
    }()

    @State private var selectedMonth = 1
    @State private var selectedDay = 1
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var isSyncingFromDate = false

    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.monthSymbols

    private var formattedPreview: String {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay

        guard let selectedDate = calendar.date(from: components) else {
            return "\(monthSymbols[max(0, selectedMonth - 1)]) \(selectedDay), \(selectedYear)"
        }

        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var daysInSelectedMonth: Int {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth

        guard
            let monthDate = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return 31
        }

        return range.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image("starcal")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(LGradients.header)

                Text(formattedPreview)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LColors.secondarySurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LColors.border.primary, lineWidth: 1)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LColors.primarySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(LColors.border.primary, lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LColors.selectedSurface)
                        .frame(height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LColors.strongBorder, lineWidth: 1)
                        )
                    Spacer()
                }
                .padding(.horizontal, 12)

                HStack(spacing: 6) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { value in
                            Text(monthSymbols[value - 1])
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()

                    Picker("Day", selection: $selectedDay) {
                        ForEach(1...daysInSelectedMonth, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()

                    Picker("Year", selection: $selectedYear) {
                        ForEach(Array(yearRange), id: \.self) { value in
                            Text(String(value))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 138)
        }
        .onAppear { syncPickersFromDate() }
        .onChange(of: selectedMonth) { syncDateFromPickers() }
        .onChange(of: selectedDay) { syncDateFromPickers() }
        .onChange(of: selectedYear) { syncDateFromPickers() }
        .onChange(of: date) { syncPickersFromDate() }
    }

    private func syncPickersFromDate() {
        isSyncingFromDate = true
        selectedMonth = calendar.component(.month, from: date)
        selectedDay = calendar.component(.day, from: date)
        selectedYear = min(max(calendar.component(.year, from: date), yearRange.lowerBound), yearRange.upperBound)
        selectedDay = min(selectedDay, daysInSelectedMonth)
        isSyncingFromDate = false
    }

    private func syncDateFromPickers() {
        guard !isSyncingFromDate else { return }

        if selectedDay > daysInSelectedMonth {
            selectedDay = daysInSelectedMonth
            return
        }

        var components = calendar.dateComponents([.hour, .minute, .second], from: date)
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay

        if let updatedDate = calendar.date(from: components) {
            date = updatedDate
        }
    }
}

// MARK: - Gradient Date Time Drum Picker

struct LumeyGradientDateTimeDrumPicker: View {
    @Binding var date: Date

    @State private var hour = Calendar.current.component(.hour, from: Date())
    @State private var minute = Calendar.current.component(.minute, from: Date())
    @State private var isSyncingFromDate = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            LumeyGradientDateDrumPicker(date: $date)

            LumeyGradientTimeDrumPicker(hour: $hour, minute: $minute)
        }
        .onAppear { syncTimeFromDate() }
        .onChange(of: hour) { syncDateFromTime() }
        .onChange(of: minute) { syncDateFromTime() }
        .onChange(of: date) { syncTimeFromDate() }
    }

    private func syncTimeFromDate() {
        isSyncingFromDate = true
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
        isSyncingFromDate = false
    }

    private func syncDateFromTime() {
        guard !isSyncingFromDate else { return }

        var components = calendar.dateComponents([.year, .month, .day, .second], from: date)
        components.hour = hour
        components.minute = minute

        if let updatedDate = calendar.date(from: components) {
            date = updatedDate
        }
    }
}

// MARK: - Dotted Gradient Spinner

struct LumeyDottedGradientSpinner: View {
    var size: CGFloat = 58
    var dotCount: Int = 14

    @State private var rotation = 0.0

    private var dotSize: CGFloat {
        max(5, size * 0.12)
    }

    private var radius: CGFloat {
        (size - dotSize) / 2
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(LGradients.progress)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(dotOpacity(for: index))
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) / Double(dotCount) * 360))
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            rotation = 0

            withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .accessibilityLabel("Loading")
    }

    private func dotOpacity(for index: Int) -> Double {
        let progress = Double(index) / Double(max(dotCount - 1, 1))
        return 0.28 + (progress * 0.72)
    }
}

// MARK: - Glass Card

/// Surface variants exposed by GlassCard. Each maps to a distinct palette-derived
/// surface color so adjacent cards on the same screen can visibly differ while
/// remaining in the same theme.
enum GlassCardVariant {
    case primary    // structure — main card surface
    case secondary  // support-tinted dark surface
    case tertiary   // accent-tinted dark surface
    case elevated   // slightly lifted primary
    case featured   // contrast-tinted dark surface (special / hero cards)
    case subtle     // near-background, lowest emphasis
}

extension GlassCardVariant {
    /// All variants render as DARK surfaces. Cards never take on a saturated
    /// palette color. Visual variety comes from the border, not the fill.
    fileprivate var fill: Color {
        switch self {
        case .primary:   return LColors.surface.primary
        case .secondary: return LColors.surface.secondary
        case .tertiary:  return LColors.surface.tertiary
        case .elevated:  return LColors.surface.elevated
        case .featured:  return LColors.surface.featured
        case .subtle:    return LColors.surface.subtle
        }
    }

    /// Palette-aware borders that carry the theme personality across variants
    /// while surfaces stay uniformly dark.
    fileprivate var borderColor: Color {
        LColors.accents.primary
    }
}

/// Deterministic surface rotation for enumerated lists so ForEach-driven
/// screens automatically distribute across surface variants without the caller
/// having to hand-assign each card.
enum GlassCardRotation {
    /// The canonical rotation order — chosen so adjacent cards visibly differ.
    static let ordered: [GlassCardVariant] = [
        .primary, .secondary, .featured, .tertiary, .primary, .elevated
    ]

    static func variant(for index: Int) -> GlassCardVariant {
        let count = ordered.count
        guard count > 0 else { return .primary }
        let i = ((index % count) + count) % count
        return ordered[i]
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = LSpacing.cardPadding
    var selected: Bool = false
    var contentAlignment: Alignment? = nil
    var variant: GlassCardVariant = .primary
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let baseFill = variant.fill
        let baseBorder = variant.borderColor

        Group {
            if let contentAlignment {
                content
                    .frame(maxWidth: .infinity, alignment: contentAlignment)
            } else {
                content
            }
        }
        .padding(padding)
        .background(
            shape
                .fill(selected ? LColors.state.selectedFill : baseFill)
                .overlay(
                    shape.strokeBorder(
                        selected ? LColors.state.selectedBorder : baseBorder,
                        lineWidth: selected ? 1.4 : 1
                    )
                )
        )
        .shadow(
            color: Color.black.opacity(selected ? 0.24 : 0.18),
            radius: selected ? 14 : 10,
            y: selected ? 8 : 5
        )
    }
}

// MARK: - Completion Banner

struct LumeyCompletionBanner: View {
    let message: String
    var isShowing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image("checkwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.cardTitle)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(LGradients.completion)
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : -20)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isShowing)
    }
}

extension View {
    func completionBanner(isShowing: Bool, message: String = "Done!") -> some View {
        self.overlay(alignment: .top) {
            LumeyCompletionBanner(message: message, isShowing: isShowing)
                .padding(.top, 16)
                .zIndex(999)
        }
    }

    func lumeyDismissKeyboardOnTap() -> some View {
        background(LumeyKeyboardDismissTapInstaller())
    }
}

private struct LumeyKeyboardDismissTapInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = LumeyKeyboardDismissHostView()
        view.configure(coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? LumeyKeyboardDismissHostView)?.configure(coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func dismissKeyboard(_ recognizer: UITapGestureRecognizer) {
            recognizer.view?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var touchedView: UIView? = touch.view

            while let currentView = touchedView {
                if currentView is UIControl || currentView is UITextField || currentView is UITextView {
                    return false
                }
                touchedView = currentView.superview
            }

            return true
        }
    }
}

private final class LumeyKeyboardDismissHostView: UIView {
    private weak var coordinator: LumeyKeyboardDismissTapInstaller.Coordinator?
    private weak var installedWindow: UIWindow?
    private weak var tapRecognizer: UITapGestureRecognizer?

    func configure(coordinator: LumeyKeyboardDismissTapInstaller.Coordinator) {
        self.coordinator = coordinator
        installRecognizerIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installRecognizerIfNeeded()
    }

    deinit {
        if let tapRecognizer {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
        }
    }

    private func installRecognizerIfNeeded() {
        guard let window, let coordinator else { return }

        if installedWindow === window, tapRecognizer != nil {
            return
        }

        if let tapRecognizer {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
        }

        let recognizer = UITapGestureRecognizer(target: coordinator, action: #selector(LumeyKeyboardDismissTapInstaller.Coordinator.dismissKeyboard(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = coordinator
        window.addGestureRecognizer(recognizer)

        installedWindow = window
        tapRecognizer = recognizer
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LumeyBackground()

        GlassCard {
            VStack(spacing: 10) {
                Text("Lumey")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text("Glass card preview")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }
}
