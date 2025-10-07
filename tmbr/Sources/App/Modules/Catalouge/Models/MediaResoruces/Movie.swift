import Fluent
import Vapor
import Foundation

final class Movie: Model, Content, @unchecked Sendable {
    static let schema = "media_movies"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$movie)
    private var resources: [MediaResource]

    var imdb: MediaResource? {
        resources.first { $0.platform == .imdb }
    }
    
    var rottenTomatoes: MediaResource? {
        resources.first { $0.platform == .rottenTomatoes }
    }

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
}
