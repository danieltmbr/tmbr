import Vapor
import Core

func configure(_ app: Application) async throws {
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
    try await registry.boot(app.routes)
    #if DEBUG || VAPOR_TESTING
    if app.environment == .testing {
        registerTestOnlyRoutes(app)
    }
    #endif
}
