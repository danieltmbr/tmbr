import Fluent
import Vapor
import Foundation

@dynamicMemberLookup
final class Movie: MediaItem, Content, @unchecked Sendable {
    static let schema = "media_movies"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$movie)
    fileprivate var resources: [MediaResource<Movie>]

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
    
    func resource(for platform: MediaPlatform<Movie>) -> MediaResource<Movie>? {
        resources.first { $0.platform == platform }
    }
    
    func upsert(resource: MediaResource<Movie>, on database: any Database) async throws {
        try await $resources.upsert(resource, on: database)
    }
    
    func upsert(resources: [MediaResource<Movie>], on database: any Database) async throws {
        try await $resources.upsert(resources, on: database)
    }
}

extension MediaPlatform where ContentType == Movie {
    
    static let imdb: Self = "imdb"
    
    static let rottenTomatoes: Self = "rotten-tomatoes"
    
    static let youtube: Self = "youtube"
}

extension Set where Element == MediaPlatform<Movie> {
    static var movie: Set<MediaPlatform<Movie>> {
        [.imdb, .rottenTomatoes, .youtube]
    }
}

extension OptionalChildProperty where From == Media, To == Movie {
    func load(on database: any Database, eager: Bool) async throws {
        try await load(on: database).get()
        guard eager else { return }
        try await wrappedValue?.$resources.load(on: database)
    }
}
