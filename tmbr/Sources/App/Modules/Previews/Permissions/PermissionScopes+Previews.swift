import AuthKit

extension PermissionScopes {
    var previews: PermissionScopes.Previews.Type { PermissionScopes.Previews.self }
}

extension PermissionScopes {
    struct Previews: PermissionScope, Sendable {
        
        let access: Permission<Preview>
        
        let edit: AuthPermission<Preview>
        
        init(
            access: Permission<Preview> = .accessPreview,
            edit: AuthPermission<Preview> = .editPreview,
        ) {
            self.access = access
            self.edit = edit
        }
    }
}
