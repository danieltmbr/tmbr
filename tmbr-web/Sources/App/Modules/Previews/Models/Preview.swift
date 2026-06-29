import WebCore
import Fluent
import Vapor
import Foundation
import WebAuth
import TmbrCore

final class Preview: Model, @unchecked Sendable {
    static let schema = "previews"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?
    
    /// The integer ID of the backing catalogue model (e.g. Song, Book, Podcast).
    /// Nil for shallow promotable items (track) before promotion, and also for orphan/collection items.
    /// Do NOT use `parentID == nil` as a proxy for "cannot have notes" — use `kind.isShallow` instead,
    /// because orphan and collection items also have a nil parentID yet can have notes.
    @OptionalField(key: "parent_id")
    private(set) var parentID: Int?
    
    @Enum(key: "parent_access")
    private(set) var parentAccess: Access
    
    @Parent(key: "parent_owner")
    private(set) var parentOwner: User
    
    @OptionalParent(key: "category_id")
    var catalogueCategory: CatalogueCategory?

    @Field(key: "primary_info")
    var primaryInfo: String

    @OptionalField(key: "secondary_info")
    var secondaryInfo: String?

    @OptionalParent(key: "image_id")
    var image: Image?

    @Field(key: "external_links")
    var externalLinks: [String]

    @Field(key: "created_at")
    private(set) var createdAt: Date

    @Timestamp(key: "updated_at", on: .update)
    private(set) var updatedAt: Date?

    var ownerID: UserID { $parentOwner.id }

    init() {}

    func adopt(parentID: Int, categoryID: CatalogueCategory.IDValue, parentAccess: Access, parentOwner: UserID) {
        self.parentID = parentID
        self.$catalogueCategory.id = categoryID
        self.parentAccess = parentAccess
        self.$parentOwner.id = parentOwner
    }

    init(
        id: UUID,
        parentID: Int?,
        parentAccess: Access,
        parentOwner: UserID,
        categoryID: CatalogueCategory.IDValue? = nil
    ) {
        self.id = id
        self.parentID = parentID
        self.parentAccess = parentAccess
        self.$parentOwner.id = parentOwner
        self.$catalogueCategory.id = categoryID
        self.createdAt = .now
    }
}

extension Preview: TimestampedModel {
    static var createdAtPath: KeyPath<Preview, FieldProperty<Preview, Date>> { \.$createdAt }
}

