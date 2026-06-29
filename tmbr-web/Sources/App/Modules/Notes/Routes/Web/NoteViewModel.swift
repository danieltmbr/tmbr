import Foundation
import WebCore
import WebAuth
import TmbrCore

struct NoteViewModel: Encodable, Sendable {

    struct EditDetails: Encodable, Sendable {
        let rawBody: String
        let access: String
        let language: String
    }

    private let id: NoteID

    private let body: String

    private let created: String

    private let editDetails: EditDetails?

    private let error: String?

    init(
        id: NoteID,
        body: String,
        created: String,
        editDetails: EditDetails? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.body = body
        self.created = created
        self.editDetails = editDetails
        self.error = error
    }

    init(
        note: Note,
        markdownFormatter formatter: MarkdownFormatter,
        isEditable: Bool,
        error: String? = nil
    ) throws {
        self.init(
            id: try note.requireID(),
            body: formatter.format(note.body),
            created: note.createdAt.formatted(.publishDate),
            editDetails: isEditable ? EditDetails(rawBody: note.body, access: note.access.rawValue, language: note.language.rawValue) : nil,
            error: error
        )
    }

    init(note: Note, isEditable: Bool = false, error: String? = nil) throws {
        try self.init(note: note, markdownFormatter: .html, isEditable: isEditable, error: error)
    }
}

struct NoteItemContext: Encodable, Sendable {
    let note: NoteViewModel
}

extension Template where Model == NoteItemContext {
    static let noteItem = Template(name: "Notes/note-item")
}
