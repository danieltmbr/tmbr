import Foundation
import Vapor

struct MovieMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let title: String?

    let director: String?

    let cover: String?

    let releaseDate: String?

    let externalID: String?
}
