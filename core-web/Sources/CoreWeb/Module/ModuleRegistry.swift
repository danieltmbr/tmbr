import Vapor

public struct ModuleRegistry: Module {
    
    private let configurations: [Configuration]
    
    private let modules: [Module]
    
    public init(configurations: [Configuration], modules: [Module]) {
        self.configurations = configurations
        self.modules = modules
    }
    
    public func configure(_ app: Application) async throws {
        for config in (configurations + modules) {
            try await config.configure(app)
        }
    }
    
    public func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        for module in modules {
            try await module.boot(routes)
        }
    }
}
