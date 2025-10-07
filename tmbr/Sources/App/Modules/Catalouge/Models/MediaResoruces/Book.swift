import Fluent
import Vapor
import Foundation

final class Book: Model, Content, @unchecked Sendable {
    static let schema = "media_books"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$book)
    private var resources: [MediaResource]
    
    var goodreads: MediaResource? {
        resources.first { $0.platform == .goodreads }
    }

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
}
