import Vapor
import FluentPostgresDriver

extension Environment {
    struct Database {
        let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
        
        let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
        
        let username = Environment.get("DATABASE_USERNAME") ?? "postgres"
        
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        
        let database = Environment.get("DATABASE_NAME") ?? "tmbr"
    }

    /// Evironment values for setting up the Database
    static let database = Database()
}
