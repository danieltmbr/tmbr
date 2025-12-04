import Foundation
import AuthKit
import Vapor

struct NotePayload: Decodable {
    
    let body: String
    
    let access: Access
}
