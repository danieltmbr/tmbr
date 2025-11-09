import Vapor
import Foundation

@dynamicMemberLookup
struct EditPostPayload: Sendable {
    
    let id: PostID
    
    private let payload: PostPayload
    
    init(id: PostID, payload: PostPayload) {
        self.id = id
        self.payload = payload
    }
    
    subscript <V>(dynamicMember keyPath: KeyPath<PostPayload, V>) -> V {
        payload[keyPath: keyPath]
    }
}

extension PostPayload {
    func edit(id: PostID) -> EditPostPayload {
        EditPostPayload(id: id, payload: self)
    }
}
