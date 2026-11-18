import Foundation

struct Evidence: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var category: String
    var detail: String
    var collectedAt: Date

    init(id: UUID = UUID(), title: String, category: String, detail: String, collectedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.category = category
        self.detail = detail
        self.collectedAt = collectedAt
    }
}
