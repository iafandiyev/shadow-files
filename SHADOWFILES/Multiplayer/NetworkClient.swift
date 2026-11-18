import Foundation
import Combine

@MainActor
final class NetworkClient: ObservableObject {
    @Published private(set) var status = "Offline"
    @Published private(set) var lastMessage = ""
    @Published private(set) var assignedRoomCode = ""

    var onRemotePlayerState: ((String, Float, Float) -> Void)?
    var onRemotePlayerLeft: ((String) -> Void)?

    private var socket: URLSessionWebSocketTask?
    private let playerID = UUID().uuidString
    private var lastStateSentAt: TimeInterval = 0

    func connect(address: String, roomCode: String, playerName: String) {
        guard let url = URL(string: address),
              let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss" else {
            status = "Invalid WebSocket URL"
            return
        }

        disconnect()
        status = "Connecting..."
        let newSocket = URLSession.shared.webSocketTask(with: url)
        socket = newSocket
        newSocket.resume()
        send(type: "hello", values: ["playerId": playerID, "playerName": playerName])

        if !roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            send(type: "join_room", values: ["roomCode": roomCode])
        } else {
            send(type: "create_room", values: [:])
        }

        receiveNextMessage(from: newSocket)
    }

    func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        status = "Offline"
    }

    func sendPlayerState(x: Float, z: Float) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastStateSentAt >= 0.06 else { return }
        lastStateSentAt = now
        send(type: "player_state", values: ["x": x, "z": z])
    }

    func sendEvidence(id: String, title: String) {
        send(type: "evidence_collected", values: ["evidenceId": id, "title": title])
    }

    func sendChat(_ message: String) {
        send(type: "chat_message", values: ["message": message])
    }

    private func send(type: String, values: [String: Any]) {
        guard let socket else { return }
        var payload = values
        payload["type"] = type
        payload["playerId"] = playerID

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }

        Task {
            do {
                try await socket.send(.string(text))
            } catch {
                status = "Send failed: \(error.localizedDescription)"
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let type = object["type"] as? String else {
            lastMessage = text
            return
        }

        switch type {
        case "connected", "welcome":
            status = "Connected"
            lastMessage = "Connected to Greywood server"
        case "room_created", "room_joined":
            assignedRoomCode = object["roomCode"] as? String ?? assignedRoomCode
            lastMessage = assignedRoomCode.isEmpty ? type : "Room code: \(assignedRoomCode)"
        case "player_state":
            guard let id = object["connectionId"] as? String,
                  let x = (object["x"] as? NSNumber)?.floatValue,
                  let z = (object["z"] as? NSNumber)?.floatValue else { return }
            onRemotePlayerState?(id, x, z)
            lastMessage = "Remote detective updated"
        case "player_left":
            if let id = object["connectionId"] as? String {
                onRemotePlayerLeft?(id)
            }
            lastMessage = "A detective left the room"
        case "player_joined":
            lastMessage = "A detective joined the room"
        case "server_error":
            lastMessage = object["message"] as? String ?? "Server error"
        default:
            lastMessage = text
        }
    }

    private func receiveNextMessage(from task: URLSessionWebSocketTask) {
        Task {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleIncomingText(text)
                case .data(let data):
                    handleIncomingText(String(data: data, encoding: .utf8) ?? "")
                @unknown default:
                    lastMessage = "Received unknown message"
                }
                receiveNextMessage(from: task)
            } catch {
                status = "Disconnected: \(error.localizedDescription)"
                socket = nil
            }
        }
    }
}
