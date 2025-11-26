import Fluent
import Vapor
import Foundation

@dynamicMemberLookup
final class Music: MediaItem, Content, @unchecked Sendable {
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
    fileprivate var resources: [MediaResource<Music>]

    init() {}
    
    convenience init(mediaID: Int) {
        self.init(mediaID: mediaID, entity: nil)
    }

    init(mediaID: Int, entity: Entity?) {
        self.$media.id = mediaID
        self.entity = entity
    }
    
    func resource(for platform: MediaPlatform<Music>) -> MediaResource<Music>? {
        resources.first { $0.platform == platform }
    }
    
    func upsert(resource: MediaResource<Music>, on database: any Database) async throws {
        try await $resources.upsert(resource, on: database)
    }
    
    func upsert(resources: [MediaResource<Music>], on database: any Database) async throws {
        try await $resources.upsert(resources, on: database)
    }
}

extension MediaPlatform where ContentType == Music {
    
    static let appleMusic: Self = "apple-music"
    
    static let genius: Self = "genius"
    
    static let spotify: Self = "spotify"
}

extension Set where Element == MediaPlatform<Music> {
    static var music: Set<MediaPlatform<Music>> {
        [.appleMusic, .spotify, .genius]
    }
}

extension OptionalChildProperty where From == Media, To == Music {
    func load(on database: any Database, eager: Bool) async throws {
        try await load(on: database).get()
        guard eager else { return }
        try await wrappedValue?.$resources.load(on: database)
    }
}
