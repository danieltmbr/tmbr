import Vapor
import Fluent
import Foundation

struct PreviewResponse: Content, Sendable {

    struct Source: Content, Sendable {
        private let id: Int

        private let type: String
        
        init(id: Int, type: String) {
            self.id = id
            self.type = type
        }
    }
    
    private let primaryInfo: String
    
    private let secondaryInfo: String?
    
    private let image: ImageResponse?
    
    private let resources: [String]
    
    private let source: Source
    
    init(preview: Preview, baseURL: String) {
        self.primaryInfo = preview.primaryInfo
        self.secondaryInfo = preview.secondaryInfo
        self.image = preview.image.map { image in
            ImageResponse(
                id: image.id,
                alt: image.alt,
                // TODO: Align image URL assembly across project
                // https://github.com/danieltmbr/tmbr/issues/56
                url: baseURL + "/gallery/data/\(image.thumbnailKey)",
                thumbnailUrl: baseURL + "/gallery/data/\(image.thumbnailKey)",
                size: CGSize(width: image.size.width, height: image.size.height),
                uploadedAt: image.uploadedAt ?? .now
            )
        }
        self.resources = preview.externalLinks
        self.source = Source(
            id: preview.parentID,
            type: preview.parentType
        )
    }
}
