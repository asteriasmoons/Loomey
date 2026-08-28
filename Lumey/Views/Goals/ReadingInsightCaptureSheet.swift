//
//  ReadingInsightCaptureSheet.swift
//  Lumey
//

import SwiftUI
import UIKit

struct ReadingInsightDraft: Equatable {
    var whatHappened: String = ""
    var whatStoodOut: String = ""
    var selectedMoods: [String] = []
    var feelingNote: String = ""
    var predictions: String = ""
    var notesAndThoughts: String = ""

    var hasContent: Bool {
        selectedMoods.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        || [
            whatHappened,
            whatStoodOut,
            feelingNote,
            predictions,
            notesAndThoughts
        ]
        .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var howIFeel: String {
        let mood = selectedMoods
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let note = feelingNote.trimmingCharacters(in: .whitespacesAndNewlines)

        if mood.isEmpty { return note }
        if note.isEmpty { return mood }
        return "\(mood): \(note)"
    }
}

struct ReadingInsightCaptureSheet: View {
    @Binding var draft: ReadingInsightDraft
    let bookTitle: String

    @Environment(\.dismiss) private var dismiss

    private let moods = [
        "Curious",
        "Moved",
        "Tense",
        "Hopeful",
        "Cozy",
        "Surprised",
        "Reflective",
        "Frustrated"
    ]

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    GlassCard(variant: .featured) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(bookTitle)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.cardTitle)
                                .lineLimit(2)

                            insightTextEditor(
                                title: "What happened today?",
                                text: $draft.whatHappened,
                                minHeight: 130
                            )

                            insightTextEditor(
                                title: "What stood out?",
                                text: $draft.whatStoodOut,
                                minHeight: 120
                            )

                            moodSection

                            insightTextEditor(
                                title: "Predictions / Questions",
                                text: $draft.predictions,
                                minHeight: 120
                            )

                            insightTextEditor(
                                title: "Notes & Thoughts",
                                text: $draft.notesAndThoughts,
                                minHeight: 130
                            )
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Save Insight")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.cardTitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LGradients.header)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(draft.hasContent ? 1 : 0.45)
                    .disabled(!draft.hasContent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 42)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .lumeyDismissKeyboardOnTap()
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading Insight")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Capture what this session gave you.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

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
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How did this session make you feel?")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(moods, id: \.self) { mood in
                    moodChip(mood)
                }
            }

            insightTextEditor(
                title: "Feeling note (optional)",
                text: $draft.feelingNote,
                minHeight: 78
            )
        }
    }

    private func moodChip(_ mood: String) -> some View {
        let isSelected = draft.selectedMoods.contains(mood)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                toggleMood(mood)
            }
        } label: {
            HStack(spacing: 8) {
                Image(isSelected ? "starfill" : "staroutline")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text(mood)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(LColors.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(LColors.accents.contrast) : AnyShapeStyle(LColors.surface.subtle.opacity(0.5)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? AnyShapeStyle(LColors.accents.secondary) : AnyShapeStyle(LColors.glassBorder), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleMood(_ mood: String) {
        if draft.selectedMoods.contains(mood) {
            draft.selectedMoods.removeAll { $0 == mood }
        } else {
            draft.selectedMoods.append(mood)
        }
    }

    private func insightTextEditor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            InsightUnlimitedTextView(text: text)
                .frame(minHeight: minHeight)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LColors.surface.nested)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )
                )
        }
    }
}

private struct InsightUnlimitedTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = UIColor.white.withAlphaComponent(0.86)
        textView.font = Self.roundedFont
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .yes
        textView.smartDashesType = .yes
        textView.smartQuotesType = .yes
        textView.text = text
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }

        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = UIColor.white.withAlphaComponent(0.86)
        textView.font = Self.roundedFont
    }

    private static var roundedFont: UIFont {
        let base = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: 14)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
