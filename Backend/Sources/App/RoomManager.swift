import Foundation
import Vapor

final class RoomManager {
    static let shared = RoomManager()

    private let lock = NSLock()
    private var sockets: [String: WebSocket] = [:]
    private var rooms: [String: Set<String>] = [:]
    private var playerRooms: [String: String] = [:]

    private init() {}

    func register(socket: WebSocket, connectionID: String) {
        lock.lock()
        sockets[connectionID] = socket
        lock.unlock()
    }

    func createRoom(for connectionID: String) -> String {
        lock.lock()
        defer { lock.unlock() }

        if let oldRoom = playerRooms[connectionID] {
            rooms[oldRoom]?.remove(connectionID)
        }

        let code = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
        rooms[code] = [connectionID]
        playerRooms[connectionID] = code
        return code
    }

    func joinRoom(code: String, connectionID: String) -> (success: Bool, error: String?) {
        lock.lock()
        defer { lock.unlock() }

        guard var members = rooms[code] else {
            return (false, "Room not found")
        }
        guard members.count < 8 else {
            return (false, "Room is full")
        }

        if let oldRoom = playerRooms[connectionID] {
            rooms[oldRoom]?.remove(connectionID)
        }
        members.insert(connectionID)
        rooms[code] = members
        playerRooms[connectionID] = code
        return (true, nil)
    }

    func roomCode(for connectionID: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return playerRooms[connectionID]
    }

    func broadcast(_ payload: [String: Any], toRoom code: String, excluding excludedID: String? = nil) {
        lock.lock()
        let recipients = (rooms[code] ?? []).filter { $0 != excludedID }.compactMap { sockets[$0] }
        lock.unlock()

        recipients.forEach { $0.sendJSON(payload) }
    }

    func unregister(connectionID: String) {
        lock.lock()
        sockets.removeValue(forKey: connectionID)
        if let room = playerRooms.removeValue(forKey: connectionID) {
            rooms[room]?.remove(connectionID)
            if rooms[room]?.isEmpty == true {
                rooms.removeValue(forKey: room)
            }
        }
        lock.unlock()
    }
}

extension WebSocket {
    func sendJSON(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return }
        send(text)
    }
}
