import Foundation
import Vapor

struct TrackMetadata: Codable, Sendable {
    let name: String
    let url: String?
}

struct AlbumMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let artist: String?

    let artwork: String?

    let externalID: String?

    let releaseDate: String?

    let title: String?

    let tracks: [TrackMetadata]?
}
