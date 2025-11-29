import Fluent
import Vapor
import Foundation
import AuthKit

final class Podcast: Model, @unchecked Sendable {
    
    static let schema = "music"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @OptionalParent(key: "artwork_id")
    var artwork: Image?
    
    @Field(key: "episode_number")
    var episodeNumber: Int?
    
    @Field(key: "episode_title")
    var episodeTitle: String
    
    @Field(key: "genre")
    var genre: String?
    
    @Parent(key: "owner_id")
    var owner: User
    
    @Children(for: \.$podcast)
    private var podcastNotes: [PodcastNote]
    
    @OptionalParent(key: "preview_id")
    var preview: Preview?
    
    @Field(key: "release_date")
    var releaseDate: Date?
    
    @Field(key: "season")
    var seasonNumber: Int?

    @Field(key: "title")
    var title: String
    
    var notes: [Note] {
        podcastNotes.map { $0.$note.wrappedValue }
    }
    
//    func resource(for platform: MediaPlatform<Podcast>) -> MediaResource<Podcast>? {
//        resources.first { $0.platform == platform }
//    }
//    
//    func upsert(resource: MediaResource<Podcast>, on database: any Database) async throws {
//        try await $resources.upsert(resource, on: database)
//    }
//    
//    func upsert(resources: [MediaResource<Podcast>], on database: any Database) async throws {
//        try await $resources.upsert(resources, on: database)
//    }
}


//extension MediaPlatform where ContentType == Podcast {
//    
//    /// Apple's Podcast app
//    ///
//    static let podcast: Self = "podcast"
//    
//    static let spotify: Self = "spotify"
//}
//
//extension Set where Element == MediaPlatform<Podcast> {
//    static var podcast: Set<MediaPlatform<Podcast>> {
//        [.podcast, .spotify]
//    }
//}
//
//extension OptionalChildProperty where From == Media, To == Podcast {
//    func load(on database: any Database, eager: Bool) async throws {
//        try await load(on: database).get()
//        guard eager else { return }
//        try await wrappedValue?.$resources.load(on: database)
//    }
//}
