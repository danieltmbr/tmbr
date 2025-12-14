import Foundation

struct NoteViewModel: Encodable, Sendable {
    
    private let id: NoteID
    
    private let body: String
    
    private let created: String
    
    init(id: NoteID, body: String, created: String) {
        self.id = id
        self.body = body
        self.created = created
    }
    
    init(note: Note) throws {
        self.init(
            id: try note.requireID(),
            body: note.body,
            created: (note.createdAt ?? .now).formatted(.publishDate)
        )
    }
}
