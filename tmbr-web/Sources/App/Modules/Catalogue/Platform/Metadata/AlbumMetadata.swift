import Foundation
import Vapor

struct TrackMetadata: Codable, Sendable {
    let name: String
    let url: String?
    var previewID: UUID? = nil
}

struct AlbumMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let artist: String?

    let artwork: String?

    let externalID: String?

    let genre: String?

    let releaseDate: String?

    let title: String?

    let tracks: [TrackMetadata]?
}
