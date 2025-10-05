import Vapor

public protocol Configuration {
    func configure(_ app: Application) async throws
}

public struct CoreConfiguration: Configuration {
    
    private let config: (Application) async throws -> Void
    
    public init(configure: @escaping (Application) async throws -> Void) {
        self.config = configure
    }
    
    public func configure(_ app: Application) async throws {
        try await config(app)
    }
}
