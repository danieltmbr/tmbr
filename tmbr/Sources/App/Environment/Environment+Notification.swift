import Vapor
import WebPush

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
