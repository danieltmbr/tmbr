import Vapor
import Fluent
import Foundation
import AuthKit

struct AlbumPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let artist: String

    let artwork: ImageID?

    let genre: String?

    let notes: [NotePayload]?

    let releaseDate: Date?

    let resourceURLs: [String]

    let title: String
}
