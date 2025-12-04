import Foundation
import Core

extension Commands {
    var notes: Commands.Notes.Type { Commands.Notes.self }
}

extension Commands {
    struct Notes: CommandCollection, Sendable {
                
        let create: CommandFactory<CreateNoteInput, Note>
        
        let delete: CommandFactory<NoteID, Void>
                
        let edit: CommandFactory<EditNoteInput, Note>
        
        let search: CommandFactory<NoteQueryPayload, [Note]>
        
        init(
            create: CommandFactory<CreateNoteInput, Note> = .createNote,
            delete: CommandFactory<NoteID, Void> = .deleteNote,
            edit: CommandFactory<EditNoteInput, Note> = .editNote,
            search: CommandFactory<NoteQueryPayload, [Note]> = .searchNote
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.search = search
        }
    }
}
