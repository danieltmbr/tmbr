import Fluent
import Vapor
import Foundation
import AuthKit

final class Music: Model, @unchecked Sendable {
    
    static let schema = "music"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "owner_id")
    var owner: User
    
    @Field(key: "album")
    var album: String?
    
    @Field(key: "artist")
    var artist: String
    
    @OptionalParent(key: "artwork_id")
    var artwork: Image?
    
    @Field(key: "genre")
    var genre: String?
    
    @Field(key: "release_date")
    var releaseDate: Date?

    @Field(key: "title")
    var title: String

    @OptionalParent(key: "preview_id")
    var preview: Preview?

    @Children(for: \.$music)
    private var musicNotes: [MusicNote]
    
    var notes: [Note] {
        musicNotes.map { $0.$note.wrappedValue }
    }
    
    func fetchPreview(on database: any Database) async throws -> Preview {
        try await $preview.load(on: database)
    }
}

//extension MediaPlatform where ContentType == Music {
//
//    static let appleMusic: Self = "apple-music"
//
//    static let genius: Self = "genius"
//
//    static let spotify: Self = "spotify"
//}
//
//extension Set where Element == MediaPlatform<Music> {
//    static var music: Set<MediaPlatform<Music>> {
//        [.appleMusic, .spotify, .genius]
//    }
//}
//
//extension OptionalChildProperty where From == Media, To == Music {
//    func load(on database: any Database, eager: Bool) async throws {
//        try await load(on: database).get()
//        guard eager else { return }
//        try await wrappedValue?.$resources.load(on: database)
//    }
//}
