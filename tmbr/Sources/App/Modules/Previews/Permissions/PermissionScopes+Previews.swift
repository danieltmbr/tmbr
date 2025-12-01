import AuthKit
import Fluent

extension PermissionScopes {
    var previews: PermissionScopes.Previews.Type { PermissionScopes.Previews.self }
}

extension PermissionScopes {
    struct Previews: PermissionScope, Sendable {
        
        let access: Permission<Preview>
        
        let edit: AuthPermission<Preview>
        
        let query: Permission<QueryBuilder<Preview>>
        
        init(
            access: Permission<Preview> = .accessPreview,
            edit: AuthPermission<Preview> = .editPreview,
            query: Permission<QueryBuilder<Preview>> = .queryPreview
        ) {
            self.access = access
            self.edit = edit
            self.query = query
        }
    }
}
