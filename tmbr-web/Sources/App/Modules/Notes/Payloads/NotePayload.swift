import Foundation
import CoreAuth
import CoreTmbr

struct NotePayload: Decodable, Sendable {

    let id: String?

    let body: String

    let access: Access

    let language: Language?

    let deleted: Bool?

    init(body: String, access: Access = .private, language: Language = .en) {
        self.id = nil
        self.body = body
        self.access = access
        self.language = language
        self.deleted = nil
    }

    var noteID: NoteID? {
        guard let raw = id, !raw.isEmpty else { return nil }
        return UUID(uuidString: raw)
    }
}
