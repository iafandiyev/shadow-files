import Foundation
import Vapor

final class RoomManager {
    static let shared = RoomManager()

    private let lock = NSLock()
    private var sockets: [String: WebSocket] = [:]
    private var rooms: [String: Set<String>] = [:]
    private var playerRooms: [String: String] = [:]
    private var positions: [String: (x: Double, z: Double)] = [:]
    private var playerNames: [String: String] = [:]

    private init() {}

    static func makeRoomCode() -> String {
        String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
    }

    func register(socket: WebSocket, connectionID: String) {
        lock.lock()
        sockets[connectionID] = socket
        lock.unlock()
    }

    func setPlayerName(_ name: String, connectionID: String) {
        lock.lock()
        playerNames[connectionID] = String(name.prefix(24))
        lock.unlock()
    }

    func createRoom(for connectionID: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        detachFromCurrentRoomLocked(connectionID)

        var code = Self.makeRoomCode()
        while rooms[code] != nil { code = Self.makeRoomCode() }
        rooms[code] = [connectionID]
        playerRooms[connectionID] = code
        return code
    }

    func joinRoom(code: String, connectionID: String) -> (success: Bool, error: String?) {
        lock.lock()
        defer { lock.unlock() }

        guard var members = rooms[code] else { return (false, "Room not found") }
        if members.contains(connectionID) { return (true, nil) }
        guard members.count < 8 else { return (false, "Room is full (maximum 8 players)") }

        detachFromCurrentRoomLocked(connectionID)
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

    func updatePosition(connectionID: String, x: Double, z: Double) -> (x: Double, z: Double)? {
        guard x.isFinite, z.isFinite else { return nil }
        lock.lock()
        defer { lock.unlock() }
        guard playerRooms[connectionID] != nil else { return nil }
        let safe = (x: max(-34, min(34, x)), z: max(-34, min(34, z)))
        positions[connectionID] = safe
        return safe
    }

    func existingPlayerStates(for connectionID: String) -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        guard let room = playerRooms[connectionID] else { return [] }
        return (rooms[room] ?? []).filter { $0 != connectionID }.compactMap { id in
            guard let point = positions[id] else { return nil }
            return ["type": "player_state", "connectionId": id, "x": point.x, "z": point.z]
        }
    }

    func broadcast(_ payload: [String: Any], toRoom code: String, excluding excludedID: String? = nil) {
        lock.lock()
        let recipients = (rooms[code] ?? []).filter { $0 != excludedID }.compactMap { sockets[$0] }
        lock.unlock()
        recipients.forEach { $0.sendJSON(payload) }
    }

    func playerName(for connectionID: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        return playerNames[connectionID] ?? "Detective"
    }

    @discardableResult
    func unregister(connectionID: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        let oldRoom = playerRooms[connectionID]
        detachFromCurrentRoomLocked(connectionID)
        sockets.removeValue(forKey: connectionID)
        positions.removeValue(forKey: connectionID)
        playerNames.removeValue(forKey: connectionID)
        return oldRoom
    }

    private func detachFromCurrentRoomLocked(_ connectionID: String) {
        guard let oldRoom = playerRooms.removeValue(forKey: connectionID) else { return }
        rooms[oldRoom]?.remove(connectionID)
        if rooms[oldRoom]?.isEmpty == true { rooms.removeValue(forKey: oldRoom) }
    }
}

extension WebSocket {
    func sendJSON(_ object: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return }
        send(text)
    }
}
