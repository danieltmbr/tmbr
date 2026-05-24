import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?
    
    let types: Set<String>?
}
