import Fluent
import Vapor
import Foundation

final class Podcast: Model, Content, @unchecked Sendable {
    static let schema = "media_podcasts"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$podcast)
    private var resources: [MediaResource]

    var applePodcasts: MediaResource? {
        resources.first { $0.platform == .appleMusic }
    }
    
    var spotify: MediaResource? {
        resources.first { $0.platform == .spotify }
    }

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
}
