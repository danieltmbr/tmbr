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

    @Field(key: "owner_id")
    var ownerID: Int

    @Field(key: "access")
    var access: String

    @Field(key: "deleted_at")
    var deletedAt: Date

    init() {}

    init(type: DeletionType, itemID: String, ownerID: Int, access: Access) {
        self.type = type.rawValue
        self.itemID = itemID
        self.ownerID = ownerID
        self.access = access.rawValue
        self.deletedAt = .now
    }
}
