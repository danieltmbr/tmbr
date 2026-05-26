import Foundation
import TmbrCore
import CoreGraphics

extension ImageResponse {

    init(image: Image, baseURL: String) {
        self.init(
            id: image.id,
            alt: image.alt,
            url: baseURL + "/gallery/data/\(image.key)",
            thumbnailUrl: baseURL + "/gallery/data/\(image.thumbnailKey)",
            size: CGSize(width: image.size.width, height: image.size.height),
            uploadedAt: image.uploadedAt ?? .now
        )
    }
}
