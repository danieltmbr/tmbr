import Fluent
import Vapor
import Foundation

typealias PreviewID = UUID

final class Preview: Model, @unchecked Sendable {
    static let schema = "previews"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?
    
    @Field(key: "parent_id")
    var parentID: Int
    
    @Field(key: "parent_type")
    var parentType: String

    @Field(key: "primary_info")
    var primaryInfo: String

    @OptionalField(key: "secondary_info")
    var secondaryInfo: String?

    @OptionalParent(key: "image_id")
    var image: Image?

    @Field(key: "links")
    var links: [String]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID,
        parentID: Int,
        parentType: String,
        primaryInfo: String,
        secondaryInfo: String? = nil,
        imageID: ImageID? = nil,
        links: [String] = []
    ) {
        self.id = id
        self.parentID = parentID
        self.parentType = parentType
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.$image.id = imageID
        self.links = links
    }
}

