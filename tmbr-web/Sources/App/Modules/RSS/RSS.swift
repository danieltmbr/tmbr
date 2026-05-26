import Vapor
import Core
import Fluent

struct RSS: Module {
    
    func configure(_ app: Vapor.Application) async throws {}
    
    func boot(_ routes: RoutesBuilder) async throws {
        routes.get("rss.xml", page: .rss)
    }
}

extension Module where Self == RSS {
    static var rss: Self {
        RSS()
    }
}
