import AuthKit

extension PermissionScopes {
    var auth: PermissionScopes.Auth.Type { PermissionScopes.Auth.self }
}

extension PermissionScopes {
    struct Auth: PermissionScope, Sendable {
        
        let signOut: AuthPermission<Void>
        
        init(signOut: AuthPermission<Void> = .signOut) {
            self.signOut = signOut
        }
    }
}
