import Foundation
import Core

extension Commands {
    var notes: Commands.Notes.Type { Commands.Notes.self }
}

extension Commands {
    struct Notes: CommandCollection, Sendable {
        
        let batchCreate: CommandFactory<BatchCreateNoteInput, [Note]>
        
        let create: CommandFactory<CreateNoteInput, Note>
        
        let delete: CommandFactory<NoteID, Void>
                
        let edit: CommandFactory<EditNoteInput, Note>
        
        let query: CommandFactory<QueryNotesInput, [Note]>
        
        let search: CommandFactory<NoteQueryPayload, [Note]>
        
        init(
            batchCreate: CommandFactory<BatchCreateNoteInput, [Note]> = .createNotes,
            create: CommandFactory<CreateNoteInput, Note> = .createNote,
            delete: CommandFactory<NoteID, Void> = .deleteNote,
            edit: CommandFactory<EditNoteInput, Note> = .editNote,
            query: CommandFactory<QueryNotesInput, [Note]> = .queryNotes,
            search: CommandFactory<NoteQueryPayload, [Note]> = .searchNote
        ) {
            self.batchCreate = batchCreate
            self.create = create
            self.delete = delete
            self.edit = edit
            self.query = query
            self.search = search
        }
    }
}
