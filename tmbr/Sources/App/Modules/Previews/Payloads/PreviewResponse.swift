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
    
    let imageURL: String?
    
    let links: [String]
    
    let source: Source
    
    init(preview: Preview) {
        self.title = preview.primaryInfo
        self.subtitle = preview.secondaryInfo
        self.imageURL = preview.imageURL
        self.links = preview.links
        self.source = Source(
            id: preview.ownerID,
            type: preview.ownerType
        )
    }
}
