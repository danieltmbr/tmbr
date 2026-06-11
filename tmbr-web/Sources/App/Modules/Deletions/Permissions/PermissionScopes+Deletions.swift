import AuthKit

extension PermissionScopes {
    var deletions: PermissionScopes.Deletions.Type { PermissionScopes.Deletions.self }
}

extension PermissionScopes {
    struct Deletions: PermissionScope, Sendable {

        let list: AuthPermission<Void>

        init(list: AuthPermission<Void> = .listDeletions) {
            self.list = list
        }
    }
}
