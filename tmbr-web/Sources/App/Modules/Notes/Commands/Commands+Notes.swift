import Foundation
import Core
import TmbrCore

extension Commands {
    var notes: Commands.Notes.Type { Commands.Notes.self }
}

extension Commands {
    struct Notes: CommandCollection, Sendable {

        let batchFetch: CommandFactory<BatchFetchNotesInput, [PreviewID: [Note]]>

        let batchCreate: CommandFactory<BatchCreateNoteInput, [Note]>

        let create: CommandFactory<CreateNoteInput, Note>

        let delete: CommandFactory<NoteID, Void>

        let edit: CommandFactory<EditNoteInput, Note>

        let fetch: CommandFactory<NoteID, Note>

        let fetchByAttachment: CommandFactory<PreviewID, [Note]>

        let query: CommandFactory<QueryNotesInput, [Note]>

        let search: CommandFactory<NoteQueryPayload, [Note]>

        let list: CommandFactory<ListNotesInput, [Note]>

        let sync: CommandFactory<SyncNotesInput, [Note]>

        init(
            batchFetch: CommandFactory<BatchFetchNotesInput, [PreviewID: [Note]]> = .batchFetchNotes,
            batchCreate: CommandFactory<BatchCreateNoteInput, [Note]> = .createNotes,
            create: CommandFactory<CreateNoteInput, Note> = .createNote,
            delete: CommandFactory<NoteID, Void> = .deleteNote,
            edit: CommandFactory<EditNoteInput, Note> = .editNote,
            fetch: CommandFactory<NoteID, Note> = .fetchNote,
            fetchByAttachment: CommandFactory<PreviewID, [Note]> = .fetchNotesByAttachment,
            list: CommandFactory<ListNotesInput, [Note]> = .listNotes,
            query: CommandFactory<QueryNotesInput, [Note]> = .queryNotes,
            search: CommandFactory<NoteQueryPayload, [Note]> = .searchNote,
            sync: CommandFactory<SyncNotesInput, [Note]> = .syncNotes
        ) {
            self.batchFetch = batchFetch
            self.batchCreate = batchCreate
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.fetchByAttachment = fetchByAttachment
            self.list = list
            self.query = query
            self.search = search
            self.sync = sync
        }
    }
}
