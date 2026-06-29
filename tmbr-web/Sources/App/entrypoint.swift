import Vapor
import Logging
import NIOCore
import NIOPosix
import WebCore

typealias Command = WebCore.Command
typealias Commands = WebCore.Commands
typealias Page = WebCore.Page
typealias Validator = WebCore.Validator

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)

        do {
            try await configure(app)
            try await app.autoMigrate()
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            app.logger.report(error: error)
            try await app.asyncShutdown()
            throw error
        }
    }
}
