import Foundation
import Vapor

struct AlbumMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let artist: String?

    let artwork: String?

    let externalID: String?

    let releaseDate: String?

    let title: String?
}
