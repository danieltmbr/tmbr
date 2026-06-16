import Vapor
import CoreWeb
import CoreAuth

func configure(_ app: Application) async throws {
    app.middleware.use(AppleSignInTokenParser())

    let registry = ModuleRegistry(
        configurations: [
            .logging,
            .database,
            .commands,
            .renderer,
            .content,
        ],
        modules: [
            .rss,
            .manifest,
            .authentication,
            .notifications,
            .gallery,
            .previews,
            .notes,
            .posts,
            .catalogue
        ]
    )
    try await registry.configure(app)

    app.migrations.add(CreateDeletion())
    try await app.permissions.add(scope: PermissionScopes.Deletions())
    try await app.commands.add(collection: Commands.Deletions())

    try await registry.boot(app.routes)
    try app.routes.register(collection: DeletionsAPIController())
}
