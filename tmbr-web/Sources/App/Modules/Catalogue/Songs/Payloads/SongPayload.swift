import Vapor
import Fluent
import Foundation
import WebAuth
import TmbrCore

struct SongPayload: Decodable, Sendable {
    
    let _csrf: String?

    let access: Access
    
    let album: String?
    
    let artist: String
    
    let artwork: ImageID?
    
    let genre: String?
    
    let notes: [NotePayload]?
    
    let releaseDate: Date?
    
    let resourceURLs: [String]
        
    let title: String
}
