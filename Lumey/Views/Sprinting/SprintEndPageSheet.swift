//
//  SprintEndPageSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct SprintEndPageSheet: View {
    let sprint: Sprint
    let userId: String
    var onClose: (() -> Void)?
    var onSubmitted: ((Sprint) -> Void)?
    @Environment(\.modelContext) private var modelContext

    @State private var endPageText: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil

    private var closeAction: () -> Void { onClose ?? {} }
    private var canSubmit: Bool { !endPageText.isEmpty && !isSubmitting }

    private var startPage: Int? {
        sprint.participants.first(where: { $0.userId == userId })?.startPage
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        if let startPage {
                            GlassCard {
                                Text("You started on page \(startPage). How far did you get?")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("End Page")

                                TextField(
                                    "What page did you reach?",
                                    text: $endPageText
                                )
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .keyboardType(.numberPad)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.055))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            Color.white.opacity(0.08),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }

                        if let start = startPage,
                           let end = Int(endPageText),
                           end > start {

                            GlassCard {
                                HStack(spacing: 8) {
                                    Image("books")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundStyle(LGradients.header)

                                    Text("\(end - start) pages read • \(end - start) points")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
    }
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter End Page")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Tell Lumey where you finished the sprint.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                closeAction()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Submit")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        canSubmit
                        ? LGradients.header
                        : LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: canSubmit
                ? LColors.accent.opacity(0.3)
                : .clear,
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    private func submit() async {
        guard canSubmit, let page = Int(endPageText) else { return }
        isSubmitting = true
        errorMessage = nil

        let body = SubmitEndPageBody(userId: userId, endPage: page)

        do {
            let updated = try await SprintService.shared.submitEndPage(sprintId: sprint.id, body: body)
            ReadingXPService.awardSprintSubmission(
                sprint: updated,
                userID: userId,
                endPage: page,
                modelContext: modelContext
            )
            onSubmitted?(updated)
        } catch {
            errorMessage = "Failed to submit. Please try again."
        }

        isSubmitting = false
    }
}
