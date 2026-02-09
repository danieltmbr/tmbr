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
    
    init(
        primaryInfo: String,
        secondaryInfo: String?,
        image: ImageResponse?,
        resources: [String],
        source: Source
    ) {
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.image = image
        self.resources = resources
        self.source = source
    }
    
    init(preview: Preview, baseURL: String) {
        self.init(
            primaryInfo: preview.primaryInfo,
            secondaryInfo: preview.secondaryInfo,
            image: preview.image.map { image in
                ImageResponse(image: image, baseURL: baseURL)
            },
            resources: preview.externalLinks,
            source: Source(
                id: preview.parentID,
                type: preview.parentType
            )
        )
    }
}
