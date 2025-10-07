import Fluent
import Vapor
import Foundation

final class Music: Model, Content, @unchecked Sendable {
    static let schema = "media_music"
    
    enum Entity: String, Codable {
        case song
        case playlist
        case album
    }

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    
    @OptionalField(key: "entity")
    var entity: Entity?

    @Children(for: \.$music)
    private var resources: [MediaResource]

    var appleMusic: MediaResource? {
        resources.first { $0.platform == .appleMusic }
    }

    var spotify: MediaResource? {
        resources.first { $0.platform == .spotify }
    }

    init() {}

    init(mediaID: Int, entity: Entity? = nil) {
        self.$media.id = mediaID
        self.entity = entity
    }
}
