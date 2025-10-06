import Vapor
import Logging
import NIOCore
import NIOPosix
import Core

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)

        let registry = ModuleRegistry(
            configurations: [
                .database,
                .renderer,
            ],
            modules: [
                .rss,
                .manifest,
                .authentication,
                .notifications,
                .posts,
                .gallery,
            ]
        )
        
        do {
            try await registry.configure(app)
            // try app.autoMigrate().wait()
            try await registry.boot(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.execute()
        try await app.asyncShutdown()
    }
}
