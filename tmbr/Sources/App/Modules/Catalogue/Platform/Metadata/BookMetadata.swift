import Foundation
import Vapor

struct BookMetadata: Encodable, AsyncResponseEncodable, Sendable {

    let author: String?

    let cover: String?

    let externalID: String?

    let releaseDate: String?

    let title: String?
}
