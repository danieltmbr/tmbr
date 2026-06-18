import CoreAuth
import Foundation
import Vapor
import CoreTmbr

struct NoteInput: Decodable {

    let access: Access

    let body: String

    let language: Language

    init(access: Access, body: String, language: Language = .en) {
        self.access = access
        self.body = body
        self.language = language
    }

    init(payload: NotePayload) {
        self.init(access: payload.access, body: payload.body, language: payload.language ?? .en)
    }
        
    func validate() throws {
        guard !body.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "Body is required")
        }
    }
}
