import Fluent
import Vapor
import Foundation
import AuthKit

typealias ImageID = Image.IDValue

final class Size: Fields, @unchecked Sendable, Codable {

    @Field(key: "width")
    private(set) var width: Int
    
    @Field(key: "height")
    private(set) var height: Int
    
    init() {
        self.width = 0
        self.height = 0
    }

    init(
        width: Int,
        height: Int
    ) {
        self.width = width
        self.height = height
    }
}

final class Image: Model, Content, @unchecked Sendable {
    static let schema = "gallery"
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @OptionalField(key: "alt")
    var alt: String?
    
    @Field(key: "key")
    private(set) var key: String
    
    @Field(key: "thumbnail_key")
    private(set) var thumbnailKey: String
    
    @Group(key: "size")
    private(set) var size: Size
    
    @Parent(key: "owner_id")
    private(set) var owner: User
    
    @Timestamp(key: "uploaded_at", on: .create)
    private(set) var uploadedAt: Date?
    
    init() {}

    convenience init(
        id: Int? = nil,
        alt: String?,
        key: String,
        thumbnailKey: String,
        width: Int,
        height: Int,
        ownerID: UserID,
        uploadedAt: Date? = nil
    ) {
        self.init(
            id: id,
            alt: alt,
            key: key,
            thumbnailKey: thumbnailKey,
            size: CGSize(width: width, height: height),
            ownerID: ownerID
        )
    }
    
    init(
        id: Int? = nil,
        alt: String?,
        key: String,
        thumbnailKey: String,
        size: CGSize,
        ownerID: UserID,
        uploadedAt: Date? = nil
    ) {
        self.id = id
        self.alt = alt
        self.key = key
        self.thumbnailKey = thumbnailKey
        self.size = Size(width: Int(size.width), height: Int(size.height))
        self.$owner.id = ownerID
        self.uploadedAt = uploadedAt
    }
}
