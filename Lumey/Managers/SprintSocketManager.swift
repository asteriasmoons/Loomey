//
//  SprintSocketManager.swift
//  Lumey
//

import Foundation
import SocketIO

final class SprintSocketManager {
    static let shared = SprintSocketManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    // Callbacks
    var onMessage: ((SprintMessage) -> Void)?
    var onSprintStarted: ((Sprint, SprintMessage) -> Void)?
    var onSprintActive: ((String, SprintMessage) -> Void)?
    var onSprintWarning: ((String, SprintMessage) -> Void)?
    var onSprintFinished: ((String, SprintResultPayload, SprintMessage) -> Void)?
    var onSprintJoined: ((String, String, String, SprintMessage) -> Void)? // sprintId, userId, displayName, msg
    var onPageSubmitted: ((String, String) -> Void)?                       // userId, displayName
    var onChatCleared: (() -> Void)?

    private let serverURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !url.isEmpty else {
            return "https://appapi.voxiverse.ink"
        }
        return url
    }()

    private init() {}

    func connect() {
        guard manager == nil, let url = URL(string: serverURL) else { return }

        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectWait(3),
            .reconnectAttempts(10)
        ])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            self?.socket?.emit("sprint:join_room")
        }

        registerEvents()
        socket?.connect()
    }

    func disconnect() {
        socket?.emit("sprint:leave_room")
        socket?.disconnect()
        manager = nil
        socket = nil
    }

    private func decode<T: Decodable>(_ dict: [String: Any], as _: T.Type) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func decodeMessage(_ dict: [String: Any]) -> SprintMessage? {
        guard let msgDict = dict["message"] as? [String: Any] else { return nil }
        return decode(msgDict, as: SprintMessage.self)
    }

    private func registerEvents() {
        socket?.on("sprint:message") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onMessage?(msg) }
        }

        socket?.on("sprint:started") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let sprintDict = dict["sprint"] as? [String: Any],
                  let sprint = self.decode(sprintDict, as: Sprint.self),
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onSprintStarted?(sprint, msg) }
        }

        socket?.on("sprint:active") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let sprintId = dict["sprintId"] as? String,
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onSprintActive?(sprintId, msg) }
        }

        socket?.on("sprint:warning") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let sprintId = dict["sprintId"] as? String,
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onSprintWarning?(sprintId, msg) }
        }

        socket?.on("sprint:finished") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let sprintId = dict["sprintId"] as? String,
                  let payloadDict = dict["resultPayload"] as? [String: Any],
                  let payload = self.decode(payloadDict, as: SprintResultPayload.self),
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onSprintFinished?(sprintId, payload, msg) }
        }

        socket?.on("sprint:joined") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let sprintId = dict["sprintId"] as? String,
                  let userId = dict["userId"] as? String,
                  let displayName = dict["displayName"] as? String,
                  let msg = self.decodeMessage(dict) else { return }
            DispatchQueue.main.async { self.onSprintJoined?(sprintId, userId, displayName, msg) }
        }

        socket?.on("sprint:page_submitted") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let displayName = dict["displayName"] as? String else { return }
            DispatchQueue.main.async { self.onPageSubmitted?(userId, displayName) }
        }

        socket?.on("sprint:chat_cleared") { [weak self] _, _ in
            guard let self else { return }
            DispatchQueue.main.async { self.onChatCleared?() }
        }
    }
}
