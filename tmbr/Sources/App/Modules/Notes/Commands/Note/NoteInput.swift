import AuthKit
import Foundation
import Vapor

struct NoteInput: Decodable {
    
    let access: Access

    let body: String
    
    init(access: Access, body: String) {
        self.access = access
        self.body = body
    }
    
    init(payload: NotePayload) {
        self.init(access: payload.access, body: payload.body)
    }
        
    func validate() throws {
        guard !body.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "Body is required")
        }
    }
}
