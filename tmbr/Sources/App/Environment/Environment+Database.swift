import Vapor
import FluentPostgresDriver

extension Environment {
    struct Database {
        let hostname = Environment.get("DATABASE_HOST")!
        
        let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
        
        let username = Environment.get("DATABASE_USERNAME")!
        
        let password = Environment.get("DATABASE_PASSWORD")!
        
        let database = Environment.get("DATABASE_NAME")!
        
        var config: DatabaseConfigurationFactory {
            get throws {
                let databaseURL: URL
                let tlsConfiguration: PostgresConnection.Configuration.TLS
                
                if let url = Environment.get("DATABASE_URL").flatMap(URL.init(string:)) {
                    databaseURL = url
                    var config: TLSConfiguration = .makeClientConfiguration()
                    config.certificateVerification = .none
                    tlsConfiguration = try .require(NIOSSLContext(configuration: config))
                } else {
                    databaseURL = URL(string: "postgresql://\(username):\(password)@\(hostname):\(port)/\(database)")!
                    tlsConfiguration = try .prefer(NIOSSLContext(configuration: .clientDefault))
                }
                
                var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
                postgresConfig.coreConfiguration.tls = tlsConfiguration
                return .postgres(configuration: postgresConfig)
            }
        }
    }

    /// Evironment values for setting up the Database
    static let database = Database()
}
