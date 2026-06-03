import Foundation

struct PostQueryPayload: Decodable, Sendable {
    let term: String?
}
