import Vapor

struct ImageResponse: Content {
    
    private let id: Int?
    
    private let alt: String?
    
    private let url: String
    
    private let thumbnailUrl: String
    
    private let size: CGSize
    
    private let uploadedAt: Date
    
    init(
        id: Int?,
        alt: String?,
        url: String,
        thumbnailUrl: String,
        size: CGSize,
        uploadedAt: Date
    ) {
        self.id = id
        self.alt = alt
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.size = size
        self.uploadedAt = uploadedAt
    }
}
