import Foundation
import CoreTmbr

extension ImageResponse {

    init(image: Image, baseURL: String) {
        self.init(
            id: image.id,
            alt: image.alt,
            url: baseURL + "/gallery/data/\(image.key)",
            thumbnailUrl: baseURL + "/gallery/data/\(image.thumbnailKey)",
            size: ImageSize(width: Double(image.size.width), height: Double(image.size.height)),
            uploadedAt: image.uploadedAt ?? .now
        )
    }
}
