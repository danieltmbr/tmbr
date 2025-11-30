import AuthKit

extension PermissionScopes {
    var notes: PermissionScopes.Notes.Type { PermissionScopes.Notes.self }
}

extension PermissionScopes {
    struct Notes: PermissionScope, Sendable {
        
        let access: Permission<Note>
        
        let create: AuthPermission<Void>
        
        let delete: AuthPermission<Note>
        
        let edit: AuthPermission<Note>
        
        init(
            access: Permission<Note> = .accessNote,
            create: AuthPermission<Void> = .createNote,
            delete: AuthPermission<Note> = .deleteNote,
            edit: AuthPermission<Note> = .editNote
        ) {
            self.access = access
            self.create = create
            self.delete = delete
            self.edit = edit
        }
    }
}
