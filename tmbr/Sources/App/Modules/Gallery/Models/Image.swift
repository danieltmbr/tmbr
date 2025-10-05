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
    static let schema = "images"
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @OptionalField(key: "alt")
    var alt: String?
    
    @Field(key: "path")
    private(set) var path: String
    
    @Field(key: "thumbnail_path")
    private(set) var thumbnailPath: String
    
    @Group(key: "size")
    private(set) var size: Size
    
    @Timestamp(key: "uploaded_at", on: .create)
    private(set) var uploadedAt: Date?
    
    init() {}

    convenience init(
        id: Int? = nil,
        alt: String?,
        path: String,
        thumbnailPath: String,
        width: Int,
        height: Int,
        uploadedAt: Date? = nil
    ) {
        self.init(
            id: id,
            alt: alt,
            path: path,
            thumbnailPath: thumbnailPath,
            size: CGSize(width: width, height: height)
        )
    }
    
    init(
        id: Int? = nil,
        alt: String?,
        path: String,
        thumbnailPath: String,
        size: CGSize,
        uploadedAt: Date? = nil
    ) {
        self.id = id
        self.alt = alt
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.size = Size(width: Int(size.width), height: Int(size.height))
        self.uploadedAt = uploadedAt
    }
}
