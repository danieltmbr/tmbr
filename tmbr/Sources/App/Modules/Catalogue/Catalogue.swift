import Vapor
import Fluent
import Core
import AuthKit

struct Catalogue: Module {
        
    private let media: ModuleRegistry
    
    init(
        media: ModuleRegistry
    ) {
        self.media = media
    }

    func configure(_ app: Vapor.Application) async throws {
        try await app.permissions.add(scope: PermissionScopes.Catalogue())
        try await app.commands.add(collection: Commands.Catalogue())
        try await media.configure(app)

        // Run after all catalogue sub-modules have added their table migrations
        app.migrations.add(DeferPreviewForeignKeys())
        app.migrations.add(DropOldPreviewForeignKeys())
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try await media.boot(routes)
        try routes.register(collection: CatalogueAPIController())
        try routes.register(collection: CatalogueWebController())
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self {
        Catalogue(
            media: ModuleRegistry(
                configurations: [],
                modules: [
                    .books,
                    .movies,
                    .podcasts,
                    .songs,
                ]
            )
        )
    }
}
