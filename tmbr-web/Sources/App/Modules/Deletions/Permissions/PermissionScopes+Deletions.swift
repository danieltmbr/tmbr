import AuthKit

extension PermissionScopes {
    var deletions: PermissionScopes.Deletions.Type { PermissionScopes.Deletions.self }
}

extension PermissionScopes {
    struct Deletions: PermissionScope, Sendable {

        let list: Permission<Void>

        init(list: Permission<Void> = .listDeletions) {
            self.list = list
        }
    }
}
