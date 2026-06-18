import Vapor
import Fluent
import Foundation
import CoreAuth
import CoreTmbr

struct BookPayload: Decodable, Sendable {
    
    let _csrf: String?

    let access: Access
    
    let author: String
    
    let cover: ImageID?
    
    let genre: String?
    
    let notes: [NotePayload]?
    
    let releaseDate: Date?
    
    let resourceURLs: [String]
    
    let title: String
}
