import Vapor
import Fluent
import Core
import AuthKit

struct Previews: Module {
    
    private let permissions: PermissionScopes.Previews
    
    init(
        permissions: PermissionScopes.Previews
    ) {
        self.permissions = permissions
    }
    
    func configure(_ app: Application) async throws {
        app.migrations.add(CreatePreview())
        app.migrations.add(AddPreviewParentAccessAndOwner())
        
        try await app.permissions.add(scope: permissions)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {}
}

extension Module where Self == Previews {
    
    static var previews: Self {
        Previews(permissions: PermissionScopes.Previews())
    }
}
