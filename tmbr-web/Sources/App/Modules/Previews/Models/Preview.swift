import Fluent
import Vapor
import Foundation
import AuthKit
import TmbrCore

final class Preview: Model, @unchecked Sendable {
    static let schema = "previews"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?
    
    @OptionalField(key: "parent_id")
    private(set) var parentID: Int?
    
    @Enum(key: "parent_access")
    private(set) var parentAccess: Access
    
    @Parent(key: "parent_owner")
    private(set) var parentOwner: User
    
    @OptionalField(key: "parent_type")
    private(set) var parentType: String?

    @OptionalField(key: "category")
    private(set) var category: String?

    @Field(key: "primary_info")
    var primaryInfo: String

    @OptionalField(key: "secondary_info")
    var secondaryInfo: String?

    @OptionalParent(key: "image_id")
    var image: Image?

    @Field(key: "external_links")
    var externalLinks: [String]

    @Timestamp(key: "created_at", on: .create)
    private(set) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    private(set) var updatedAt: Date?

    var ownerID: UserID { $parentOwner.id }

    init() {}

    func adopt(parentID: Int, parentType: String, parentAccess: Access, parentOwner: UserID) {
        self.parentID = parentID
        self.parentType = parentType
        self.parentAccess = parentAccess
        self.$parentOwner.id = parentOwner
    }

    init(
        id: UUID,
        parentID: Int?,
        parentAccess: Access,
        parentOwner: UserID,
        parentType: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.parentID = parentID
        self.parentAccess = parentAccess
        self.$parentOwner.id = parentOwner
        self.parentType = parentType
        self.category = category
    }
}

