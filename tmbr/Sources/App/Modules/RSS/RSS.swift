import Vapor
import Core
import Fluent

struct RSS: Module {
    
    func configure(_ app: Vapor.Application) throws {}
    
    func boot(_ app: Vapor.Application) throws {
        app.get("rss.xml", page: .rss)
    }
}

extension Module where Self == RSS {
    static var rss: Self {
        RSS()
    }
}
