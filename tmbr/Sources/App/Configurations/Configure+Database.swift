import Fluent
import FluentPostgresDriver
import Vapor

func configureDatabase(_ app: Application) throws {
    try app.databases.use(
        DatabaseConfigurationFactory(environment: app.environment),
        as: .psql
    )
    
    app.migrations.add(CreatePost())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateSubscription())
}
