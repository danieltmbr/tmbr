import Vapor
import Logging
import NIOCore
import NIOPosix
import Core

typealias Command = Core.Command
typealias Commands = Core.Commands
typealias Page = Core.Page
typealias Validator = Core.Validator

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)

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
        
        do {
            try await registry.configure(app)
            try await app.autoMigrate()
            try await registry.boot(app)
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            app.logger.report(error: error)
            try await app.asyncShutdown()
            throw error
        }
    }
}
