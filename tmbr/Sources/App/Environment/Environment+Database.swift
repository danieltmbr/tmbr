import Vapor
import FluentPostgresDriver

extension Environment {
    struct Database {
        let hostname = Environment.get("DATABASE_HOST")!
        
        let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
        
        let username = Environment.get("DATABASE_USERNAME")!
        
        let password = Environment.get("DATABASE_PASSWORD")!
        
        let database = Environment.get("DATABASE_NAME")!
    }

    /// Evironment values for setting up the Database
    static let database = Database()
}
