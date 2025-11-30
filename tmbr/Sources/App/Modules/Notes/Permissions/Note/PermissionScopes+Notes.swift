import AuthKit
import Fluent

extension PermissionScopes {
    var notes: PermissionScopes.Notes.Type { PermissionScopes.Notes.self }
}

extension PermissionScopes {
    struct Notes: PermissionScope, Sendable {
                
        let create: AuthPermission<Void>
        
        let delete: AuthPermission<Note>
        
        let edit: AuthPermission<Note>
        
        let query: Permission<QueryBuilder<Note>>
        
        init(
            create: AuthPermission<Void> = .createNote,
            delete: AuthPermission<Note> = .deleteNote,
            edit: AuthPermission<Note> = .editNote,
            query: Permission<QueryBuilder<Note>> = .queryNote
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.query = query
        }
    }
}
