import Foundation
import Vapor

@main
enum ShadowFilesServer {
    static func main() async throws {
        var environment = try Environment.detect()
        try LoggingSystem.bootstrap(from: &environment)

        let app = Application(environment)
        app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"
        app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

        app.get("health") { request async -> [String: String] in
            ["status": "ok", "game": "SHADOW FILES", "server": "greywood-room-server", "version": "1.0.0"]
        }

        app.webSocket("ws") { request, socket in
            let connectionID = UUID().uuidString
            RoomManager.shared.register(socket: socket, connectionID: connectionID)
            socket.sendJSON(["type": "connected", "connectionId": connectionID])

            socket.onText { currentSocket, text in
                guard text.utf8.count <= 4096,
                      let data = text.data(using: .utf8),
                      let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                      let type = payload["type"] as? String else {
                    currentSocket.sendJSON(["type": "server_error", "message": "Invalid or oversized JSON message"])
                    return
                }

                switch type {
                case "hello":
                    let name = (payload["playerName"] as? String ?? "Detective").trimmingCharacters(in: .whitespacesAndNewlines)
                    RoomManager.shared.setPlayerName(name.isEmpty ? "Detective" : name, connectionID: connectionID)
                    currentSocket.sendJSON(["type": "welcome", "connectionId": connectionID])

                case "create_room":
                    let code = RoomManager.shared.createRoom(for: connectionID)
                    currentSocket.sendJSON(["type": "room_created", "roomCode": code, "capacity": 8])

                case "join_room":
                    let rawCode = (payload["roomCode"] as? String ?? "").uppercased()
                    let code = String(rawCode.filter { $0.isLetter || $0.isNumber }.prefix(6))
                    guard code.count == 6 else {
                        currentSocket.sendJSON(["type": "server_error", "message": "Room code must contain 6 letters or digits"])
                        return
                    }
                    let result = RoomManager.shared.joinRoom(code: code, connectionID: connectionID)
                    if result.success {
                        currentSocket.sendJSON(["type": "room_joined", "roomCode": code])
                        for state in RoomManager.shared.existingPlayerStates(for: connectionID) {
                            currentSocket.sendJSON(state)
                        }
                        RoomManager.shared.broadcast(
                            ["type": "player_joined", "connectionId": connectionID],
                            toRoom: code,
                            excluding: connectionID
                        )
                    } else {
                        currentSocket.sendJSON(["type": "server_error", "message": result.error ?? "Could not join room"])
                    }

                case "player_state":
                    guard let x = (payload["x"] as? NSNumber)?.doubleValue,
                          let z = (payload["z"] as? NSNumber)?.doubleValue,
                          let point = RoomManager.shared.updatePosition(connectionID: connectionID, x: x, z: z),
                          let room = RoomManager.shared.roomCode(for: connectionID) else {
                        currentSocket.sendJSON(["type": "server_error", "message": "Join a room and send valid coordinates first"])
                        return
                    }
                    RoomManager.shared.broadcast(
                        ["type": "player_state", "connectionId": connectionID, "x": point.x, "z": point.z],
                        toRoom: room,
                        excluding: connectionID
                    )

                case "chat_message":
                    guard let room = RoomManager.shared.roomCode(for: connectionID) else {
                        currentSocket.sendJSON(["type": "server_error", "message": "Join a room before chatting"])
                        return
                    }
                    let message = (payload["message"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !message.isEmpty, message.count <= 250 else {
                        currentSocket.sendJSON(["type": "server_error", "message": "Chat message must be 1–250 characters"])
                        return
                    }
                    RoomManager.shared.broadcast(
                        ["type": "chat_message", "connectionId": connectionID,
                         "playerName": RoomManager.shared.playerName(for: connectionID), "message": message],
                        toRoom: room
                    )

                case "evidence_collected":
                    guard let room = RoomManager.shared.roomCode(for: connectionID) else { return }
                    let title = String((payload["title"] as? String ?? "Evidence").prefix(80))
                    let evidenceID = String((payload["evidenceId"] as? String ?? "").prefix(80))
                    RoomManager.shared.broadcast(
                        ["type": "evidence_collected", "connectionId": connectionID,
                         "evidenceId": evidenceID, "title": title],
                        toRoom: room,
                        excluding: connectionID
                    )

                case "ping":
                    currentSocket.sendJSON(["type": "pong", "time": ISO8601DateFormatter().string(from: Date())])

                default:
                    currentSocket.sendJSON(["type": "server_error", "message": "Unsupported message type"])
                }
            }

            socket.onClose.whenComplete { _ in
                if let room = RoomManager.shared.unregister(connectionID: connectionID) {
                    RoomManager.shared.broadcast(
                        ["type": "player_left", "connectionId": connectionID],
                        toRoom: room
                    )
                }
            }
        }

        app.logger.info("SHADOW FILES v1.0 room server listening on port \(app.http.server.configuration.port)")
        try await app.execute()
        try await app.asyncShutdown()
    }
}
