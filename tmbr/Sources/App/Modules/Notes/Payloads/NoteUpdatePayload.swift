import Foundation
import AuthKit
import Vapor

@dynamicMemberLookup
struct EditNotePayload: Sendable {
    
    struct Content: Decodable, Sendable {
        
        let body: String
        
        let access: Access
        
        func validate() throws {
            guard !body.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "Body is required")
            }
        }
    }
    
    let id: NoteID
    
    private let content: Content
    
    init(id: NoteID, content: Content) {
        self.id = id
        self.content = content
    }
    
    subscript <V>(dynamicMember keyPath: KeyPath<Content, V>) -> V {
        content[keyPath: keyPath]
    }
    
    func validate() throws {
        try content.validate()
    }
}
