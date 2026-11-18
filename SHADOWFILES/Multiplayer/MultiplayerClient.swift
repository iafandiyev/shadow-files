import Foundation
import Combine

@MainActor
final class MultiplayerClient: ObservableObject {
    @Published private(set) var status = "Offline"
    @Published private(set) var roomCode = ""
    @Published private(set) var messages: [String] = []
    @Published private(set) var playerCountHint = 1

    var onRemotePlayerState: ((String, Float, Float) -> Void)?
    var onRemotePlayerLeft: ((String) -> Void)?

    private var socket: URLSessionWebSocketTask?
    private let localPlayerID = UUID().uuidString
    private var lastStateSentAt: TimeInterval = 0

    func connect(serverURL: String, requestedRoom: String, playerName: String) {
        guard let url = URL(string: serverURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss",
              url.host != nil else {
            status = "Invalid WebSocket URL"
            return
        }

        disconnect()
        status = "Connecting…"
        roomCode = ""
        let task = URLSession.shared.webSocketTask(with: url)
        socket = task
        task.resume()

        Task { [weak self] in
            guard let self else { return }
            await self.send(type: "hello", values: [
                "playerId": self.localPlayerID,
                "playerName": String(playerName.prefix(24))
            ])
            try? await Task.sleep(nanoseconds: 120_000_000)
            let code = requestedRoom.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if code.isEmpty {
                await self.send(type: "create_room", values: [:])
            } else {
                await self.send(type: "join_room", values: ["roomCode": code])
            }
            await self.receiveLoop(task)
        }
    }

    func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        status = "Offline"
        roomCode = ""
    }

    func sendPlayerState(x: Float, z: Float) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastStateSentAt >= 0.075 else { return }
        lastStateSentAt = now
        Task { await send(type: "player_state", values: ["x": x, "z": z]) }
    }

    func sendEvidence(id: String, title: String) {
        Task { await send(type: "evidence_collected", values: ["evidenceId": id, "title": title]) }
    }

    func sendChat(_ message: String) {
        let cleaned = String(message.trimmingCharacters(in: .whitespacesAndNewlines).prefix(250))
        guard !cleaned.isEmpty else { return }
        Task { await send(type: "chat_message", values: ["message": cleaned]) }
    }

    private func send(type: String, values: [String: Any]) async {
        guard let activeSocket = socket else { return }
        var payload = values
        payload["type"] = type
        payload["clientPlayerId"] = localPlayerID
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }

        do {
            try await activeSocket.send(.string(text))
        } catch {
            status = "Send failed: \(error.localizedDescription)"
        }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled && socket === task {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleIncomingText(text)
                case .data(let data):
                    handleIncomingText(String(data: data, encoding: .utf8) ?? "")
                @unknown default:
                    appendMessage("Received an unknown server message.")
                }
            } catch {
                if socket === task {
                    status = "Disconnected: \(error.localizedDescription)"
                    socket = nil
                    roomCode = ""
                }
                break
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let type = object["type"] as? String else {
            appendMessage(text)
            return
        }

        switch type {
        case "connected", "welcome":
            status = "Connected"
        case "room_created", "room_joined":
            roomCode = object["roomCode"] as? String ?? roomCode
            appendMessage(roomCode.isEmpty ? "Room ready." : "Room code: \(roomCode)")
        case "player_state":
            guard let id = object["connectionId"] as? String,
                  let x = (object["x"] as? NSNumber)?.floatValue,
                  let z = (object["z"] as? NSNumber)?.floatValue else { return }
            onRemotePlayerState?(id, x, z)
        case "player_left":
            if let id = object["connectionId"] as? String { onRemotePlayerLeft?(id) }
            appendMessage("A detective left the room.")
        case "player_joined":
            appendMessage("A detective joined the room.")
        case "chat_message":
            let name = object["playerName"] as? String ?? "Detective"
            let message = object["message"] as? String ?? ""
            appendMessage("\(name): \(message)")
        case "evidence_collected":
            let title = object["title"] as? String ?? "Evidence"
            appendMessage("Teammate collected: \(title)")
        case "server_error":
            appendMessage("Server: \(object["message"] as? String ?? "Unknown error")")
        default:
            break
        }
    }

    private func appendMessage(_ message: String) {
        messages.append(message)
        if messages.count > 60 { messages.removeFirst(messages.count - 60) }
    }
}
