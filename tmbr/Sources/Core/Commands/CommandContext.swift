import Foundation
import Fluent
import Vapor

struct CommandContext: Sendable {
    
    @TaskLocal
    static var database: (any Database)? = nil
}


extension Request {
    
    /// Database to inject into Commands.
    ///
    /// The command db is either the application's main db or
    /// it is an emphemeral db of a transaction.
    ///
    /// The latter allows us to execute multiple commands under
    /// a single transaction while keeping the Commands agnostic
    /// from this information.
    ///
    /// In order to leverage this feature the CommandFactory creating
    /// a command needs to use this computed property instead
    /// of accessing the request's db directly.
    ///
    public var commandDB: any Database {
        CommandContext.database ?? application.db
    }
}
