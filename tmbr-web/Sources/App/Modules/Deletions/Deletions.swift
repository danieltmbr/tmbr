import Vapor
import Fluent
import Core
import AuthKit
import TmbrCore

struct Deletions: Module {

    private let commands: Commands.Deletions

    init(commands: Commands.Deletions) {
        self.commands = commands
    }

    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateDeletion())
        app.databases.middleware.use(DeletionMiddleware<Note>(
            deletionType: .note,
            itemID: { $0.id?.uuidString },
            ownerID: { $0.$author.id },
            access: { $0.access }
        ))
        app.databases.middleware.use(DeletionMiddleware<Preview>(
            deletionType: .catalogueItem,
            itemID: { $0.id?.uuidString },
            ownerID: { $0.$parentOwner.id },
            access: { $0.parentAccess }
        ))
        app.databases.middleware.use(DeletionMiddleware<Post>(
            deletionType: .post,
            itemID: { $0.id.map(String.init) },
            ownerID: { $0.$author.id },
            access: { $0.state == .published ? .public : .private }
        ))
        try await app.permissions.add(scope: PermissionScopes.Deletions())
        try await app.commands.add(collection: commands)
    }

    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: DeletionsAPIController())
    }
}

extension Module where Self == Deletions {
    static var deletions: Self {
        Deletions(commands: Commands.Deletions())
    }
}
