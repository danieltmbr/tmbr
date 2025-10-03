import Vapor

public struct ModuleRegistry {
    
    private let configurations: [Configuration]
    
    private let modules: [Module]
    
    public init(configurations: [Configuration], modules: [Module]) {
        self.configurations = configurations
        self.modules = modules
    }
    
    public func configure(_ app: Application) throws {
        for config in (configurations + modules) {
            try config.configure(app)
        }
    }
    
    public func boot(_ app: Application) throws {
        for module in modules {
            try module.boot(app)
        }
    }
}
