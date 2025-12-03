import Foundation

struct Resource: Codable, Sendable {
    
    let platform: String
    
    let url: URL
    
    let externalID: String?
}
