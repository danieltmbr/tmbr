import Foundation

struct CatalogueQueryPayload: Decodable, Sendable {
    
    let term: String?
    
    let types: Set<String>?
}

