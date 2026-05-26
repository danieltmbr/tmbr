import Vapor

struct MediaContentType: Hashable {
    let httpType: HTTPMediaType
    
    let fileExtension: String
    
    var contentType: String {
        httpType.serialize()
    }
    
    static let png = Self(httpType: .png, fileExtension: "png")
    
    static let jpeg = Self(httpType: .jpeg, fileExtension: "jpg")
    
    static let webp = Self(
        httpType: HTTPMediaType(type: "image", subType: "webp"),
        fileExtension: "webp"
    )
    
    static let gif = Self(httpType: .gif, fileExtension: "gif")
    
    static let svg = Self(
        httpType: HTTPMediaType(type: "image", subType: "svg+xml"),
        fileExtension: "svg"
    )
}
