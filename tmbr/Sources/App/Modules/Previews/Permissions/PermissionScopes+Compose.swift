import AuthKit

extension PermissionScopes {
    var compose: ComposePermissionScope.Type { ComposePermissionScope.self }
}

struct ComposePermissionScope: CompositionScope {}
