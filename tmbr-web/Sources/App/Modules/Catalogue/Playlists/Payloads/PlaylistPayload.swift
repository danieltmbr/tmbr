import Vapor
import Foundation
import AuthKit
import TmbrCore

struct PlaylistPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let artwork: ImageID?

    let description: String?

    let notes: [NotePayload]?

    let resourceURLs: [String]

    let title: String
}
