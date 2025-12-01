import Foundation
import Core

extension Commands {
    var notes: Commands.Notes.Type { Commands.Notes.self }
}

extension Commands {
    struct Notes: CommandCollection, Sendable {
                
        let create: CommandFactory<NotePayload, Note>
        
        let delete: CommandFactory<NoteID, Void>
                
        let edit: CommandFactory<EditNotePayload, Note>
        
        init(
            create: CommandFactory<NotePayload, Note> = .createNote,
            delete: CommandFactory<NoteID, Void> = .deleteNote,
            edit: CommandFactory<EditNotePayload, Note> = .editNote
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
        }
    }
}
