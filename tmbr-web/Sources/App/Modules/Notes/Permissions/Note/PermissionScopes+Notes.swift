import AuthKit
import Fluent

extension PermissionScopes {
    var notes: PermissionScopes.Notes.Type { PermissionScopes.Notes.self }
}

extension PermissionScopes {
    struct Notes: PermissionScope, Sendable {
                
        let attach: AuthPermission<AttachNotePermissionInput>

        let create: AuthPermission<Void>

        let delete: AuthPermission<Note>

        let edit: AuthPermission<Note>

        let list: AuthPermission<Void>

        let query: Permission<QueryBuilder<Note>>

        init(
            attach: AuthPermission<AttachNotePermissionInput> = .attachNote,
            create: AuthPermission<Void> = .createNote,
            delete: AuthPermission<Note> = .deleteNote,
            edit: AuthPermission<Note> = .editNote,
            list: AuthPermission<Void> = AuthPermission<Void>(),
            query: Permission<QueryBuilder<Note>> = .queryNote
        ) {
            self.attach = attach
            self.create = create
            self.delete = delete
            self.edit = edit
            self.list = list
            self.query = query
        }
    }
}
