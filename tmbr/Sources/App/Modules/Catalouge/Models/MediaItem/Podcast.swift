import Fluent
import Vapor
import Foundation

@dynamicMemberLookup
final class Podcast: MediaItem, Content, @unchecked Sendable {
    static let schema = "media_podcasts"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "media_id")
    var media: Media

    @Children(for: \.$podcast)
    fileprivate var resources: [MediaResource<Podcast>]

    init() {}

    init(mediaID: Int) {
        self.$media.id = mediaID
    }
    
    func resource(for platform: MediaPlatform<Podcast>) -> MediaResource<Podcast>? {
        resources.first { $0.platform == platform }
    }
    
    func upsert(resource: MediaResource<Podcast>, on database: any Database) async throws {
        try await $resources.upsert(resource, on: database)
    }
    
    func upsert(resources: [MediaResource<Podcast>], on database: any Database) async throws {
        try await $resources.upsert(resources, on: database)
    }
}

extension MediaPlatform where ContentType == Podcast {
    
    /// Apple's Podcast app
    ///
    static let podcast: Self = "podcast"
    
    static let spotify: Self = "spotify"
}

extension Set where Element == MediaPlatform<Podcast> {
    static var podcast: Set<MediaPlatform<Podcast>> {
        [.podcast, .spotify]
    }
}

extension OptionalChildProperty where From == Media, To == Podcast {
    func load(on database: any Database, eager: Bool) async throws {
        try await load(on: database).get()
        guard eager else { return }
        try await wrappedValue?.$resources.load(on: database)
    }
}
