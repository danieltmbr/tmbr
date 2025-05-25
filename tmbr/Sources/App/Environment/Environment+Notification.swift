import Vapor
import WebPush

extension Environment {
    struct WebApp: Sendable {
        /// Name of the installed Progressive Web App
        let appName = Environment.get("PWA_APP_NAME")!
        
        /// Start URL of the installed Progressive Web App
        let startURL = Environment.get("PWA_START_URL")!
    }

    /// Evironment values for PWA
    static let webApp = WebApp()
}


extension VAPID.Configuration {
    enum ConfigurationError: Error {
        case missingEnvironmentVariable(String)
        case missingPrimaryKey
    }
    
    init(
        environment: Environment,
        decoder: JSONDecoder = .init()
    ) throws {
        guard let configJSON = Environment.get("VAPID_CONFIG") else {
            throw ConfigurationError.missingEnvironmentVariable("VAPID_CONFIG")
        }
        let configuration = try decoder.decode(Self.self, from: Data(configJSON.utf8))
        guard configuration.primaryKey != nil else {
            throw ConfigurationError.missingPrimaryKey
        }
        self = configuration
    }
}
