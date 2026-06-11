import Vapor
import Core
import AuthKit

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
            .deletions,
            .catalogue
        ]
    )
    try await registry.configure(app)
    try await registry.boot(app.routes)
}
