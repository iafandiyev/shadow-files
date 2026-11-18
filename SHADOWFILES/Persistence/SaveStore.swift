import Foundation

enum SaveStore {
    private static let fileName = "shadow-files-v1-save.json"

    private static var fileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent(fileName)
    }

    static func load() -> GameSave {
        guard let data = try? Data(contentsOf: fileURL),
              let save = try? JSONDecoder().decode(GameSave.self, from: data) else {
            return GameSave()
        }
        return save
    }

    static func write(_ save: GameSave) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
