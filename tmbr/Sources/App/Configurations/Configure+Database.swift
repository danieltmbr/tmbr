import Fluent
import FluentPostgresDriver
import Vapor

func configureDatabase(_ app: Application) throws {
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.database.hostname,
        port: Environment.database.port,
        username: Environment.database.username,
        password: Environment.database.password,
        database: Environment.database.database,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreatePost())
    app.migrations.add(CreateUser())
}
