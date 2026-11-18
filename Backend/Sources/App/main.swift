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
            ["status": "ok", "game": "SHADOW FILES", "server": "greywood-multiplayer"]
        }

        app.webSocket("ws") { request, socket in
            let connectionID = UUID().uuidString
            RoomManager.shared.register(socket: socket, connectionID: connectionID)
            socket.sendJSON(["type": "connected", "connectionId": connectionID])

            socket.onText { currentSocket, text in
                guard let data = text.data(using: .utf8),
                      let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                      let type = payload["type"] as? String else {
                    currentSocket.sendJSON(["type": "server_error", "message": "Invalid JSON message"])
                    return
                }

                switch type {
                case "hello":
                    currentSocket.sendJSON(["type": "welcome", "connectionId": connectionID])

                case "create_room":
                    let code = RoomManager.shared.createRoom(for: connectionID)
                    currentSocket.sendJSON(["type": "room_created", "roomCode": code, "capacity": 8])

                case "join_room":
                    let code = (payload["roomCode"] as? String ?? "").uppercased()
                    let result = RoomManager.shared.joinRoom(code: code, connectionID: connectionID)
                    if result.success {
                        currentSocket.sendJSON(["type": "room_joined", "roomCode": code])
                        RoomManager.shared.broadcast(
                            ["type": "player_joined", "connectionId": connectionID],
                            toRoom: code,
                            excluding: connectionID
                        )
                    } else {
                        currentSocket.sendJSON(["type": "server_error", "message": result.error ?? "Could not join room"])
                    }

                case "player_state", "evidence_collected", "chat_message", "mission_update":
                    guard let roomCode = RoomManager.shared.roomCode(for: connectionID) else {
                        currentSocket.sendJSON(["type": "server_error", "message": "Join a room first"])
                        return
                    }
                    var forwarded = payload
                    forwarded["connectionId"] = connectionID
                    RoomManager.shared.broadcast(forwarded, toRoom: roomCode, excluding: connectionID)

                case "ping":
                    currentSocket.sendJSON(["type": "pong", "time": ISO8601DateFormatter().string(from: Date())])

                default:
                    currentSocket.sendJSON(["type": "server_error", "message": "Unsupported message type"])
                }
            }

            socket.onClose.whenComplete { _ in
                let roomCode = RoomManager.shared.roomCode(for: connectionID)
                RoomManager.shared.unregister(connectionID: connectionID)
                if let roomCode {
                    RoomManager.shared.broadcast(
                        ["type": "player_left", "connectionId": connectionID],
                        toRoom: roomCode,
                        excluding: connectionID
                    )
                }
            }
        }

        app.logger.info("SHADOW FILES server listening on port \(app.http.server.configuration.port)")
        try await app.execute()
        try await app.asyncShutdown()
    }
}
