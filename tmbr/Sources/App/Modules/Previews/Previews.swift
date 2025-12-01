import Vapor
import Fluent
import Core
import AuthKit

struct Previews: Module {
    
    private let commands: Commands.Previews
    
    private let permissions: PermissionScopes.Previews
    
    init(
        commands: Commands.Previews,
        permissions: PermissionScopes.Previews
    ) {
        self.commands = commands
        self.permissions = permissions
    }
    
    func configure(_ app: Application) async throws {
        app.migrations.add(CreatePreview())
        app.migrations.add(AddPreviewParentAccessAndOwner())
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {}
}

extension Module where Self == Previews {
    
    static var previews: Self {
        Previews(
            commands: Commands.Previews(),
            permissions: PermissionScopes.Previews()
        )
    }
}
