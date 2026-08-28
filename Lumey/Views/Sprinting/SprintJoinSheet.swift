//
//  SprintJoinSheet.swift
//  Lumey
//

import SwiftUI

struct SprintJoinSheet: View {
    let sprint: Sprint
    let userId: String
    let displayName: String
    var onClose: (() -> Void)?
    var onJoined: ((Sprint) -> Void)?

    @State private var startPageText: String = ""
    @State private var isJoining = false
    @State private var errorMessage: String? = nil

    private var closeAction: () -> Void { onClose ?? {} }
    private var canJoin: Bool { !startPageText.isEmpty && !isJoining }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard(variant: .featured) {
                            HStack(spacing: 8) {
                                Image("sparkbolt")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(
                                        LColors.accents.secondary
                                    )
                                    .frame(width: 46, height: 46)
                                    .background(
                                        Circle()
                                            .fill(LColors.bg)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        LColors.accents.secondary,
                                                        lineWidth: 1.35
                                                    )
                                            )
                                            .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                                    )

                                Text("\(sprint.durationMinutes) minute sprint • \(sprint.participants.count) participant\(sprint.participants.count == 1 ? "" : "s") joined")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GlassCard(variant: .primary) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("Your Start Page")

                                TextField("What page are you on?", text: $startPageText)
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
                                            .strokeBorder(LColors.border.nested, lineWidth: 1)
                                    )
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        joinButton
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
                Text("Join Sprint")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text("Set your starting page before joining.")
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
                    .frame(width: 24, height: 24)
                    .foregroundStyle(
                        LColors.accents.secondary
                    )
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LColors.accents.secondary,
                                        lineWidth: 1.35
                                    )
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
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
                .fill(LColors.border.nested)
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    private var joinButton: some View {
        Button {
            Task { await join() }
        } label: {
            Group {
                if isJoining {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Join Sprint")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.cardTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        canJoin
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
                color: canJoin
                ? LColors.accent.opacity(0.3)
                : .clear,
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!canJoin)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    private func join() async {
        guard canJoin, let page = Int(startPageText) else { return }
        isJoining = true
        errorMessage = nil

        let body = JoinSprintBody(userId: userId, displayName: displayName, startPage: page)

        do {
            let updated = try await SprintService.shared.joinSprint(sprintId: sprint.id, body: body)
            onJoined?(updated)
        } catch {
            errorMessage = "Failed to join. The sprint may have ended."
        }

        isJoining = false
    }
}
