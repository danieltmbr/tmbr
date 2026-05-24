import Fluent
import FluentPostgresDriver
import Vapor
import Core

extension Configuration where Self == CoreConfiguration {
    static var database: Self {
        CoreConfiguration { app in
            try app.databases.use(
                DatabaseConfigurationFactory(environment: app.environment),
                as: .psql
            )
        }
    }
}

private extension DatabaseConfigurationFactory {
    enum ConfigurationError: Error {
        case missingEnvironmentVariable(String)
    }
    
    private static var development: DatabaseConfigurationFactory {
        get throws {
            guard let hostname = Environment.get("DATABASE_HOST") else {
                throw ConfigurationError.missingEnvironmentVariable("DATABASE_HOST")
            }
            guard let username = Environment.get("DATABASE_USERNAME") else {
                throw ConfigurationError.missingEnvironmentVariable("DATABASE_USERNAME")
            }
            guard let password = Environment.get("DATABASE_PASSWORD") else {
                throw ConfigurationError.missingEnvironmentVariable("DATABASE_PASSWORD")
            }
            guard let database = Environment.get("DATABASE_NAME") else  {
                throw ConfigurationError.missingEnvironmentVariable("DATABASE_NAME")
            }
            
            let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
            
            let configuration = try SQLPostgresConfiguration(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: database,
                tls: .prefer(NIOSSLContext(configuration: .clientDefault))
            )
            return .postgres(configuration: configuration)
        }
    }
    
    private static var production: DatabaseConfigurationFactory {
        get throws {
            guard let databaseURL = Environment.get("DATABASE_URL").flatMap(URL.init(string:)) else {
                throw ConfigurationError.missingEnvironmentVariable("DATABASE_URL")
            }
            
            var tlsConfig: TLSConfiguration = .makeClientConfiguration()
            tlsConfig.certificateVerification = .none
            
            var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
            postgresConfig.coreConfiguration.tls = try .require(NIOSSLContext(configuration: tlsConfig))
            
            return .postgres(configuration: postgresConfig)
        }
    }
    
    init(environment: Environment) throws {
        switch environment {
        case .production:
            self = try .production
        default:
            self = try .development
        }
    }
}
