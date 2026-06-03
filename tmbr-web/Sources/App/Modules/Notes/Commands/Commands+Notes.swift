import Foundation
import Core
import TmbrCore

extension Commands {
    var notes: Commands.Notes.Type { Commands.Notes.self }
}

extension Commands {
    struct Notes: CommandCollection, Sendable {

        let batchCreate: CommandFactory<BatchCreateNoteInput, [Note]>

        let create: CommandFactory<CreateNoteInput, Note>

        let delete: CommandFactory<NoteID, Void>

        let edit: CommandFactory<EditNoteInput, Note>

        let fetch: CommandFactory<NoteID, Note>

        let query: CommandFactory<QueryNotesInput, [Note]>

        let search: CommandFactory<NoteQueryPayload, [Note]>

        let sync: CommandFactory<SyncNotesInput, [Note]>

        init(
            batchCreate: CommandFactory<BatchCreateNoteInput, [Note]> = .createNotes,
            create: CommandFactory<CreateNoteInput, Note> = .createNote,
            delete: CommandFactory<NoteID, Void> = .deleteNote,
            edit: CommandFactory<EditNoteInput, Note> = .editNote,
            fetch: CommandFactory<NoteID, Note> = .fetchNote,
            query: CommandFactory<QueryNotesInput, [Note]> = .queryNotes,
            search: CommandFactory<NoteQueryPayload, [Note]> = .searchNote,
            sync: CommandFactory<SyncNotesInput, [Note]> = .syncNotes
        ) {
            self.batchCreate = batchCreate
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.query = query
            self.search = search
            self.sync = sync
        }
    }
}
