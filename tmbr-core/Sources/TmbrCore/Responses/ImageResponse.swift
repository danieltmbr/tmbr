import Foundation
import CoreGraphics

public struct ImageResponse: Codable, Sendable {

    public let id: ImageID?

    public let alt: String?

    public let url: String

    public let thumbnailUrl: String

    public let size: CGSize

    public let uploadedAt: Date

    public init(
        id: ImageID?,
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
