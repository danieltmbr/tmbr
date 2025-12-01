import Foundation

struct QuoteQueryPayload: Decodable, Sendable {

    let term: String?
    
    let types: Set<String>?
}
