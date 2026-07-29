// BuddySocketManager.swift
// Lumey

import Foundation
import SocketIO

final class BuddySocketManager: NSObject {
    static let shared = BuddySocketManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentGroupId: String?

    // Callbacks set by the chat view
    var onMessage: ((BuddyMessage) -> Void)?
    var onMemberJoined: ((String, String) -> Void)?   // userId, displayName
    var onMemberLeft: ((String, String) -> Void)?     // userId, displayName
    var onJoinRequest: ((String, String) -> Void)?    // requesterUserId, displayName
    var onJoinDeclined: ((String) -> Void)?           // userId
    var onChatCleared: (() -> Void)?

    private let serverURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !url.isEmpty else {
            return "https://appapi.voxiverse.ink"
        }
        return url
    }()

    private override init() {}

    // MARK: - Connect

    func connect() {
        guard manager == nil, let url = URL(string: serverURL) else { return }

        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectWait(3),
            .reconnectAttempts(5)
        ])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self, let groupId = self.currentGroupId else { return }
            self.socket?.emit("buddy:join_room", groupId)
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.currentGroupId = nil
        }

        registerEvents()
        socket?.connect()
    }

    // MARK: - Room management

    func joinRoom(_ groupId: String) {
        currentGroupId = groupId
        if socket?.status == .connected {
            socket?.emit("buddy:join_room", groupId)
        } else {
            connect()
        }
    }

    func leaveRoom(_ groupId: String) {
        socket?.emit("buddy:leave_room", groupId)
        currentGroupId = nil
    }

    func disconnect() {
        socket?.disconnect()
        manager = nil
        socket = nil
        currentGroupId = nil
    }

    // MARK: - Event registration

    private func registerEvents() {
        socket?.on("buddy:message") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let messageDict = dict["message"] as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
                  let message = try? JSONDecoder().decode(BuddyMessage.self, from: jsonData)
            else { return }
            DispatchQueue.main.async { self.onMessage?(message) }
        }

        socket?.on("buddy:member_joined") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let displayName = dict["displayName"] as? String
            else { return }
            DispatchQueue.main.async { self.onMemberJoined?(userId, displayName) }
        }

        socket?.on("buddy:member_left") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let displayName = dict["displayName"] as? String
            else { return }
            DispatchQueue.main.async { self.onMemberLeft?(userId, displayName) }
        }

        socket?.on("buddy:join_request") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let userId = dict["requesterUserId"] as? String,
                  let displayName = dict["requesterDisplayName"] as? String
            else { return }
            DispatchQueue.main.async { self.onJoinRequest?(userId, displayName) }
        }

        socket?.on("buddy:join_declined") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String
            else { return }
            DispatchQueue.main.async { self.onJoinDeclined?(userId) }
        }

        socket?.on("buddy:chat_cleared") { [weak self] _, _ in
            guard let self else { return }
            DispatchQueue.main.async { self.onChatCleared?() }
        }
    }
}
