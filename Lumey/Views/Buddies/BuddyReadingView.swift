//
//
//  BuddyReadingView.swift
//  Lumey
//

import SwiftUI

struct BuddyReadingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var board: [BuddyAnnouncement] = []
    @State private var myAnnouncements: [BuddyAnnouncement] = []
    @State private var myGroups: [BuddyGroup] = []
    @State private var isLoading = false
    @State private var showPostSheet = false
    @State private var showGroupView = false
    @State private var showGroupPicker = false
    @State private var activeGroup: BuddyGroup? = nil
    @State private var groupPendingLeave: BuddyGroup?
    @State private var errorMessage: String? = nil
    @State private var showSetDisplayName = false
    @State private var showChangeDisplayName = false
    @State private var localDisplayNameOverride: String = ""
    @State private var announcementPendingDelete: BuddyAnnouncement?
    @State private var announcementPendingArchive: BuddyAnnouncement?
    @State private var announcementPendingClose: BuddyAnnouncement?
    
    private var userId: String { appState.currentAppleUserId ?? "" }
    private var displayName: String {
        if !localDisplayNameOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return localDisplayNameOverride
        }
        return appState.currentUser?.displayName ?? ""
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                mainContent
            }
            .navigationDestination(isPresented: $showGroupView) {
                if let group = activeGroup {
                    BuddyGroupView(group: group, userId: userId, displayName: displayName)
                }
            }
            .adaptivePresentation(isPresented: $showGroupPicker, useFullScreenCover: horizontalSizeClass == .regular) {
                BuddyGroupPickerSheet(
                    groups: myGroups,
                    currentUserId: userId,
                    onClose: { showGroupPicker = false },
                    onSelect: { group in
                        showGroupPicker = false
                        activeGroup = group
                        showGroupView = true
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
            }
            .adaptivePresentation(isPresented: $showPostSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                BuddyPostAnnouncementSheet(
                    userId: userId,
                    displayName: displayName,
                    onClose: { showPostSheet = false },
                    onPost: { announcement in
                        myAnnouncements.append(announcement)
                        showPostSheet = false
                        Task { await loadBoard() }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
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
            .alert(
                "Delete Announcement?",
                isPresented: Binding(
                    get: { announcementPendingDelete != nil },
                    set: { if !$0 { announcementPendingDelete = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let announcement = announcementPendingDelete {
                        Task { await removeAnnouncement(announcement) }
                    }
                }
                Button("Cancel", role: .cancel) {
                    announcementPendingDelete = nil
                }
            } message: {
                Text("This removes the announcement from the board.")
            }
            .alert(
                "Archive Announcement?",
                isPresented: Binding(
                    get: { announcementPendingArchive != nil },
                    set: { if !$0 { announcementPendingArchive = nil } }
                )
            ) {
                Button("Archive", role: .destructive) {
                    if let announcement = announcementPendingArchive {
                        Task { await archiveAnnouncement(announcement) }
                    }
                }
                Button("Cancel", role: .cancel) {
                    announcementPendingArchive = nil
                }
            } message: {
                Text("Archived announcements stop appearing on the board.")
            }
            .alert(
                "Close Group?",
                isPresented: Binding(
                    get: { announcementPendingClose != nil },
                    set: { if !$0 { announcementPendingClose = nil } }
                )
            ) {
                Button("Close Group", role: .destructive) {
                    if let announcement = announcementPendingClose {
                        Task { await closeAnnouncement(announcement) }
                    }
                }
                Button("Cancel", role: .cancel) {
                    announcementPendingClose = nil
                }
            } message: {
                Text("Readers already in the group can stay, but no one else can join.")
            }
            .alert(
                "Leave Group?",
                isPresented: Binding(
                    get: { groupPendingLeave != nil },
                    set: { if !$0 { groupPendingLeave = nil } }
                )
            ) {
                Button("Leave", role: .destructive) {
                    if let group = groupPendingLeave {
                        Task { await leaveGroup(group) }
                    }
                }
                Button("Cancel", role: .cancel) {
                    groupPendingLeave = nil
                }
            } message: {
                if let group = groupPendingLeave {
                    Text("You'll stop reading \(group.bookTitle) with this group. Your other buddy reads aren't affected.")
                }
            }
            .onAppear { Task { await loadAll() } }
        }
    }
    
    // MARK: - Main content
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                if !groupsAwaitingResponse.isEmpty {
                    joinRequestsSection
                }
                myStatusSection
                boardSection
                Spacer(minLength: 96)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 140)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Buddy Reading")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                
                Button {
                    showChangeDisplayName = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                            .frame(width: 34, height: 34)
                        Image("profilewavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.35
                                            )
                                    )
                                    .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    Task { await loadAll() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                            .frame(width: 34, height: 34)
                        Image("reset")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(LColors.bg)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.35
                                            )
                                    )
                                    .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 24)
        }
    }
    
    // MARK: - My status section
    
    private var myStatusSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("My Status")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                if !myGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image("profilewavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)
                                .foregroundStyle(LGradients.header)
                            Text(groupSummaryText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(LColors.textPrimary)
                        }

                        Button {
                            openChat()
                        } label: {
                            HStack(spacing: 8) {
                                Image("chatlinesfill")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)

                                Text(myGroups.count > 1 ? "Open a Chat" : "Open Chat")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(LGradients.header)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(LColors.glassSurface2))
                            .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                    }
                }

                // Announcements + post button — always visible regardless of group status
                VStack(alignment: .leading, spacing: 12) {
                    if !myAnnouncements.isEmpty {
                        ForEach(myAnnouncements) { announcement in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image("books")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                            .foregroundStyle(LGradients.header)
                                        Text(announcement.bookTitle)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(LColors.textPrimary)
                                    }
                                    if let msg = announcement.message, !msg.isEmpty {
                                        Text("\"\(msg)\"")
                                            .font(.subheadline)
                                            .foregroundStyle(LColors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if announcement.isClosed {
                                    ownerStatusPill("Closed")
                                } else if announcement.isArchived {
                                    ownerStatusPill("Archived")
                                }
                                ownerActionButton(icon: "lockwavy", title: "Close Group", disabled: announcement.isClosed || announcement.isArchived) {
                                    announcementPendingClose = announcement
                                }
                                ownerActionButton(icon: "archivefill", title: "Archive", disabled: announcement.isArchived) {
                                    announcementPendingArchive = announcement
                                }
                                Button {
                                    announcementPendingDelete = announcement
                                } label: {
                                    Image("minuswavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(LColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(LColors.glassBorder, lineWidth: 1))
                        }
                    }

                    if myAnnouncements.count < 3 {
                        if myGroups.isEmpty && myAnnouncements.isEmpty {
                            Text("Post what you're reading and find a buddy to read along with.")
                                .font(.subheadline)
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Button {
                            showPostSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image("addwavy")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)

                                Text(myAnnouncements.isEmpty ? "Post Announcement" : "Post Another")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(LGradients.header)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(LColors.glassSurface2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(LColors.glassBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
            }
        }
    }
    
    // MARK: - Join requests

    /// Every group of mine that has someone waiting on a decision.
    private var groupsAwaitingResponse: [BuddyGroup] {
        myGroups.filter { !$0.pendingMembers.isEmpty }
    }

    private var totalPendingRequests: Int {
        groupsAwaitingResponse.reduce(0) { $0 + $1.pendingMembers.count }
    }

    private var joinRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Join Requests")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(totalPendingRequests)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LGradients.header))
            }

            ForEach(groupsAwaitingResponse) { group in
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image("books")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(LGradients.header)

                            Text(group.bookTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LColors.textPrimary)
                                .lineLimit(1)
                        }

                        ForEach(group.pendingMembers) { member in
                            requestRow(group: group, member: member)
                        }
                    }
                }
            }
        }
    }

    private func requestRow(group: BuddyGroup, member: BuddyMember) -> some View {
        HStack(spacing: 10) {
            Text(member.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 6)

            Button {
                Task { await respond(groupId: group.id, targetUserId: member.userId, accept: true) }
            } label: {
                Text("Accept")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(LColors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Task { await respond(groupId: group.id, targetUserId: member.userId, accept: false) }
            } label: {
                Text("Decline")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(LColors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LColors.glassBorder, lineWidth: 1))
    }
    
    // MARK: - Board
    
    private var boardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Announcement Board")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
            }
            
            if board.isEmpty && !isLoading {
                GlassCard {
                    Text("No announcements yet. Be the first to post!")
                        .font(.subheadline)
                        .foregroundStyle(LColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
            } else {
                ForEach(board) { announcement in
                    BuddyAnnouncementCard(
                        announcement: announcement,
                        currentUserId: userId,
                        currentUserDisplayName: displayName,
                        joinedGroup: joinedGroup(for: announcement),
                        onRequestJoin: {
                            Task { await requestToJoin(announcement: announcement) }
                        },
                        onLeave: { group in
                            groupPendingLeave = group
                        },
                        onOpenChat: { group in
                            activeGroup = group
                            showGroupView = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Group helpers

    /// The group backing this announcement, but only if the current user is a joined member.
    private func joinedGroup(for announcement: BuddyAnnouncement) -> BuddyGroup? {
        guard let groupId = announcement.groupId else { return nil }
        return myGroups.first { $0.id == groupId }
    }

    private var groupSummaryText: String {
        guard myGroups.count == 1, let group = myGroups.first else {
            return "You're in \(myGroups.count) buddy reads"
        }
        let count = group.joinedMembers.count
        return "Reading \(group.bookTitle) with \(count) \(count == 1 ? "buddy" : "buddies")"
    }

    /// One group opens directly; multiple ask which one first.
    private func openChat() {
        if myGroups.count == 1 {
            activeGroup = myGroups[0]
            showGroupView = true
        } else if myGroups.count > 1 {
            showGroupPicker = true
        }
    }

    // MARK: - Actions

    private func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let board = loadBoard()
        async let myAnnouncement = loadMyAnnouncement()
        async let groups = loadMyGroups()
        _ = await (board, myAnnouncement, groups)
        isLoading = false
        
        if (appState.currentUser?.displayName ?? "").isEmpty {
            showSetDisplayName = true
        }
    }
    
    @discardableResult
    private func loadBoard() async -> Void {
        do {
            board = try await BuddyService.shared.getBoard(userId: userId)
        } catch {
            errorMessage = "Failed to load board"
        }
    }
    
    @discardableResult
    private func loadMyAnnouncement() async -> Void {
        myAnnouncements = (try? await BuddyService.shared.getMyAnnouncement(userId: userId)) ?? []
    }
    
    @discardableResult
    private func loadMyGroups() async -> Void {
        myGroups = (try? await BuddyService.shared.getMyGroups(userId: userId)) ?? []
    }
    
    private func removeAnnouncement(_ announcement: BuddyAnnouncement) async {
        do {
            try await BuddyService.shared.removeAnnouncement(id: announcement.id, userId: userId)
            myAnnouncements.removeAll { $0.id == announcement.id }
            announcementPendingDelete = nil
            await loadBoard()
        } catch {
            errorMessage = "Failed to remove announcement"
        }
    }

    private func archiveAnnouncement(_ announcement: BuddyAnnouncement) async {
        do {
            _ = try await BuddyService.shared.archiveAnnouncement(id: announcement.id, ownerUserId: userId)
            announcementPendingArchive = nil
            await loadAll()
        } catch {
            errorMessage = "Failed to archive announcement"
        }
    }

    private func closeAnnouncement(_ announcement: BuddyAnnouncement) async {
        do {
            _ = try await BuddyService.shared.closeAnnouncement(id: announcement.id, ownerUserId: userId)
            announcementPendingClose = nil
            await loadAll()
        } catch {
            errorMessage = "Failed to close group"
        }
    }
    
    private func requestToJoin(announcement: BuddyAnnouncement) async {
        // Already a member of this specific read — nothing to request.
        guard joinedGroup(for: announcement) == nil else { return }
        do {
            let currentDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let body = RequestToJoinBody(
                announcementId: announcement.id,
                requesterUserId: userId,
                requesterDisplayName: currentDisplayName
            )
            _ = try await BuddyService.shared.requestToJoin(body: body)
            await loadAll()
        } catch {
            errorMessage = "Failed to send join request"
        }
    }

    private func respond(groupId: String, targetUserId: String, accept: Bool) async {
        // Buddy reads have no owner — any joined member can accept or decline.
        guard let group = myGroups.first(where: { $0.id == groupId }),
              group.joinedMembers.contains(where: { $0.userId == userId }) else { return }
        do {
            let body = RespondToJoinBody(actorUserId: userId, targetUserId: targetUserId, accept: accept)
            let updated = try await BuddyService.shared.respondToJoinRequest(groupId: groupId, body: body)
            if let index = myGroups.firstIndex(where: { $0.id == updated.id }) {
                myGroups[index] = updated
            }
        } catch {
            errorMessage = "Failed to respond to request"
        }
    }

    /// Leaves exactly one group. Other buddy reads are untouched.
    private func leaveGroup(_ group: BuddyGroup) async {
        do {
            try await BuddyService.shared.leaveGroup(groupId: group.id, userId: userId)
            myGroups.removeAll { $0.id == group.id }
            groupPendingLeave = nil
            await loadAll()
        } catch {
            errorMessage = "Failed to leave group"
        }
    }
    
    private func applyUpdatedDisplayName(_ newName: String) {
        guard !newName.isEmpty else { return }
        localDisplayNameOverride = newName
    }

    private func ownerStatusPill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(LColors.textPrimary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
    }

    private func ownerActionButton(
        icon: String,
        title: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(disabled ? LColors.textSecondary.opacity(0.45) : LColors.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(title)
    }
    
    // MARK: - Announcement card
    
    struct BuddyAnnouncementCard: View {
        let announcement: BuddyAnnouncement
        let currentUserId: String
        let currentUserDisplayName: String
        /// Non-nil when the current user is a joined member of *this* announcement's group.
        let joinedGroup: BuddyGroup?
        let onRequestJoin: () -> Void
        let onLeave: (BuddyGroup) -> Void
        let onOpenChat: (BuddyGroup) -> Void

        private var isMember: Bool { joinedGroup != nil }
        private var pendingCount: Int { joinedGroup?.pendingMembers.count ?? 0 }
        private var spotsLeft: Int { announcement.availableSpots }
        private var actionTitle: String {
            announcement.ownerUserId == currentUserId ? "Join Your Group" : "Request to Read Together"
        }
        
        private var ownerNameText: String {
            announcement.ownerUserId == currentUserId ? currentUserDisplayName : announcement.ownerDisplayName
        }
        
        var body: some View {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image("books")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                    .foregroundStyle(LGradients.header)
                                Text(announcement.bookTitle)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(LColors.textPrimary)
                            }
                            
                            if let author = announcement.bookAuthor, !author.isEmpty {
                                Text(author)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                        }
                        
                        Spacer()

                        HStack(spacing: 6) {
                            if pendingCount > 0 {
                                Text("\(pendingCount) waiting")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(LGradients.header))
                            }

                            Text("\(spotsLeft) spot\(spotsLeft == 1 ? "" : "s")")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image("profilewavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                            .foregroundStyle(LColors.textSecondary)
                        Text(ownerNameText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    
                    if let chapter = announcement.currentChapter {
                        Text("Currently on chapter \(chapter)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LColors.textSecondary)
                    } else if let page = announcement.currentPage {
                        Text("Currently on page \(page)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    
                    if let msg = announcement.message, !msg.isEmpty {
                        Text("\"\(msg)\"")
                            .font(.subheadline)
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(3)
                    }
                    
                    HStack(spacing: 10) {
                        if let group = joinedGroup {
                            Button {
                                onOpenChat(group)
                            } label: {
                                HStack(spacing: 8) {
                                    Image("chatlinesfill")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)

                                    Text("Open Chat")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(LGradients.header)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(LColors.glassSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LColors.glassBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onLeave(group)
                            } label: {
                                Text("Leave Group")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(LColors.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(LColors.glassBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                onRequestJoin()
                            } label: {
                                HStack(spacing: 8) {
                                    Image("addwavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)

                                    Text(actionTitle)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(LGradients.header)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(LColors.glassSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LColors.glassBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

}

// MARK: - Group Picker

struct BuddyGroupPickerSheet: View {
    let groups: [BuddyGroup]
    let currentUserId: String
    let onClose: () -> Void
    let onSelect: (BuddyGroup) -> Void

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 10) {
                        ForEach(groups) { group in
                            Button {
                                onSelect(group)
                            } label: {
                                groupRow(group)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Which Buddy Read?")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("You're reading with more than one group. Pick a chat to open.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func groupRow(_ group: BuddyGroup) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image("books")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().strokeBorder(LColors.glassBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.bookTitle)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let author = group.bookAuthor, !author.isEmpty {
                        Text(author)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }

                    Text(group.joinedMembers.map(\.displayName).joined(separator: ", "))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(1)

                    if let owner = group.ownerLabel(currentUserId: currentUserId) {
                        Text(owner)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LGradients.header)
                    }
                }

                Spacer(minLength: 0)

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
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
