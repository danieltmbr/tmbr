import Fluent
import FluentPostgresDriver
import Vapor

func configureDatabase(_ app: Application) throws {
    try app.databases.use(Environment.database.config, as: .psql)
    
    app.migrations.add(CreatePost())
    app.migrations.add(CreateUser())
}
