import AuthKit

extension PermissionScopes {
    var catalogue: PermissionScopes.Catalogue.Type { PermissionScopes.Catalogue.self }
}

extension PermissionScopes {
    struct Catalogue: PermissionScope, Sendable {
        
        let metadata: AuthPermission<Void>
        
        init(
            metadata: AuthPermission<Void> = AuthPermission<Void>()
        ) {
            self.metadata = metadata
        }
    }
}
