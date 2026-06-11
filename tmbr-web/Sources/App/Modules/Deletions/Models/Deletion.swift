import Foundation
import Fluent
import TmbrCore

final class Deletion: Model, @unchecked Sendable {

    static let schema = "deletions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "type")
    var type: String

    @Field(key: "item_id")
    var itemID: String

    @Field(key: "deleted_at")
    var deletedAt: Date

    init() {}

    init(type: DeletionType, itemID: String) {
        self.type = type.rawValue
        self.itemID = itemID
        self.deletedAt = .now
    }
}
