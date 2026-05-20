import Foundation
import AuthKit

struct NotePayload: Decodable, Sendable {

    let id: String?

    let body: String

    let access: Access

    let deleted: Bool?

    init(body: String, access: Access = .private) {
        self.id = nil
        self.body = body
        self.access = access
        self.deleted = nil
    }

    var noteID: NoteID? {
        guard let raw = id, !raw.isEmpty else { return nil }
        return UUID(uuidString: raw)
    }
}
