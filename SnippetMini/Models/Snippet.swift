import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var sortOrder: Int
    /// 複数Mac間の統合で「どちらが新しいか」を決める基準。
    var updatedAt: Date
    /// 削除の墓標。nil でなければ削除済み。
    /// 物理削除にすると、他のMacが持つ古いレコードとの統合で削除済みが復活してしまう。
    var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        sortOrder: Int = 0,
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // updatedAt / deletedAt を持たない旧フォーマットの JSON も読めるようにする。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}
