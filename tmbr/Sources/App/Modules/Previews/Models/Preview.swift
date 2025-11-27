import Fluent
import Vapor
import Foundation

final class Preview: Model, @unchecked Sendable {
    static let schema = "previews"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "owner_id")
    var ownerID: Int
    
    @Field(key: "owner_type")
    var ownerType: String

    @Field(key: "primary_info")
    var primaryInfo: String

    @OptionalField(key: "secondary_info")
    var secondaryInfo: String?

    @OptionalField(key: "image_url")
    var imageURL: String?

    @Field(key: "links")
    var links: [String]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        ownerID: Int,
        ownerType: String,
        primaryInfo: String,
        secondaryInfo: String? = nil,
        imageURL: String? = nil,
        links: [String] = []
    ) {
        self.ownerID = ownerID
        self.ownerType = ownerType
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.imageURL = imageURL
        self.links = links
    }
}
