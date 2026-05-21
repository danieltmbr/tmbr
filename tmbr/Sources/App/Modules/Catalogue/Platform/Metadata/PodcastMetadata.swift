import Foundation
import Vapor

struct PodcastMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let episodeTitle: String?

    let showTitle: String?

    let artwork: String?

    let releaseDate: String?

    let episodeNumber: Int?

    let seasonNumber: Int?

    let externalID: String?
}
