import Vapor
import Fluent
import Foundation
import AuthKit

struct PodcastPayload: Decodable, Sendable {
    
    let _csrf: String?

    let access: Access
    
    let artwork: ImageID?
    
    let episodeNumber: Int?
    
    let episodeTitle: String
    
    let genre: String?
    
    let notes: [NotePayload]?
    
    let releaseDate: Date?
    
    let resourceURLs: [String]
    
    let seasonNumber: Int?
    
    let title: String
}
