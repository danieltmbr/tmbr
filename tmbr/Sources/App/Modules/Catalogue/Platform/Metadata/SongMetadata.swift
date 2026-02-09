import Foundation
import Vapor

struct SongMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let album: String?

    let artist: String?

    let artwork: String?

    let externalID: String?

    let releaseDate: String?

    let title: String?
}
