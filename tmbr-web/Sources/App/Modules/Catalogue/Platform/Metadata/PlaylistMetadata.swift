import Vapor
import CoreWeb

struct PlaylistMetadata: Encodable, AsyncResponseEncodable, Sendable {
    let artwork: MetadataArtwork?
    let createdAt: String?
    let description: String?
    let title: String?
    let tracks: [TrackMetadata]?
}
