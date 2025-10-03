import Vapor

public protocol Configuration {
    func configure(_ app: Application) throws
}

public struct CoreConfiguration: Configuration {
    
    private let config: (Application) throws -> Void
    
    public init(configure: @escaping (Application) throws -> Void) {
        self.config = configure
    }
    
    public func configure(_ app: Application) throws {
        try config(app)
    }
}
