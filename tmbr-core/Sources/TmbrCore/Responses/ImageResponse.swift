import Foundation

public struct ImageSize: Codable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct ImageResponse: Codable, Sendable {

    public let id: ImageID?

    public let alt: String?

    public let url: String

    public let thumbnailUrl: String

    public let size: ImageSize

    public let uploadedAt: Date

    public init(
        id: ImageID?,
        alt: String?,
        url: String,
        thumbnailUrl: String,
        size: ImageSize,
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
