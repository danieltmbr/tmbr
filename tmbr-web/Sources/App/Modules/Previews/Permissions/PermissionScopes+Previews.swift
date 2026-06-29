import WebAuth
import Fluent

extension PermissionScopes {
    var previews: PermissionScopes.Previews.Type { PermissionScopes.Previews.self }
}

extension PermissionScopes {
    struct Previews: PermissionScope, Sendable {

        let access: Permission<Preview>

        let create: AuthPermission<Void>

        let edit: AuthPermission<Preview>

        let query: Permission<QueryBuilder<Preview>>

        init(
            access: Permission<Preview> = .accessPreview,
            create: AuthPermission<Void> = .create("You don't have permission to create a catalogue item."),
            edit: AuthPermission<Preview> = .editPreview,
            query: Permission<QueryBuilder<Preview>> = .queryPreview
        ) {
            self.access = access
            self.create = create
            self.edit = edit
            self.query = query
        }
    }
}
