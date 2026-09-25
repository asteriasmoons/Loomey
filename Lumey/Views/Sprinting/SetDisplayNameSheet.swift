//
//  SetDisplayNameSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct SetDisplayNameSheet: View {
    let userId: String
    let isChanging: Bool // true = editing existing, false = first time setup
    var onClose: (() -> Void)?
    var onSaved: ((String) -> Void)?

    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query private var users: [AuthUser]

    @State private var nameText: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private var closeAction: () -> Void { onClose ?? {} }
    private var canSave: Bool {
        let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 30 && !isSaving
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if !isChanging {
                            GlassCard(variant: .featured) {
                                Text("This name will appear in the Sprint Room chat and on the leaderboard. You can change it later.")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Display Name")

                            TextField("e.g. Asteria", text: $nameText)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .textInputAutocapitalization(.words)
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

                            HStack {
                                Spacer()

                                Text("\(nameText.count)/30")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(nameText.count > 30 ? Color.red : LColors.textSecondary)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }

                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
        .onAppear {
            if isChanging, let existing = users.first(where: { $0.appleUserId == userId })?.displayName {
                nameText = existing
            }
        }
    }
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isChanging ? "Change Display Name" : "Choose a Display Name")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(isChanging ? "Update the name people see." : "Pick the name people will see in sprint rooms.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            if isChanging {
                Button {
                    closeAction()
                } label: {
                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .bubblyIconMaterial(tint: theme.palette.primaryAction)
                        .frame(width: 36, height: 36)
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    private var saveButton: some View {
        Button { Task { await save() } } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isChanging ? "Save" : "Let's Go")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.palette.background.opacity(0.70), radius: 1, y: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                BubblyTileSurface(
                    tint: canSave
                        ? theme.palette.secondaryAccent
                        : theme.palette.secondaryAccent.opacity(0.34),
                    cornerRadius: 16
                )
            }
            .bubblyTileLift()
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .tracking(0.5)
    }

    private func save() async {
        let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 30 else { return }
        isSaving = true
        errorMessage = nil

        // Save to backend
        do {
            try await UserProfileService.shared.setDisplayName(userId: userId, displayName: trimmed)
        } catch {
            errorMessage = "Failed to save. Please try again."
            isSaving = false
            return
        }

        // Save locally to SwiftData and update the live AppState user
        if let user = users.first(where: { $0.appleUserId == userId }) {
            user.displayName = trimmed
            try? modelContext.save()
        }
        appState.updateCurrentUserDisplayName(trimmed)

        isSaving = false
        onSaved?(trimmed)
    }
}
