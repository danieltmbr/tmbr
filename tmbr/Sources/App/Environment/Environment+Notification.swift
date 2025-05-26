import Vapor
import WebPush

extension Environment {
    struct WebApp: Sendable {
        /// Name of the installed Progressive Web App
        let appName = Environment.get("PWA_APP_NAME")!
        
        /// Start URL of the installed Progressive Web App
        let startURL = Environment.get("PWA_START_URL")!
    }
    
    struct WebPush: Sendable {
        /// Authorization key for sending out notifications
        let notifyApiKey = Environment.get("NOTIFY_API_KEY")
        
        /// Configuration JSON for web push
        let vapidConfig = Environment.get("VAPID_CONFIG")
    }
    
    /// Evironment values for Web Push
    static let webPush = WebPush()

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
        guard let configJSON = Environment.webPush.vapidConfig else {
            throw ConfigurationError.missingEnvironmentVariable("VAPID_CONFIG")
        }
        let configuration = try decoder.decode(Self.self, from: Data(configJSON.utf8))
        guard configuration.primaryKey != nil else {
            throw ConfigurationError.missingPrimaryKey
        }
        self = configuration
    }
}
