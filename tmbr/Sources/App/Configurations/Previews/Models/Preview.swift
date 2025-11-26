import Vapor
import Fluent
import Foundation

public struct Preview: Encodable, Sendable {
    // TODO: add href and api endpoint links
    public struct Source: Encodable, Sendable {
        public let id: Int

        public let type: String
    }
    
    public let title: String
    
    public let subtitle: String?
    
    public let imageURL: String?
    
    public let links: [String]
    
    public let source: Source
    
    public init(
        id: Int,
        type: String,
        title: String,
        subtitle: String? = nil,
        imageURL: String? = nil,
        links: [String] = []
    ) {
        self.source = Source(id: id, type: type)
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.links = links
    }
}
