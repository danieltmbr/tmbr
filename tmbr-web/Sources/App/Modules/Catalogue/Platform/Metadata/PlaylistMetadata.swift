import Vapor
import Core

struct PlaylistMetadata: Encodable, AsyncResponseEncodable, Sendable {
    let artwork: MetadataArtwork?
    let description: String?
    let title: String?
    let tracks: [TrackMetadata]?
}
