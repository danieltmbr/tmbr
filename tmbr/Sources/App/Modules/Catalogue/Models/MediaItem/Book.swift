import Fluent
import Vapor
import Foundation

@dynamicMemberLookup
final class Book: MediaItem, Content, @unchecked Sendable {
    static let schema = "media_books"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$book)
    fileprivate var resources: [MediaResource<Book>]

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
    
    func resource(for platform: MediaPlatform<Book>) -> MediaResource<Book>? {
        resources.first { $0.platform == platform }
    }
    
    func upsert(resource: MediaResource<Book>, on database: any Database) async throws {
        try await $resources.upsert(resource, on: database)
    }
    
    func upsert(resources: [MediaResource<Book>], on database: any Database) async throws {
        try await $resources.upsert(resources, on: database)
    }
}

extension MediaPlatform where ContentType == Book {
    
    static let goodreads: Self = "goodreads"
}

extension Set where Element == MediaPlatform<Book> {
    static var book: Set<MediaPlatform<Book>> {
        [.goodreads]
    }
}

extension OptionalChildProperty where From == Media, To == Book {
    func load(on database: any Database, eager: Bool) async throws {
        try await load(on: database).get()
        guard eager else { return }
        try await wrappedValue?.$resources.load(on: database)
    }
}
