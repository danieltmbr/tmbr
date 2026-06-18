import CoreAuth

extension PermissionScopes {
    var compose: ComposePermissionScope.Type { ComposePermissionScope.self }
}

struct ComposePermissionScope: CompositionScope {}

extension PermissionCompositionResolver {
    func callAsFunction(_ definition: ComposeDefinition) -> ComposeDefinition {
        definition.filtered(allowed: callAsFunction(definition.allEntries))
    }
}
