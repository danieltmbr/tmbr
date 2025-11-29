import Vapor
import Fluent
import Foundation

struct PreviewResponse: Content, Sendable {
    // TODO: add href and api endpoint links
    struct Source: Content, Sendable {
        let id: Int

        let type: String
    }
    
    let title: String
    
    let subtitle: String?
    
    let image: ImageResponse?
    
    let links: [String]
    
    let source: Source
    
    init(preview: Preview, image) {
        self.title = preview.primaryInfo
        self.subtitle = preview.secondaryInfo
        self.image = preview.image.map { image in
            ImageResponse(id: <#T##Int?#>, alt: <#T##String?#>, url: <#T##String#>, thumbnailUrl: <#T##String#>, size: <#T##CGSize#>, uploadedAt: <#T##Date#>)
        }
        self.links = preview.links
        self.source = Source(
            id: preview.parentID,
            type: preview.parentType
        )
    }
}
