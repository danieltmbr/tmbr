import Foundation
import Core

struct NoteViewModel: Encodable, Sendable {

    private let id: NoteID

    private let body: String

    private let created: String

    init(id: NoteID, body: String, created: String) {
        self.id = id
        self.body = body
        self.created = created
    }
    
    init(
        note: Note,
        markdownFormatter formatter: MarkdownFormatter
    ) throws {
        self.init(
            id: try note.requireID(),
            body: formatter.format(note.body),
            created: (note.createdAt ?? .now).formatted(.publishDate)
        )
    }


    init(
        note: Note
    ) throws {
        try self.init(
            note: note,
            markdownFormatter: .html
        )
    }
}
