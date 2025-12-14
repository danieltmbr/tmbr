import Vapor
import Fluent
import Foundation
import AuthKit

struct MoviePayload: Decodable, Sendable {
    
    let _csrf: String?

    let access: Access
    
    let cover: ImageID?
    
    let director: String?
    
    let genre: String?
    
    let notes: [NotePayload]?
    
    let releaseDate: Date
    
    let resourceURLs: [String]
    
    let title: String
}
