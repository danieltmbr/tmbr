import Fluent
import Vapor
import Foundation
import AuthKit

final class Movie: Model, @unchecked Sendable {
    
    static let schema = "movies"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @OptionalParent(key: "cover_id")
    var cover: Image?
    
    @Field(key: "director")
    var director: String?
    
    @Field(key: "genre")
    var genre: String?
    
    @Children(for: \.$movie)
    private var movieNotes: [MovieNote]
    
    @Parent(key: "owner_id")
    var owner: User
    
    @OptionalParent(key: "preview_id")
    var preview: Preview?
    
    @Field(key: "release_date")
    var releaseDate: Date?

    @Field(key: "title")
    var title: String
    
    var notes: [Note] {
        movieNotes.map { $0.$note.wrappedValue }
    }
    
//    func resource(for platform: MediaPlatform<Movie>) -> MediaResource<Movie>? {
//        resources.first { $0.platform == platform }
//    }
//    
//    func upsert(resource: MediaResource<Movie>, on database: any Database) async throws {
//        try await $resources.upsert(resource, on: database)
//    }
//    
//    func upsert(resources: [MediaResource<Movie>], on database: any Database) async throws {
//        try await $resources.upsert(resources, on: database)
//    }
}

//extension MediaPlatform where ContentType == Movie {
//    
//    static let imdb: Self = "imdb"
//    
//    static let rottenTomatoes: Self = "rotten-tomatoes"
//    
//    static let youtube: Self = "youtube"
//}
//
//extension Set where Element == MediaPlatform<Movie> {
//    static var movie: Set<MediaPlatform<Movie>> {
//        [.imdb, .rottenTomatoes, .youtube]
//    }
//}
//
//extension OptionalChildProperty where From == Media, To == Movie {
//    func load(on database: any Database, eager: Bool) async throws {
//        try await load(on: database).get()
//        guard eager else { return }
//        try await wrappedValue?.$resources.load(on: database)
//    }
//}
