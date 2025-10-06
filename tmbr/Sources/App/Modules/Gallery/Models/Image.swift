import Fluent
import Vapor
import Foundation

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
    
    @Field(key: "name")
    private(set) var name: String
    
    @Field(key: "thumbnail")
    private(set) var thumbnail: String
    
    @Group(key: "size")
    private(set) var size: Size
    
    @Timestamp(key: "uploaded_at", on: .create)
    private(set) var uploadedAt: Date?
    
    init() {}

    convenience init(
        id: Int? = nil,
        alt: String?,
        name: String,
        thumbnail: String,
        width: Int,
        height: Int,
        uploadedAt: Date? = nil
    ) {
        self.init(
            id: id,
            alt: alt,
            name: name,
            thumbnail: thumbnail,
            size: CGSize(width: width, height: height)
        )
    }
    
    init(
        id: Int? = nil,
        alt: String?,
        name: String,
        thumbnail: String,
        size: CGSize,
        uploadedAt: Date? = nil
    ) {
        self.id = id
        self.alt = alt
        self.name = name
        self.thumbnail = thumbnail
        self.size = Size(width: Int(size.width), height: Int(size.height))
        self.uploadedAt = uploadedAt
    }
}
