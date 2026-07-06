import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var sortOrder: Int

    init(id: UUID = UUID(), title: String, body: String, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.body = body
        self.sortOrder = sortOrder
    }
}
