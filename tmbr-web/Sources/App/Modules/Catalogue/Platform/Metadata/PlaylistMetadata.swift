import Vapor
import Core

struct PlaylistMetadata: Encodable, AsyncResponseEncodable, Sendable {
    let artwork: String?
    let description: String?
    let title: String?
    let tracks: [TrackMetadata]?
}
