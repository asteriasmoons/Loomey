//
// SprintRoomView.swift
// Lumey
//

import SwiftUI
import UserNotifications

@MainActor
struct SprintRoomView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var messages: [SprintMessage] = []
    @State private var activeSprint: Sprint? = nil
    @State private var messageText: String = ""
    @State private var isSending = false
    @State private var isLoading = false
    @State private var showStartSheet = false
    @State private var showJoinSheet = false
    @State private var showEndPageSheet = false
    @State private var showLeaderboard = false
    @State private var errorMessage: String? = nil
    @State private var hasSubmittedEndPage = false
    @State private var sprintTimeRemaining: String = ""
    @State private var countdownTimer: Timer? = nil
    @State private var showSetDisplayName = false
    @State private var showChangeDisplayName = false
    @State private var localDisplayNameOverride: String = ""
    @State private var showClearConfirm = false
    @State private var showMyPoints = false
    @State private var showRoomMenu = false
    @State private var myLeaderboardEntry: SprintLeaderboardEntry? = nil
    @State private var isLoadingPoints = false

    private let socketManager = SprintSocketManager.shared

    private var isAdminUser: Bool {
        appState.currentAppleUserId == "001664.f2fefbb84f024544b98e865fa6c6b49e.1524"
    }

    private var userId: String { appState.currentAppleUserId ?? "" }
    private var displayName: String {
        if !localDisplayNameOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return localDisplayNameOverride
        }
        return appState.currentUser?.displayName ?? ""
    }

    private var isParticipant: Bool {
        activeSprint?.participants.contains(where: { $0.userId == userId }) ?? false
    }

    private var showFloatingSubmit: Bool {
        guard let sprint = activeSprint else { return false }
        return isParticipant && (sprint.isActive || sprint.isSubmitting) && !hasSubmittedEndPage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
            VStack(spacing: 0) {
                roomHeader
                if let sprint = activeSprint, !sprint.isFinished {
                    sprintBanner(sprint: sprint)
                    Rectangle().fill(LColors.glassBorder).frame(height: 1)
                }
                messagesArea
                chatInputBar
            }

            if showFloatingSubmit {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showEndPageSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image("loveflag")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(LColors.accents.primary)
                                Text("Submit Pages")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                activeSprint?.isSubmitting == true
                                    ? Color.orange
                                    : LColors.accent
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 12, y: 6
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showLeaderboard) {
            SprintLeaderboardView()
        }
        .adaptivePresentation(isPresented: $showMyPoints, useFullScreenCover: horizontalSizeClass == .regular) {
            SprintMyPointsSheet(entry: myLeaderboardEntry, userId: userId, displayName: displayName)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            socketManager.connect()
            registerSocketCallbacks()
            Task { await loadAll() }
        }
        .onDisappear {
            socketManager.disconnect()
            countdownTimer?.invalidate()
        }
        .confirmationDialog("Clear all sprint chat messages?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear Chat", role: .destructive) {
                Task { await clearSprintChat() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .adaptivePresentation(isPresented: $showStartSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            SprintStartSheet(
                userId: userId,
                displayName: displayName,
                onClose: { showStartSheet = false },
                onStarted: { sprint in
                    activeSprint = sprint
                    showStartSheet = false
                    scheduleWarningNotification(sprint: sprint)
                    startCountdown()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.dark)
        }
        .adaptivePresentation(isPresented: $showJoinSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            if let sprint = activeSprint {
                SprintJoinSheet(
                    sprint: sprint,
                    userId: userId,
                    displayName: displayName,
                    onClose: { showJoinSheet = false },
                    onJoined: { updatedSprint in
                        activeSprint = updatedSprint
                        showJoinSheet = false
                        scheduleWarningNotification(sprint: updatedSprint)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
            }
        }
        .adaptivePresentation(isPresented: $showEndPageSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            if let sprint = activeSprint {
                SprintEndPageSheet(
                    sprint: sprint,
                    userId: userId,
                    onClose: { showEndPageSheet = false },
                    onSubmitted: { _ in
                        hasSubmittedEndPage = true
                        showEndPageSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
            }
        }
        .adaptivePresentation(isPresented: $showSetDisplayName, useFullScreenCover: horizontalSizeClass == .regular) {
            SetDisplayNameSheet(
                userId: userId,
                isChanging: false,
                onClose: nil,
                onSaved: { newName in
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    localDisplayNameOverride = trimmed
                    applyUpdatedDisplayName(trimmed)
                    showSetDisplayName = false
                    Task { await loadAll() }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
            .preferredColorScheme(.dark)
        }
        .adaptivePresentation(isPresented: $showChangeDisplayName, useFullScreenCover: horizontalSizeClass == .regular) {
            SetDisplayNameSheet(
                userId: userId,
                isChanging: true,
                onClose: { showChangeDisplayName = false },
                onSaved: { newName in
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    localDisplayNameOverride = trimmed
                    applyUpdatedDisplayName(trimmed)
                    showChangeDisplayName = false
                    Task { await loadAll() }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.dark)
        }
            .animation(.easeInOut(duration: 0.3), value: showFloatingSubmit)
        }
    }

    // MARK: - Header

    private var roomHeader: some View {
        HStack {
            Text("Sprint Room")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LColors.headingPrimary)
            Spacer()

            Menu {
                Button {
                    showLeaderboard = true
                } label: {
                    Label {
                        Text("Leaderboard")
                    } icon: {
                        Image("startrophyfill")
                    }
                }

                Button {
                    showMyPoints = true
                } label: {
                    Label {
                        Text("My Points")
                    } icon: {
                        Image("starfill")
                    }
                }

                Button {
                    showChangeDisplayName = true
                } label: {
                    Label {
                        Text("Change Username")
                    } icon: {
                        Image("profilewavy")
                    }
                }

                Button {
                    Task { await loadAll() }
                } label: {
                    Label {
                        Text("Refresh")
                    } icon: {
                        Image("reset")
                    }
                }

                if isAdminUser {
                    Divider()
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label {
                            Text("Clear Chat")
                        } icon: {
                            Image("trash")
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(LColors.border.nested)
                        .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                        .frame(width: 34, height: 34)
                    Image("dotswavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(
                            LColors.accents.special
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(LColors.bg)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LColors.accents.special,
                                            lineWidth: 1.35
                                        )
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Sprint banner

    private func sprintBanner(sprint: Sprint) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(sprint.isWaiting ? Color.yellow : sprint.isSubmitting ? Color.orange : Color.green)
                        .frame(width: 7, height: 7)
                    Text(sprint.isWaiting ? "Waiting" : sprint.isActive ? "In Progress" : "Submit Now")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LColors.textPrimary)
                }

                if !sprint.isWaiting && !sprintTimeRemaining.isEmpty {
                    Text(sprintTimeRemaining)
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(sprint.isSubmitting ? Color.orange : LColors.textPrimary)
                }

                if sprint.isWaiting {
                    Text("Join before the sprint begins")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image("profilewavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(LColors.textSecondary)
                Text("\(sprint.participants.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LColors.textSecondary)
            }

            if !isParticipant {
                Button { showJoinSheet = true } label: {
                    Text("Join")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(LColors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if hasSubmittedEndPage {
                HStack(spacing: 4) {
                    Image("checkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(LColors.textSecondary)
                    Text("Submitted")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(LColors.glassSurface)
    }

    // MARK: - Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        SprintMessageBubble(message: message, currentUserId: userId)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .padding(.bottom, showFloatingSubmit ? 150 : 72)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Chat input

    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(LColors.glassBorder).frame(height: 1)

            HStack(spacing: 12) {
                if activeSprint == nil {
                    Button { showStartSheet = true } label: {
                        ZStack {
                            Circle()
                                .fill(LColors.border.nested)
                                .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                                .frame(width: 40, height: 40)
                            Image("sparkbolt")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(
                                    LColors.accents.special
                                )
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(LColors.bg)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    LColors.accents.special,
                                                    lineWidth: 1.35
                                                )
                                        )
                                        .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                GlassCard(variant: .featured) {
                    TextField("Message...", text: $messageText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)

                Button { Task { await sendMessage() } } label: {
                    Image("arrowupwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(
                            LColors.accents.special
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(LColors.bg)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LColors.accents.special,
                                            lineWidth: 1.35
                                        )
                                )
                                .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                        )
                        .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.45 : 1)
                }
                .buttonStyle(.plain)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .padding(.bottom, 104)
        }
    }

    // MARK: - Socket callbacks

    private func registerSocketCallbacks() {
        socketManager.onMessage = { [self] message in
            DispatchQueue.main.async {
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onSprintStarted = { [self] sprint, message in
            DispatchQueue.main.async {
                activeSprint = sprint
                startCountdown()
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onSprintActive = { [self] _, message in
            DispatchQueue.main.async {
                if let sprint = activeSprint {
                    activeSprint = Sprint(
                        id: sprint.id,
                        startedByUserId: sprint.startedByUserId,
                        startedByDisplayName: sprint.startedByDisplayName,
                        durationMinutes: sprint.durationMinutes,
                        startsAt: sprint.startsAt,
                        endsAt: sprint.endsAt,
                        status: "active",
                        participants: sprint.participants,
                        createdAt: sprint.createdAt
                    )
                }
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onSprintWarning = { [self] _, message in
            DispatchQueue.main.async {
                if let sprint = activeSprint {
                    activeSprint = Sprint(
                        id: sprint.id,
                        startedByUserId: sprint.startedByUserId,
                        startedByDisplayName: sprint.startedByDisplayName,
                        durationMinutes: sprint.durationMinutes,
                        startsAt: sprint.startsAt,
                        endsAt: sprint.endsAt,
                        status: "submitting",
                        participants: sprint.participants,
                        createdAt: sprint.createdAt
                    )
                    if isParticipant && !hasSubmittedEndPage {
                        showEndPageSheet = true
                    }
                }
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onSprintFinished = { [self] _, _, message in
            DispatchQueue.main.async {
                countdownTimer?.invalidate()
                sprintTimeRemaining = ""
                Task { activeSprint = try? await SprintService.shared.getActiveSprint() }
                hasSubmittedEndPage = false
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onSprintJoined = { [self] _, _, _, message in
            DispatchQueue.main.async {
                Task { activeSprint = try? await SprintService.shared.getActiveSprint() }
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }

        socketManager.onPageSubmitted = { _, _ in }

        socketManager.onChatCleared = { [self] in
            DispatchQueue.main.async {
                messages = []
            }
        }
    }

    // MARK: - Actions

    private func loadAll() async {
        isLoading = true
        activeSprint = try? await SprintService.shared.getActiveSprint()
        messages = (try? await SprintService.shared.getMessages()) ?? []
        myLeaderboardEntry = try? await SprintService.shared.getUserLeaderboardEntry(userId: userId)
        isLoading = false

        if let sprint = activeSprint {
            hasSubmittedEndPage = sprint.participants.first(where: { $0.userId == userId })?.submittedAt != nil
            startCountdown()
        }

        if (appState.currentUser?.displayName ?? "").isEmpty {
            showSetDisplayName = true
        }
    }

    private func applyUpdatedDisplayName(_ newName: String) {
        guard !newName.isEmpty else { return }
        patchActiveSprintDisplayName(newName)
        messages = messages.map { message in
            guard message.senderUserId == userId else { return message }
            return SprintMessage(
                id: message.id,
                senderUserId: message.senderUserId,
                senderDisplayName: newName,
                type: message.type,
                text: message.text,
                sprintId: message.sprintId,
                resultPayload: message.resultPayload,
                createdAt: message.createdAt
            )
        }
    }

    private func patchActiveSprintDisplayName(_ newName: String) {
        guard let sprint = activeSprint else { return }

        let updatedParticipants = sprint.participants.map { participant in
            guard participant.userId == userId else { return participant }
            return SprintParticipant(
                userId: participant.userId,
                displayName: newName,
                startPage: participant.startPage,
                endPage: participant.endPage,
                pagesRead: participant.pagesRead,
                pointsAwarded: participant.pointsAwarded,
                joinedAt: participant.joinedAt,
                submittedAt: participant.submittedAt
            )
        }

        activeSprint = Sprint(
            id: sprint.id,
            startedByUserId: sprint.startedByUserId,
            startedByDisplayName: sprint.startedByUserId == userId ? newName : sprint.startedByDisplayName,
            durationMinutes: sprint.durationMinutes,
            startsAt: sprint.startsAt,
            endsAt: sprint.endsAt,
            status: sprint.status,
            participants: updatedParticipants,
            createdAt: sprint.createdAt
        )
    }

    private func clearSprintChat() async {
        _ = try? await SprintService.shared.clearMessages(userId: userId)
        messages = []
    }

    private func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        messageText = ""

        let body = SendSprintMessageBody(
            senderUserId: userId,
            senderDisplayName: displayName,
            text: text
        )

        if let sent = try? await SprintService.shared.sendMessage(body: body) {
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
            }
        }

        isSending = false
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer(timeInterval: 1, repeats: true) { [self] _ in
            guard let sprint = activeSprint else { return }

            if sprint.isWaiting, let startsAt = sprint.startsAtDate {
                let remaining = startsAt.timeIntervalSinceNow
                if remaining <= 0 { return }
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                sprintTimeRemaining = String(format: "%d:%02d", mins, secs)
            } else if let endsAt = sprint.endsAtDate {
                let remaining = endsAt.timeIntervalSinceNow
                if remaining <= 0 {
                    sprintTimeRemaining = "0:00"
                    return
                }
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                sprintTimeRemaining = String(format: "%d:%02d", mins, secs)
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    // MARK: - Local notification

    private func scheduleWarningNotification(sprint: Sprint) {
        guard let endsAt = sprint.endsAtDate else { return }
        let fireDate = endsAt.addingTimeInterval(-3 * 60)
        guard fireDate > Date() else { return }

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["sprint.warning.\(sprint.id)"]
        )

        NotificationManager.shared.scheduleCalendarEvent(
            id: "sprint.warning.\(sprint.id)",
            title: "Sprint ending soon!",
            body: "3 minutes left — enter your end page now.",
            fireDate: fireDate
        )
    }
}

private extension View {
    @ViewBuilder
    func adaptivePresentation<Content: View>(
        isPresented: Binding<Bool>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(isPresented: isPresented, content: content)
        } else {
            self.sheet(isPresented: isPresented, content: content)
        }
    }
}

// MARK: - My Points Sheet

struct SprintMyPointsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialEntry: SprintLeaderboardEntry?
    let userId: String
    let displayName: String

    @State private var entry: SprintLeaderboardEntry?
    @State private var isLoading = false

    init(entry: SprintLeaderboardEntry?, userId: String, displayName: String) {
        self.initialEntry = entry
        self.userId = userId
        self.displayName = displayName
        _entry = State(initialValue: entry)
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .foregroundStyle(LColors.accents.contrast)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LColors.accents.primary, lineWidth: 1.35)
                                    )
                                    .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 10)

                Text("My Sprint Points")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else if let entry {
                    HStack(spacing: 16) {
                        pointsStat(value: "\(entry.totalPoints)", label: "Total Points", icon: "starwavy", color: .white)
                        pointsStat(value: "\(entry.totalPagesRead)", label: "Pages Read", icon: "flatbook", color: .white)
                        pointsStat(value: "\(entry.sprintsParticipated)", label: "Sprints", icon: "sparkbolt", color: .white)
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)

                    Text("Keep sprinting to climb the leaderboard!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 10) {
                        Image("sparkbolt")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(LColors.textSecondary)
                        Text("No sprint data yet.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LColors.textSecondary)
                        Text("Join a sprint to start earning points!")
                            .font(.system(size: 13))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.top, 16)
        }
        .task {
            guard entry == nil else { return }
            isLoading = true
            entry = try? await SprintService.shared.getUserLeaderboardEntry(userId: userId)
            isLoading = false
        }
    }

    private func pointsStat(value: String, label: String, icon: String, color: Color) -> some View {
        GlassCard(padding: 14, variant: .secondary) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(LColors.accents.secondary)
                }

                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)

                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Message bubble

struct SprintMessageBubble: View {
    let message: SprintMessage
    let currentUserId: String

    private var isMe: Bool { message.senderUserId == currentUserId }

    var body: some View {
        if message.isSystem {
            systemBubble
        } else if message.isSprintResult, let payload = message.resultPayload {
            SprintResultCard(payload: payload)
        } else {
            regularBubble
        }
    }

    private var systemBubble: some View {
        Text(message.text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(LColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }

    private var regularBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.senderDisplayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LColors.textSecondary)
                }
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMe ? LColors.accent : LColors.border.subtle)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Sprint result card

struct SprintResultCard: View {
    let payload: SprintResultPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("loveflag")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(LColors.accents.special)
                Text("Sprint Results — \(payload.durationMinutes) min")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LColors.textPrimary)
            }

            if payload.ranked.isEmpty {
                Text("No one submitted their pages.")
                    .font(.subheadline)
                    .foregroundStyle(LColors.textSecondary)
            } else {
                ForEach(Array(payload.ranked.enumerated()), id: \.element.id) { index, entry in
                    GlassCard(variant: .primary) {
                        HStack(spacing: 10) {
                            rankIcon(for: index)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(LColors.textPrimary)

                                Text("\(entry.pagesRead) pages · \(entry.pointsAwarded) pts")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(LColors.textSecondary)
                            }

                            Spacer()

                            Text("#\(entry.rank)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(14)
        .background(LColors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LColors.glassBorder, lineWidth: 1))
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func rankIcon(for index: Int) -> some View {
        switch index {
        case 0:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.primary)
        case 1:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.contrast)
        case 2:
            Image("startrophyfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.secondary)
        default:
            Image("sparklybook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LColors.accents.special)
        }
    }
}
