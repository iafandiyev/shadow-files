import Foundation

/// Lightweight local JSON persistence for the first playable build.
/// A production release can replace this with SQLite without changing game models.
enum SaveManager {
    private static let fileName = "shadow-files-save.json"

    private static var saveURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    static func save<T: Encodable>(_ value: T) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: saveURL, options: .atomic)
    }

    static func load<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try Data(contentsOf: saveURL)
        return try JSONDecoder().decode(type, from: data)
    }
}
