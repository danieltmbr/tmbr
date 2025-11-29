import Fluent
import Vapor
import Foundation
import AuthKit

final class Book: Model, @unchecked Sendable {
    
    static let schema = "books"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "artist")
    var author: String
    
    @Children(for: \.$book)
    private var bookNotes: [BookNote]
    
    @OptionalParent(key: "cover_id")
    var cover: Image?

    @Field(key: "genre")
    var genre: String
    
    @Parent(key: "owner_id")
    var owner: User
    
    @OptionalParent(key: "preview_id")
    var preview: Preview?
    
    @Field(key: "release_date")
    var releaseDate: Date

    @Field(key: "title")
    var title: String
    
    var notes: [Note] {
        bookNotes.map { $0.$note.wrappedValue }
    }
    
//    func resource(for platform: MediaPlatform<Book>) -> MediaResource<Book>? {
//        resources.first { $0.platform == platform }
//    }
//    
//    func upsert(resource: MediaResource<Book>, on database: any Database) async throws {
//        try await $resources.upsert(resource, on: database)
//    }
//    
//    func upsert(resources: [MediaResource<Book>], on database: any Database) async throws {
//        try await $resources.upsert(resources, on: database)
//    }
}

//extension MediaPlatform where ContentType == Book {
//    
//    static let goodreads: Self = "goodreads"
//}
//
//extension Set where Element == MediaPlatform<Book> {
//    static var book: Set<MediaPlatform<Book>> {
//        [.goodreads]
//    }
//}
//
//extension OptionalChildProperty where From == Media, To == Book {
//    func load(on database: any Database, eager: Bool) async throws {
//        try await load(on: database).get()
//        guard eager else { return }
//        try await wrappedValue?.$resources.load(on: database)
//    }
//}
