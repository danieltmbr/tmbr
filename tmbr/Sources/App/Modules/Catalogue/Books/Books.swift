import Vapor
import Fluent
import Core
import AuthKit

struct Books: Module {
    
    private let commands: CommandCollection
    
    private let permissions: PermissionScope
    
    init(
        commands: CommandCollection,
        permissions: PermissionScope
    ) {
        self.commands = commands
        self.permissions = permissions
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateBook())
        app.databases.middleware.use(PreviewModelMiddleware.book, on: .psql)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {

    }
}

extension Module where Self == Books {
    static var books: Self {
        Books(
            commands: Commands.Books(),
            permissions: PreviewablePermissionScope.books
        )
    }
}
