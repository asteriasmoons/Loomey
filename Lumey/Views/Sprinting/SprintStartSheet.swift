//
//  SprintStartSheet.swift
//  Lumey
//

import SwiftUI

struct SprintStartSheet: View {
    @Environment(\.appTheme) private var theme

    let userId: String
    let displayName: String
    var onClose: (() -> Void)?
    var onStarted: ((Sprint) -> Void)?

    @State private var selectedDuration: Int = 25
    @State private var startPageText: String = ""
    @State private var isStarting = false
    @State private var errorMessage: String? = nil

    private let durations = [5, 10, 15, 20, 25, 30, 45, 60]
    private var closeAction: () -> Void { onClose ?? {} }
    private var canStart: Bool { !startPageText.isEmpty && !isStarting }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard(variant: .featured, borderColor: theme.palette.primaryAction) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Duration")

                                LazyVGrid(
                                    columns: Array(
                                        repeating: GridItem(.flexible(), spacing: 10),
                                        count: 4
                                    ),
                                    spacing: 10
                                ) {
                                    ForEach(Array(durations.enumerated()), id: \.element) { index, duration in
                                        let tint = theme.palette.rotation[index % theme.palette.rotation.count]

                                        Button {
                                            selectedDuration = duration
                                        } label: {
                                            Text("\(duration)m")
                                                .font(.system(size: 13, weight: .black, design: .rounded))
                                                .foregroundStyle(.white)
                                                .shadow(color: theme.palette.background.opacity(0.70), radius: 1, y: 1)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background {
                                                    BubblyTileSurface(tint: tint, cornerRadius: 14)
                                                }
                                                .opacity(selectedDuration == duration ? 1 : 0.62)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        GlassCard(variant: .primary, borderColor: theme.palette.secondaryAccent) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Your Start Page")

                                TextField("e.g. 42", text: $startPageText)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(LColors.surface.nestedSoft)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(theme.palette.primaryAction, lineWidth: 1)
                                    )
                            }
                        }

                        GlassCard(variant: .secondary, borderColor: theme.palette.indicators) {
                            Text("A 30 second join window opens before the sprint begins. Others can join during this time.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        startButton
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
                Text("Start a Sprint")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Choose your duration and starting page.")
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
                    .frame(width: 20, height: 20)
                    .bubblyIconMaterial(tint: theme.palette.primaryAction)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.palette.primaryAction, lineWidth: 1.35)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    private var startButton: some View {
        Button {
            Task { await start() }
        } label: {
            Group {
                if isStarting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Sprint")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                BubblyTileSurface(
                    tint: canStart
                        ? theme.palette.primaryAction
                        : theme.palette.primaryAction.opacity(0.34),
                    cornerRadius: 16
                )
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    private func start() async {
        guard canStart, let page = Int(startPageText) else { return }
        isStarting = true
        errorMessage = nil

        let body = StartSprintBody(
            userId: userId,
            displayName: displayName,
            durationMinutes: selectedDuration,
            startPage: page
        )

        do {
            let sprint = try await SprintService.shared.startSprint(body: body)
            onStarted?(sprint)
        } catch {
            errorMessage = "Failed to start sprint. There may already be one active."
        }

        isStarting = false
    }
}
